from django.db import models
from django.contrib.auth.models import User
from django.core.validators import RegexValidator

class Task(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tasks')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    due_date = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title


class Note(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notes')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title


class WasteReport(models.Model):
    WASTE_TYPE_CHOICES = [
        ('plastic', '♻️ Plastic'),
        ('paper', '📦 Paper'),
        ('organic', '🍌 Organic / Wet Waste'),
        ('metal', '🔩 Metal'),
        ('glass', '🧴 Glass'),
        ('e_waste', '💻 E-Waste'),
        ('medical', '🏥 Medical Waste'),
        ('construction', '🧱 Construction Waste'),
        ('other', '❓ Other'),
    ]
    
    QUANTITY_TYPE_CHOICES = [
        ('small', 'Small (1–2 kg)'),
        ('medium', 'Medium (3–10 kg)'),
        ('large', 'Large (10+ kg)'),
    ]
    
    CONDITION_CHOICES = [
        ('dry', 'Dry'),
        ('wet', 'Wet'),
        ('mixed', 'Mixed'),
        ('hazardous', 'Hazardous'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    # User Information
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='waste_reports')
    name = models.CharField(max_length=200, blank=True)
    mobile_number = models.CharField(max_length=15, blank=True)
    email = models.EmailField(blank=True)
    
    # Waste Details
    waste_type = models.CharField(max_length=20, choices=WASTE_TYPE_CHOICES)
    waste_type_other = models.CharField(max_length=100, blank=True, help_text="Specify if 'Other' is selected")
    quantity_type = models.CharField(max_length=10, choices=QUANTITY_TYPE_CHOICES)
    exact_quantity = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Exact quantity in kg")
    waste_condition = models.CharField(max_length=20, choices=CONDITION_CHOICES, blank=True)
    
    # Photo
    image = models.ImageField(upload_to='waste_reports/', help_text="Upload waste photo")
    
    # Location
    location_auto = models.BooleanField(default=False)
    latitude = models.DecimalField(max_digits=8, decimal_places=5, null=True, blank=True)
    longitude = models.DecimalField(max_digits=8, decimal_places=5, null=True, blank=True)
    area = models.CharField(max_length=200, blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    landmark = models.CharField(max_length=200, blank=True)
    full_address = models.TextField(blank=True, help_text="Complete pickup address with house/flat number, street, etc.")
    
    # Additional
    additional_notes = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.get_waste_type_display()} - {self.user.username} ({self.created_at.strftime('%Y-%m-%d')})"
    
    @property
    def location_display(self):
        """Return formatted location"""
        if self.location_auto and self.latitude and self.longitude:
            return f"{self.latitude}, {self.longitude}"
        else:
            parts = [self.area, self.city, self.landmark]
            return ", ".join([p for p in parts if p])
    
    @property
    def quantity_display(self):
        """Return formatted quantity"""
        if self.exact_quantity:
            return f"{self.exact_quantity} kg"
        return self.get_quantity_type_display()


class Buyer(models.Model):
    """Buyer/Recycler model for waste collection businesses"""
    
    SHOP_TYPE_CHOICES = [
        ('scrap_dealer', 'Scrap Dealer'),
        ('recycling_center', 'Recycling Center'),
        ('waste_collector', 'Waste Collector'),
        ('junkyard', 'Junkyard'),
        ('ewaste_handler', 'E-Waste Handler'),
        ('other', 'Other'),
    ]
    
    WASTE_CATEGORY_CHOICES = [
        ('plastic', 'Plastic'),
        ('metal', 'Metal'),
        ('paper', 'Paper & Cardboard'),
        ('glass', 'Glass'),
        ('organic', 'Organic'),
        ('ewaste', 'E-Waste'),
        ('mixed', 'Mixed Waste'),
    ]
    
    # Link to Django User
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='buyer_profile')
    
    # Personal Details
    full_name = models.CharField(max_length=200)
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed."
    )
    mobile_number = models.CharField(validators=[phone_regex], max_length=17, unique=True)
    
    # Business Details
    shop_name = models.CharField(max_length=300)
    shop_type = models.CharField(max_length=50, choices=SHOP_TYPE_CHOICES)
    waste_categories_handled = models.JSONField(default=list, help_text="List of waste categories this buyer handles")
    shop_address = models.TextField()
    shop_photo = models.ImageField(upload_to='buyer_shops/', null=True, blank=True)
    
    # Verification Details
    aadhaar_number = models.CharField(max_length=500, help_text="Encrypted Aadhaar number")
    aadhaar_last_4 = models.CharField(max_length=4, help_text="Last 4 digits for display")
    trade_license = models.FileField(upload_to='buyer_licenses/', null=True, blank=True, help_text="Upload trade license/business registration (optional)")
    
    # Status & Metadata
    is_verified = models.BooleanField(default=False, help_text="Admin verification status")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.shop_name} - {self.full_name}"
    
    @property
    def masked_aadhaar(self):
        """Return masked Aadhaar number"""
        return f"XXXX XXXX {self.aadhaar_last_4}"
    
    @property
    def waste_categories_display(self):
        """Return comma-separated waste categories"""
        return ", ".join(self.waste_categories_handled) if self.waste_categories_handled else "None"
    
    @property
    def average_rating(self):
        """Calculate average rating"""
        from django.db.models import Avg
        avg = self.ratings.aggregate(Avg('rating'))['rating__avg']
        return round(avg, 1) if avg else 0
    
    @property
    def total_ratings(self):
        """Get total number of ratings"""
        return self.ratings.count()
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Buyer'
        verbose_name_plural = 'Buyers'


class PickupRequest(models.Model):
    """Pickup request from buyer to user for waste collection"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('scheduled', 'Scheduled'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Relations
    waste_report = models.ForeignKey(WasteReport, on_delete=models.CASCADE, related_name='pickup_requests')
    buyer = models.ForeignKey(Buyer, on_delete=models.CASCADE, related_name='pickup_requests')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_requests')
    
    # Request Details
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    offered_price = models.DecimalField(max_digits=10, decimal_places=2, help_text="Price offered by buyer in ₹")
    message = models.TextField(blank=True, help_text="Message from buyer to user")
    
    # Response Details
    user_response_message = models.TextField(blank=True, help_text="Message from user")
    confirmed_pickup_address = models.TextField(blank=True, help_text="Final confirmed pickup address")
    
    # Scheduling
    proposed_time_slot_1 = models.DateTimeField(null=True, blank=True, help_text="First proposed pickup time by buyer")
    proposed_time_slot_2 = models.DateTimeField(null=True, blank=True, help_text="Second proposed pickup time by buyer")
    proposed_time_slot_3 = models.DateTimeField(null=True, blank=True, help_text="Third proposed pickup time by buyer")
    confirmed_pickup_time = models.DateTimeField(null=True, blank=True, help_text="Confirmed pickup time by user")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    scheduled_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.buyer.shop_name} → {self.waste_report.user.username} ({self.get_status_display()})"
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Pickup Request'
        verbose_name_plural = 'Pickup Requests'


class BuyerRating(models.Model):
    """User ratings for buyers"""
    
    buyer = models.ForeignKey(Buyer, on_delete=models.CASCADE, related_name='ratings')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='given_ratings')
    pickup_request = models.OneToOneField(PickupRequest, on_delete=models.CASCADE, related_name='rating', null=True, blank=True)
    
    # Rating (1-5 stars)
    rating = models.IntegerField(choices=[(i, f"{i} Star{'s' if i > 1 else ''}") for i in range(1, 6)])
    review = models.TextField(blank=True, help_text="Optional review comment")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username} → {self.buyer.shop_name} ({self.rating}★)"
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['buyer', 'user', 'pickup_request']
        verbose_name = 'Buyer Rating'
        verbose_name_plural = 'Buyer Ratings'


class PickupHistory(models.Model):
    """Historical record of completed pickups (preserved after waste report deletion)"""
    
    # User & Buyer Info
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='pickup_history')
    user_username = models.CharField(max_length=150, help_text="Username at time of pickup")
    buyer_shop_name = models.CharField(max_length=200, help_text="Shop name at time of pickup")
    
    # Waste Details
    waste_type = models.CharField(max_length=50, help_text="Type of waste collected")
    quantity = models.CharField(max_length=100, help_text="Quantity collected")
    location = models.CharField(max_length=500, blank=True, help_text="Pickup location")
    
    # Transaction Details
    offered_price = models.DecimalField(max_digits=10, decimal_places=2, help_text="Final price paid")
    
    # Timing
    reported_at = models.DateTimeField(help_text="When waste was originally reported")
    scheduled_at = models.DateTimeField(help_text="When pickup was scheduled")
    completed_at = models.DateTimeField(help_text="When pickup was completed")
    
    # Optional: Reference to original pickup request (if still exists)
    pickup_request = models.ForeignKey(PickupRequest, on_delete=models.SET_NULL, null=True, blank=True, related_name='history')
    
    def __str__(self):
        return f"{self.user_username} ← {self.buyer_shop_name} | {self.waste_type} ({self.completed_at.date()})"
    
    class Meta:
        ordering = ['-completed_at']
        verbose_name = 'Pickup History'
        verbose_name_plural = 'Pickup Histories'


class Notification(models.Model):
    """Notification model for user alerts"""
    
    NOTIFICATION_TYPES = [
        ('pickup_request', 'Pickup Request'),
        ('request_accepted', 'Request Accepted'),
        ('request_rejected', 'Request Rejected'),
        ('pickup_completed', 'Pickup Completed'),
        ('system', 'System Notification'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Optional references
    pickup_request = models.ForeignKey(PickupRequest, on_delete=models.CASCADE, null=True, blank=True)
    waste_report = models.ForeignKey(WasteReport, on_delete=models.CASCADE, null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.title}"
