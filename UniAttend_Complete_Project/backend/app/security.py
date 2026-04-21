import os
import base64
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from jose import jwt

JWT_SECRET = os.getenv("UNIATTEND_JWT_SECRET", "change-this-in-production")
JWT_ALGORITHM = "HS256"
TOKEN_EXPIRE_MINUTES = int(os.getenv("UNIATTEND_TOKEN_EXPIRE_MINUTES", "720"))


def hash_password(password: str) -> str:
        salt = secrets.token_bytes(16)
        dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 100_000)
        return "pbkdf2_sha256$100000$" + base64.b64encode(salt).decode("ascii") + "$" + base64.b64encode(dk).decode("ascii")


def verify_password(password: str, password_hash: str) -> bool:
        try:
            algo, iterations, salt_b64, digest_b64 = password_hash.split("$", 3)
            if algo != "pbkdf2_sha256":
                    return False
            salt = base64.b64decode(salt_b64.encode("ascii"))
            expected = base64.b64decode(digest_b64.encode("ascii"))
            actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, int(iterations))
            return hmac.compare_digest(actual, expected)
        except Exception:
            return False


def create_access_token(user_id: str, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=TOKEN_EXPIRE_MINUTES)
    payload = {"sub": user_id, "role": role, "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
