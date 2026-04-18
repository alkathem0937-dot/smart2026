"""
HTTP client for inter-service communication.

Usage:
    from smartjudi_common.service_client import ServiceClient

    auth_client = ServiceClient(base_url=os.environ['AUTH_SERVICE_URL'])
    user = auth_client.get(f'/internal/users/{user_id}/')
"""
import os
import logging
import httpx
from functools import lru_cache

logger = logging.getLogger(__name__)

DEFAULT_TIMEOUT = 10.0


class ServiceClient:
    """Synchronous HTTP client for internal service-to-service calls."""

    def __init__(self, base_url: str, timeout: float = DEFAULT_TIMEOUT):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self._api_key = os.environ.get('INTERNAL_API_KEY', '')

    def _headers(self) -> dict:
        return {
            'X-Internal-API-Key': self._api_key,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

    def get(self, path: str, params: dict = None) -> dict | None:
        url = f'{self.base_url}{path}'
        try:
            resp = httpx.get(url, headers=self._headers(), params=params, timeout=self.timeout)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            logger.warning('Service call failed: %s %s → %s', 'GET', url, e.response.status_code)
            return None
        except httpx.RequestError as e:
            logger.error('Service unreachable: %s %s → %s', 'GET', url, str(e))
            return None

    def post(self, path: str, data: dict = None) -> dict | None:
        url = f'{self.base_url}{path}'
        try:
            resp = httpx.post(url, headers=self._headers(), json=data, timeout=self.timeout)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            logger.warning('Service call failed: %s %s → %s', 'POST', url, e.response.status_code)
            return None
        except httpx.RequestError as e:
            logger.error('Service unreachable: %s %s → %s', 'POST', url, str(e))
            return None


class AsyncServiceClient:
    """Async HTTP client for internal service-to-service calls."""

    def __init__(self, base_url: str, timeout: float = DEFAULT_TIMEOUT):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self._api_key = os.environ.get('INTERNAL_API_KEY', '')

    def _headers(self) -> dict:
        return {
            'X-Internal-API-Key': self._api_key,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

    async def get(self, path: str, params: dict = None) -> dict | None:
        url = f'{self.base_url}{path}'
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                resp = await client.get(url, headers=self._headers(), params=params)
                resp.raise_for_status()
                return resp.json()
        except (httpx.HTTPStatusError, httpx.RequestError) as e:
            logger.error('Async service call failed: GET %s → %s', url, str(e))
            return None

    async def post(self, path: str, data: dict = None) -> dict | None:
        url = f'{self.base_url}{path}'
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                resp = await client.post(url, headers=self._headers(), json=data)
                resp.raise_for_status()
                return resp.json()
        except (httpx.HTTPStatusError, httpx.RequestError) as e:
            logger.error('Async service call failed: POST %s → %s', url, str(e))
            return None
