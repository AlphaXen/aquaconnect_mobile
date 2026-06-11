"""
AquaConnect 서버 (젯슨 나노용)
실행: python3 -m uvicorn server:app --host 0.0.0.0 --port 8000

폴더 구조:
  photos/
    tank_001/
      2024-01-15_143022.jpg
  aquaconnect.db  (SQLite - 자동 생성)
  ../web_jobs/    (구인구직 웹앱 - 자동 서빙)
"""

import json
import sqlite3
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# ── 경로 설정 ──────────────────────────────────────────────────────
PHOTOS_DIR   = Path("./photos")
DB_PATH      = Path("./aquaconnect.db")
WEB_JOBS_DIR = Path(__file__).parent.parent / "web_jobs"
SUPPORTED_EXT = {".jpg", ".jpeg", ".png", ".bmp"}


# ══════════════════════════════════════════════════════════════════
# SQLite 헬퍼
# ══════════════════════════════════════════════════════════════════

def get_db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def row_to_dict(row: sqlite3.Row) -> dict:
    return dict(row)


def init_db() -> None:
    conn = get_db()
    conn.executescript("""
        -- ── 기존 테이블 ────────────────────────────────────────────
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

        -- ── 구인구직 테이블 ─────────────────────────────────────────
        CREATE TABLE IF NOT EXISTS jobs (
            id            TEXT PRIMARY KEY,
            center_id     TEXT NOT NULL DEFAULT '',
            center_name   TEXT NOT NULL,
            title         TEXT NOT NULL,
            type          TEXT NOT NULL DEFAULT '기타',
            description   TEXT NOT NULL DEFAULT '',
            start_date    TEXT NOT NULL DEFAULT '',
            end_date      TEXT NOT NULL DEFAULT '',
            location      TEXT NOT NULL DEFAULT '',
            wage          INTEGER NOT NULL DEFAULT 0,
            wage_type     TEXT NOT NULL DEFAULT '일당',
            skills        TEXT NOT NULL DEFAULT '[]',
            contact       TEXT NOT NULL DEFAULT '',
            emoji         TEXT NOT NULL DEFAULT '📋',
            applied_count INTEGER NOT NULL DEFAULT 0,
            status        TEXT NOT NULL DEFAULT 'open',
            created_at    TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS applications (
            id           TEXT PRIMARY KEY,
            job_id       TEXT NOT NULL,
            job_title    TEXT NOT NULL DEFAULT '',
            company_name TEXT NOT NULL DEFAULT '',
            location     TEXT NOT NULL DEFAULT '',
            applicant_id TEXT NOT NULL DEFAULT '',
            name         TEXT NOT NULL,
            phone        TEXT NOT NULL,
            experience   TEXT NOT NULL DEFAULT '',
            intro        TEXT NOT NULL DEFAULT '',
            status       TEXT NOT NULL DEFAULT 'applied',
            applied_at   TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at   TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_jobs_status    ON jobs(status);
        CREATE INDEX IF NOT EXISTS idx_jobs_type      ON jobs(type);
        CREATE INDEX IF NOT EXISTS idx_apps_job       ON applications(job_id);
        CREATE INDEX IF NOT EXISTS idx_apps_applicant ON applications(applicant_id);
        CREATE UNIQUE INDEX IF NOT EXISTS idx_apps_unique ON applications(job_id, applicant_id);
    """)
    conn.commit()
    conn.close()


# ── 샘플 구인 공고 (DB 최초 실행 시 삽입) ──────────────────────────
_SEED_JOBS = [
    {
        "id": "j1", "center_id": "c1", "center_name": "제주 수산질병관리원",
        "title": "넙치 백신 접종 보조 인력", "type": "어류방역",
        "description": "제주 한림 지역 넙치 양식장에서 백신 접종 보조 업무를 담당합니다. 수산질병관리사 지도하에 작업하며 숙박비 지원됩니다. 경험자 우대합니다.",
        "start_date": "2026-05-01", "end_date": "2026-05-31",
        "location": "제주시 한림읍", "wage": 150000, "wage_type": "일당",
        "skills": ["수산질병관리사", "백신 접종", "넙치 양식"],
        "contact": "064-123-4567", "emoji": "🐟", "applied_count": 3,
        "created_at": "2026-04-25 09:00:00",
    },
    {
        "id": "j2", "center_id": "c2", "center_name": "완도 해양수산연구원",
        "title": "전복 양식장 수중 관리 인력", "type": "양식장관리",
        "description": "전복 양식장 수중 시설 점검 및 먹이 공급 업무입니다. 스쿠버 다이빙 자격증 소지자 우대. 경력 무관 지원 가능합니다.",
        "start_date": "2026-05-15", "end_date": "2026-07-15",
        "location": "전남 완도군", "wage": 130000, "wage_type": "일당",
        "skills": ["스쿠버 다이빙", "전복 양식", "수중 작업"],
        "contact": "061-550-1234", "emoji": "🦪", "applied_count": 7,
        "created_at": "2026-04-24 09:00:00",
    },
    {
        "id": "j3", "center_id": "c3", "center_name": "통영 수산물 가공업체",
        "title": "굴 가공 및 위생 포장 인력", "type": "수산물가공",
        "description": "굴 껍데기 제거 및 위생 포장 업무입니다. 일 8시간 근무이며 점심 식사를 제공합니다. 주 5일 근무 기준.",
        "start_date": "2026-05-01", "end_date": "2026-06-30",
        "location": "경남 통영시", "wage": 110000, "wage_type": "일당",
        "skills": ["수산물 가공", "위생 관리", "포장 작업"],
        "contact": "055-641-5678", "emoji": "🦪", "applied_count": 12,
        "created_at": "2026-04-23 09:00:00",
    },
    {
        "id": "j4", "center_id": "c4", "center_name": "여수 해양조사연구소",
        "title": "해양 수질 모니터링 보조 연구원", "type": "해양조사",
        "description": "연안 해양 수질 측정 및 데이터 기록 업무를 담당합니다. 이학 계열 전공자 또는 관련 자격증 소지자 우대합니다.",
        "start_date": "2026-06-01", "end_date": "2026-08-31",
        "location": "전남 여수시", "wage": 2800000, "wage_type": "월급",
        "skills": ["수질 분석", "데이터 기록", "현장 조사"],
        "contact": "061-690-3456", "emoji": "🔬", "applied_count": 5,
        "created_at": "2026-04-22 09:00:00",
    },
    {
        "id": "j5", "center_id": "c5", "center_name": "부산 참치 양식연구소",
        "title": "참다랑어 사료 공급 및 건강 체크", "type": "양식장관리",
        "description": "해상 가두리 양식장에서 참다랑어 사료 공급 및 이상 개체 선별 업무. 선박 운항 가능자 우대합니다.",
        "start_date": "2026-05-10", "end_date": "2026-09-30",
        "location": "부산 기장군", "wage": 140000, "wage_type": "일당",
        "skills": ["어류 건강 체크", "선박 운항", "사료 관리"],
        "contact": "051-720-9012", "emoji": "🐡", "applied_count": 2,
        "created_at": "2026-04-27 09:00:00",
    },
    {
        "id": "j6", "center_id": "c6", "center_name": "강원 연어양식협동조합",
        "title": "연어 치어 방류 및 부화장 관리", "type": "어류방역",
        "description": "연어 치어 방류 행사 진행 보조 및 부화장 일상 관리 업무입니다. 초보자도 지원 가능하며 교육 제공.",
        "start_date": "2026-04-28", "end_date": "2026-05-20",
        "location": "강원 양양군", "wage": 120000, "wage_type": "일당",
        "skills": ["어류 관리", "치어 방류", "부화장 운영"],
        "contact": "033-671-3456", "emoji": "🐠", "applied_count": 4,
        "created_at": "2026-04-28 09:00:00",
    },
    {
        "id": "j7", "center_id": "c7", "center_name": "제주 성게 채취 협회",
        "title": "성게 채취 및 선별 작업자", "type": "수산물가공",
        "description": "제주 해안 성게 채취 및 선별, 포장 업무입니다. 해녀 자격 소지자 또는 수중 작업 경험자 우대. 장비 지급.",
        "start_date": "2026-05-01", "end_date": "2026-06-15",
        "location": "제주시 구좌읍", "wage": 160000, "wage_type": "일당",
        "skills": ["수중 작업", "성게 선별", "해산물 포장"],
        "contact": "064-783-5678", "emoji": "🦔", "applied_count": 8,
        "created_at": "2026-04-15 09:00:00",
    },
    {
        "id": "j8", "center_id": "c8", "center_name": "인천 서해 수산연구원",
        "title": "꽃게 어획 및 항구 운반 인력", "type": "기타",
        "description": "꽃게 어선 동행 어획 지원 및 항구 운반 업무입니다. 체력 우수자 우대하며 실적 추가 수당 지급.",
        "start_date": "2026-05-20", "end_date": "2026-06-30",
        "location": "인천 강화군", "wage": 180000, "wage_type": "일당",
        "skills": ["선박 이해", "어획 작업", "체력 필요"],
        "contact": "032-933-7890", "emoji": "🦀", "applied_count": 1,
        "created_at": "2026-04-10 09:00:00",
    },
]


def seed_jobs() -> None:
    conn = get_db()
    count = conn.execute("SELECT COUNT(*) FROM jobs").fetchone()[0]
    if count > 0:
        conn.close()
        return
    for job in _SEED_JOBS:
        conn.execute("""
            INSERT OR IGNORE INTO jobs
                (id, center_id, center_name, title, type, description,
                 start_date, end_date, location, wage, wage_type, skills,
                 contact, emoji, applied_count, status, created_at, updated_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            job["id"], job["center_id"], job["center_name"], job["title"],
            job["type"], job["description"], job["start_date"], job["end_date"],
            job["location"], job["wage"], job["wage_type"],
            json.dumps(job["skills"], ensure_ascii=False),
            job["contact"], job["emoji"], job["applied_count"], "open",
            job["created_at"], job["created_at"],
        ))
    conn.commit()
    conn.close()


# ══════════════════════════════════════════════════════════════════
# Pydantic 모델
# ══════════════════════════════════════════════════════════════════

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
    status: str
    director_notes: str = ""


class JobIn(BaseModel):
    center_id: str = ""
    center_name: str
    title: str
    type: str = "기타"
    description: str = ""
    start_date: str = ""
    end_date: str = ""
    location: str
    wage: int
    wage_type: str = "일당"
    skills: list[str] = []
    contact: str = ""
    emoji: str = "📋"


class ApplicationIn(BaseModel):
    job_id: str
    applicant_id: str = ""
    name: str
    phone: str
    experience: str = ""
    intro: str = ""


class AppStatusUpdate(BaseModel):
    status: str  # reviewing | accepted | rejected


# ── 변환 헬퍼 ──────────────────────────────────────────────────────
def _job_row(row: sqlite3.Row) -> dict:
    d = row_to_dict(row)
    d["skills"] = json.loads(d["skills"])
    return d


def _res_row_to_dict(row: sqlite3.Row) -> dict:
    d = row_to_dict(row)
    d["selected_tanks"] = json.loads(d["selected_tanks"])
    return d


# ══════════════════════════════════════════════════════════════════
# Lifespan
# ══════════════════════════════════════════════════════════════════

@asynccontextmanager
async def lifespan(app: FastAPI):
    PHOTOS_DIR.mkdir(exist_ok=True)
    init_db()
    seed_jobs()
    yield


app = FastAPI(title="AquaConnect Server", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


# ══════════════════════════════════════════════════════════════════
# 공통
# ══════════════════════════════════════════════════════════════════

@app.get("/health")
async def health_check():
    return {"status": "ok", "photos_dir": str(PHOTOS_DIR.resolve())}


@app.get("/")
async def root():
    return {
        "service": "AquaConnect API",
        "version": "2.0",
        "endpoints": {
            "jobs_ui":    "/jobs/",
            "jobs_api":   "/api/jobs",
            "apply_api":  "/api/applications",
            "health":     "/health",
            "docs":       "/docs",
        },
    }


# ══════════════════════════════════════════════════════════════════
# 사진 엔드포인트 (변경 없음)
# ══════════════════════════════════════════════════════════════════

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
            from datetime import datetime as dt
            photos.append({
                "filename": f.name,
                "url": f"/photos/{tank_id}/{f.name}",
                "size": stat.st_size,
                "captured_at": dt.fromtimestamp(stat.st_mtime).isoformat(),
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
# 양식장 프로필
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
# 수산질병관리원 프로필
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


# ══════════════════════════════════════════════════════════════════
# 구인공고 엔드포인트
# ══════════════════════════════════════════════════════════════════

@app.get("/api/jobs")
async def list_jobs(status: str = Query("open", description="open | closed | all")):
    conn = get_db()
    if status == "all":
        rows = conn.execute(
            "SELECT * FROM jobs ORDER BY created_at DESC"
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM jobs WHERE status = ? ORDER BY created_at DESC", (status,)
        ).fetchall()
    conn.close()
    jobs = [_job_row(r) for r in rows]
    return {"jobs": jobs, "total": len(jobs)}


@app.post("/api/jobs", status_code=201)
async def create_job(body: JobIn):
    job_id = f"job_{int(datetime.now().timestamp() * 1000)}"
    now = datetime.now().isoformat()
    conn = get_db()
    conn.execute("""
        INSERT INTO jobs
            (id, center_id, center_name, title, type, description,
             start_date, end_date, location, wage, wage_type,
             skills, contact, emoji, status, created_at, updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (
        job_id, body.center_id, body.center_name, body.title,
        body.type, body.description, body.start_date, body.end_date,
        body.location, body.wage, body.wage_type,
        json.dumps(body.skills, ensure_ascii=False),
        body.contact, body.emoji, "open", now, now,
    ))
    conn.commit()
    row = conn.execute("SELECT * FROM jobs WHERE id = ?", (job_id,)).fetchone()
    conn.close()
    return _job_row(row)


@app.get("/api/jobs/{job_id}")
async def get_job(job_id: str):
    conn = get_db()
    row = conn.execute("SELECT * FROM jobs WHERE id = ?", (job_id,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="Job not found")
    return _job_row(row)


@app.patch("/api/jobs/{job_id}/status")
async def update_job_status(job_id: str, status: str = Query(..., description="open | closed")):
    if status not in {"open", "closed"}:
        raise HTTPException(status_code=400, detail="status must be 'open' or 'closed'")
    conn = get_db()
    conn.execute(
        "UPDATE jobs SET status = ?, updated_at = ? WHERE id = ?",
        (status, datetime.now().isoformat(), job_id),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM jobs WHERE id = ?", (job_id,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="Job not found")
    return _job_row(row)


@app.delete("/api/jobs/{job_id}", status_code=204)
async def delete_job(job_id: str):
    conn = get_db()
    conn.execute("DELETE FROM jobs WHERE id = ?", (job_id,))
    conn.commit()
    conn.close()


# ══════════════════════════════════════════════════════════════════
# 지원 엔드포인트
# ══════════════════════════════════════════════════════════════════

@app.post("/api/applications", status_code=201)
async def create_application(body: ApplicationIn):
    conn = get_db()

    # 공고 존재 확인
    job = conn.execute("SELECT * FROM jobs WHERE id = ?", (body.job_id,)).fetchone()
    if job is None:
        conn.close()
        raise HTTPException(status_code=404, detail="Job not found")

    if job["status"] != "open":
        conn.close()
        raise HTTPException(status_code=400, detail="Job is closed")

    # 중복 지원 방지
    dup = conn.execute(
        "SELECT id FROM applications WHERE job_id = ? AND applicant_id = ?",
        (body.job_id, body.applicant_id),
    ).fetchone()
    if dup:
        conn.close()
        raise HTTPException(status_code=409, detail="Already applied")

    app_id = f"app_{int(datetime.now().timestamp() * 1000)}"
    now    = datetime.now().isoformat()

    conn.execute("""
        INSERT INTO applications
            (id, job_id, job_title, company_name, location, applicant_id,
             name, phone, experience, intro, status, applied_at, updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (
        app_id, body.job_id, job["title"], job["center_name"], job["location"],
        body.applicant_id, body.name, body.phone,
        body.experience, body.intro, "applied", now, now,
    ))

    # 지원자 수 증가
    conn.execute(
        "UPDATE jobs SET applied_count = applied_count + 1, updated_at = ? WHERE id = ?",
        (now, body.job_id),
    )
    conn.commit()

    row = conn.execute("SELECT * FROM applications WHERE id = ?", (app_id,)).fetchone()
    conn.close()
    return row_to_dict(row)


@app.get("/api/applications/applicant/{applicant_id}")
async def get_applications_by_applicant(applicant_id: str):
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM applications WHERE applicant_id = ? ORDER BY applied_at DESC",
        (applicant_id,),
    ).fetchall()
    conn.close()
    return {"applications": [row_to_dict(r) for r in rows], "total": len(rows)}


@app.get("/api/applications/job/{job_id}")
async def get_applications_for_job(job_id: str):
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM applications WHERE job_id = ? ORDER BY applied_at DESC",
        (job_id,),
    ).fetchall()
    conn.close()
    return {"applications": [row_to_dict(r) for r in rows], "total": len(rows)}


@app.patch("/api/applications/{app_id}/status")
async def update_application_status(app_id: str, body: AppStatusUpdate):
    valid = {"reviewing", "accepted", "rejected"}
    if body.status not in valid:
        raise HTTPException(status_code=400, detail=f"status must be one of {valid}")
    now = datetime.now().isoformat()
    conn = get_db()
    conn.execute(
        "UPDATE applications SET status = ?, updated_at = ? WHERE id = ?",
        (body.status, now, app_id),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM applications WHERE id = ?", (app_id,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="Application not found")
    return row_to_dict(row)


# ══════════════════════════════════════════════════════════════════
# 구인구직 웹앱 서빙 (/jobs/)
# ══════════════════════════════════════════════════════════════════

if WEB_JOBS_DIR.exists():
    app.mount("/jobs", StaticFiles(directory=WEB_JOBS_DIR, html=True), name="web_jobs")
