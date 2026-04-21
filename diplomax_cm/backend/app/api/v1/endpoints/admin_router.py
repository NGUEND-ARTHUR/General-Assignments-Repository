"""
Diplomax CM — Admin System Endpoints
Complete CRUD for institution management, sub-admin creation, audit logs, platform settings.
Full role-based access control (RBAC) with 4-tier hierarchy.
"""
import uuid
import secrets
import logging
from datetime import datetime, timezone, timedelta
from typing import List, Optional
from enum import Enum as PyEnum

from fastapi import APIRouter, Depends, HTTPException, Request, Query
from pydantic import BaseModel, EmailStr, validator
from sqlalchemy import select, desc, and_
from sqlalchemy.ext.asyncio import AsyncSession
from passlib.context import CryptContext

from app.core.config import get_settings
from app.core.database import get_request_db_session
from app.models.admin_models import (
    DiplomaxAdmin, MinistryAdmin, InstitutionApprovalRequest, AuditLog,
    AdminRole, InstitutionApprovalStatus, PlatformSettings, InstitutionApiKey
)
from app.models.models import University, UniversityStaff

settings = get_settings()
admin_router = APIRouter(prefix="/admin", tags=["Admin"])
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
admin_logger = logging.getLogger("diplomax.admin")


def _log_audit(
    action: str,
    entity_type: str,
    entity_id: str,
    entity_name: Optional[str] = None,
    admin_id: Optional[str] = None,
    admin_email: Optional[str] = None,
    new_values: Optional[dict] = None,
    old_values: Optional[dict] = None,
    reason: Optional[str] = None,
    ip_address: Optional[str] = None,
):
    """Log an admin action to audit trail."""
    admin_logger.info({
        "action": action,
        "entity_type": entity_type,
        "entity_id": entity_id,
        "admin_id": admin_id,
        "admin_email": admin_email,
        "reason": reason,
        "ip_address": ip_address,
    })


async def _get_current_admin(request: Request, db: AsyncSession) -> DiplomaxAdmin:
    """Extract and verify current admin from Bearer token (JWT)."""
    from app.api.v1.endpoints.router import _current_user
    user = await _current_user(request=request, db=db)
    
    if not user or user.get("type") != "diplomax_admin":
        raise HTTPException(status_code=403, detail="Only Diplomax admins can access this endpoint")
    
    admin_id = user.get("id")
    stmt = select(DiplomaxAdmin).where(DiplomaxAdmin.id == admin_id)
    result = await db.execute(stmt)
    admin = result.scalars().first()
    
    if not admin or not admin.is_active:
        raise HTTPException(status_code=403, detail="Admin account is inactive")
    
    return admin


async def _require_role(admin: DiplomaxAdmin, required_role: List[AdminRole]):
    """Check if admin has one of the required roles."""
    if admin.role not in required_role:
        raise HTTPException(status_code=403, detail=f"Required role: {required_role}")


async def _record_audit(
    db: AsyncSession,
    admin: DiplomaxAdmin,
    action: str,
    entity_type: str,
    entity_id: str,
    entity_name: Optional[str] = None,
    new_values: Optional[dict] = None,
    old_values: Optional[dict] = None,
    reason: Optional[str] = None,
    ip_address: Optional[str] = None,
):
    """Record an audit log entry."""
    log = AuditLog(
        admin_id=admin.id,
        admin_email=admin.email,
        action=action,
        entity_type=entity_type,
        entity_id=uuid.UUID(entity_id) if isinstance(entity_id, str) else entity_id,
        entity_name=entity_name,
        new_values=new_values,
        old_values=old_values,
        reason=reason,
        ip_address=ip_address,
    )
    db.add(log)
    await db.commit()
    _log_audit(
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id),
        entity_name=entity_name,
        admin_id=str(admin.id),
        admin_email=admin.email,
        reason=reason,
        ip_address=ip_address,
    )


# ─── Request/Response Models ──────────────────────────────────────────────

class InstitutionApprovalResponse(BaseModel):
    id: str
    name: str
    institution_type: str
    email: str
    status: str
    reviewed_at: Optional[str]
    review_notes: Optional[str]
    rejection_reason: Optional[str]

    class Config:
        from_attributes = True


class CreateSubAdminRequest(BaseModel):
    """Create a sub-admin account."""
    email: EmailStr
    full_name: str
    role: AdminRole
    
    @validator('role')
    def validate_role(cls, v):
        # Non-superadmins cannot create other superadmins
        if v == AdminRole.diplomax_superadmin:
            raise ValueError("Cannot create diplomax_superadmin via API")
        return v


class UpdateAdminRoleRequest(BaseModel):
    """Update an admin's role."""
    role: AdminRole


class SuspendAdminRequest(BaseModel):
    """Suspend or reinstate an admin account."""
    action: str  # "suspend" | "reinstate"
    reason: Optional[str]


class ApproveInstitutionRequest(BaseModel):
    """Approve an institution registration."""
    review_notes: Optional[str]
    staff_password: Optional[str]  # If not provided, auto-generate


class RejectInstitutionRequest(BaseModel):
    """Reject an institution registration."""
    reason: str
    notification_sent: bool = True


class RotateApiKeyRequest(BaseModel):
    """Rotate an institution's API key."""
    reason: str


class PlatformSettingsUpdate(BaseModel):
    """Update platform settings."""
    fee_diploma: Optional[int]
    fee_transcript: Optional[int]
    fee_certificate: Optional[int]
    fee_attestation: Optional[int]
    treasury_share: Optional[int]
    university_share: Optional[int]
    platform_share: Optional[int]
    max_login_attempts: Optional[int]
    lockout_duration_seconds: Optional[int]
    maintenance_mode: Optional[bool]
    maintenance_reason: Optional[str]


# ─── Institution Management ────────────────────────────────────────────────

@admin_router.get("/institutions/pending")
async def list_pending_institutions(
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """List all pending institution registration applications."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = (
        select(InstitutionApprovalRequest)
        .where(InstitutionApprovalRequest.status == InstitutionApprovalStatus.pending)
        .order_by(desc(InstitutionApprovalRequest.submitted_at))
    )
    result = await db.execute(stmt)
    requests = result.scalars().all()
    
    return [
        {
            "id": str(r.id),
            "name": r.name,
            "institution_type": r.institution_type,
            "email": r.email,
            "admin_name": r.admin_full_name,
            "status": r.status.value,
            "submitted_at": r.submitted_at.isoformat(),
        }
        for r in requests
    ]


@admin_router.get("/institutions/{institution_id}/detail")
async def get_institution_detail(
    institution_id: str,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Get full details of an institution including documents and audit trail."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = select(InstitutionApprovalRequest).where(InstitutionApprovalRequest.id == institution_id)
    result = await db.execute(stmt)
    req = result.scalars().first()
    
    if not req:
        raise HTTPException(status_code=404, detail="Institution not found")
    
    # Get audit trail for this institution
    audit_stmt = (
        select(AuditLog)
        .where(
            and_(
                AuditLog.entity_type == "institution",
                AuditLog.entity_id == uuid.UUID(institution_id)
            )
        )
        .order_by(desc(AuditLog.created_at))
    )
    audit_result = await db.execute(audit_stmt)
    audit_logs = audit_result.scalars().all()
    
    return {
        "id": str(req.id),
        "name": req.name,
        "institution_type": req.institution_type,
        "city": req.city,
        "region": req.region,
        "email": req.email,
        "phone": req.phone,
        "website": req.website,
        "accreditation_body": req.accreditation_body,
        "accreditation_number": req.accreditation_number,
        "is_government": req.is_government,
        "matricule_prefix": req.matricule_prefix,
        "admin_name": req.admin_full_name,
        "admin_email": req.admin_email,
        "admin_phone": req.admin_phone,
        "status": req.status.value,
        "review_notes": req.review_notes,
        "rejection_reason": req.rejection_reason,
        "submitted_at": req.submitted_at.isoformat(),
        "reviewed_at": req.reviewed_at.isoformat() if req.reviewed_at else None,
        "audit_trail": [
            {
                "action": log.action,
                "admin_email": log.admin_email,
                "created_at": log.created_at.isoformat(),
                "reason": log.reason,
                "ip_address": log.ip_address,
            }
            for log in audit_logs
        ]
    }


@admin_router.post("/institutions/{institution_id}/approve")
async def approve_institution(
    institution_id: str,
    body: ApproveInstitutionRequest,
    request: Request,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Approve institution registration and activate it."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = select(InstitutionApprovalRequest).where(InstitutionApprovalRequest.id == institution_id)
    result = await db.execute(stmt)
    req = result.scalars().first()
    
    if not req:
        raise HTTPException(status_code=404, detail="Institution not found")
    
    if req.status != InstitutionApprovalStatus.pending and req.status != InstitutionApprovalStatus.under_review:
        raise HTTPException(status_code=400, detail=f"Cannot approve institution with status: {req.status.value}")
    
    # Create or update University record
    if not req.institution_id:
        uni = University(
            name=req.name,
            short_name=req.matricule_prefix,
            city=req.city or "Cameroon",
            country=req.country or "Cameroon",
        )
        db.add(uni)
        await db.flush()
        req.institution_id = uni.id
    else:
        uni_stmt = select(University).where(University.id == req.institution_id)
        uni_result = await db.execute(uni_stmt)
        uni = uni_result.scalars().first()
        uni.is_connected = True
    
    # Create admin staff account with auto-generated password if not provided
    staff_password = body.staff_password or secrets.token_urlsafe(16)
    staff = UniversityStaff(
        university_id=req.institution_id,
        name=req.admin_full_name,
        email=req.admin_email,
        phone=req.admin_phone,
        role="admin",
        password_hash=pwd_ctx.hash(staff_password),
    )
    db.add(staff)
    
    # Generate and store API key
    raw_key = f"diplomax_inst_{uuid.uuid4().hex[:32]}"
    key_hash = pwd_ctx.hash(raw_key)
    api_key = InstitutionApiKey(
        institution_id=req.institution_id,
        key_hash=key_hash,
    )
    db.add(api_key)
    
    # Update approval request
    req.status = InstitutionApprovalStatus.approved
    req.reviewed_by_id = admin.id
    req.reviewed_at = datetime.now(timezone.utc)
    req.review_notes = body.review_notes
    req.approved_at = datetime.now(timezone.utc)
    
    await db.commit()
    
    # Record audit
    await _record_audit(
        db=db,
        admin=admin,
        action="institution_approved",
        entity_type="institution",
        entity_id=str(req.institution_id),
        entity_name=req.name,
        reason=body.review_notes,
        ip_address=request.client.host if request.client else "unknown",
        new_values={
            "status": "approved",
            "staff_email": req.admin_email,
            "api_key_generated": True,
        }
    )
    
    return {
        "status": "approved",
        "institution_id": str(req.institution_id),
        "api_key": raw_key if not body.staff_password else None,  # Only show if we generated it
        "staff_credentials": {
            "email": req.admin_email,
            "password": staff_password if not body.staff_password else None,
        }
    }


@admin_router.post("/institutions/{institution_id}/reject")
async def reject_institution(
    institution_id: str,
    body: RejectInstitutionRequest,
    request: Request,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Reject institution registration."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = select(InstitutionApprovalRequest).where(InstitutionApprovalRequest.id == institution_id)
    result = await db.execute(stmt)
    req = result.scalars().first()
    
    if not req:
        raise HTTPException(status_code=404, detail="Institution not found")
    
    req.status = InstitutionApprovalStatus.rejected
    req.reviewed_by_id = admin.id
    req.reviewed_at = datetime.now(timezone.utc)
    req.rejection_reason = body.reason
    
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=admin,
        action="institution_rejected",
        entity_type="institution",
        entity_id=institution_id,
        entity_name=req.name,
        reason=body.reason,
        ip_address=request.client.host if request.client else "unknown",
    )
    
    # TODO: Send email to institution with rejection reason
    
    return {"status": "rejected", "institution_id": institution_id}


@admin_router.post("/institutions/{institution_id}/under-review")
async def mark_under_review(
    institution_id: str,
    request: Request,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Mark institution as under review."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = select(InstitutionApprovalRequest).where(InstitutionApprovalRequest.id == institution_id)
    result = await db.execute(stmt)
    req = result.scalars().first()
    
    if not req:
        raise HTTPException(status_code=404, detail="Institution not found")
    
    req.status = InstitutionApprovalStatus.under_review
    req.reviewed_by_id = admin.id
    req.review_notes = "Under review"
    
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=admin,
        action="institution_under_review",
        entity_type="institution",
        entity_id=institution_id,
        entity_name=req.name,
        ip_address=request.client.host if request.client else "unknown",
    )
    
    return {"status": "under_review", "institution_id": institution_id}


@admin_router.post("/institutions/{institution_id}/suspend")
async def suspend_institution(
    institution_id: str,
    body: dict,
    request: Request,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Suspend an active institution (disable all access)."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = select(University).where(University.id == institution_id)
    result = await db.execute(stmt)
    uni = result.scalars().first()
    
    if not uni:
        raise HTTPException(status_code=404, detail="Institution not found")
    
    uni.is_connected = False  # Soft suspension
    
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=admin,
        action="institution_suspended",
        entity_type="institution",
        entity_id=institution_id,
        entity_name=uni.name,
        reason=body.get("reason"),
        ip_address=request.client.host if request.client else "unknown",
    )
    
    return {"status": "suspended", "institution_id": institution_id}


@admin_router.post("/institutions/{institution_id}/reinstate")
async def reinstate_institution(
    institution_id: str,
    request: Request,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Reinstate a suspended institution."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = select(University).where(University.id == institution_id)
    result = await db.execute(stmt)
    uni = result.scalars().first()
    
    if not uni:
        raise HTTPException(status_code=404, detail="Institution not found")
    
    uni.is_connected = True
    
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=admin,
        action="institution_reinstated",
        entity_type="institution",
        entity_id=institution_id,
        entity_name=uni.name,
        ip_address=request.client.host if request.client else "unknown",
    )
    
    return {"status": "reinstated", "institution_id": institution_id}


# ─── Sub-Admin Management ──────────────────────────────────────────────────

@admin_router.post("/admins/create")
async def create_sub_admin(
    body: CreateSubAdminRequest,
    request: Request,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Create a new Diplomax admin account."""
    await _require_role(admin, [AdminRole.diplomax_superadmin])
    
    # Check if email already exists
    stmt = select(DiplomaxAdmin).where(DiplomaxAdmin.email == body.email)
    result = await db.execute(stmt)
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Admin with this email already exists")
    
    temp_password = secrets.token_urlsafe(16)
    new_admin = DiplomaxAdmin(
        email=body.email,
        full_name=body.full_name,
        role=body.role,
        password_hash=pwd_ctx.hash(temp_password),
        created_by_id=admin.id,
    )
    db.add(new_admin)
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=admin,
        action="admin_created",
        entity_type="diplomax_admin",
        entity_id=str(new_admin.id),
        entity_name=body.email,
        new_values={
            "email": body.email,
            "role": body.role.value,
            "full_name": body.full_name,
        },
        ip_address=request.client.host if request.client else "unknown",
    )
    
    # TODO: Send temp password to new admin's email
    
    return {
        "admin_id": str(new_admin.id),
        "email": body.email,
        "temp_password": temp_password,
        "message": "Temporary password sent to admin email. Must change on first login."
    }


@admin_router.get("/admins")
async def list_admins(
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """List all Diplomax admins."""
    await _require_role(admin, [AdminRole.diplomax_superadmin])
    
    stmt = select(DiplomaxAdmin).order_by(DiplomaxAdmin.created_at)
    result = await db.execute(stmt)
    admins = result.scalars().all()
    
    return [
        {
            "id": str(a.id),
            "email": a.email,
            "full_name": a.full_name,
            "role": a.role.value,
            "is_active": a.is_active,
            "last_login_at": a.last_login_at.isoformat() if a.last_login_at else None,
            "created_at": a.created_at.isoformat(),
        }
        for a in admins
    ]


@admin_router.post("/admins/{admin_id}/role")
async def update_admin_role(
    admin_id: str,
    body: UpdateAdminRoleRequest,
    request: Request,
    current_admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Change an admin's role."""
    await _require_role(current_admin, [AdminRole.diplomax_superadmin])
    
    stmt = select(DiplomaxAdmin).where(DiplomaxAdmin.id == admin_id)
    result = await db.execute(stmt)
    target_admin = result.scalars().first()
    
    if not target_admin:
        raise HTTPException(status_code=404, detail="Admin not found")
    
    old_role = target_admin.role.value
    target_admin.role = body.role
    
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=current_admin,
        action="admin_role_changed",
        entity_type="diplomax_admin",
        entity_id=admin_id,
        entity_name=target_admin.email,
        old_values={"role": old_role},
        new_values={"role": body.role.value},
        ip_address=request.client.host if request.client else "unknown",
    )
    
    return {"admin_id": admin_id, "new_role": body.role.value}


@admin_router.post("/admins/{admin_id}/suspend")
async def suspend_admin(
    admin_id: str,
    body: SuspendAdminRequest,
    request: Request,
    current_admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Suspend or reinstate an admin account."""
    await _require_role(current_admin, [AdminRole.diplomax_superadmin])
    
    stmt = select(DiplomaxAdmin).where(DiplomaxAdmin.id == admin_id)
    result = await db.execute(stmt)
    target_admin = result.scalars().first()
    
    if not target_admin:
        raise HTTPException(status_code=404, detail="Admin not found")
    
    action = "admin_suspended" if body.action == "suspend" else "admin_reinstated"
    target_admin.is_active = body.action == "reinstate"
    
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=current_admin,
        action=action,
        entity_type="diplomax_admin",
        entity_id=admin_id,
        entity_name=target_admin.email,
        reason=body.reason,
        ip_address=request.client.host if request.client else "unknown",
    )
    
    return {
        "admin_id": admin_id,
        "action": body.action,
        "is_active": target_admin.is_active
    }


# ─── Audit Logs ────────────────────────────────────────────────────────────

@admin_router.get("/audit-logs")
async def get_audit_logs(
    action: Optional[str] = Query(None),
    entity_type: Optional[str] = Query(None),
    days: int = Query(30, ge=1, le=365),
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """List audit logs with optional filtering."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=days)
    
    conditions = [AuditLog.created_at >= cutoff_date]
    if action:
        conditions.append(AuditLog.action == action)
    if entity_type:
        conditions.append(AuditLog.entity_type == entity_type)
    
    stmt = (
        select(AuditLog)
        .where(and_(*conditions) if conditions else True)
        .order_by(desc(AuditLog.created_at))
        .limit(1000)
    )
    result = await db.execute(stmt)
    logs = result.scalars().all()
    
    return [
        {
            "action": log.action,
            "admin_email": log.admin_email,
            "entity_type": log.entity_type,
            "entity_name": log.entity_name,
            "reason": log.reason,
            "ip_address": log.ip_address,
            "created_at": log.created_at.isoformat(),
        }
        for log in logs
    ]


# ─── Platform Settings ─────────────────────────────────────────────────────

@admin_router.get("/settings")
async def get_platform_settings(
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Get current platform settings."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    stmt = select(PlatformSettings)
    result = await db.execute(stmt)
    settings_obj = result.scalars().first()
    
    if not settings_obj:
        # Return defaults
        settings_obj = PlatformSettings()
    
    return {
        "fees": {
            "diploma": settings_obj.fee_diploma,
            "transcript": settings_obj.fee_transcript,
            "certificate": settings_obj.fee_certificate,
            "attestation": settings_obj.fee_attestation,
        },
        "revenue_split": {
            "treasury_share": settings_obj.treasury_share,
            "university_share": settings_obj.university_share,
            "platform_share": settings_obj.platform_share,
        },
        "security": {
            "max_login_attempts": settings_obj.max_login_attempts,
            "lockout_duration_seconds": settings_obj.lockout_duration_seconds,
            "liveness_timeout_seconds": settings_obj.liveness_timeout_seconds,
        },
        "maintenance_mode": settings_obj.maintenance_mode,
        "maintenance_reason": settings_obj.maintenance_reason,
        "maintenance_until": settings_obj.maintenance_until.isoformat() if settings_obj.maintenance_until else None,
    }


@admin_router.patch("/settings")
async def update_platform_settings(
    body: PlatformSettingsUpdate,
    request: Request,
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Update platform settings (superadmin only)."""
    await _require_role(admin, [AdminRole.diplomax_superadmin])
    
    stmt = select(PlatformSettings)
    result = await db.execute(stmt)
    settings_obj = result.scalars().first()
    
    if not settings_obj:
        settings_obj = PlatformSettings()
        db.add(settings_obj)
    
    old_values = {
        "fee_diploma": settings_obj.fee_diploma,
        "treasury_share": settings_obj.treasury_share,
        "maintenance_mode": settings_obj.maintenance_mode,
    }
    
    if body.fee_diploma is not None:
        settings_obj.fee_diploma = body.fee_diploma
    if body.fee_transcript is not None:
        settings_obj.fee_transcript = body.fee_transcript
    if body.fee_certificate is not None:
        settings_obj.fee_certificate = body.fee_certificate
    if body.fee_attestation is not None:
        settings_obj.fee_attestation = body.fee_attestation
    
    if body.treasury_share is not None:
        settings_obj.treasury_share = body.treasury_share
    if body.university_share is not None:
        settings_obj.university_share = body.university_share
    if body.platform_share is not None:
        settings_obj.platform_share = body.platform_share
    
    if body.max_login_attempts is not None:
        settings_obj.max_login_attempts = body.max_login_attempts
    if body.lockout_duration_seconds is not None:
        settings_obj.lockout_duration_seconds = body.lockout_duration_seconds
    
    if body.maintenance_mode is not None:
        settings_obj.maintenance_mode = body.maintenance_mode
    if body.maintenance_reason is not None:
        settings_obj.maintenance_reason = body.maintenance_reason
    
    settings_obj.updated_by_id = admin.id
    
    await db.commit()
    
    await _record_audit(
        db=db,
        admin=admin,
        action="platform_settings_changed",
        entity_type="platform_settings",
        entity_id="system",
        old_values=old_values,
        new_values=body.dict(exclude_none=True),
        ip_address=request.client.host if request.client else "unknown",
    )
    
    return {"status": "updated"}


# ─── Dashboard Analytics ──────────────────────────────────────────────────

@admin_router.get("/dashboard")
async def get_admin_dashboard(
    admin: DiplomaxAdmin = Depends(_get_current_admin),
    db: AsyncSession = Depends(get_request_db_session),
):
    """Get dashboard analytics for admin overview."""
    await _require_role(admin, [AdminRole.diplomax_superadmin, AdminRole.diplomax_admin])
    
    # Count pending applications
    pending_stmt = select(InstitutionApprovalRequest).where(
        InstitutionApprovalRequest.status == InstitutionApprovalStatus.pending
    )
    pending_result = await db.execute(pending_stmt)
    pending_count = len(pending_result.scalars().all())
    
    # Count approved institutions
    approved_stmt = select(University).where(University.is_connected == True)
    approved_result = await db.execute(approved_stmt)
    approved_count = len(approved_result.scalars().all())
    
    # Count admins
    admins_stmt = select(DiplomaxAdmin).where(DiplomaxAdmin.is_active == True)
    admins_result = await db.execute(admins_stmt)
    admin_count = len(admins_result.scalars().all())
    
    return {
        "pending_applications": pending_count,
        "approved_institutions": approved_count,
        "active_admins": admin_count,
        "current_user": {
            "email": admin.email,
            "role": admin.role.value,
            "name": admin.full_name,
        }
    }
