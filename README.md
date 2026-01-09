# Hackathon Project - Waste Management System

A Django web application with comprehensive waste reporting system and REST API support for Flutter mobile integration.

## ✅ Current Status

**Phase 1 - Django Web Application: COMPLETED**
- ✓ Django project setup
- ✓ **Waste Reporting System** (MAIN FEATURE)
  - Photo upload with camera support
  - Comprehensive waste details form
  - GPS location tracking
  - Multiple waste categories
  - Quantity and condition tracking
  - Status management (Pending/Assigned/Collected)
- ✓ Task and Note management models
- ✓ Web interface with Bootstrap
- ✓ User authentication
- ✓ Admin panel with full waste report management

**Phase 2 - Flutter Mobile App: READY TO START**
- REST API endpoints (configured, needs implementation)
- Flutter project creation
- API integration

## 🚀 Quick Start

### Django Backend & Web

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Run migrations:**
```bash
python manage.py migrate
```

3. **Create a superuser:**
```bash
python manage.py createsuperuser
```
Follow the prompts to create an admin account.

4. **Run development server:**
```bash
python manage.py runserver
```

5. **Access the application:**
- 🌐 Web Interface: http://127.0.0.1:8000/
- 🔧 Admin Panel: http://127.0.0.1:8000/admin/
- 📝 Login to create waste reports

## 📱 Main Features

### 🗑️ Waste Reporting System (Core Feature)

**Report Waste Form includes:**
1. **User Information**
   - Name (auto-filled from user profile)
   - Mobile Number
   - Email (auto-filled)

2. **Waste Details**
   - Waste Type: Plastic, Paper, Organic, Metal, Glass, E-Waste, Medical, Construction, Other
   - Quantity: Small/Medium/Large or exact weight in kg
   - Condition: Dry, Wet, Mixed, Hazardous

3. **Photo Upload**
   - Camera capture support
   - Gallery upload option
   - Image validation (JPG/PNG, max 5MB)
   - Live image preview

4. **Location Tracking**
   - GPS auto-detection
   - Manual location entry (Area, City, Landmark)
   - Google Maps integration

5. **Additional Notes**
   - Text description field

6. **Status Tracking**
   - Pending (new report)
   - Assigned (in progress)
   - Collected (completed)

### Other Features
- **Task Management**: Create, read, update, and delete tasks
- **Note Taking**: Keep organized notes
- **User Authentication**: Secure login/logout
- **Responsive Design**: Works on desktop and mobile browsers

## 📁 Project Structure

```
hackathon/
├── manage.py              # Django management script
├── requirements.txt       # Python dependencies
├── db.sqlite3            # SQLite database
├── media/                # User uploaded images
│   └── waste_reports/    # Waste report photos
├── myproject/            # Django project settings
│   ├── settings.py       # Configuration (includes MEDIA settings)
│   └── urls.py          # URL routing (includes media serving)
└── mainapp/             # Main application
    ├── models.py        # Models: Task, Note, WasteReport
    ├── views.py         # Views for all features
    ├── urls.py          # App URLs
    ├── forms.py         # Forms: TaskForm, NoteForm, WasteReportForm
    ├── admin.py         # Admin configuration
    ├── templates/       # HTML templates
    │   └── mainapp/
    │       ├── base.html
    │       ├── home.html
    │       ├── login.html
    │       ├── waste_report_form.html
    │       ├── waste_report_list.html
    │       ├── waste_report_detail.html
    │       └── ...
    └── migrations/      # Database migrations
```

## 🎯 Waste Report Database Schema

```sql
WasteReport:
- id (Primary Key)
- user (Foreign Key to User)
- name, mobile_number, email
- waste_type (choices: plastic, paper, organic, metal, glass, e_waste, medical, construction, other)
- waste_type_other (text if "other" selected)
- quantity_type (small/medium/large)
- exact_quantity (decimal, optional)
- waste_condition (dry/wet/mixed/hazardous)
- image (ImageField - stored in media/waste_reports/)
- location_auto (boolean)
- latitude, longitude (GPS coordinates)
- area, city, landmark (manual location)
- additional_notes (text)
- status (pending/assigned/collected)
- created_at, updated_at (timestamps)
```

## 🔧 Usage

### Reporting Waste

1. Login to your account
2. Click "Report Waste" button or navigate to `/waste-report/`
3. Fill in the waste details form:
   - Select waste type
   - Choose quantity
   - Upload/capture photo
   - Enable GPS or enter location manually
   - Add any additional notes
4. Submit the report
5. View your reports at `/waste-reports/`
6. Track status changes in the admin panel

### Admin Management

Access the admin panel at `/admin/` to:
- View all waste reports
- Update report status (Pending → Assigned → Collected)
- Filter by waste type, status, condition
- Search by location, user, or notes
- View detailed report information

## 🔧 Next Steps for Phase 2

To add Flutter mobile app support:
1. Create REST API serializers for WasteReport
2. Add API viewsets with Django REST Framework
3. Add API endpoints in urls.py
4. Create Flutter project
5. Implement camera functionality in Flutter
6. Implement API calls in Flutter
7. Build and test mobile app

## 📸 Key Features for Mobile

- Native camera access
- Real-time GPS tracking
- Offline form storage
- Image compression before upload
- Push notifications for status updates

Let me know when you're ready to proceed with the Flutter integration! 🚀📱
