from django.contrib import admin
from .models import Task, Note, WasteReport, Notification

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'status', 'created_by', 'created_at', 'due_date']
    list_filter = ['status', 'created_at']
    search_fields = ['title', 'description']
    date_hierarchy = 'created_at'

@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ['title', 'author', 'created_at']
    list_filter = ['created_at']
    search_fields = ['title', 'content']
    date_hierarchy = 'created_at'

@admin.register(WasteReport)
class WasteReportAdmin(admin.ModelAdmin):
    list_display = ['user', 'waste_type', 'quantity_type', 'status', 'created_at', 'city']
    list_filter = ['waste_type', 'status', 'waste_condition', 'created_at']
    search_fields = ['user__username', 'waste_type', 'area', 'city', 'additional_notes']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'name', 'mobile_number', 'email')
        }),
        ('Waste Details', {
            'fields': ('waste_type', 'waste_type_other', 'quantity_type', 'exact_quantity', 'waste_condition', 'image')
        }),
        ('Location', {
            'fields': ('location_auto', 'latitude', 'longitude', 'area', 'city', 'landmark')
        }),
        ('Additional Information', {
            'fields': ('additional_notes', 'status', 'created_at', 'updated_at')
        }),
    )


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'notification_type', 'title', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']
    search_fields = ['user__username', 'title', 'message']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at']
