"""
Main FastAPI application
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

# Import routers
from app.routers import golf_courses
# from app.routers import golf_rounds, user_profiles, friendships, group_rounds, hole_scores

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Golf Tracker Analytics API for managing golf courses, rounds, and player statistics",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Golf Tracker Analytics API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": settings.PROJECT_NAME}


# Include routers
app.include_router(golf_courses.router, prefix=f"{settings.API_V1_STR}/golf-courses", tags=["golf-courses"])
# app.include_router(golf_rounds.router, prefix=f"{settings.API_V1_STR}/golf-rounds", tags=["golf-rounds"])
# app.include_router(user_profiles.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
# app.include_router(friendships.router, prefix=f"{settings.API_V1_STR}/friendships", tags=["friendships"])
# app.include_router(group_rounds.router, prefix=f"{settings.API_V1_STR}/group-rounds", tags=["group-rounds"])
# app.include_router(hole_scores.router, prefix=f"{settings.API_V1_STR}/hole-scores", tags=["hole-scores"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
