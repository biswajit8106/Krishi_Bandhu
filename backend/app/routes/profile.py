# backend/app/routes/profile.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app import database
from app.models.user import User
from app.utils.auth_utils import get_current_user  # auth_dep की जगह auth_utils से import

router = APIRouter()

@router.get("/me")
def get_profile(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "phone": current_user.phone,
        "state": current_user.state,
        "district": current_user.district,
        "language": current_user.language,
        "role": current_user.role
    }

@router.put("/update")
def update_profile(
    name: str,
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    current_user.name = name
    db.commit()
    db.refresh(current_user)
    return {"msg": "Profile updated", "name": current_user.name}
