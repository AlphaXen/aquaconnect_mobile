"""
AquaConnect 불량어류 사진 서버 (젯슨 나노용)
실행: uvicorn server:app --host 0.0.0.0 --port 8000

폴더 구조:
  photos/
    tank_001/
      2024-01-15_143022.jpg
      2024-01-15_143055.jpg
    tank_002/
      ...
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pathlib import Path
from datetime import datetime
import os

app = FastAPI(title="AquaConnect Photo Server")

# CORS 허용 (Flutter 앱에서 접근 가능하도록)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)

# 사진 저장 경로 (실제 환경에 맞게 수정)
PHOTOS_DIR = Path("./photos")
SUPPORTED_EXT = {".jpg", ".jpeg", ".png", ".bmp"}


def ensure_photos_dir():
    PHOTOS_DIR.mkdir(exist_ok=True)


@app.on_event("startup")
async def startup():
    ensure_photos_dir()


@app.get("/api/tanks")
async def list_tanks():
    """사진이 있는 수조 목록 반환"""
    ensure_photos_dir()
    tanks = []
    for d in sorted(PHOTOS_DIR.iterdir()):
        if d.is_dir():
            count = sum(1 for f in d.iterdir() if f.suffix.lower() in SUPPORTED_EXT)
            tanks.append({"tank_id": d.name, "photo_count": count})
    return {"tanks": tanks}


@app.get("/api/tanks/{tank_id}/photos")
async def get_tank_photos(tank_id: str):
    """특정 수조의 불량어류 사진 목록 반환"""
    tank_dir = PHOTOS_DIR / tank_id
    if not tank_dir.exists():
        return {"tank_id": tank_id, "photos": []}

    photos = []
    for f in sorted(tank_dir.iterdir(), reverse=True):  # 최신순 정렬
        if f.is_file() and f.suffix.lower() in SUPPORTED_EXT:
            stat = f.stat()
            photos.append({
                "filename": f.name,
                "url": f"/photos/{tank_id}/{f.name}",
                "size": stat.st_size,
                "captured_at": datetime.fromtimestamp(stat.st_mtime).isoformat(),
            })

    return {"tank_id": tank_id, "photos": photos}


@app.get("/photos/{tank_id}/{filename}")
async def serve_photo(tank_id: str, filename: str):
    """실제 이미지 파일 서빙"""
    # 경로 탐색 공격 방지
    if ".." in tank_id or ".." in filename:
        raise HTTPException(status_code=400, detail="Invalid path")

    file_path = PHOTOS_DIR / tank_id / filename
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=404, detail="Photo not found")

    return FileResponse(file_path, media_type="image/jpeg")


@app.get("/health")
async def health_check():
    """서버 상태 확인"""
    return {"status": "ok", "photos_dir": str(PHOTOS_DIR.resolve())}
