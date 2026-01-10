from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    
    # Task URLs
    path('tasks/', views.task_list, name='task_list'),
    path('tasks/create/', views.task_create, name='task_create'),
    path('tasks/<int:pk>/update/', views.task_update, name='task_update'),
    path('tasks/<int:pk>/delete/', views.task_delete, name='task_delete'),
    
    # Note URLs
    path('notes/', views.note_list, name='note_list'),
    path('notes/create/', views.note_create, name='note_create'),
    path('notes/<int:pk>/update/', views.note_update, name='note_update'),
    path('notes/<int:pk>/delete/', views.note_delete, name='note_delete'),
    
    # Waste Report URLs
    path('waste-report/', views.waste_report_create, name='waste_report_create'),
    path('waste-reports/', views.waste_report_list, name='waste_report_list'),
    path('waste-reports/<int:pk>/', views.waste_report_detail, name='waste_report_detail'),
    path('waste-reports/<int:pk>/delete/', views.waste_report_delete, name='waste_report_delete'),
    
    # AI Classification API
    path('api/classify-waste/', views.classify_waste_api, name='classify_waste_api'),
    
    # Authentication URLs
    path('signup-choice/', views.signup_choice, name='signup_choice'),
    path('signup/', views.signup, name='signup'),
    path('buyer-signup/', views.buyer_signup, name='buyer_signup'),
    path('login/', views.user_login, name='login'),
   
    
    # Buyer URLs
    path('buyer/dashboard/', views.buyer_dashboard, name='buyer_dashboard'),
    path('buyer/profile/', views.buyer_profile, name='buyer_profile'),
    path('buyer/requests/', views.buyer_requests, name='buyer_requests'),
    path('buyer/my-pickups/', views.buyer_my_pickups, name='buyer_my_pickups'),
    path('buyer/waste/<int:pk>/', views.waste_detail_for_buyer, name='waste_detail_for_buyer'),
    path('buyer/send-request/<int:pk>/', views.send_pickup_request, name='send_pickup_request'),
    
    # User Notification URLs
    path('notifications/', views.user_notifications, name='user_notifications'),
    path('notifications/respond/<int:pk>/', views.respond_to_pickup_request, name='respond_to_pickup_request'),
    
    # Browse buyers (for users)
    path('buyers/', views.browse_buyers, name='browse_buyers'),
    path('buyer/<int:pk>/', views.buyer_profile_public, name='buyer_profile_public'),
    path('buyer/<int:pk>/rate/', views.rate_buyer, name='rate_buyer'),
    
    # Pickup History
    path('history/', views.pickup_history, name='pickup_history') ]