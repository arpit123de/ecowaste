from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import api_views

# Create router for viewsets
router = DefaultRouter()
router.register(r'tasks', api_views.TaskViewSet, basename='task')
router.register(r'notes', api_views.NoteViewSet, basename='note')
router.register(r'waste-reports', api_views.WasteReportViewSet, basename='wastereport')
router.register(r'buyers', api_views.BuyerViewSet, basename='buyer')
router.register(r'pickup-requests', api_views.PickupRequestViewSet, basename='pickuprequest')
router.register(r'ratings', api_views.BuyerRatingViewSet, basename='rating')
router.register(r'pickup-history', api_views.PickupHistoryViewSet, basename='pickuphistory')
router.register(r'notifications', api_views.NotificationViewSet, basename='notification')

# API URL patterns
urlpatterns = [
    # Authentication endpoints
    path('auth/register/', api_views.register_user, name='api-register'),
    path('auth/login/', api_views.login_user, name='api-login'),
    path('auth/logout/', api_views.logout_user, name='api-logout'),
    path('auth/profile/', api_views.user_profile, name='api-profile'),
    
    # Include router URLs
    path('', include(router.urls)),
]
