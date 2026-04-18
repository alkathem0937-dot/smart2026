"""
Redis Pub/Sub event system for inter-service communication.

Usage:
    from smartjudi_common.events import EventPublisher, EventListener

    # Publishing (in cases-service)
    publisher = EventPublisher()
    publisher.publish('lawsuits', 'lawsuit.created', {'lawsuit_id': 1, 'created_by_id': 5})

    # Listening (in notifications-service)
    listener = EventListener()
    listener.subscribe('lawsuits', handler_func)
    listener.listen()  # blocking
"""
import os
import json
import logging
import threading
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

CHANNEL_PREFIX = 'smartjudi:events'


def _get_redis():
    """Lazy import and create Redis connection."""
    import redis
    url = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
    return redis.from_url(url, decode_responses=True)


class EventPublisher:
    """Publish events to Redis Pub/Sub channels."""

    def __init__(self):
        self._redis = None

    @property
    def redis(self):
        if self._redis is None:
            self._redis = _get_redis()
        return self._redis

    def publish(self, channel: str, event_type: str, payload: dict) -> int:
        """
        Publish an event.

        Args:
            channel: Topic name (e.g. 'lawsuits', 'hearings', 'judgments')
            event_type: Event name (e.g. 'lawsuit.created', 'hearing.scheduled')
            payload: Event data dict

        Returns:
            Number of subscribers that received the message.
        """
        full_channel = f'{CHANNEL_PREFIX}:{channel}'
        message = {
            'event_type': event_type,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'source_service': os.environ.get('SERVICE_NAME', 'unknown'),
            'payload': payload,
        }
        try:
            count = self.redis.publish(full_channel, json.dumps(message, ensure_ascii=False))
            logger.info('Published %s to %s (%d subscribers)', event_type, full_channel, count)
            return count
        except Exception as e:
            logger.error('Failed to publish %s: %s', event_type, str(e))
            return 0


class EventListener:
    """Subscribe to Redis Pub/Sub channels and dispatch to handlers."""

    def __init__(self):
        self._redis = _get_redis()
        self._pubsub = self._redis.pubsub()
        self._handlers: dict[str, list] = {}

    def subscribe(self, channel: str, handler):
        """
        Register a handler for a channel.

        Args:
            channel: Topic name (e.g. 'lawsuits')
            handler: Callable that receives (event_type: str, payload: dict)
        """
        full_channel = f'{CHANNEL_PREFIX}:{channel}'
        if full_channel not in self._handlers:
            self._handlers[full_channel] = []
        self._handlers[full_channel].append(handler)
        self._pubsub.subscribe(full_channel)
        logger.info('Subscribed to %s', full_channel)

    def listen(self, daemon=True):
        """
        Start listening for events. If daemon=True, runs in a background thread.
        """
        if daemon:
            t = threading.Thread(target=self._listen_loop, daemon=True)
            t.start()
            logger.info('Event listener started in background thread')
        else:
            self._listen_loop()

    def _listen_loop(self):
        for raw_message in self._pubsub.listen():
            if raw_message['type'] != 'message':
                continue
            channel = raw_message['channel']
            try:
                data = json.loads(raw_message['data'])
                event_type = data.get('event_type', '')
                payload = data.get('payload', {})
            except (json.JSONDecodeError, AttributeError):
                logger.warning('Invalid event data on %s', channel)
                continue

            handlers = self._handlers.get(channel, [])
            for handler in handlers:
                try:
                    handler(event_type, payload)
                except Exception as e:
                    logger.error('Handler error on %s/%s: %s', channel, event_type, str(e))
