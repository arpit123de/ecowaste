# Testing Checklist for Signup Feature

## ✅ Setup Status

### Backend (Django)
- ✅ Server running at: http://127.0.0.1:8000
- ✅ API endpoint: http://127.0.0.1:8000/api/auth/register/
- ✅ Multipart form-data support: YES
- ✅ Buyer model with encryption: YES
- ✅ Transaction handling: YES

### Frontend (Flutter)
- ✅ App running in Chrome
- ✅ Dev tools: http://127.0.0.1:9101
- ✅ API service with multipart: YES
- ✅ Auth provider updated: YES
- ✅ Register screen complete: YES

---

## Test Cases

### Test Case 1: User Registration (Simple)

**Steps**:
1. ☐ Open app in Chrome
2. ☐ Navigate to Signup screen
3. ☐ Ensure "User" role is selected
4. ☐ Fill in form:
   ```
   First Name: Test
   Last Name: User
   Username: testuser1
   Email: test@example.com
   Password: Test1234
   Confirm Password: Test1234
   ```
5. ☐ Check password strength shows "Strong" (green)
6. ☐ Click "Create Account"

**Expected Results**:
- ☐ Loading spinner appears
- ☐ Success message: "Welcome Test!"
- ☐ Auto-redirect to home screen
- ☐ No error messages

**Database Verification**:
```sql
-- Check user created
SELECT * FROM auth_user WHERE username='testuser1';

-- Expected: 1 row with email, name, hashed password
```

---

### Test Case 2: Buyer Registration (With Files)

**Steps**:
1. ☐ Navigate to Signup screen
2. ☐ Click "Buyer" role toggle
3. ☐ Fill in common fields:
   ```
   First Name: Green
   Last Name: Recycler
   Username: greenrecycler
   Email: green@recycler.com
   Password: Secure1234
   Confirm Password: Secure1234
   ```
4. ☐ Fill in buyer-specific fields:
   ```
   Mobile: 9876543210
   Shop Name: Green Waste Solutions
   Shop Address: 123 Eco Street, Green City, State
   Aadhaar: 123456789012
   ```
5. ☐ Select waste types:
   - ☐ Click "Plastic" chip (turns green)
   - ☐ Click "Metal" chip (turns green)
   - ☐ Click "Paper & Cardboard" chip (turns green)
6. ☐ Upload shop photo:
   - ☐ Click "Upload Shop Photo"
   - ☐ Select an image file
   - ☐ Verify file name appears
7. ☐ Upload trade license (optional):
   - ☐ Click "Upload Trade License"
   - ☐ Select a file
   - ☐ Verify file name appears
8. ☐ Click "Create Account"

**Expected Results**:
- ☐ Loading spinner appears
- ☐ Success message: "Welcome Green!"
- ☐ Auto-redirect to home screen
- ☐ No error messages

**Database Verification**:
```sql
-- Check user created
SELECT * FROM auth_user WHERE username='greenrecycler';

-- Check buyer profile created
SELECT 
    b.id,
    b.shop_name,
    b.mobile_number,
    b.shop_address,
    b.aadhaar_last_4,
    b.waste_categories_handled,
    b.shop_photo,
    b.trade_license,
    b.is_verified
FROM mainapp_buyer b
JOIN auth_user u ON b.user_id = u.id
WHERE u.username = 'greenrecycler';

-- Expected:
-- - shop_name: Green Waste Solutions
-- - mobile_number: 9876543210
-- - aadhaar_last_4: 9012 (last 4 of 123456789012)
-- - waste_categories_handled: ["Plastic", "Metal", "Paper & Cardboard"]
-- - shop_photo: buyer_shops/filename.jpg
-- - trade_license: buyer_licenses/filename.pdf
-- - is_verified: 0 (false)

-- Check Aadhaar is encrypted (NOT plain text)
SELECT aadhaar_number FROM mainapp_buyer WHERE user_id = 
  (SELECT id FROM auth_user WHERE username='greenrecycler');
-- Expected: Long encrypted string, NOT "123456789012"
```

**File System Verification**:
```bash
# Check shop photo uploaded
ls media/buyer_shops/
# Should show the uploaded image file

# Check trade license uploaded
ls media/buyer_licenses/
# Should show the uploaded file
```

---

### Test Case 3: Validation Tests

#### 3.1: Empty Fields
**Steps**:
1. ☐ Click "Create Account" with empty form
2. ☐ Verify error messages appear for required fields

#### 3.2: Password Mismatch
**Steps**:
1. ☐ Enter Password: "Test1234"
2. ☐ Enter Confirm Password: "Test5678"
3. ☐ Click "Create Account"
4. ☐ Verify error: "Passwords don't match"

#### 3.3: Invalid Email
**Steps**:
1. ☐ Enter Email: "notanemail"
2. ☐ Move to next field
3. ☐ Verify error: "Please enter a valid email"

#### 3.4: Weak Password
**Steps**:
1. ☐ Enter Password: "weak"
2. ☐ Verify strength indicator shows RED "Weak"

#### 3.5: Buyer Without Required Fields
**Steps**:
1. ☐ Select "Buyer" role
2. ☐ Fill only common fields
3. ☐ Leave mobile/shop name empty
4. ☐ Click "Create Account"
5. ☐ Verify error: "Mobile number is required for buyers"

#### 3.6: Invalid Aadhaar
**Steps**:
1. ☐ Enter Aadhaar: "12345" (less than 12 digits)
2. ☐ Click "Create Account"
3. ☐ Verify error: "Aadhaar must be exactly 12 digits"

#### 3.7: No Waste Type Selected
**Steps**:
1. ☐ Fill all buyer fields except waste types
2. ☐ Click "Create Account"
3. ☐ Verify error: "Select at least one waste type"

---

### Test Case 4: UI/UX Verification

**Visual Checks**:
- ☐ Dark gradient background (dark blue → green gradient)
- ☐ Glassmorphic card with blur effect
- ☐ Green accents on focused inputs
- ☐ Password strength bar animates smoothly
- ☐ Role toggle highlights selected option in green
- ☐ Waste type chips toggle green when selected
- ☐ Upload buttons show file names after selection
- ☐ Loading spinner appears during registration
- ☐ Form is scrollable on small screens
- ☐ Text is readable (white on dark background)

**Animation Checks**:
- ☐ Screen fades in on load
- ☐ Form animates smoothly
- ☐ Password strength bar animates

---

### Test Case 5: Error Handling

#### 5.1: Duplicate Username
**Steps**:
1. ☐ Register user with username "testuser1"
2. ☐ Try registering again with same username
3. ☐ Verify error message appears

#### 5.2: Duplicate Email
**Steps**:
1. ☐ Register user with email "test@example.com"
2. ☐ Try registering again with same email
3. ☐ Verify error message appears

#### 5.3: Backend Offline
**Steps**:
1. ☐ Stop Django server
2. ☐ Try to register
3. ☐ Verify error message appears

---

## Post-Registration Verification

### After Successful Registration:

**App State**:
- ☐ User is logged in (token stored)
- ☐ Home screen loaded
- ☐ Welcome message displayed
- ☐ User can see their name/username

**Storage Check** (Browser DevTools → Application → Storage):
- ☐ Token stored in secure storage
- ☐ User ID stored
- ☐ Username stored

**Backend Logs** (Django terminal):
- ☐ POST request logged: `POST /api/auth/register/ 201`
- ☐ No error messages
- ☐ File upload logged (if files uploaded)

---

## API Testing (Postman/cURL)

### User Registration:
```bash
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "apitest",
    "email": "api@test.com",
    "password": "Test1234",
    "password2": "Test1234",
    "first_name": "API",
    "last_name": "Test",
    "role": "user"
  }'
```

**Expected Response**:
```json
{
  "token": "abc123...",
  "user": {
    "id": 1,
    "username": "apitest",
    "email": "api@test.com",
    "first_name": "API",
    "last_name": "Test"
  },
  "role": "user",
  "message": "User registered successfully"
}
```

### Buyer Registration:
```bash
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -F "username=buyertest" \
  -F "email=buyer@test.com" \
  -F "password=Test1234" \
  -F "password2=Test1234" \
  -F "first_name=Buyer" \
  -F "last_name=Test" \
  -F "role=buyer" \
  -F "mobile=9876543210" \
  -F "shop_name=Test Shop" \
  -F "shop_address=123 Test St" \
  -F "aadhaar=123456789012" \
  -F 'waste_types=["Plastic","Metal"]' \
  -F "shop_photo=@/path/to/image.jpg" \
  -F "trade_license=@/path/to/license.pdf"
```

**Expected Response**:
```json
{
  "token": "xyz789...",
  "user": {
    "id": 2,
    "username": "buyertest",
    "email": "buyer@test.com",
    "first_name": "Buyer",
    "last_name": "Test"
  },
  "role": "buyer",
  "message": "Buyer registered successfully"
}
```

---

## Troubleshooting Guide

### Issue: "Connection refused"
- **Check**: Is Django server running?
- **Solution**: Run `python manage.py runserver`

### Issue: "404 Not Found"
- **Check**: Is API URL correct?
- **Solution**: Verify `baseUrl` in `api_service.dart` is `http://127.0.0.1:8000/api` (for Chrome)

### Issue: "500 Internal Server Error"
- **Check**: Django error logs in terminal
- **Common causes**:
  - Encryption key not set
  - Database connection issue
  - Migration not applied

### Issue: Files not uploading
- **Check**: Is `MEDIA_ROOT` configured in `settings.py`?
- **Check**: Does directory `media/buyer_shops/` exist?
- **Solution**: Create directories or check permissions

### Issue: "Aadhaar must be exactly 12 digits"
- **Check**: Input is numeric only
- **Check**: No spaces or special characters
- **Solution**: Use numeric keyboard on mobile

### Issue: Token not saved
- **Check**: Is `flutter_secure_storage` working?
- **Check**: Browser storage permissions
- **Solution**: Check browser console for errors

---

## Success Metrics

### Registration Flow:
- ☐ User registration < 5 seconds
- ☐ Buyer registration < 10 seconds (with files)
- ☐ 100% of required fields validated
- ☐ Auto-login works 100% of time
- ☐ Files upload successfully 100% of time

### Data Integrity:
- ☐ All user fields stored correctly
- ☐ All buyer fields stored correctly
- ☐ Aadhaar encrypted (never plain text)
- ☐ Files stored in correct directories
- ☐ Tokens generated uniquely

### UX Quality:
- ☐ Form is intuitive
- ☐ Validation messages are clear
- ☐ Loading states are visible
- ☐ Success feedback is immediate
- ☐ Errors are helpful

---

## Status: Ready for Testing ✅

**Backend**: Running on http://127.0.0.1:8000
**Frontend**: Running in Chrome
**Database**: MySQL (eco_db)
**All Files**: Implemented and error-free

**Next Action**: Start testing with Test Case 1!
