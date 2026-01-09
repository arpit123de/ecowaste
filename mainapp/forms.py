from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from .models import Task, Note, WasteReport, Buyer
from cryptography.fernet import Fernet
import os

class TaskForm(forms.ModelForm):
    class Meta:
        model = Task
        fields = ['title', 'description', 'status', 'due_date']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Enter task title'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 4, 'placeholder': 'Enter task description'}),
            'status': forms.Select(attrs={'class': 'form-control'}),
            'due_date': forms.DateTimeInput(attrs={'class': 'form-control', 'type': 'datetime-local'}),
        }

class NoteForm(forms.ModelForm):
    class Meta:
        model = Note
        fields = ['title', 'content']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Enter note title'}),
            'content': forms.Textarea(attrs={'class': 'form-control', 'rows': 6, 'placeholder': 'Enter note content'}),
        }


class WasteReportForm(forms.ModelForm):
    class Meta:
        model = WasteReport
        fields = [
            'name', 'mobile_number', 'email',
            'waste_type', 'waste_type_other',
            'quantity_type', 'exact_quantity',
            'waste_condition',
            'image',
            'location_auto', 'latitude', 'longitude',
            'area', 'city', 'state', 'landmark', 'full_address',
            'additional_notes'
        ]
        widgets = {
            'name': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Enter your name (optional)'
            }),
            'mobile_number': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': '+91 XXXXXXXXXX',
                'type': 'tel'
            }),
            'email': forms.EmailInput(attrs={
                'class': 'form-control',
                'placeholder': 'your@email.com'
            }),
            'waste_type': forms.Select(attrs={
                'class': 'form-select',
                'id': 'waste_type'
            }),
            'waste_type_other': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Specify waste type',
                'id': 'waste_type_other',
                'style': 'display:none;'
            }),
            'quantity_type': forms.Select(attrs={
                'class': 'form-select'
            }),
            'exact_quantity': forms.NumberInput(attrs={
                'class': 'form-control',
                'placeholder': 'e.g., 5',
                'step': '0.01'
            }),
            'waste_condition': forms.Select(attrs={
                'class': 'form-select'
            }),
            'image': forms.FileInput(attrs={
                'class': 'form-control',
                'accept': 'image/*',
                'capture': 'environment',
                'id': 'waste_image'
            }),
            'location_auto': forms.CheckboxInput(attrs={
                'class': 'form-check-input',
                'id': 'location_auto'
            }),
            'latitude': forms.HiddenInput(),
            'longitude': forms.HiddenInput(),
            'area': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Area / Street Name'
            }),
            'city': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'City'
            }),
            'state': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'State'
            }),
            'landmark': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Nearby Landmark'
            }),
            'full_address': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': 'Complete pickup address (House/Flat No., Building Name, Street, etc.)',
                'required': True
            }),
            'additional_notes': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': 'e.g., Plastic bottles near roadside, blocking drainage'
            }),
        }
    
    def clean_image(self):
        image = self.cleaned_data.get('image')
        if image:
            # Validate file size (5MB max)
            if image.size > 5 * 1024 * 1024:
                raise forms.ValidationError("Image file size must be under 5MB")
            # Validate file type
            if not image.content_type in ['image/jpeg', 'image/jpg', 'image/png']:
                raise forms.ValidationError("Only JPG and PNG images are allowed")
        return image
    
    def clean(self):
        cleaned_data = super().clean()
        waste_type = cleaned_data.get('waste_type')
        waste_type_other = cleaned_data.get('waste_type_other')
        
        # If "Other" is selected, waste_type_other must be provided
        if waste_type == 'other' and not waste_type_other:
            self.add_error('waste_type_other', 'Please specify the waste type')
        
        return cleaned_data


class SignUpForm(UserCreationForm):
    email = forms.EmailField(
        max_length=254,
        required=True,
        widget=forms.EmailInput(attrs={
            'class': 'form-control',
            'placeholder': 'Email address'
        })
    )
    first_name = forms.CharField(
        max_length=30,
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'First name (optional)'
        })
    )
    last_name = forms.CharField(
        max_length=30,
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Last name (optional)'
        })
    )
    
    class Meta:
        model = User
        fields = ('username', 'first_name', 'last_name', 'email', 'password1', 'password2')
        widgets = {
            'username': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Username'
            }),
        }
    
    def __init__(self, *args, **kwargs):
        super(SignUpForm, self).__init__(*args, **kwargs)
        self.fields['password1'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Password'
        })
        self.fields['password2'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Confirm password'
        })


class BuyerRegistrationForm(UserCreationForm):
    """Registration form for buyers/recyclers"""
    
    # Personal Details
    full_name = forms.CharField(
        max_length=200,
        required=True,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Enter full name'})
    )
    mobile_number = forms.CharField(
        max_length=17,
        required=True,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': '+91XXXXXXXXXX'})
    )
    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'your@email.com'})
    )
    
    # Business Details
    shop_name = forms.CharField(
        max_length=300,
        required=True,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Enter shop/business name'})
    )
    shop_type = forms.ChoiceField(
        choices=Buyer.SHOP_TYPE_CHOICES,
        required=True,
        widget=forms.Select(attrs={'class': 'form-select'})
    )
    waste_categories_handled = forms.MultipleChoiceField(
        choices=Buyer.WASTE_CATEGORY_CHOICES,
        required=True,
        widget=forms.CheckboxSelectMultiple(attrs={'class': 'form-check-input'}),
        label='Waste Categories You Handle'
    )
    shop_address = forms.CharField(
        required=True,
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'Full shop address'})
    )
    shop_photo = forms.ImageField(
        required=False,
        widget=forms.FileInput(attrs={'class': 'form-control', 'accept': 'image/*'})
    )
    
    # Verification Details
    aadhaar_number = forms.CharField(
        max_length=12,
        required=True,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'XXXXXXXXXXXX (12 digits)',
            'pattern': '[0-9]{12}',
            'maxlength': '12'
        }),
        label='Aadhaar Number'
    )
    trade_license = forms.FileField(
        required=False,
        widget=forms.FileInput(attrs={'class': 'form-control', 'accept': '.pdf,.jpg,.jpeg,.png'}),
        label='Trade License/Business Registration (Optional)'
    )
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password1', 'password2']
        widgets = {
            'username': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Choose a username'}),
        }
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['password1'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Password'
        })
        self.fields['password2'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Confirm password'
        })
    
    def clean_mobile_number(self):
        mobile = self.cleaned_data.get('mobile_number')
        if Buyer.objects.filter(mobile_number=mobile).exists():
            raise forms.ValidationError("This mobile number is already registered.")
        return mobile
    
    def clean_aadhaar_number(self):
        aadhaar = self.cleaned_data.get('aadhaar_number')
        if not aadhaar.isdigit() or len(aadhaar) != 12:
            raise forms.ValidationError("Aadhaar must be exactly 12 digits.")
        return aadhaar
    
    def clean_shop_photo(self):
        photo = self.cleaned_data.get('shop_photo')
        if photo:
            if photo.size > 5 * 1024 * 1024:
                raise forms.ValidationError("Image file size must be under 5MB")
        return photo
    
    def clean_trade_license(self):
        license_file = self.cleaned_data.get('trade_license')
        if license_file:
            if license_file.size > 10 * 1024 * 1024:
                raise forms.ValidationError("File size must be under 10MB")
        return license_file
    
    def save(self, commit=True):
        user = super().save(commit=False)
        user.email = self.cleaned_data['email']
        
        if commit:
            user.save()
            
            # Encrypt Aadhaar number
            aadhaar = self.cleaned_data['aadhaar_number']
            encryption_key = os.environ.get('ENCRYPTION_KEY')
            
            # Generate key if not exists
            if not encryption_key:
                encryption_key = Fernet.generate_key().decode()
            
            if isinstance(encryption_key, str):
                encryption_key = encryption_key.encode()
                
            cipher = Fernet(encryption_key)
            encrypted_aadhaar = cipher.encrypt(aadhaar.encode()).decode()
            
            # Create Buyer profile
            buyer = Buyer.objects.create(
                user=user,
                full_name=self.cleaned_data['full_name'],
                mobile_number=self.cleaned_data['mobile_number'],
                shop_name=self.cleaned_data['shop_name'],
                shop_type=self.cleaned_data['shop_type'],
                waste_categories_handled=list(self.cleaned_data['waste_categories_handled']),
                shop_address=self.cleaned_data['shop_address'],
                shop_photo=self.cleaned_data.get('shop_photo'),
                aadhaar_number=encrypted_aadhaar,
                aadhaar_last_4=aadhaar[-4:],
                trade_license=self.cleaned_data['trade_license'],
                is_verified=False
            )
            
        return user
