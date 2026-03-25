"""
AquaConnect 서버 (젯슨 나노용)
실행: python3 -m uvicorn server:app --host 0.0.0.0 --port 8000

폴더 구조:
  photos/
    tank_001/
      2024-01-15_143022.jpg
    tank_002/
      ...
  aquaconnect.db  (SQLite - 자동 생성)
"""

import json
import sqlite3
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel

# ── 경로 설정 ──────────────────────────────────────────────────────
PHOTOS_DIR = Path("./photos")
DB_PATH = Path("./aquaconnect.db")
SUPPORTED_EXT = {".jpg", ".jpeg", ".png", ".bmp"}


# ── SQLite 헬퍼 ────────────────────────────────────────────────────
def get_db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def init_db() -> None:
    conn = get_db()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS farm_profiles (
            id           TEXT PRIMARY KEY,
            farm_name    TEXT NOT NULL,
            owner_name   TEXT NOT NULL DEFAULT '',
            location     TEXT NOT NULL DEFAULT '',
            address      TEXT NOT NULL DEFAULT '',
            fish_species TEXT NOT NULL DEFAULT '[]',
            phone        TEXT NOT NULL DEFAULT '',
            description  TEXT NOT NULL DEFAULT '',
            updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS center_profiles (
            id             TEXT PRIMARY KEY,
            center_name    TEXT NOT NULL,
            director_name  TEXT NOT NULL DEFAULT '',
            location       TEXT NOT NULL DEFAULT '',
            phone          TEXT NOT NULL DEFAULT '',
            specialties    TEXT NOT NULL DEFAULT '[]',
            business_hours TEXT NOT NULL DEFAULT '',
            is_available   INTEGER NOT NULL DEFAULT 1,
            rating         REAL NOT NULL DEFAULT 0.0,
            review_count   INTEGER NOT NULL DEFAULT 0,
            description    TEXT NOT NULL DEFAULT '',
            updated_at     TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS reservations (
            id                TEXT PRIMARY KEY,
            farm_id           TEXT NOT NULL,
            center_id         TEXT NOT NULL,
            farm_name         TEXT NOT NULL,
            center_name       TEXT NOT NULL,
            scheduled_date    TEXT NOT NULL,
            scheduled_time    TEXT NOT NULL,
            selected_tanks    TEXT NOT NULL DEFAULT '[]',
            total_fish        INTEGER NOT NULL DEFAULT 0,
            service_type      TEXT NOT NULL,
            status            TEXT NOT NULL DEFAULT 'pending',
            notes             TEXT NOT NULL DEFAULT '',
            contract_url      TEXT,
            service_amount    INTEGER NOT NULL DEFAULT 0,
            commission_rate   REAL NOT NULL DEFAULT 0.10,
            commission_amount INTEGER NOT NULL DEFAULT 0,
            director_notes    TEXT,
            created_at        TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE INDEX IF NOT EXISTS idx_res_farm   ON reservations(farm_id);
        CREATE INDEX IF NOT EXISTS idx_res_center ON reservations(center_id);
        CREATE INDEX IF NOT EXISTS idx_res_status ON reservations(status);
    """)
    conn.commit()
    conn.close()


def row_to_dict(row: sqlite3.Row) -> dict:
    return dict(row)


# ── Pydantic 모델 ──────────────────────────────────────────────────
class FarmProfileIn(BaseModel):
    farm_name: str
    owner_name: str = ""
    location: str = ""
    address: str = ""
    fish_species: list[str] = []
    phone: str = ""
    description: str = ""


class CenterProfileIn(BaseModel):
    center_name: str
    director_name: str = ""
    location: str = ""
    phone: str = ""
    specialties: list[str] = []
    business_hours: str = ""
    is_available: bool = True
    rating: float = 0.0
    review_count: int = 0
    description: str = ""


class ReservationIn(BaseModel):
    farm_id: str
    center_id: str
    farm_name: str
    center_name: str
    scheduled_date: str
    scheduled_time: str
    selected_tanks: list[str] = []
    total_fish: int = 0
    service_type: str
    notes: str = ""
    service_amount: int = 0
    commission_rate: float = 0.10
    commission_amount: int = 0


class StatusUpdate(BaseModel):
    status: str  # approved | rejected | completed
    director_notes: str = ""


# ── Lifespan ───────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    PHOTOS_DIR.mkdir(exist_ok=True)
    init_db()
    yield


app = FastAPI(title="AquaConnect Server", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


# ══════════════════════════════════════════════════════════════════
# 기존 Photo 엔드포인트 (변경 없음)
# ══════════════════════════════════════════════════════════════════

@app.get("/health")
async def health_check():
    return {"status": "ok", "photos_dir": str(PHOTOS_DIR.resolve())}


@app.get("/api/tanks")
async def list_tanks():
    tanks = []
    for d in sorted(PHOTOS_DIR.iterdir()):
        if d.is_dir():
            count = sum(1 for f in d.iterdir() if f.suffix.lower() in SUPPORTED_EXT)
            tanks.append({"tank_id": d.name, "photo_count": count})
    return {"tanks": tanks}


@app.get("/api/tanks/{tank_id}/photos")
async def get_tank_photos(tank_id: str):
    tank_dir = PHOTOS_DIR / tank_id
    if not tank_dir.exists():
        return {"tank_id": tank_id, "photos": []}
    photos = []
    for f in sorted(tank_dir.iterdir(), reverse=True):
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
    if ".." in tank_id or ".." in filename:
        raise HTTPException(status_code=400, detail="Invalid path")
    file_path = PHOTOS_DIR / tank_id / filename
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=404, detail="Photo not found")
    return FileResponse(file_path, media_type="image/jpeg")


# ══════════════════════════════════════════════════════════════════
# 양식장 프로필 엔드포인트
# ══════════════════════════════════════════════════════════════════

@app.get("/api/profiles/farm/{farm_id}")
async def get_farm_profile(farm_id: str):
    conn = get_db()
    row = conn.execute("SELECT * FROM farm_profiles WHERE id = ?", (farm_id,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="Farm profile not found")
    data = row_to_dict(row)
    data["fish_species"] = json.loads(data["fish_species"])
    return data


@app.put("/api/profiles/farm/{farm_id}")
async def save_farm_profile(farm_id: str, body: FarmProfileIn):
    now = datetime.now().isoformat()
    conn = get_db()
    conn.execute("""
        INSERT INTO farm_profiles (id, farm_name, owner_name, location, address, fish_species, phone, description, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            farm_name    = excluded.farm_name,
            owner_name   = excluded.owner_name,
            location     = excluded.location,
            address      = excluded.address,
            fish_species = excluded.fish_species,
            phone        = excluded.phone,
            description  = excluded.description,
            updated_at   = excluded.updated_at
    """, (
        farm_id, body.farm_name, body.owner_name, body.location,
        body.address, json.dumps(body.fish_species, ensure_ascii=False),
        body.phone, body.description, now,
    ))
    conn.commit()
    row = conn.execute("SELECT * FROM farm_profiles WHERE id = ?", (farm_id,)).fetchone()
    conn.close()
    data = row_to_dict(row)
    data["fish_species"] = json.loads(data["fish_species"])
    return data


# ══════════════════════════════════════════════════════════════════
# 수산질병관리원 프로필 엔드포인트
# ══════════════════════════════════════════════════════════════════

@app.get("/api/profiles/centers")
async def list_centers():
    conn = get_db()
    rows = conn.execute("SELECT * FROM center_profiles ORDER BY center_name").fetchall()
    conn.close()
    centers = []
    for row in rows:
        data = row_to_dict(row)
        data["specialties"] = json.loads(data["specialties"])
        data["is_available"] = bool(data["is_available"])
        centers.append(data)
    return {"centers": centers}


@app.get("/api/profiles/center/{center_id}")
async def get_center_profile(center_id: str):
    conn = get_db()
    row = conn.execute("SELECT * FROM center_profiles WHERE id = ?", (center_id,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="Center profile not found")
    data = row_to_dict(row)
    data["specialties"] = json.loads(data["specialties"])
    data["is_available"] = bool(data["is_available"])
    return data


@app.put("/api/profiles/center/{center_id}")
async def save_center_profile(center_id: str, body: CenterProfileIn):
    now = datetime.now().isoformat()
    conn = get_db()
    conn.execute("""
        INSERT INTO center_profiles
            (id, center_name, director_name, location, phone, specialties,
             business_hours, is_available, rating, review_count, description, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            center_name    = excluded.center_name,
            director_name  = excluded.director_name,
            location       = excluded.location,
            phone          = excluded.phone,
            specialties    = excluded.specialties,
            business_hours = excluded.business_hours,
            is_available   = excluded.is_available,
            rating         = excluded.rating,
            review_count   = excluded.review_count,
            description    = excluded.description,
            updated_at     = excluded.updated_at
    """, (
        center_id, body.center_name, body.director_name, body.location,
        body.phone, json.dumps(body.specialties, ensure_ascii=False),
        body.business_hours, 1 if body.is_available else 0,
        body.rating, body.review_count, body.description, now,
    ))
    conn.commit()
    row = conn.execute("SELECT * FROM center_profiles WHERE id = ?", (center_id,)).fetchone()
    conn.close()
    data = row_to_dict(row)
    data["specialties"] = json.loads(data["specialties"])
    data["is_available"] = bool(data["is_available"])
    return data


# ══════════════════════════════════════════════════════════════════
# 예약 엔드포인트
# ══════════════════════════════════════════════════════════════════

def _res_row_to_dict(row: sqlite3.Row) -> dict:
    data = row_to_dict(row)
    data["selected_tanks"] = json.loads(data["selected_tanks"])
    return data


@app.post("/api/reservations", status_code=201)
async def create_reservation(body: ReservationIn):
    res_id = f"res_{int(datetime.now().timestamp() * 1000)}"
    now = datetime.now().isoformat()
    conn = get_db()
    conn.execute("""
        INSERT INTO reservations
            (id, farm_id, center_id, farm_name, center_name,
             scheduled_date, scheduled_time, selected_tanks, total_fish,
             service_type, notes, service_amount, commission_rate, commission_amount,
             created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        res_id, body.farm_id, body.center_id, body.farm_name, body.center_name,
        body.scheduled_date, body.scheduled_time,
        json.dumps(body.selected_tanks, ensure_ascii=False),
        body.total_fish, body.service_type, body.notes,
        body.service_amount, body.commission_rate, body.commission_amount,
        now, now,
    ))
    conn.commit()
    row = conn.execute("SELECT * FROM reservations WHERE id = ?", (res_id,)).fetchone()
    conn.close()
    return _res_row_to_dict(row)


@app.get("/api/reservations/farm/{farm_id}")
async def get_reservations_by_farm(farm_id: str):
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM reservations WHERE farm_id = ? ORDER BY created_at DESC", (farm_id,)
    ).fetchall()
    conn.close()
    return {"reservations": [_res_row_to_dict(r) for r in rows]}


@app.get("/api/reservations/center/{center_id}")
async def get_reservations_by_center(center_id: str):
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM reservations WHERE center_id = ? ORDER BY created_at DESC", (center_id,)
    ).fetchall()
    conn.close()
    return {"reservations": [_res_row_to_dict(r) for r in rows]}


@app.patch("/api/reservations/{reservation_id}/status")
async def update_reservation_status(reservation_id: str, body: StatusUpdate):
    valid = {"approved", "rejected", "completed"}
    if body.status not in valid:
        raise HTTPException(status_code=400, detail=f"status must be one of {valid}")

    conn = get_db()
    row = conn.execute("SELECT id FROM reservations WHERE id = ?", (reservation_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="Reservation not found")

    now = datetime.now().isoformat()
    contract_url = f"/contracts/{reservation_id}.pdf" if body.status == "approved" else None

    if contract_url:
        conn.execute("""
            UPDATE reservations
            SET status = ?, director_notes = ?, contract_url = ?, updated_at = ?
            WHERE id = ?
        """, (body.status, body.director_notes, contract_url, now, reservation_id))
    else:
        conn.execute("""
            UPDATE reservations
            SET status = ?, director_notes = ?, updated_at = ?
            WHERE id = ?
        """, (body.status, body.director_notes, now, reservation_id))

    conn.commit()
    row = conn.execute("SELECT * FROM reservations WHERE id = ?", (reservation_id,)).fetchone()
    conn.close()
    return _res_row_to_dict(row)
