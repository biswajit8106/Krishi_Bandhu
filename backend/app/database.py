# backend/app/database.py
import pymysql
pymysql.install_as_MySQLdb()

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import NullPool, QueuePool
from app.config import DATABASE_URL
from sqlalchemy import text

# Configure connection pool with better resilience
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=5,
    max_overflow=10,
    pool_recycle=3600,  # Recycle connections every hour
    pool_pre_ping=True,  # Test connections before use
    connect_args={
        'connect_timeout': 10,
        'charset': 'utf8mb4',
        'read_timeout': 30,
        'write_timeout': 30
    }
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def create_tables_with_retry(max_retries=3, initial_wait=2):
    """Create all database tables with exponential backoff retry logic."""
    import time
    last_error = None
    
    for attempt in range(max_retries):
        try:
            Base.metadata.create_all(bind=engine)
            print("✓ Database tables created successfully")
            return True
        except Exception as e:
            last_error = e
            if attempt < max_retries - 1:
                wait_time = initial_wait * (2 ** attempt)
                print(f"⚠ Table creation attempt {attempt + 1} failed. Retrying in {wait_time}s...")
                print(f"  Error: {str(e)[:100]}")
                time.sleep(wait_time)
            else:
                print(f"✗ Failed to create tables after {max_retries} attempts")
    
    # Don't crash startup - tables might already exist
    print(f"⚠ Warning: Database initialization incomplete. Tables may need manual creation.")
    return False

def ensure_user_verification_columns():
    """Ensure `email_verified` and `phone_verified` columns exist on `users` table.
    This runs a safe check against information_schema and alters the table if needed.
    """
    try:
        with engine.connect() as conn:
            # Check email_verified
            email_exists = conn.execute(
                text("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'email_verified'")
            ).scalar()
            if not email_exists:
                conn.execute(text("ALTER TABLE users ADD COLUMN email_verified TINYINT(1) DEFAULT 0"))
                conn.commit()

            phone_exists = conn.execute(
                text("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'phone_verified'")
            ).scalar()
            if not phone_exists:
                conn.execute(text("ALTER TABLE users ADD COLUMN phone_verified TINYINT(1) DEFAULT 0"))
                conn.commit()
    except Exception as e:
        print(f"⚠ Warning: Could not verify user columns: {str(e)[:100]}")

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
