"""
Friendship SQLAlchemy model
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Friendship(Base):
    """Friendship model for user connections"""
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Keys
    user_id = Column(Integer, ForeignKey("user_profiles.id"), nullable=False)
    friend_id = Column(Integer, ForeignKey("user_profiles.id"), nullable=False)
    
    # Friendship status
    status = Column(String(20), default="pending")  # pending, accepted, declined, blocked
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    accepted_at = Column(DateTime(timezone=True))
    
    # Relationships
    user = relationship("UserProfile", foreign_keys=[user_id], back_populates="friendships_initiated")
    friend = relationship("UserProfile", foreign_keys=[friend_id], back_populates="friendships_received")
    
    # Constraints
    __table_args__ = (
        UniqueConstraint('user_id', 'friend_id', name='unique_friendship'),
    )
