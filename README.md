# Golf Tracker Analytics API

Eine FastAPI-basierte CRUD API für Golfplatz-Daten mit Supabase-Datenbankanbindung, Docker-Containerisierung und AWS-Deployment.

## 🏌️ Features

- **Vollständige CRUD-Operationen** für Golf-Entitäten
- **FastAPI** mit automatischer API-Dokumentation
- **Supabase** PostgreSQL Datenbankanbindung
- **Docker** Containerisierung mit Multi-Stage Build
- **Terraform** Infrastructure as Code für AWS
- **Async/Await** Support für optimale Performance
- **Pydantic** Datenvalidierung und Serialisierung
- **SQLAlchemy** ORM mit async Support

## 🏗️ Architektur

### Datenmodell
- **Golf Courses**: Golfplatz-Informationen
- **Golf Rounds**: Gespielten Runden
- **Hole Scores**: Einzelloch-Ergebnisse
- **User Profiles**: Spielerprofile
- **Friendships**: Freundschaftssystem
- **Group Rounds**: Gruppenrunden

### API Endpunkte
- `GET /api/v1/golf-courses/` - Alle Golfplätze (mit Pagination)
- `POST /api/v1/golf-courses/` - Neuen Golfplatz erstellen
- `GET /api/v1/golf-courses/{id}` - Einzelnen Golfplatz abrufen
- `PUT /api/v1/golf-courses/{id}` - Golfplatz aktualisieren
- `DELETE /api/v1/golf-courses/{id}` - Golfplatz löschen
- `GET /api/v1/golf-courses/{id}/stats` - Golfplatz-Statistiken

## 🚀 Schnellstart

### 1. Repository klonen
```bash
git clone <repository-url>
cd GolfTrackerAnalytics
```

### 2. Umgebungsvariablen konfigurieren
```bash
cp env.example .env
# .env mit echten Werten befüllen
```

### 3. Mit Docker starten
```bash
# API starten
docker-compose up -d golf-api

# Mit lokaler PostgreSQL (optional)
docker-compose --profile local-db up -d

# Mit Redis Cache (optional)
docker-compose --profile cache up -d
```

### 4. API-Dokumentation
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health

## 🔧 Entwicklung

### Lokale Entwicklung
```bash
# Virtuelle Umgebung erstellen
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate  # Windows

# Dependencies installieren
pip install -r requirements.txt

# Umgebungsvariablen setzen
export SUPABASE_URL="your_url"
export DATABASE_URL="your_db_url"
# ... weitere Variablen

# API starten
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Testing
```bash
# Tests ausführen
pytest

# Mit Coverage
pytest --cov=app
```

## 🔐 Umgebungsvariablen

| Variable | Beschreibung | Beispiel |
|----------|-------------|----------|
| `SUPABASE_URL` | Supabase Projekt URL | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase Anonymous Key | `eyJ...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Service Role Key | `eyJ...` |
| `DATABASE_URL` | PostgreSQL Connection String | `postgresql+asyncpg://user:pass@host:port/db` |
| `DEBUG` | Debug Modus | `true` / `false` |
| `ALLOWED_ORIGINS` | CORS Origins | `http://localhost:3000,http://localhost:8080` |

## 🏗️ Infrastruktur

### Docker Deployment
```bash
# Image bauen
docker build -t golf-api .

# Container starten
docker run -p 8000:8000 --env-file .env golf-api
```

### AWS Deployment (Terraform)
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## 📊 API Beispiele

### Golf Course erstellen
```bash
curl -X POST "http://localhost:8000/api/v1/golf-courses/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Augusta National Golf Club",
    "city": "Augusta",
    "country": "USA",
    "num_holes": 18,
    "par": 72,
    "course_rating": 76.2,
    "slope_rating": 137
  }'
```

### Golf Courses suchen
```bash
# Alle Courses
curl "http://localhost:8000/api/v1/golf-courses/"

# Mit Suche
curl "http://localhost:8000/api/v1/golf-courses/?search=Augusta&country=USA"

# Mit Pagination
curl "http://localhost:8000/api/v1/golf-courses/?skip=0&limit=10"
```

## 🏛️ Projektstruktur

```
GolfTrackerAnalytics/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI Anwendung
│   ├── config.py              # Konfiguration
│   ├── database.py            # Datenbankverbindung
│   ├── dependencies.py       # Abhängigkeiten
│   ├── models/               # SQLAlchemy Models
│   │   ├── golf_course.py
│   │   ├── golf_round.py
│   │   ├── hole_score.py
│   │   ├── user_profile.py
│   │   ├── friendship.py
│   │   └── group_round.py
│   ├── schemas/              # Pydantic Schemas
│   │   ├── golf_course.py
│   │   ├── golf_round.py
│   │   ├── hole_score.py
│   │   ├── user_profile.py
│   │   ├── friendship.py
│   │   └── group_round.py
│   └── routers/              # API Router
│       ├── golf_courses.py
│       ├── golf_rounds.py
│       ├── hole_scores.py
│       ├── user_profiles.py
│       ├── friendships.py
│       └── group_rounds.py
├── terraform/                # Infrastructure as Code
├── requirements.txt          # Python Dependencies
├── Dockerfile               # Docker Image
├── docker-compose.yml       # Docker Compose
└── README.md
```

## 🚦 Status

✅ FastAPI Basis-Setup  
✅ SQLAlchemy Models  
✅ Pydantic Schemas  
✅ Golf Courses CRUD  
✅ Docker Konfiguration  
🚧 Weitere Router (Rounds, Users, etc.)  
🚧 Terraform AWS Infrastruktur  
🚧 CI/CD Pipeline  

## 🤝 Beitragen

1. Fork das Repository
2. Feature Branch erstellen (`git checkout -b feature/neue-funktion`)
3. Änderungen committen (`git commit -am 'Neue Funktion hinzufügen'`)
4. Branch pushen (`git push origin feature/neue-funktion`)
5. Pull Request erstellen

## 📄 Lizenz

MIT License - siehe LICENSE file für Details.
