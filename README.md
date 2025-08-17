# Golf Tracker Analytics API

Eine moderne FastAPI-basierte CRUD-API für Golfplätze mit Supabase-Integration und AWS-Deployment über Terraform.

## 🏌️ Features

- **FastAPI**: Moderne, schnelle Web-API mit automatischer OpenAPI-Dokumentation
- **Supabase Integration**: PostgreSQL-Datenbank mit Echtzeit-Funktionen
- **Docker**: Containerisierte Anwendung für konsistente Deployments
- **AWS ECS Fargate**: Serverless Container-Hosting
- **Terraform**: Infrastructure as Code für AWS
- **HCP Terraform**: Automatisierte Deployments über Version Control
- **Auto Scaling**: Automatische Skalierung basierend auf CPU/Memory
- **Monitoring**: CloudWatch Logs und Container Insights

## 🚀 API Endpoints

### Golf Courses
- `POST /api/v1/golf-courses/` - Neuen Golfplatz erstellen
- `GET /api/v1/golf-courses/` - Alle Golfplätze abrufen (mit Pagination und Filtern)
- `GET /api/v1/golf-courses/{id}` - Spezifischen Golfplatz abrufen
- `PUT /api/v1/golf-courses/{id}` - Golfplatz aktualisieren
- `DELETE /api/v1/golf-courses/{id}` - Golfplatz löschen
- `GET /api/v1/golf-courses/search/` - Golfplätze durchsuchen

### Health & Documentation
- `GET /health` - Health Check
- `GET /docs` - Swagger UI Dokumentation
- `GET /redoc` - ReDoc Dokumentation

## 🛠️ Setup

### 1. Lokale Entwicklung

```bash
# Repository klonen
git clone <repository-url>
cd GolfTrackerAnalytics

# Environment-Datei erstellen
cp env.example .env
# .env mit Ihren Supabase-Credentials ausfüllen

# Dependencies installieren
pip install -r requirements.txt

# Datenbank-Schema in Supabase ausführen
# database/schema.sql in Supabase SQL Editor ausführen

# API lokal starten
python -m uvicorn app.main:app --reload
```

### 2. Docker

```bash
# Mit docker-compose
docker-compose up --build

# Oder mit Docker direkt
docker build -t golf-tracker-api .
docker run -p 8000:8000 --env-file .env golf-tracker-api
```

### 3. AWS Deployment

#### Voraussetzungen:
- AWS Account mit entsprechenden Berechtigungen
- HCP Terraform Account
- ECR Repository für Container Images
- Supabase Account und Datenbank

#### Schritte:

1. **ECR Repository erstellen**:
```bash
aws ecr create-repository --repository-name golf-tracker --region eu-central-1
```

2. **Image zu ECR pushen**:
```bash
# Login zu ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

# Image bauen und pushen
docker build -t golf-tracker .
docker tag golf-tracker:latest <account-id>.dkr.ecr.eu-central-1.amazonaws.com/golf-tracker:latest
docker push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/golf-tracker:latest
```

3. **HCP Terraform Workspace konfigurieren**:
   - Neuen Workspace in HCP Terraform erstellen
   - VCS-Integration mit GitHub einrichten
   - Environment Variables setzen:
     - `TF_VAR_container_image`: ECR Image URI
     - `TF_VAR_supabase_url`: Supabase URL
     - `TF_VAR_supabase_key`: Supabase Anon Key
     - `TF_VAR_database_url`: Database Connection String

4. **GitHub Secrets konfigurieren**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `TF_API_TOKEN`
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `DATABASE_URL`

5. **Deployment**:
   - Push zu `main` Branch triggert automatisches Deployment
   - GitHub Actions baut Image und deployed via Terraform

## 📊 Datenmodell

### Golf Course
```json
{
  "id": 1,
  "name": "Münchener Golf Club",
  "description": "Einer der ältesten und prestigeträchtigsten Golfclubs...",
  "address": "Golfplatzstraße 1",
  "city": "München",
  "country": "Deutschland",
  "postal_code": "80539",
  "phone": "+49 89 123456",
  "email": "info@mgc.de",
  "website": "https://www.mgc.de",
  "holes": 18,
  "par": 72,
  "yardage": 6200,
  "difficulty": "championship",
  "green_fee": 95.00,
  "latitude": 48.1351,
  "longitude": 11.5820,
  "is_active": true,
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

## 🔧 Konfiguration

### Environment Variables
- `SUPABASE_URL`: Supabase Projekt URL
- `SUPABASE_KEY`: Supabase Anon/Service Key
- `DATABASE_URL`: PostgreSQL Connection String
- `ENVIRONMENT`: dev/staging/prod
- `API_HOST`: Host für die API (default: 0.0.0.0)
- `API_PORT`: Port für die API (default: 8000)

### Terraform Variables
Siehe `terraform/terraform.auto.tfvars.example` für alle verfügbaren Konfigurationsoptionen.

## 🏗️ Architektur

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub        │    │   HCP Terraform  │    │      AWS        │
│   Repository    │───▶│   Workspace      │───▶│   ECS Fargate   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
┌─────────────────┐    ┌──────────────────┐             │
│   Supabase      │◀───│   FastAPI App    │◀────────────┘
│   Database      │    │   (Container)    │
└─────────────────┘    └──────────────────┘
```

### AWS Infrastruktur:
- **VPC**: Isoliertes Netzwerk mit Public/Private Subnets
- **ECS Fargate**: Serverless Container-Hosting
- **Application Load Balancer**: HTTPS-Terminierung und Load Balancing
- **Auto Scaling**: CPU/Memory-basierte Skalierung
- **CloudWatch**: Logs und Monitoring
- **Systems Manager**: Secure Parameter Store für Secrets

## 🔍 Monitoring

- **Health Check**: `/health` Endpoint für Liveness/Readiness Probes
- **CloudWatch Logs**: Zentrale Log-Aggregation
- **Container Insights**: Detaillierte Container-Metriken
- **ALB Access Logs**: HTTP-Request-Logging

## 🚦 CI/CD Pipeline

1. **Test**: Unit Tests ausführen
2. **Build**: Docker Image bauen
3. **Push**: Image zu ECR pushen
4. **Deploy**: Terraform Apply via HCP Terraform

## 📝 Development

### Code-Struktur:
```
app/
├── __init__.py
├── main.py              # FastAPI App
├── config.py            # Konfiguration
├── models.py            # Pydantic Models
├── database.py          # Supabase Client
├── crud.py              # Database Operations
└── routes/
    ├── __init__.py
    ├── golf_courses.py  # Golf Course Endpoints
    └── health.py        # Health Check
```

### Lokale Tests:
```bash
# Tests ausführen (wenn implementiert)
python -m pytest tests/ -v

# API lokal testen
curl http://localhost:8000/health
curl http://localhost:8000/docs
```

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert.
