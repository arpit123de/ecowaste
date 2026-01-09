"""
Management command to clean up completed waste reports after scheduled pickup time
Run this periodically (e.g., via cron job or task scheduler)
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from mainapp.models import PickupRequest, WasteReport, PickupHistory


class Command(BaseCommand):
    help = 'Delete waste reports after scheduled pickup time has passed and create history records'

    def add_arguments(self, parser):
        parser.add_argument(
            '--hours',
            type=int,
            default=2,
            help='Hours after pickup time to delete report (default: 2 hours)'
        )

    def handle(self, *args, **options):
        hours_buffer = options['hours']
        current_time = timezone.now()
        cutoff_time = current_time - timedelta(hours=hours_buffer)
        
        # Find scheduled pickup requests where pickup time has passed
        completed_requests = PickupRequest.objects.filter(
            status='scheduled',
            confirmed_pickup_time__lte=cutoff_time
        ).select_related('waste_report', 'buyer', 'user')
        
        deleted_count = 0
        history_count = 0
        
        for request in completed_requests:
            waste_report = request.waste_report
            
            # Create history record before deleting
            history = PickupHistory.objects.create(
                user=request.user,
                user_username=request.user.username,
                buyer_shop_name=request.buyer.shop_name,
                waste_type=waste_report.get_waste_type_display(),
                quantity=waste_report.quantity_display,
                location=waste_report.location or "Location not specified",
                offered_price=request.offered_price,
                reported_at=waste_report.created_at,
                scheduled_at=request.scheduled_at,
                completed_at=current_time,
                pickup_request=request
            )
            history_count += 1
            
            # Mark pickup as completed
            request.status = 'completed'
            request.completed_at = current_time
            request.save()
            
            # Delete the waste report
            report_id = waste_report.id
            report_user = waste_report.user.username
            waste_report.delete()
            
            deleted_count += 1
            self.stdout.write(
                self.style.SUCCESS(
                    f'✓ Archived & deleted waste report #{report_id} (user: {report_user}) - '
                    f'Pickup was at {request.confirmed_pickup_time}'
                )
            )
        
        if deleted_count > 0:
            self.stdout.write(
                self.style.SUCCESS(
                    f'\n📊 Summary:'
                    f'\n   - Created {history_count} history record(s)'
                    f'\n   - Deleted {deleted_count} waste report(s)'
                )
            )
        else:
            self.stdout.write(
                self.style.WARNING('No waste reports to process at this time')
            )
