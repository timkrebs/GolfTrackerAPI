# Golf Course API

A comprehensive FastAPI-based CRUD application for managing golf course data, including detailed hole information, course metadata, and search functionality.

## Features

- **Full CRUD Operations**: Create, Read, Update, Delete golf courses
- **Detailed Hole Management**: Each course includes comprehensive hole data (par, distance, handicap)
- **Search Functionality**: Search courses by name, location, or country
- **Data Validation**: Comprehensive input validation using Pydantic models
- **API Documentation**: Auto-generated OpenAPI/Swagger documentation
- **Docker Support**: Fully containerized application
- **Health Checks**: Built-in health monitoring endpoints

## API Endpoints

### Golf Courses
- `GET /golf-courses` - Get all golf courses (with optional search)
- `GET /golf-courses/{course_id}` - Get a specific golf course
- `POST /golf-courses` - Create a new golf course
- `PUT /golf-courses/{course_id}` - Update an existing golf course
- `DELETE /golf-courses/{course_id}` - Delete a golf course

### Holes
- `GET /golf-courses/{course_id}/holes` - Get all holes for a course
- `GET /golf-courses/{course_id}/holes/{hole_number}` - Get a specific hole

### Utility
- `GET /` - API information
- `GET /health` - Health check endpoint
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation (ReDoc)

## Data Model

### Golf Course
```json
{
  "id": "uuid4",
  "name": "Golf Course Name",
  "location": "City, State/Region",
  "country": "Country",
  "total_holes": 18,
  "holes": [...]
}
```

### Hole
```json
{
  "hole_number": 1,
  "par": 4,
  "distance_meters": 400,
  "handicap": 10
}
```

## Quick Start

### Using Docker (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd GolfTrackerAnalytics
   ```

2. **Start the application**
   ```bash
   docker-compose up -d
   ```

3. **Access the API**
   - API: http://localhost:8000
   - Documentation: http://localhost:8000/docs
   - Health Check: http://localhost:8000/health

### Local Development

1. **Set up Python virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

## Docker Commands

### Build and Run
```bash
# Build the Docker image
docker build -t golf-course-api .

# Run the container
docker run -p 8000:8000 golf-course-api

# Or use docker-compose
docker-compose up -d
```

### Development with Hot Reload
```bash
# Run with volume mounting for development
docker-compose up
```

### Stop the Application
```bash
docker-compose down
```

## Example Usage

### Creating a Golf Course
```bash
curl -X POST "http://localhost:8000/golf-courses" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Augusta National Golf Club",
    "location": "Augusta, Georgia",
    "country": "United States",
    "total_holes": 18,
    "holes": [
      {
        "hole_number": 1,
        "par": 4,
        "distance_meters": 411,
        "handicap": 10
      }
    ]
  }'
```

### Getting All Golf Courses
```bash
curl "http://localhost:8000/golf-courses"
```

### Searching Golf Courses
```bash
curl "http://localhost:8000/golf-courses?search=Augusta"
```

### Getting a Specific Course
```bash
curl "http://localhost:8000/golf-courses/{course-id}"
```

## Sample Data

The application comes with two pre-loaded golf courses:

1. **Golf-Club Bad Kissingen e.V. - Thuringia Course** (Germany)
2. **Augusta National Golf Club** (United States)

Both courses include complete 18-hole data with par, distance, and handicap information.

## API Response Format

All API responses follow a consistent format:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... },
  "total": 2  // For list endpoints
}
```

## Validation Rules

- **Hole Numbers**: Must be sequential from 1 to total_holes
- **Par Values**: Must be between 3 and 5
- **Distance**: Must be greater than 0 meters
- **Handicap**: Must be between 1 and 18
- **Total Holes**: Must match the number of holes provided

## Error Handling

The API includes comprehensive error handling with appropriate HTTP status codes:

- `200` - Success
- `400` - Bad Request (validation errors)
- `404` - Not Found
- `500` - Internal Server Error

## Development

### Project Structure
```
GolfTrackerAnalytics/
├── app/
│   ├── main.py          # FastAPI application and routes
│   ├── models.py        # Pydantic data models
│   └── database.py      # In-memory database
├── requirements.txt     # Python dependencies
├── Dockerfile          # Docker configuration
├── docker-compose.yml  # Docker Compose configuration
└── README.md           # This file
```

### Adding New Features

1. **Models**: Add new Pydantic models in `app/models.py`
2. **Database**: Extend the database class in `app/database.py`
3. **Routes**: Add new endpoints in `app/main.py`

### Running Tests

Currently, the application includes basic validation and error handling. For production use, consider adding:

- Unit tests with pytest
- Integration tests
- Load testing
- Logging configuration
- Database persistence (PostgreSQL, MongoDB, etc.)

## Production Considerations

For production deployment, consider:

1. **Database**: Replace in-memory storage with a persistent database
2. **Authentication**: Add user authentication and authorization
3. **Rate Limiting**: Implement API rate limiting
4. **Monitoring**: Add application monitoring and logging
5. **HTTPS**: Configure SSL/TLS certificates
6. **Environment Variables**: Use environment-based configuration
7. **Scaling**: Consider horizontal scaling with load balancers

## 🚀 CI/CD Pipeline

This project includes a complete CI/CD pipeline using GitHub Actions:

### Features
- **Automated Testing**: Runs on every pull request
- **Multi-Environment Deployment**: Separate dev and prod environments  
- **Security Scanning**: Vulnerability scanning with Trivy
- **Infrastructure as Code**: Automated Terraform deployments
- **Health Checks**: Post-deployment verification

### Quick Setup
```bash
# Run the setup script
./scripts/setup-cicd.sh

# Follow the instructions to configure GitHub secrets
```

### Deployment
- **Development**: Push to `develop` branch
- **Production**: Push to `main` branch
- **Infrastructure**: Manual workflow dispatch or terraform changes

For detailed instructions, see [CICD_GUIDE.md](CICD_GUIDE.md)

## 📊 Project Structure

```
GolfTrackerAnalytics/
├── .github/workflows/       # CI/CD pipelines
│   ├── deploy.yml          # Application deployment
│   └── infrastructure.yml  # Infrastructure deployment
├── app/                    # FastAPI application
├── terraform/              # Infrastructure as Code
├── tests/                  # Test suite
├── scripts/                # Deployment and setup scripts
└── docs/                   # Documentation
```

## License

This project is open source and available under the MIT License.
