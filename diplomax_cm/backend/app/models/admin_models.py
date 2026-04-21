"""
Diplomax CM — Admin System Models
Complete role hierarchy: DiplomaxAdmin, MinistryAdmin, audit logs, institution approval queue.
"""
import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import (
    Boolean, Column, DateTime, Enum, ForeignKey, Integer, String, Text, func, Index
)
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import relationship

from app.models.models import Base


# ─── Admin Role Enums ──────────────────────────────────────────────────────

class AdminRole(PyEnum):
    diplomax_superadmin = "diplomax_superadmin"      # Full platform control (Bassa Joëlle)
    diplomax_admin = "diplomax_admin"                # Manage institutions, view data
    ministry_superadmin = "ministry_superadmin"      # Minister/DG of MINESUP
    ministry_analyst = "ministry_analyst"            # Ministry read-only analyst


class InstitutionApprovalStatus(PyEnum):
    pending = "pending"        # Just submitted
    under_review = "under_review"  # Admin marked as reviewing
    approved = "approved"      # Activated with API key
    rejected = "rejected"      # Permanently rejected
    suspended = "suspended"    # Was active, now disabled


# ─── Diplomax Admin Users ──────────────────────────────────────────────────

class DiplomaxAdmin(Base):
    """
    System administrator for Diplomax platform.
    Can create/suspend institutions, manage other admins, configure platform, view all data.
    """
    __tablename__ = "diplomax_admins"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email           = Column(String(255), unique=True, nullable=False, index=True)
    password_hash   = Column(String(255), nullable=False)
    full_name       = Column(String(255), nullable=False)
    role            = Column(Enum(AdminRole), default=AdminRole.diplomax_admin, nullable=False)
    
    is_active       = Column(Boolean, default=True)
    failed_login_attempts = Column(Integer, default=0)
    locked_until    = Column(DateTime, nullable=True)
    last_login_at   = Column(DateTime, nullable=True)
    last_login_ip   = Column(String(50), nullable=True)
    
    created_at      = Column(DateTime, server_default=func.now())
    updated_at      = Column(DateTime, server_default=func.now(), onupdate=func.now())
    created_by_id   = Column(UUID(as_uuid=True), ForeignKey("diplomax_admins.id"), nullable=True)
    
    created_by      = relationship("DiplomaxAdmin", remote_side=[id], backref="created_admins")
    audit_logs      = relationship("AuditLog", back_populates="admin")

    __table_args__ = (
        Index('ix_diplomax_admins_email', 'email'),
        Index('ix_diplomax_admins_role', 'role'),
        Index('ix_diplomax_admins_is_active', 'is_active'),
    )


# ─── Ministry Admin Users ──────────────────────────────────────────────────

class MinistryAdmin(Base):
    """
    Ministry of Education administrator.
    Can approve/reject institutions, view all documents, export reports.
    """
    __tablename__ = "ministry_admins"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email           = Column(String(255), unique=True, nullable=False, index=True)
    password_hash   = Column(String(255), nullable=False)
    full_name       = Column(String(255), nullable=False)
    title           = Column(String(255))  # Minister, Director General, etc.
    role            = Column(Enum(AdminRole), default=AdminRole.ministry_analyst, nullable=False)
    
    is_active       = Column(Boolean, default=True)
    failed_login_attempts = Column(Integer, default=0)
    locked_until    = Column(DateTime, nullable=True)
    last_login_at   = Column(DateTime, nullable=True)
    last_login_ip   = Column(String(50), nullable=True)
    
    created_at      = Column(DateTime, server_default=func.now())
    updated_at      = Column(DateTime, server_default=func.now(), onupdate=func.now())
    created_by_id   = Column(UUID(as_uuid=True), ForeignKey("diplomax_admins.id"), nullable=True)
    
    created_by      = relationship("DiplomaxAdmin", foreign_keys=[created_by_id])
    audit_logs      = relationship("AuditLog", foreign_keys="AuditLog.ministry_admin_id", back_populates="ministry_admin")

    __table_args__ = (
        Index('ix_ministry_admins_email', 'email'),
        Index('ix_ministry_admins_role', 'role'),
        Index('ix_ministry_admins_is_active', 'is_active'),
    )


# ─── Institution Approval Queue ────────────────────────────────────────────

class InstitutionApprovalRequest(Base):
    """
    Institution registration application waiting for admin review and approval.
    """
    __tablename__ = "institution_approval_requests"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    institution_id  = Column(UUID(as_uuid=True), ForeignKey("universities.id"), nullable=True, index=True)
    
    # Copy of submitted data (in case original changes)
    name            = Column(String(255), nullable=False)
    institution_type = Column(String(100), nullable=False)
    city            = Column(String(100))
    region          = Column(String(100))
    country         = Column(String(100), default="Cameroon")
    email           = Column(String(255), nullable=False)
    phone           = Column(String(20))
    website         = Column(String(255))
    accreditation_body = Column(String(100))
    accreditation_number = Column(String(100))
    is_government   = Column(Boolean, default=False)
    matricule_prefix = Column(String(20), nullable=False)
    
    # Admin contact
    admin_full_name = Column(String(255))
    admin_email     = Column(String(255))
    admin_phone     = Column(String(20))
    admin_title     = Column(String(100))
    
    # Approval workflow
    status          = Column(Enum(InstitutionApprovalStatus), default=InstitutionApprovalStatus.pending, index=True)
    reviewed_by_id  = Column(UUID(as_uuid=True), ForeignKey("diplomax_admins.id"), nullable=True)
    review_notes    = Column(Text)
    rejection_reason = Column(Text)
    
    submitted_at    = Column(DateTime, server_default=func.now())
    reviewed_at     = Column(DateTime, nullable=True)
    approved_at     = Column(DateTime, nullable=True)
    
    reviewed_by     = relationship("DiplomaxAdmin", foreign_keys=[reviewed_by_id])

    __table_args__ = (
        Index('ix_institution_approval_requests_status', 'status'),
        Index('ix_institution_approval_requests_institution_id', 'institution_id'),
    )


# ─── Audit Logs ────────────────────────────────────────────────────────────

class AuditLog(Base):
    """
    Complete audit trail of all admin actions.
    Immutable record of who did what, when, on what entity, from which IP.
    """
    __tablename__ = "audit_logs"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Who
    admin_id        = Column(UUID(as_uuid=True), ForeignKey("diplomax_admins.id"), nullable=False, index=True)
    ministry_admin_id = Column(UUID(as_uuid=True), ForeignKey("ministry_admins.id"), nullable=True, index=True)
    admin_email     = Column(String(255), nullable=False)
    
    # What
    action          = Column(String(100), nullable=False, index=True)
    # Possible actions: institution_approved, institution_rejected, institution_suspended, institution_reinstated,
    #   admin_created, admin_suspended, admin_deleted, settings_changed, api_key_rotated, document_revoked,
    #   institution_under_review, etc.
    
    # On what
    entity_type     = Column(String(50), nullable=False, index=True)
    # Possible entities: institution, diplomax_admin, ministry_admin, document, api_key, settings
    entity_id       = Column(UUID(as_uuid=True), nullable=False, index=True)
    entity_name     = Column(String(255))
    
    # Change details
    old_values      = Column(JSON)  # Previous state (for edit actions)
    new_values      = Column(JSON)  # New state or action parameters
    
    # Context
    reason          = Column(Text)  # Why this action was taken
    ip_address      = Column(String(50))
    user_agent      = Column(String(500))
    
    created_at      = Column(DateTime, server_default=func.now(), index=True)
    
    admin           = relationship("DiplomaxAdmin", foreign_keys=[admin_id], back_populates="audit_logs")
    ministry_admin  = relationship("MinistryAdmin", foreign_keys=[ministry_admin_id], back_populates="audit_logs")

    __table_args__ = (
        Index('ix_audit_logs_admin_id_created_at', 'admin_id', 'created_at'),
        Index('ix_audit_logs_action_created_at', 'action', 'created_at'),
        Index('ix_audit_logs_entity_type_entity_id', 'entity_type', 'entity_id'),
    )


# ─── Platform Settings ─────────────────────────────────────────────────────

class PlatformSettings(Base):
    """
    Diplomax platform configuration (fees, revenue splits, security parameters).
    Single row table — one record only.
    """
    __tablename__ = "platform_settings"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Certification fees (per document)
    fee_diploma     = Column(Integer, default=2500)  # FCFA
    fee_transcript  = Column(Integer, default=1000)  # FCFA
    fee_certificate = Column(Integer, default=500)   # FCFA
    fee_attestation = Column(Integer, default=500)   # FCFA
    
    # Revenue split (percentages)
    treasury_share  = Column(Integer, default=40)  # 40% to national treasury
    university_share = Column(Integer, default=40) # 40% to issuing university
    platform_share  = Column(Integer, default=20)  # 20% to Diplomax
    
    # Security parameters
    max_login_attempts = Column(Integer, default=5)
    lockout_duration_seconds = Column(Integer, default=1800)  # 30 minutes
    liveness_timeout_seconds = Column(Integer, default=120)   # 2 minutes
    
    # System state
    maintenance_mode = Column(Boolean, default=False)  # When True, only admins can log in
    maintenance_reason = Column(Text)
    maintenance_until = Column(DateTime, nullable=True)
    
    # Signing certificates
    platform_public_cert = Column(Text)  # X.509 public certificate for platform signatures
    
    updated_at      = Column(DateTime, server_default=func.now(), onupdate=func.now())
    updated_by_id   = Column(UUID(as_uuid=True), ForeignKey("diplomax_admins.id"), nullable=True)
    
    updated_by      = relationship("DiplomaxAdmin", foreign_keys=[updated_by_id])


# ─── Institution API Key Management ────────────────────────────────────────

class InstitutionApiKey(Base):
    """
    API key for institution backend-to-backend calls.
    Tracks rotation, revocation, and usage.
    """
    __tablename__ = "institution_api_keys"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    institution_id  = Column(UUID(as_uuid=True), ForeignKey("universities.id"), nullable=False, index=True)
    
    key_hash        = Column(String(255), nullable=False, unique=True)  # SHA-256 hash
    is_active       = Column(Boolean, default=True)
    
    created_at      = Column(DateTime, server_default=func.now())
    rotated_by_id   = Column(UUID(as_uuid=True), ForeignKey("diplomax_admins.id"), nullable=True)
    revoked_at      = Column(DateTime, nullable=True)
    revoked_by_id   = Column(UUID(as_uuid=True), ForeignKey("diplomax_admins.id"), nullable=True)
    revocation_reason = Column(String(255))
    
    rotated_by      = relationship("DiplomaxAdmin", foreign_keys=[rotated_by_id])
    revoked_by      = relationship("DiplomaxAdmin", foreign_keys=[revoked_by_id])

    __table_args__ = (
        Index('ix_institution_api_keys_institution_id', 'institution_id'),
        Index('ix_institution_api_keys_is_active', 'is_active'),
    )
