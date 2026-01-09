# Scheduling & Auto-Cleanup Setup

## Pickup Scheduling Feature

The system now supports scheduled pickups with the following workflow:

1. **Buyer sends request** with:
   - Offered price
   - Message
   - Up to 3 proposed pickup time slots

2. **User receives notification** and can:
   - View all proposed time slots
   - Select preferred time
   - Confirm schedule with optional message
   - OR reject the request

3. **After confirmation**:
   - Status changes to "Scheduled"
   - Confirmed pickup time is saved
   - Waste report status becomes "Assigned"

4. **Auto-cleanup after pickup**:
   - Waste reports are automatically deleted after scheduled pickup time passes
   - Pickup request status is marked as "Completed"

## Running Auto-Cleanup

### Manual Cleanup
Run this command anytime to clean up completed pickups:

```bash
python manage.py cleanup_completed_pickups
```

By default, it deletes reports 2 hours after scheduled pickup time. To change the buffer:

```bash
python manage.py cleanup_completed_pickups --hours 1
```

### Automated Cleanup (Windows Task Scheduler)

1. Open **Task Scheduler** (search in Start menu)
2. Click **Create Basic Task**
3. Name: "Waste Report Cleanup"
4. Trigger: Daily (or hourly if needed)
5. Action: Start a program
6. Program: `C:\Users\Hp\Desktop\hackathon\.venv\Scripts\python.exe`
7. Arguments: `manage.py cleanup_completed_pickups`
8. Start in: `C:\Users\Hp\Desktop\hackathon`

### Automated Cleanup (Linux/Mac - Cron Job)

Add to crontab (`crontab -e`):

```bash
# Run every hour
0 * * * * cd /path/to/hackathon && /path/to/.venv/bin/python manage.py cleanup_completed_pickups

# Or run every 30 minutes
*/30 * * * * cd /path/to/hackathon && /path/to/.venv/bin/python manage.py cleanup_completed_pickups
```

## Status Flow

- **Pending** → User hasn't responded yet
- **Accepted** → User accepted without scheduling (legacy)
- **Scheduled** → User confirmed a specific pickup time
- **Rejected** → User rejected the request
- **Completed** → Pickup time passed, report auto-deleted
- **Cancelled** → Buyer cancelled the request

## Notes

- Only reports with status "Scheduled" are auto-deleted after pickup time
- Pickup requests remain in database even after waste report is deleted (for history/ratings)
- The cleanup command is safe to run multiple times
- Adjust `--hours` parameter based on your pickup completion time needs
