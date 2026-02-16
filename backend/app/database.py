# backend/app/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import DATABASE_URL
from sqlalchemy import text

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def ensure_user_verification_columns():
    """Ensure `email_verified` and `phone_verified` columns exist on `users` table.
    This runs a safe check against information_schema and alters the table if needed.
    """
    with engine.connect() as conn:
        # Check email_verified
        email_exists = conn.execute(
            text("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'email_verified'")
        ).scalar()
        if not email_exists:
            conn.execute(text("ALTER TABLE users ADD COLUMN email_verified TINYINT(1) DEFAULT 0"))

        phone_exists = conn.execute(
            text("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'phone_verified'")
        ).scalar()
        if not phone_exists:
            conn.execute(text("ALTER TABLE users ADD COLUMN phone_verified TINYINT(1) DEFAULT 0"))

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
