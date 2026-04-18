import os
from fastapi import FastAPI, Request
from fastapi.responses import Response
import httpx

# Local (LAN) backend (initially the monolith; later it becomes local microservices)
LOCAL_BASE = os.environ.get('LOCAL_BASE', os.environ.get('MONOLITH_BASE', 'http://127.0.0.1:8000')).rstrip('/')

# Local (LAN) inheritance-service (fully offline computation)
INHERITANCE_LOCAL_BASE = os.environ.get('INHERITANCE_LOCAL_BASE', 'http://127.0.0.1:8001').rstrip('/')

# Cloud backends
LEGAL_CLOUD_BASE = os.environ.get('LEGAL_CLOUD_BASE', '').rstrip('/')
AI_CLOUD_BASE = os.environ.get('AI_CLOUD_BASE', '').rstrip('/')

# Dev option (set to 0 only if you use self-signed certs in staging)
CLOUD_SSL_VERIFY = os.environ.get('CLOUD_SSL_VERIFY', '1') != '0'

# Cloud-only endpoints (read-only knowledge + AI)
CLOUD_LEGAL_PREFIXES = (
    '/api/legal-categories/',
    '/api/laws/',
    '/api/law-chapters/',
    '/api/law-sections/',
    '/api/law-articles/',
    '/api/case-legal-references/',
    '/api/legal-library/',
    '/api/legal-procedures/',
)

CLOUD_AI_PREFIXES = (
    '/api/ai/',
)

LOCAL_INHERITANCE_PREFIXES = (
    '/api/inheritance/',
)

app = FastAPI()


@app.get('/health/')
def health():
    return {'status': 'ok', 'service': 'local-gateway'}


def _choose_upstream(path: str) -> str:
    for p in LOCAL_INHERITANCE_PREFIXES:
        if path.startswith(p) and INHERITANCE_LOCAL_BASE:
            return INHERITANCE_LOCAL_BASE
    for p in CLOUD_AI_PREFIXES:
        if path.startswith(p) and AI_CLOUD_BASE:
            return AI_CLOUD_BASE
    for p in CLOUD_LEGAL_PREFIXES:
        if path.startswith(p) and LEGAL_CLOUD_BASE:
            return LEGAL_CLOUD_BASE
    return LOCAL_BASE


@app.api_route('/{full_path:path}', methods=['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'HEAD'])
async def proxy(full_path: str, request: Request):
    path = '/' + full_path
    upstream = _choose_upstream(path)
    url = upstream + path

    # Preserve query string
    if request.url.query:
        url += '?' + request.url.query

    headers = dict(request.headers)
    headers.pop('host', None)

    body = await request.body()

    upstream_kwargs = {}
    if upstream in (LEGAL_CLOUD_BASE, AI_CLOUD_BASE):
        upstream_kwargs['verify'] = CLOUD_SSL_VERIFY

    async with httpx.AsyncClient(follow_redirects=False, timeout=60.0, **upstream_kwargs) as client:
        upstream_resp = await client.request(
            request.method,
            url,
            content=body,
            headers=headers,
        )

    # Pass-through response
    excluded = {'content-encoding', 'transfer-encoding', 'connection'}
    resp_headers = {k: v for k, v in upstream_resp.headers.items() if k.lower() not in excluded}

    return Response(
        content=upstream_resp.content,
        status_code=upstream_resp.status_code,
        headers=resp_headers,
        media_type=upstream_resp.headers.get('content-type'),
    )
