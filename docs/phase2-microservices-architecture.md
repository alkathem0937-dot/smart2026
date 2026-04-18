# المرحلة 2 — SmartJudi Microservices Architecture Design

---

## 1. Service Boundaries

### 1.1 Service Map (8 Services)

```
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (Nginx/Kong)                     │
│                    gateway.smartjudi.local                        │
├──────┬──────┬──────┬──────┬──────┬──────┬──────┬────────────────┤
│      │      │      │      │      │      │      │                │
│ AUTH │CASES │HEAR- │ DOCS │LEGAL │NOTIF │SEARCH│   AI ASSIST    │
│      │      │INGS  │      │      │      │      │  (RAG Engine)  │
│:8001 │:8002 │:8003 │:8004 │:8005 │:8006 │:8007 │    :8008       │
│      │      │      │      │      │      │      │                │
│Pg-01 │Pg-02 │Pg-03 │Pg-04 │Pg-05 │Pg-06 │Pg-07 │ ChromaDB      │
└──────┴──────┴──────┴──────┴──────┴──────┴──────┴────────────────┘
         │              │              │
         └──── Redis (Cache + Events) ─┘
```

### 1.2 Service Definitions

| # | Service | Port | Responsibility | Current Django Apps |
|---|---------|------|----------------|---------------------|
| 1 | **auth-service** | 8001 | JWT auth, registration, user profiles, RBAC, sub-accounts, sessions | `accounts`, `logs.UserSession` |
| 2 | **cases-service** | 8002 | Lawsuits, Cases, Parties, Templates, Financial Claims, Responses, Appeals, Judgments, Payments | `lawsuits`, `parties`, `responses`, `appeals`, `judgments`, `payments` |
| 3 | **hearings-service** | 8003 | Court hearings, scheduling, calendar | `hearings` |
| 4 | **documents-service** | 8004 | File uploads, case file items, storage | `attachments`, `lawsuits.CaseFileItem` |
| 5 | **legal-service** | 8005 | Legal library, laws, articles, procedures, courts reference data | `laws`, `courts` |
| 6 | **notifications-service** | 8006 | In-app notifications, push, email, messaging | `notifications`, `messaging` |
| 7 | **search-service** | 8007 | Full-text search, search logs, AI chat logs | `logs.SearchLog`, `logs.AIChatLog` |
| 8 | **ai-service** | 8008 | AI assistant, case analysis, RAG | `ai_assistant`, `rag_engine` |

---

## 2. Database Schemas Per Service

### 2.1 auth-service DB (`smartjudi_auth`)

```sql
-- Django auth tables (managed by Django)
auth_user (id, username, password, email, first_name, last_name, is_active, is_staff, is_superuser, ...)
auth_group, auth_permission, auth_user_groups, auth_user_user_permissions

-- Custom tables
user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES auth_user(id),
    role VARCHAR(20) NOT NULL DEFAULT 'citizen',  -- judge|lawyer|notary|citizen|assistant|admin
    phone_number VARCHAR(20),
    national_id VARCHAR(30),
    supervisor_id INTEGER REFERENCES auth_user(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES auth_user(id),
    ip_address VARCHAR(45),
    device_type VARCHAR(50),
    device_name VARCHAR(100),
    os_version VARCHAR(50),
    app_version VARCHAR(20),
    governorate VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    login_time TIMESTAMP DEFAULT NOW(),
    logout_time TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- JWT Token Blacklist (managed by simplejwt)
token_blacklist_outstandingtoken, token_blacklist_blacklistedtoken
```

**Exposed User ID**: All other services reference `user_id` (integer) from this service. They do NOT store user details — they call auth-service to resolve user info when needed.

### 2.2 cases-service DB (`smartjudi_cases`)

```sql
cases (
    id SERIAL PRIMARY KEY,
    case_number VARCHAR(100) UNIQUE NOT NULL,
    filing_date DATE,
    gregorian_date DATE,
    hijri_date VARCHAR(50),
    case_year_hijri SMALLINT,
    case_status VARCHAR(50) DEFAULT 'جديد',
    case_type VARCHAR(50),
    case_subtype VARCHAR(100),
    governorate VARCHAR(50),
    court_id INTEGER,          -- reference to legal-service court
    court_name VARCHAR(200),   -- denormalized
    subject VARCHAR(200),
    description TEXT,
    client_id INTEGER,         -- user_id from auth-service
    created_by_id INTEGER,     -- user_id from auth-service
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

case_parties (
    id SERIAL PRIMARY KEY,
    case_id INTEGER REFERENCES cases(id),
    role VARCHAR(20),          -- client|opponent
    party_type VARCHAR(20),    -- person|organization
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(20),
    national_id VARCHAR(30),
    address TEXT,
    user_account_id INTEGER,   -- optional link to auth user
    created_at TIMESTAMP DEFAULT NOW()
);

lawsuits (
    id SERIAL PRIMARY KEY,
    case_id INTEGER REFERENCES cases(id),
    case_number VARCHAR(100) UNIQUE NOT NULL,
    filing_date DATE,
    gregorian_date DATE,
    hijri_date VARCHAR(50),
    case_year_hijri SMALLINT,
    case_type VARCHAR(50) DEFAULT 'دعوى',
    case_subtype VARCHAR(100),
    case_status VARCHAR(50) DEFAULT 'جديد',
    status VARCHAR(50) DEFAULT 'pending',
    governorate VARCHAR(50),
    court_id INTEGER,
    court_name VARCHAR(200),
    subject VARCHAR(200),
    description TEXT,
    facts TEXT,
    legal_basis TEXT,
    legal_reasons TEXT,
    reasons TEXT,
    requests TEXT,
    notes TEXT,
    parent_lawsuit_id INTEGER REFERENCES lawsuits(id),
    client_id INTEGER,
    created_by_id INTEGER,
    -- Archive lifecycle
    archive_status VARCHAR(20) DEFAULT 'active',
    archive_date TIMESTAMP,
    archive_reason TEXT,
    archived_by_id INTEGER,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

legal_templates (
    id SERIAL PRIMARY KEY,
    case_type VARCHAR(50),
    section_key VARCHAR(100),
    section_title VARCHAR(200),
    default_text TEXT,
    template_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

financial_claims (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    amount DECIMAL(18,2),
    currency VARCHAR(5) DEFAULT 'YER',
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

plaintiffs (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    name VARCHAR(200) NOT NULL,
    gender VARCHAR(10),
    nationality VARCHAR(50),
    occupation VARCHAR(100),
    address TEXT,
    phone VARCHAR(20),
    attorney_name VARCHAR(200),
    attorney_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

defendants (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    name VARCHAR(200) NOT NULL,
    gender VARCHAR(10),
    nationality VARCHAR(50),
    occupation VARCHAR(100),
    address TEXT,
    phone VARCHAR(20),
    attorney_name VARCHAR(200),
    attorney_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

responses (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    response_text TEXT,
    submitted_by VARCHAR(200),
    submitted_by_user_id INTEGER,
    submission_date DATE,
    response_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

appeals (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    appeal_type VARCHAR(50),
    appeal_number VARCHAR(100),
    appeal_date DATE,
    appeal_reasons TEXT,
    appeal_requests TEXT,
    higher_court VARCHAR(200),
    status VARCHAR(50) DEFAULT 'pending',
    submitted_by_user_id INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

judgments (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    judgment_type VARCHAR(50),
    judgment_number VARCHAR(100),
    judgment_date DATE,
    judgment_text TEXT,
    summary TEXT,
    judge_name VARCHAR(200),
    judge_id INTEGER,
    court_name VARCHAR(200),
    status VARCHAR(50) DEFAULT 'draft',
    created_by_id INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

payment_orders (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    order_number VARCHAR(100),
    amount DECIMAL(18,2),
    description TEXT,
    order_date DATE,
    status VARCHAR(50) DEFAULT 'pending',
    paid_amount DECIMAL(18,2) DEFAULT 0,
    payment_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

audit_logs (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    user_id INTEGER,
    lawsuit_id INTEGER REFERENCES lawsuits(id),
    description TEXT,
    metadata JSONB,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT NOW()
);
```

### 2.3 hearings-service DB (`smartjudi_hearings`)

```sql
hearings (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER NOT NULL,     -- cross-service reference
    hearing_date DATE,
    hearing_time TIME,
    notes TEXT,
    hearing_type VARCHAR(50),
    judge_name VARCHAR(200),
    judge_id INTEGER,                -- user_id from auth-service
    created_by_id INTEGER,
    -- Archive lifecycle
    archive_status VARCHAR(20) DEFAULT 'active',
    archive_date TIMESTAMP,
    archive_reason TEXT,
    archived_by_id INTEGER,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 2.4 documents-service DB (`smartjudi_documents`)

```sql
attachments (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER NOT NULL,     -- cross-service reference
    document_type VARCHAR(50),
    gregorian_date DATE,
    hijri_date VARCHAR(50),
    page_count INTEGER,
    content TEXT,
    evidence_basis TEXT,
    file VARCHAR(500),               -- S3/MinIO path
    original_filename VARCHAR(255),
    file_size INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

case_file_items (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER NOT NULL,
    item_type VARCHAR(30) DEFAULT 'document',
    title VARCHAR(255),
    description TEXT DEFAULT '',
    file VARCHAR(500),
    original_filename VARCHAR(255) DEFAULT '',
    file_size INTEGER,
    related_object_id INTEGER,
    related_object_type VARCHAR(50) DEFAULT '',
    created_by_id INTEGER,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 2.5 legal-service DB (`smartjudi_legal`)

```sql
-- Reference data: courts hierarchy
governorates (id, name, code, created_at);
districts (id, name, governorate_id REFERENCES governorates(id), created_at);
court_types (id, name, judicial_level, order, created_at);
court_specializations (id, name, code, created_at);
courts (id, name, court_type_id, governorate_id, district_id, is_active, ...);
courts_specializations (court_id, specialization_id);  -- M2M

-- Legal knowledge
legal_categories (id, name, description, created_at);
laws (id, name, description, category_id, issue_year, created_at);
law_chapters (id, title, law_id, order, created_at);
law_sections (id, title, chapter_id, order, created_at);
law_articles (id, article_number, article_text, section_id, order, created_at);

-- Denormalized flat table for fast search
legal_articles_flat (
    id SERIAL PRIMARY KEY,
    source_title VARCHAR(500),
    book_title VARCHAR(500),
    section_title VARCHAR(500),
    chapter_title VARCHAR(500),
    branch_title VARCHAR(500),
    article_number VARCHAR(100),
    article_text TEXT
);

-- Procedures guide (tree structure)
legal_procedure_nodes (
    id BIGINT PRIMARY KEY,
    parent_id BIGINT REFERENCES legal_procedure_nodes(id),
    source_title VARCHAR(500),
    title TEXT,
    body TEXT,
    level VARCHAR(50),
    node_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Case → Article references (cross-service: lawsuit_id from cases-service)
case_legal_references (
    id SERIAL PRIMARY KEY,
    lawsuit_id INTEGER NOT NULL,
    article_id INTEGER REFERENCES law_articles(id),
    notes TEXT,
    confidence_score FLOAT DEFAULT 0,
    is_ai BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Lawyers directory
lawyers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,              -- optional auth-service user link
    registration_number VARCHAR(50),
    name VARCHAR(200),
    grade VARCHAR(100),
    branch VARCHAR(100),
    governorate VARCHAR(100),
    neighborhood VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

lawyer_filter_options (id, option_type, display_name, sort_order, is_active);
```

### 2.6 notifications-service DB (`smartjudi_notifications`)

```sql
notifications (
    id SERIAL PRIMARY KEY,
    recipient_id INTEGER NOT NULL,  -- user_id from auth-service
    notification_type VARCHAR(30) DEFAULT 'system',
    title VARCHAR(255),
    body TEXT DEFAULT '',
    is_read BOOLEAN DEFAULT FALSE,
    related_object_id INTEGER,
    related_object_type VARCHAR(50) DEFAULT '',
    created_at TIMESTAMP DEFAULT NOW()
);

messages (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    lawsuit_id INTEGER,             -- cross-service reference
    content TEXT,
    attachment VARCHAR(500),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 2.7 search-service DB (`smartjudi_search`)

```sql
search_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    search_query TEXT,
    results_count INTEGER DEFAULT 0,
    search_date TIMESTAMP DEFAULT NOW()
);

ai_chat_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question TEXT,
    answer TEXT,
    model_version VARCHAR(50),
    tokens_used INTEGER DEFAULT 0,
    response_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 2.8 ai-service (ChromaDB — already separate)
Uses ChromaDB vector store + HuggingFace embeddings (existing `rag_engine/`). No relational DB.

---

## 3. API Contracts

### 3.1 API Gateway Routing

```nginx
# /etc/nginx/conf.d/gateway.conf

# Auth Service
location /api/token/          { proxy_pass http://auth-service:8001; }
location /api/token/refresh/  { proxy_pass http://auth-service:8001; }
location /api/register/       { proxy_pass http://auth-service:8001; }
location /api/profiles/       { proxy_pass http://auth-service:8001; }
location /api/user-sessions/  { proxy_pass http://auth-service:8001; }

# Cases Service
location /api/cases/              { proxy_pass http://cases-service:8002; }
location /api/case-parties/       { proxy_pass http://cases-service:8002; }
location /api/lawsuits/           { proxy_pass http://cases-service:8002; }
location /api/legal-templates/    { proxy_pass http://cases-service:8002; }
location /api/financial-claims/   { proxy_pass http://cases-service:8002; }
location /api/plaintiffs/         { proxy_pass http://cases-service:8002; }
location /api/defendants/         { proxy_pass http://cases-service:8002; }
location /api/responses/          { proxy_pass http://cases-service:8002; }
location /api/appeals/            { proxy_pass http://cases-service:8002; }
location /api/judgments/          { proxy_pass http://cases-service:8002; }
location /api/payment-orders/     { proxy_pass http://cases-service:8002; }
location /api/audit-logs/         { proxy_pass http://cases-service:8002; }

# Hearings Service
location /api/hearings/           { proxy_pass http://hearings-service:8003; }

# Documents Service
location /api/attachments/        { proxy_pass http://documents-service:8004; }
location /api/case-file-items/    { proxy_pass http://documents-service:8004; }

# Legal Service
location /api/governorates/             { proxy_pass http://legal-service:8005; }
location /api/districts/                { proxy_pass http://legal-service:8005; }
location /api/court-types/              { proxy_pass http://legal-service:8005; }
location /api/court-specializations/    { proxy_pass http://legal-service:8005; }
location /api/courts/                   { proxy_pass http://legal-service:8005; }
location /api/legal-categories/         { proxy_pass http://legal-service:8005; }
location /api/laws/                     { proxy_pass http://legal-service:8005; }
location /api/law-chapters/             { proxy_pass http://legal-service:8005; }
location /api/law-sections/             { proxy_pass http://legal-service:8005; }
location /api/law-articles/             { proxy_pass http://legal-service:8005; }
location /api/case-legal-references/    { proxy_pass http://legal-service:8005; }
location /api/legal-library/            { proxy_pass http://legal-service:8005; }
location /api/legal-procedures/         { proxy_pass http://legal-service:8005; }
location /api/lawyers/                  { proxy_pass http://legal-service:8005; }
location /api/lawyer-filter-options/    { proxy_pass http://legal-service:8005; }

# Notifications Service
location /api/notifications/    { proxy_pass http://notifications-service:8006; }
location /api/messaging/        { proxy_pass http://notifications-service:8006; }

# Search Service
location /api/search-logs/      { proxy_pass http://search-service:8007; }
location /api/ai-chat-logs/     { proxy_pass http://search-service:8007; }

# AI Service
location /api/ai/               { proxy_pass http://ai-service:8008; }
```

**Key principle**: Flutter `api_config.dart` endpoints remain **UNCHANGED**. The API Gateway routes by prefix to the correct service. Zero frontend code changes for routing.

### 3.2 Inter-Service Communication

| From | To | Method | Use Case |
|------|----|--------|----------|
| cases-service | auth-service | REST `GET /internal/users/{id}/` | Resolve user names for serializers |
| hearings-service | cases-service | REST `GET /internal/lawsuits/{id}/` | Validate lawsuit exists |
| hearings-service | auth-service | REST `GET /internal/users/{id}/` | Resolve judge name |
| documents-service | cases-service | REST `GET /internal/lawsuits/{id}/` | Validate lawsuit exists |
| legal-service | cases-service | REST `GET /internal/lawsuits/{id}/` | Validate lawsuit for legal refs |
| notifications-service | auth-service | REST `GET /internal/users/{id}/` | Resolve recipient info |
| cases-service | notifications-service | **Redis Event** `lawsuit.created` | Trigger notification to client |
| cases-service | notifications-service | **Redis Event** `judgment.issued` | Notify parties |
| hearings-service | notifications-service | **Redis Event** `hearing.scheduled` | Notify parties |
| cases-service | search-service | **Redis Event** `lawsuit.updated` | Update search index |

### 3.3 Internal API (Service-to-Service)

Each service exposes `/internal/` endpoints accessible only within the Docker network (not exposed through Gateway):

```python
# auth-service internal endpoints
GET  /internal/users/{id}/           → {id, username, first_name, last_name, role}
GET  /internal/users/bulk/           → POST {ids: [1,2,3]} → [{id, username, role}, ...]
GET  /internal/users/{id}/validate/  → {valid: true, role: "lawyer"}

# cases-service internal endpoints
GET  /internal/lawsuits/{id}/        → {id, case_number, subject, created_by_id, client_id}
GET  /internal/lawsuits/{id}/exists/ → {exists: true}

# legal-service internal endpoints
GET  /internal/courts/{id}/          → {id, name, court_type, governorate}
```

### 3.4 Shared JWT Validation

All services validate JWT tokens independently using the **same `SECRET_KEY`**:

```python
# shared_auth.py (included as a pip package or copied to each service)
SIMPLE_JWT = {
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': os.environ['JWT_SECRET_KEY'],
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```

Each service decodes the JWT to get `user_id` and `role` without calling auth-service. Only when full user details (name, email) are needed does a service call `/internal/users/{id}/`.

---

## 4. Event-Driven Communication

### 4.1 Redis Pub/Sub Channels

```
smartjudi:events:lawsuits      → lawsuit.created, lawsuit.updated, lawsuit.archived
smartjudi:events:hearings      → hearing.scheduled, hearing.updated, hearing.cancelled
smartjudi:events:judgments      → judgment.issued, judgment.updated
smartjudi:events:documents      → document.uploaded, document.deleted
smartjudi:events:notifications  → notification.send
```

### 4.2 Event Schema

```json
{
    "event_type": "lawsuit.created",
    "timestamp": "2025-04-17T20:00:00Z",
    "source_service": "cases-service",
    "payload": {
        "lawsuit_id": 123,
        "case_number": "001/2025",
        "created_by_id": 5,
        "client_id": 12
    }
}
```

### 4.3 Event Handlers

| Event | Handler Service | Action |
|-------|-----------------|--------|
| `lawsuit.created` | notifications-service | Create notification for client |
| `hearing.scheduled` | notifications-service | Notify all lawsuit parties |
| `judgment.issued` | notifications-service | Notify lawyer + client |
| `document.uploaded` | search-service | Index document content |
| `lawsuit.updated` | search-service | Update search index |

---

## 5. Docker Infrastructure

### 5.1 Directory Structure

```
smartjudi-microservices/
├── docker-compose.yml
├── docker-compose.dev.yml
├── .env
├── gateway/
│   └── nginx.conf
├── services/
│   ├── auth/
│   │   ├── Dockerfile
│   │   ├── manage.py
│   │   ├── auth_service/
│   │   │   ├── settings.py
│   │   │   ├── urls.py
│   │   │   └── wsgi.py
│   │   ├── accounts/           ← migrated from monolith
│   │   ├── requirements.txt
│   │   └── shared/             ← shared JWT config
│   ├── cases/
│   │   ├── Dockerfile
│   │   ├── manage.py
│   │   ├── cases_service/
│   │   ├── lawsuits/           ← migrated
│   │   ├── parties/            ← migrated
│   │   ├── responses/          ← migrated
│   │   ├── appeals/            ← migrated
│   │   ├── judgments/          ← migrated
│   │   ├── payments/           ← migrated
│   │   ├── audit/              ← migrated
│   │   └── requirements.txt
│   ├── hearings/
│   │   ├── Dockerfile
│   │   ├── hearings_app/       ← migrated
│   │   └── requirements.txt
│   ├── documents/
│   │   ├── Dockerfile
│   │   ├── attachments/        ← migrated
│   │   └── requirements.txt
│   ├── legal/
│   │   ├── Dockerfile
│   │   ├── laws/               ← migrated
│   │   ├── courts/             ← migrated
│   │   ├── lawyers/            ← migrated
│   │   └── requirements.txt
│   ├── notifications/
│   │   ├── Dockerfile
│   │   ├── notifications_app/  ← new app from Phase 1
│   │   ├── messaging/          ← migrated
│   │   └── requirements.txt
│   ├── search/
│   │   ├── Dockerfile
│   │   ├── search_app/
│   │   └── requirements.txt
│   └── ai/
│       ├── Dockerfile          ← existing rag_engine/Dockerfile
│       ├── main.py             ← existing rag_engine/main.py
│       └── requirements.txt
└── flutter/                     ← existing Flutter app (unchanged)
    ├── lib/
    └── pubspec.yaml
```

### 5.2 docker-compose.yml

```yaml
version: '3.8'

services:
  # ─── Infrastructure ───
  gateway:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes: ["./gateway/nginx.conf:/etc/nginx/conf.d/default.conf:ro"]
    depends_on: [auth, cases, hearings, documents, legal, notifications, search, ai]
    networks: [smartjudi-net]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
    volumes: ["redis-data:/data"]
    networks: [smartjudi-net]

  # ─── Databases ───
  db-auth:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: smartjudi_auth
      POSTGRES_USER: smartjudi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata-auth:/var/lib/postgresql/data"]
    networks: [smartjudi-net]

  db-cases:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: smartjudi_cases
      POSTGRES_USER: smartjudi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata-cases:/var/lib/postgresql/data"]
    networks: [smartjudi-net]

  db-hearings:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: smartjudi_hearings
      POSTGRES_USER: smartjudi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata-hearings:/var/lib/postgresql/data"]
    networks: [smartjudi-net]

  db-documents:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: smartjudi_documents
      POSTGRES_USER: smartjudi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata-documents:/var/lib/postgresql/data"]
    networks: [smartjudi-net]

  db-legal:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: smartjudi_legal
      POSTGRES_USER: smartjudi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata-legal:/var/lib/postgresql/data"]
    networks: [smartjudi-net]

  db-notifications:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: smartjudi_notifications
      POSTGRES_USER: smartjudi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata-notifications:/var/lib/postgresql/data"]
    networks: [smartjudi-net]

  db-search:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: smartjudi_search
      POSTGRES_USER: smartjudi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata-search:/var/lib/postgresql/data"]
    networks: [smartjudi-net]

  # ─── Application Services ───
  auth:
    build: ./services/auth
    environment:
      DATABASE_URL: postgres://smartjudi:${DB_PASSWORD}@db-auth:5432/smartjudi_auth
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      REDIS_URL: redis://redis:6379/0
    depends_on: [db-auth, redis]
    networks: [smartjudi-net]

  cases:
    build: ./services/cases
    environment:
      DATABASE_URL: postgres://smartjudi:${DB_PASSWORD}@db-cases:5432/smartjudi_cases
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      REDIS_URL: redis://redis:6379/0
      AUTH_SERVICE_URL: http://auth:8001
    depends_on: [db-cases, redis]
    networks: [smartjudi-net]

  hearings:
    build: ./services/hearings
    environment:
      DATABASE_URL: postgres://smartjudi:${DB_PASSWORD}@db-hearings:5432/smartjudi_hearings
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      REDIS_URL: redis://redis:6379/0
      CASES_SERVICE_URL: http://cases:8002
      AUTH_SERVICE_URL: http://auth:8001
    depends_on: [db-hearings, redis]
    networks: [smartjudi-net]

  documents:
    build: ./services/documents
    environment:
      DATABASE_URL: postgres://smartjudi:${DB_PASSWORD}@db-documents:5432/smartjudi_documents
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      REDIS_URL: redis://redis:6379/0
      CASES_SERVICE_URL: http://cases:8002
    depends_on: [db-documents, redis]
    networks: [smartjudi-net]

  legal:
    build: ./services/legal
    environment:
      DATABASE_URL: postgres://smartjudi:${DB_PASSWORD}@db-legal:5432/smartjudi_legal
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
    depends_on: [db-legal]
    networks: [smartjudi-net]

  notifications:
    build: ./services/notifications
    environment:
      DATABASE_URL: postgres://smartjudi:${DB_PASSWORD}@db-notifications:5432/smartjudi_notifications
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      REDIS_URL: redis://redis:6379/0
      AUTH_SERVICE_URL: http://auth:8001
    depends_on: [db-notifications, redis]
    networks: [smartjudi-net]

  search:
    build: ./services/search
    environment:
      DATABASE_URL: postgres://smartjudi:${DB_PASSWORD}@db-search:5432/smartjudi_search
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      REDIS_URL: redis://redis:6379/0
    depends_on: [db-search, redis]
    networks: [smartjudi-net]

  ai:
    build: ./services/ai
    environment:
      GROQ_API_KEY: ${GROQ_API_KEY}
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      CHROMA_DB_DIR: /data/chroma_db
    volumes: ["ai-chromadb:/data/chroma_db"]
    depends_on: [redis]
    networks: [smartjudi-net]

volumes:
  redis-data:
  pgdata-auth:
  pgdata-cases:
  pgdata-hearings:
  pgdata-documents:
  pgdata-legal:
  pgdata-notifications:
  pgdata-search:
  ai-chromadb:

networks:
  smartjudi-net:
    driver: bridge
```

### 5.3 Standard Dockerfile (per service)

```dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN python manage.py collectstatic --noinput || true

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "120", "service.wsgi:application"]
```

---

## 6. Stepwise Migration Plan

### Phase 2A: Infrastructure Setup (Week 1)

| Step | Action | Risk |
|------|--------|------|
| 1 | Create `smartjudi-microservices/` repo structure | None |
| 2 | Set up `docker-compose.yml` with all databases + Redis + Gateway | None |
| 3 | Create shared JWT validation package (`smartjudi-auth-common`) | None |
| 4 | Set up Nginx gateway config routing all traffic to monolith initially | None |

### Phase 2B: Extract Legal Service (Week 2) — Lowest Risk

| Step | Action | Why First |
|------|--------|-----------|
| 1 | Copy `laws/`, `courts/`, `lawyers/` apps to `services/legal/` | Read-only reference data, no writes from other services |
| 2 | Create `legal_service/settings.py` pointing to `db-legal` | Independent DB |
| 3 | Run `pg_dump` of `laws_*`, `courts_*`, `lawyers_*` tables → import to `db-legal` | Data migration |
| 4 | Update Gateway: route `/api/legal-*`, `/api/courts*`, `/api/lawyers*` → legal-service | Transparent to frontend |
| 5 | Remove routes from monolith, keep models for FK references | Monolith still runs |
| 6 | **Smoke test**: Flutter app → legal library, courts, lawyers | Verify zero breakage |

### Phase 2C: Extract Auth Service (Week 3)

| Step | Action |
|------|--------|
| 1 | Copy `accounts/` to `services/auth/`, add `user_sessions` from `logs/` |
| 2 | Migrate `auth_user`, `user_profiles`, `user_sessions` tables |
| 3 | Update Gateway: route `/api/token/`, `/api/register/`, `/api/profiles/` → auth-service |
| 4 | Add `/internal/users/{id}/` endpoint to auth-service |
| 5 | Update cases/hearings/documents services to call internal endpoint for user resolution |
| 6 | **Test**: login, register, profile update, sub-account creation |

### Phase 2D: Extract Notifications Service (Week 4)

| Step | Action |
|------|--------|
| 1 | Copy `notifications/`, `messaging/` to `services/notifications/` |
| 2 | Migrate `notifications_notification`, `messaging_message` tables |
| 3 | Set up Redis event listener for `lawsuit.*`, `hearing.*`, `judgment.*` |
| 4 | Update Gateway routing |
| 5 | **Test**: notifications list, mark read, messaging |

### Phase 2E: Extract Documents Service (Week 5)

| Step | Action |
|------|--------|
| 1 | Copy `attachments/` to `services/documents/`, include `CaseFileItem` |
| 2 | Migrate `attachments_attachment`, `lawsuits_casefileitem` tables |
| 3 | Set up file storage (MinIO or local volume) |
| 4 | Add internal endpoint to validate lawsuit_id via cases-service |
| 5 | Update Gateway routing |
| 6 | **Test**: upload, download, case file sync |

### Phase 2F: Extract Hearings Service (Week 6)

| Step | Action |
|------|--------|
| 1 | Copy `hearings/` to `services/hearings/` |
| 2 | Migrate `hearings_hearing` table |
| 3 | Add lawsuit validation via REST call to cases-service |
| 4 | Publish `hearing.scheduled` events to Redis |
| 5 | Update Gateway routing |
| 6 | **Test**: create hearing, archive, calendar view |

### Phase 2G: Extract Search + AI Services (Week 7)

| Step | Action |
|------|--------|
| 1 | Copy `logs.SearchLog`, `logs.AIChatLog` → `services/search/` |
| 2 | Move `rag_engine/` → `services/ai/` (already containerized) |
| 3 | Move `ai_assistant/` views → `services/ai/` |
| 4 | Update Gateway routing for `/api/ai/*`, `/api/search-logs/`, `/api/ai-chat-logs/` |
| 5 | **Test**: AI chat, legal search, search logs |

### Phase 2H: Cases Service = Remaining Monolith (Week 8)

| Step | Action |
|------|--------|
| 1 | The monolith now only serves `lawsuits`, `parties`, `responses`, `appeals`, `judgments`, `payments`, `audit` |
| 2 | Rename it to `cases-service`, clean up settings, remove extracted apps |
| 3 | Switch DB to `db-cases` PostgreSQL |
| 4 | Publish events for `lawsuit.created`, `judgment.issued` |
| 5 | **Full integration test** |

---

## 7. Flutter Frontend Adaptation

### 7.1 Zero Breaking Changes

The API Gateway preserves all existing endpoint paths. `api_config.dart` requires **NO changes** for routing. The Flutter app talks to one gateway URL just like the monolith.

### 7.2 Recommended Future Improvements

| Improvement | Description | Priority |
|-------------|-------------|----------|
| **Split ApiService** | Break 1300-line `ApiService` into domain services: `AuthApiService`, `CasesApiService`, `HearingsApiService`, etc. | High |
| **Add retry with refresh** | When 401 received, auto-refresh token (2h expiry now vs 24h before) | High |
| **Add offline queue** | Queue mutations when offline, sync when back online | Medium |
| **WebSocket for notifications** | Real-time notifications via WebSocket through gateway | Medium |
| **Repository pattern** | Add repository layer between providers and API services | Low |

### 7.3 ApiService Split Example

```dart
// lib/services/auth_api_service.dart
class AuthApiService {
  Future<Map<String, dynamic>> login(String username, String password) { ... }
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) { ... }
  Future<Map<String, dynamic>> getProfile() { ... }
  Future<void> refreshToken() { ... }
}

// lib/services/cases_api_service.dart
class CasesApiService {
  Future<List<dynamic>> getLawsuits({Map<String, String>? params}) { ... }
  Future<Map<String, dynamic>> createLawsuit(Map<String, dynamic> data) { ... }
  Future<Map<String, dynamic>> archiveLawsuit(int id, String reason) { ... }
}

// lib/services/hearings_api_service.dart
class HearingsApiService { ... }

// lib/services/documents_api_service.dart
class DocumentsApiService { ... }
```

---

## 8. Security Architecture

### 8.1 JWT Flow (Microservices)

```
Flutter App
    │
    ├── POST /api/token/ ──────────────► Gateway ──► auth-service
    │   ◄── {access_token, refresh_token}
    │
    ├── GET /api/lawsuits/ ────────────► Gateway ──► cases-service
    │   (Bearer <access_token>)                      │
    │                                                 ├── Decode JWT locally
    │                                                 ├── Extract user_id + role
    │                                                 └── Filter queryset
    │
    ├── GET /api/hearings/ ────────────► Gateway ──► hearings-service
    │   (Bearer <access_token>)                      │
    │                                                 └── Same JWT decode
```

### 8.2 Internal Service Authentication

Service-to-service calls use a shared `INTERNAL_API_KEY` header:

```python
# In cases-service calling auth-service
headers = {
    'X-Internal-API-Key': os.environ['INTERNAL_API_KEY'],
    'Content-Type': 'application/json',
}
response = httpx.get(f"{AUTH_SERVICE_URL}/internal/users/{user_id}/", headers=headers)
```

### 8.3 Network Isolation

- `/api/*` endpoints: Exposed through Gateway → public
- `/internal/*` endpoints: Only accessible within `smartjudi-net` Docker network
- Databases: Not exposed outside Docker network
- Redis: Not exposed outside Docker network

---

## 9. Monitoring & Observability (Future)

| Tool | Purpose |
|------|---------|
| **Prometheus + Grafana** | Metrics per service (request rate, latency, error rate) |
| **ELK Stack** | Centralized logging across all services |
| **Health checks** | Each service exposes `GET /health/` returning `{"status": "ok"}` |
| **Redis monitoring** | Track event queue depth and processing lag |

---

## 10. Summary

| Metric | Value |
|--------|-------|
| **Total services** | 8 + Gateway + Redis |
| **Total databases** | 7 PostgreSQL + 1 ChromaDB |
| **Migration timeline** | ~8 weeks (1 service/week) |
| **Flutter changes needed** | None for Phase 2 (Gateway preserves all routes) |
| **Risk level** | Low — each service extracted independently with Gateway as safety net |
| **Rollback strategy** | Gateway can route back to monolith per-endpoint at any time |
