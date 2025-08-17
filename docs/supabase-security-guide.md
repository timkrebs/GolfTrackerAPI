# Supabase Security Best Practices

## 🔐 Key Types & Usage

### 1. Anon Key (Public)
```bash
# Use for: Client-side applications, public API access
# Security: Can be exposed in frontend code
# Permissions: Limited by Row Level Security (RLS)
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. Service Role Key (Private)
```bash
# Use for: Server-side applications, admin operations
# Security: NEVER expose to client-side
# Permissions: Bypasses RLS, full database access
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🛡️ Security Recommendations

### For Our Golf Tracker API:

#### Development Environment
```bash
# Use Anon Key for development
SUPABASE_KEY=your_anon_key_here
# Easier debugging, respects RLS policies
```

#### Production Environment  
```bash
# Use Service Key for production API
SUPABASE_KEY=your_service_key_here
# Full control, implement application-level security
```

## 🔒 Row Level Security (RLS) Setup

### Enable RLS for Golf Courses
```sql
-- Enable RLS
ALTER TABLE golf_courses ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read golf courses
CREATE POLICY "Golf courses are viewable by everyone" 
    ON golf_courses FOR SELECT 
    USING (true);

-- Policy: Only authenticated users can insert
CREATE POLICY "Authenticated users can insert golf courses" 
    ON golf_courses FOR INSERT 
    TO authenticated 
    WITH CHECK (true);

-- Policy: Only authenticated users can update
CREATE POLICY "Authenticated users can update golf courses" 
    ON golf_courses FOR UPDATE 
    TO authenticated 
    USING (true);

-- Policy: Only authenticated users can delete
CREATE POLICY "Authenticated users can delete golf courses" 
    ON golf_courses FOR DELETE 
    TO authenticated 
    USING (true);
```

### Application-Level Security (Recommended)
```python
# In your FastAPI app, implement your own auth
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer

security = HTTPBearer()

async def verify_token(token: str = Depends(security)):
    # Implement your authentication logic
    # Validate JWT, check permissions, etc.
    if not is_valid_token(token.credentials):
        raise HTTPException(status_code=401, detail="Invalid token")
    return token
```

## 🔄 Key Rotation Strategy

### 1. Environment Separation
```bash
# Development Keys (Rotate Monthly)
SUPABASE_DEV_URL=https://dev-project.supabase.co
SUPABASE_DEV_KEY=dev_key_here

# Production Keys (Rotate Weekly)
SUPABASE_PROD_URL=https://prod-project.supabase.co  
SUPABASE_PROD_KEY=prod_key_here
```

### 2. Automated Rotation (Advanced)
```bash
# Using AWS Secrets Manager Rotation
aws secretsmanager rotate-secret \
    --secret-id golf-tracker/prod/supabase \
    --rotation-lambda-arn arn:aws:lambda:region:account:function:supabase-rotator
```

## 📊 Monitoring & Auditing

### 1. Supabase Dashboard
- Monitor API usage
- Check authentication patterns
- Review database performance

### 2. Custom Logging
```python
# Add to your FastAPI app
import logging

logger = logging.getLogger(__name__)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(f"API Request: {request.method} {request.url.path} - {response.status_code} - {process_time:.4f}s")
    return response
```

### 3. AWS CloudWatch Integration
```python
# Send metrics to CloudWatch
import boto3

cloudwatch = boto3.client('cloudwatch')

def send_api_metric(metric_name: str, value: float):
    cloudwatch.put_metric_data(
        Namespace='GolfTracker/API',
        MetricData=[
            {
                'MetricName': metric_name,
                'Value': value,
                'Unit': 'Count'
            }
        ]
    )
```

## 🚨 Emergency Procedures

### If Keys Are Compromised:

1. **Immediate Actions**
   ```bash
   # 1. Revoke compromised keys in Supabase Dashboard
   # 2. Generate new keys
   # 3. Update all environments
   ```

2. **Update Production**
   ```bash
   # Update AWS SSM Parameter
   aws ssm put-parameter \
       --name "/golf-tracker/prod/supabase_key" \
       --value "new_key_here" \
       --type "SecureString" \
       --overwrite
   
   # Restart ECS service to pick up new keys
   aws ecs update-service \
       --cluster golf-tracker-prod-cluster \
       --service golf-tracker-prod-service \
       --force-new-deployment
   ```

3. **Audit & Monitor**
   ```bash
   # Check Supabase logs for unauthorized access
   # Review CloudWatch logs for anomalies
   # Monitor application metrics for unusual patterns
   ```

## 🔍 Testing Security

### Local Security Testing
```bash
# Test with invalid credentials
curl -X GET "http://localhost:8000/api/v1/golf-courses/" \
     -H "Authorization: Bearer invalid_token"

# Test rate limiting (if implemented)
for i in {1..100}; do
  curl -X GET "http://localhost:8000/api/v1/golf-courses/"
done
```

### Production Security Validation
```bash
# Verify HTTPS
curl -I https://your-api-domain.com/health

# Test security headers
curl -I https://your-api-domain.com/health | grep -i security

# Validate certificate
openssl s_client -connect your-api-domain.com:443 -servername your-api-domain.com
```

## 📋 Security Checklist

- [ ] RLS enabled on database tables
- [ ] Service keys stored securely (AWS SSM/Secrets Manager)
- [ ] Different keys for different environments
- [ ] API rate limiting implemented
- [ ] HTTPS enforced in production
- [ ] Security headers configured
- [ ] Input validation on all endpoints
- [ ] Error messages don't leak sensitive info
- [ ] Logging configured but secrets redacted
- [ ] Regular security audits scheduled
- [ ] Incident response plan documented
