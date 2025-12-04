from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import datetime
from app import database
from app.models.user import User
from app.models.token import Token

security = HTTPBearer()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(database.get_db)
):
    token = credentials.credentials
    token_entry = db.query(Token).filter(Token.token == token, Token.token_type == "access").first()
    if not token_entry or token_entry.expires_at < datetime.utcnow():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    return token_entry.user
