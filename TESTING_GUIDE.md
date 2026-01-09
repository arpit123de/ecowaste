# Waste Reporting System - Testing Guide

## ✅ What's Been Built

Your waste reporting system is now **fully functional**! Here's what you can do:

## 🚀 How to Test

### 1. Start the Server (if not running)
```bash
python manage.py runserver
```

### 2. Create a User Account
```bash
python manage.py createsuperuser
```
- Username: admin
- Email: admin@example.com
- Password: admin (or your choice)

### 3. Access the Application
- Open browser: http://127.0.0.1:8000/
- Login with your credentials

### 4. Test Waste Reporting

**Steps:**
1. Click "Report Waste Now" button on home page
2. Fill in the form:
   - **User Info**: Name and mobile (optional, auto-filled)
   - **Waste Type**: Select from dropdown (e.g., Plastic)
   - **Quantity**: Choose Small/Medium/Large or enter exact kg
   - **Condition**: Select Dry/Wet/Mixed/Hazardous
   - **Photo**: Click "Choose File" and select an image
   - **Location**: 
     - Check "Use my current location" for GPS (browser will ask permission)
     - OR enter Area, City, Landmark manually
   - **Notes**: Add any additional description
3. Click "Submit Report"

### 5. View Your Reports
- Click "My Reports" in navbar
- See all your waste reports with images
- Click "View Details" to see full report
- Click "Delete" to remove a report

### 6. Admin Panel Features
- Go to: http://127.0.0.1:8000/admin/
- Login with superuser credentials
- Navigate to "Waste Reports"
- Features:
  - View all reports from all users
  - Filter by: waste type, status, condition, date
  - Search by: user, location, notes
  - Update status: Pending → Assigned → Collected
  - View uploaded images
  - See GPS coordinates with "View on Google Maps" link

## 📱 Mobile Testing

### Test on Phone:
1. Find your computer's local IP (e.g., 192.168.1.100)
2. Run: `python manage.py runserver 0.0.0.0:8000`
3. Update `ALLOWED_HOSTS` in settings.py:
   ```python
   ALLOWED_HOSTS = ['*']  # For testing only
   ```
4. Access from phone: http://192.168.1.100:8000/
5. Test camera capture directly from phone browser

## 🎯 Key Features to Test

### ✓ Form Validation
- Try submitting without image (should fail)
- Try uploading large image >5MB (should fail)
- Select "Other" waste type without specifying (should fail)

### ✓ GPS Location
- Enable GPS and check if coordinates are captured
- Verify "View on Google Maps" link works in detail view

### ✓ Image Upload
- Test camera capture on mobile
- Test gallery upload
- Check image preview before submit
- Verify images are saved in `media/waste_reports/`

### ✓ Status Management
- In admin, change status from Pending to Assigned
- Change to Collected
- Verify status badge colors in list view

## 🗃️ Database Location

All data is stored in: `hackathon/db.sqlite3`

Images are stored in: `hackathon/media/waste_reports/`

## 🔍 Troubleshooting

### Image not displaying?
- Check if `media/` folder exists
- Verify `MEDIA_URL` and `MEDIA_ROOT` in settings.py
- Ensure `DEBUG = True` for development

### Can't upload from phone?
- Check if server is accessible from phone's browser
- Verify ALLOWED_HOSTS includes your IP
- Ensure phone and computer are on same network

### GPS not working?
- Browser needs HTTPS for GPS (or localhost)
- Grant location permission when prompted
- Use manual location entry as fallback

## 📊 Sample Test Data

Create diverse waste reports to test:
1. Plastic bottle - Small - Dry - with GPS
2. Paper waste - Medium - Mixed - manual location  
3. E-waste - Large - Hazardous - with detailed notes
4. Organic waste - 5kg exact - Wet - with photo

## ✅ Success Criteria

Your system is working if you can:
- [ ] Login successfully
- [ ] Fill and submit waste report form
- [ ] Upload/capture image
- [ ] See reports in list view
- [ ] View detailed report with image
- [ ] Update status in admin panel
- [ ] Delete reports
- [ ] GPS location capture works (optional)

## 🎉 Next Steps

Once basic testing is complete:
1. Add REST API for Flutter mobile app
2. Create API authentication
3. Build Flutter project
4. Implement AI classification (Gemini API)
5. Add waste valuation system
6. Build buyer marketplace

Your waste reporting MVP is ready! 🚀
