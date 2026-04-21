from typing import Literal

from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator


Role = Literal["student", "course_rep", "lecturer", "admin", "super_admin"]
RequestedRole = Literal["student", "course_rep", "lecturer", "admin"]
ICT_EMAIL_DOMAIN = "@ictuniversity.edu.cm"


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2)
    email: EmailStr
    password: str = Field(min_length=6)
    matric_number: str = Field(min_length=3)
    department: str = Field(min_length=2)
    phone_number: str | None = None
    role: RequestedRole = "student"
    role_justification: str | None = None
    selected_course_ids: list[str] = Field(default_factory=list)

    @field_validator("email")
    @classmethod
    def validate_ict_email(cls, v):
        if not v.lower().endswith(ICT_EMAIL_DOMAIN):
            raise ValueError(
                f"Email must be an ICT University email ({ICT_EMAIL_DOMAIN})"
            )
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)

    @field_validator("email")
    @classmethod
    def validate_ict_email(cls, v):
        if not v.lower().endswith(ICT_EMAIL_DOMAIN):
            raise ValueError(
                f"Email must be an ICT University email ({ICT_EMAIL_DOMAIN})"
            )
        return v


class SessionCreateRequest(BaseModel):
    course_id: str
    class_type: Literal["normal", "catch_up"]
    scheduled_date: str
    classroom_latitude: float
    classroom_longitude: float


class SessionQrRequest(BaseModel):
    phase: Literal["checkin", "checkout"]


class CourseCreateRequest(BaseModel):
    course_code: str = Field(min_length=3)
    course_name: str = Field(min_length=3)
    semester: str = Field(min_length=2)
    academic_year: int = Field(ge=2000, le=2100)
    lecturer_id: str | None = None
    lecturer_identifier: str | None = None
    course_rep_id: str | None = None

    @model_validator(mode="before")
    @classmethod
    def map_legacy_and_camelcase_keys(cls, data):
        if not isinstance(data, dict):
            return data

        normalized = dict(data)

        if not normalized.get("lecturer_id") and normalized.get("lecturerId"):
            normalized["lecturer_id"] = normalized["lecturerId"]

        if not normalized.get("course_rep_id") and normalized.get("courseRepId"):
            normalized["course_rep_id"] = normalized["courseRepId"]

        if not normalized.get("lecturer_identifier"):
            for key in (
                "lecturerIdentifier",
                "lecturer_name",
                "lecturerName",
                "lecturer_display_name",
                "lecturerDisplayName",
            ):
                value = normalized.get(key)
                if value is not None and str(value).strip():
                    normalized["lecturer_identifier"] = value
                    break

        return normalized

    @field_validator("lecturer_id", "lecturer_identifier", "course_rep_id", mode="before")
    @classmethod
    def normalize_optional_identifiers(cls, v):
        if v is None:
            return None
        text = str(v).strip()
        return text or None


class CheckRequest(BaseModel):
    session_id: str
    student_id: str
    device_id: str
    qr_payload: str | None = None
    latitude: float
    longitude: float

    @field_validator("qr_payload", mode="before")
    @classmethod
    def normalize_qr_payload(cls, v):
        if v is None:
            return None
        text = str(v).strip()
        return text or None


class ManualAttendanceRequest(BaseModel):
    session_id: str
    student_identifier: str
    reason: str | None = None


class AttendanceAnomalyRequest(BaseModel):
    session_id: str
    student_id: str
    reason: str = Field(min_length=5)
    details: str | None = None


class AdminUserUpdateRequest(BaseModel):
    full_name: str = Field(min_length=2)
    email: EmailStr
    matric_number: str = Field(min_length=3)
    department: str = Field(min_length=2)
    phone_number: str | None = None
    role: Role


class AdminUserBlockRequest(BaseModel):
    reason: str | None = None


class RoleApplicationActionRequest(BaseModel):
    reason: str | None = None
