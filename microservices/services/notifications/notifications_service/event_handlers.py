"""
Redis event handlers for notifications-service.
Listens to events from other services and creates notifications.
"""
import logging
from smartjudi_common.events import EventListener
from smartjudi_common.service_client import ServiceClient
import os

logger = logging.getLogger(__name__)


def _get_auth_client():
    return ServiceClient(base_url=os.environ.get('AUTH_SERVICE_URL', 'http://auth:8000'))


def handle_lawsuit_event(event_type: str, payload: dict):
    """Handle events from the cases channel."""
    from notifications_app.models import Notification

    if event_type == 'lawsuit.created':
        client_id = payload.get('client_id')
        case_number = payload.get('case_number', '')
        if client_id:
            Notification.objects.create(
                recipient_id=client_id,
                notification_type=Notification.TYPE_LAWSUIT,
                title=f'دعوى جديدة: {case_number}',
                body=f'تم إنشاء دعوى جديدة برقم {case_number}',
                related_object_id=payload.get('lawsuit_id'),
                related_object_type='lawsuit',
            )
            logger.info('Created notification for lawsuit.created → user %s', client_id)

    elif event_type == 'judgment.issued':
        lawsuit_id = payload.get('lawsuit_id')
        # Notify both created_by and client
        for user_id in [payload.get('created_by_id'), payload.get('client_id')]:
            if user_id:
                Notification.objects.create(
                    recipient_id=user_id,
                    notification_type=Notification.TYPE_JUDGMENT,
                    title='صدور حكم',
                    body=f'صدر حكم جديد بشأن الدعوى',
                    related_object_id=lawsuit_id,
                    related_object_type='judgment',
                )


def handle_hearing_event(event_type: str, payload: dict):
    """Handle events from the hearings channel."""
    from notifications_app.models import Notification

    if event_type == 'hearing.scheduled':
        hearing_date = payload.get('hearing_date', '')
        lawsuit_id = payload.get('lawsuit_id')
        for user_id in [payload.get('created_by_id'), payload.get('client_id')]:
            if user_id:
                Notification.objects.create(
                    recipient_id=user_id,
                    notification_type=Notification.TYPE_HEARING,
                    title=f'موعد جلسة: {hearing_date}',
                    body='تم تحديد موعد جلسة جديدة',
                    related_object_id=lawsuit_id,
                    related_object_type='hearing',
                )


def start_event_listener():
    """Start listening to all relevant event channels."""
    listener = EventListener()
    listener.subscribe('lawsuits', handle_lawsuit_event)
    listener.subscribe('hearings', handle_hearing_event)
    listener.listen(daemon=True)
    logger.info('Notifications event listener started')
