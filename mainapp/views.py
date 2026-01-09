from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib.auth import login, authenticate
from django.contrib import messages
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.db.models import Avg
from .models import Task, Note, WasteReport, Buyer, PickupRequest, BuyerRating, PickupHistory
from .forms import TaskForm, NoteForm, WasteReportForm, SignUpForm, BuyerRegistrationForm
from .waste_classifier import classify_waste_image
import json

def home(request):
    """Home page view"""
    context = {}
    if request.user.is_authenticated:
        # Get user's recent reports for dashboard
        recent_reports = WasteReport.objects.filter(user=request.user)[:3]
        total_reports = WasteReport.objects.filter(user=request.user).count()
        
        # Get unread notification count for users
        if not hasattr(request.user, 'buyer_profile'):
            pending_requests_count = PickupRequest.objects.filter(
                user=request.user,
                status='pending'
            ).count()
            context['pending_requests_count'] = pending_requests_count
        
        context.update({
            'recent_reports': recent_reports,
            'total_reports': total_reports,
        })
    return render(request, 'mainapp/home.html', context)

@login_required
def task_list(request):
    """Display all tasks"""
    tasks = Task.objects.filter(created_by=request.user)
    return render(request, 'mainapp/task_list.html', {'tasks': tasks})

@login_required
def task_create(request):
    """Create a new task"""
    if request.method == 'POST':
        form = TaskForm(request.POST)
        if form.is_valid():
            task = form.save(commit=False)
            task.created_by = request.user
            task.save()
            messages.success(request, 'Task created successfully!')
            return redirect('task_list')
    else:
        form = TaskForm()
    return render(request, 'mainapp/task_form.html', {'form': form, 'title': 'Create Task'})

@login_required
def task_update(request, pk):
    """Update an existing task"""
    task = get_object_or_404(Task, pk=pk, created_by=request.user)
    if request.method == 'POST':
        form = TaskForm(request.POST, instance=task)
        if form.is_valid():
            form.save()
            messages.success(request, 'Task updated successfully!')
            return redirect('task_list')
    else:
        form = TaskForm(instance=task)
    return render(request, 'mainapp/task_form.html', {'form': form, 'title': 'Update Task'})

@login_required
def task_delete(request, pk):
    """Delete a task"""
    task = get_object_or_404(Task, pk=pk, created_by=request.user)
    if request.method == 'POST':
        task.delete()
        messages.success(request, 'Task deleted successfully!')
        return redirect('task_list')
    return render(request, 'mainapp/task_confirm_delete.html', {'task': task})

@login_required
def note_list(request):
    """Display all notes"""
    notes = Note.objects.filter(author=request.user)
    return render(request, 'mainapp/note_list.html', {'notes': notes})

@login_required
def note_create(request):
    """Create a new note"""
    if request.method == 'POST':
        form = NoteForm(request.POST)
        if form.is_valid():
            note = form.save(commit=False)
            note.author = request.user
            note.save()
            messages.success(request, 'Note created successfully!')
            return redirect('note_list')
    else:
        form = NoteForm()
    return render(request, 'mainapp/note_form.html', {'form': form, 'title': 'Create Note'})

@login_required
def note_update(request, pk):
    """Update an existing note"""
    note = get_object_or_404(Note, pk=pk, author=request.user)
    if request.method == 'POST':
        form = NoteForm(request.POST, instance=note)
        if form.is_valid():
            form.save()
            messages.success(request, 'Note updated successfully!')
            return redirect('note_list')
    else:
        form = NoteForm(instance=note)
    return render(request, 'mainapp/note_form.html', {'form': form, 'title': 'Update Note'})

@login_required
def note_delete(request, pk):
    """Delete a note"""
    note = get_object_or_404(Note, pk=pk, author=request.user)
    if request.method == 'POST':
        note.delete()
        messages.success(request, 'Note deleted successfully!')
        return redirect('note_list')
    return render(request, 'mainapp/note_confirm_delete.html', {'note': note})


# ============= WASTE REPORTING VIEWS =============

@login_required
def waste_report_create(request):
    """Create a new waste report"""
    if request.method == 'POST':
        form = WasteReportForm(request.POST, request.FILES)
        if form.is_valid():
            waste_report = form.save(commit=False)
            waste_report.user = request.user
            
            # Auto-fill name and email from user if not provided
            if not waste_report.name:
                waste_report.name = request.user.get_full_name() or request.user.username
            if not waste_report.email:
                waste_report.email = request.user.email
            
            waste_report.save()
            messages.success(request, '✅ Waste report submitted successfully! You can view it in "My Reports".')
            return redirect('home')
    else:
        # Pre-fill user information
        initial_data = {
            'name': request.user.get_full_name() or request.user.username,
            'email': request.user.email,
        }
        form = WasteReportForm(initial=initial_data)
    
    return render(request, 'mainapp/waste_report_form.html', {'form': form})

@login_required
def waste_report_list(request):
    """Display all waste reports"""
    reports = WasteReport.objects.filter(user=request.user)
    return render(request, 'mainapp/waste_report_list.html', {'reports': reports})

@login_required
def waste_report_detail(request, pk):
    """Display waste report details"""
    report = get_object_or_404(WasteReport, pk=pk, user=request.user)
    return render(request, 'mainapp/waste_report_detail.html', {'report': report})

@login_required
def waste_report_delete(request, pk):
    """Delete a waste report"""
    report = get_object_or_404(WasteReport, pk=pk, user=request.user)
    if request.method == 'POST':
        report.delete()
        messages.success(request, 'Waste report deleted successfully!')
        return redirect('waste_report_list')
    return render(request, 'mainapp/waste_report_confirm_delete.html', {'report': report})


# ============= USER AUTHENTICATION VIEWS =============
# ============= USER AUTHENTICATION VIEWS =============

def signup_choice(request):
    """User type selection view - Choose between User or Buyer"""
    if request.user.is_authenticated:
        # Check if user is buyer or regular user
        if hasattr(request.user, 'buyer_profile'):
            return redirect('buyer_dashboard')
        return redirect('home')
    
    return render(request, 'mainapp/signup_choice.html')


def signup(request):
    """Regular user registration view"""
    if request.user.is_authenticated:
        return redirect('home')
    
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            user = form.save()
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password1')
            user = authenticate(username=username, password=password)
            login(request, user)
            messages.success(request, f'Account created successfully! Welcome, {username}!')
            return redirect('home')
    else:
        form = SignUpForm()
    
    return render(request, 'mainapp/signup.html', {'form': form})


def buyer_signup(request):
    """Buyer registration view"""
    if request.user.is_authenticated:
        return redirect('buyer_dashboard')
    
    if request.method == 'POST':
        form = BuyerRegistrationForm(request.POST, request.FILES)
        if form.is_valid():
            user = form.save()
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password1')
            user = authenticate(username=username, password=password)
            login(request, user)
            messages.success(request, f'Buyer account created successfully! Welcome, {username}!')
            return redirect('buyer_dashboard')
    else:
        form = BuyerRegistrationForm()
    
    return render(request, 'mainapp/buyer_signup.html', {'form': form})


def user_login(request):
    """Custom login view that redirects based on user type"""
    if request.user.is_authenticated:
        if hasattr(request.user, 'buyer_profile'):
            return redirect('buyer_dashboard')
        return redirect('home')
    
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        
        if user is not None:
            login(request, user)
            # Check user type and redirect accordingly
            if hasattr(user, 'buyer_profile'):
                messages.success(request, f'Welcome back, {user.buyer_profile.shop_name}!')
                return redirect('buyer_dashboard')
            else:
                messages.success(request, f'Welcome back, {user.username}!')
                return redirect('home')
        else:
            messages.error(request, 'Invalid username or password.')
    
    return render(request, 'mainapp/login.html')


# ============= BUYER VIEWS =============

@login_required
def buyer_dashboard(request):
    """Buyer dashboard view with stats"""
    # Check if user is a buyer
    if not hasattr(request.user, 'buyer_profile'):
        messages.error(request, 'Access denied. You are not registered as a buyer.')
        return redirect('home')
    
    buyer = request.user.buyer_profile
    
    # Get stats
    total_requests = PickupRequest.objects.filter(buyer=buyer).count()
    pending_requests = PickupRequest.objects.filter(buyer=buyer, status='pending').count()
    accepted_requests = PickupRequest.objects.filter(buyer=buyer, status='accepted').count()
    completed_requests = PickupRequest.objects.filter(buyer=buyer, status='completed').count()
    
    # Get available waste listings (pending waste reports that buyer hasn't requested yet)
    available_listings = WasteReport.objects.filter(
        status='pending'
    ).exclude(
        pickup_requests__buyer=buyer
    ).order_by('-created_at')[:5]
    
    context = {
        'buyer': buyer,
        'total_requests': total_requests,
        'pending_requests': pending_requests,
        'accepted_requests': accepted_requests,
        'completed_requests': completed_requests,
        'available_listings': available_listings,
    }
    return render(request, 'mainapp/buyer_dashboard.html', context)


@login_required
def buyer_requests(request):
    """View all available waste requests"""
    if not hasattr(request.user, 'buyer_profile'):
        messages.error(request, 'Access denied. You are not registered as a buyer.')
        return redirect('home')
    
    buyer = request.user.buyer_profile
    
    # Get all available waste reports (not yet collected, buyer hasn't requested)
    available_listings = WasteReport.objects.filter(
        status='pending'
    ).exclude(
        pickup_requests__buyer=buyer
    ).order_by('-created_at')
    
    context = {
        'buyer': buyer,
        'listings': available_listings,
    }
    return render(request, 'mainapp/buyer_requests.html', context)


@login_required
def buyer_my_pickups(request):
    """View buyer's pickup requests"""
    if not hasattr(request.user, 'buyer_profile'):
        messages.error(request, 'Access denied. You are not registered as a buyer.')
        return redirect('home')
    
    buyer = request.user.buyer_profile
    
    # Archive expired scheduled pickups to history (where scheduled time has passed)
    now = timezone.now()
    expired_pickups = PickupRequest.objects.filter(
        buyer=buyer,
        status='scheduled',
        confirmed_pickup_time__lt=now
    ).select_related('waste_report', 'user')
    
    expired_count = 0
    for pickup in expired_pickups:
        # Save to history before deletion
        PickupHistory.objects.create(
            user=pickup.user,
            user_username=pickup.user.username,
            buyer_shop_name=buyer.shop_name,
            waste_type=pickup.waste_report.get_waste_type_display(),
            quantity=pickup.waste_report.quantity_display,
            location=f"{pickup.waste_report.city}, {pickup.waste_report.state}" if pickup.waste_report.city else "Location not specified",
            offered_price=pickup.offered_price,
            reported_at=pickup.waste_report.created_at,
            scheduled_at=pickup.confirmed_pickup_time,
            completed_at=now,  # Mark as expired at current time
            pickup_request=None  # Will be deleted
        )
        expired_count += 1
    
    if expired_count > 0:
        expired_pickups.delete()
        messages.info(request, f'{expired_count} expired pickup request(s) moved to history.')
    
    # Get all pickup requests made by this buyer
    pickups = PickupRequest.objects.filter(buyer=buyer).order_by('-created_at')
    
    context = {
        'buyer': buyer,
        'pickups': pickups,
    }
    return render(request, 'mainapp/buyer_my_pickups.html', context)


@login_required
def waste_detail_for_buyer(request, pk):
    """Detailed waste report view for buyers"""
    if not hasattr(request.user, 'buyer_profile'):
        messages.error(request, 'Access denied.')
        return redirect('home')
    
    buyer = request.user.buyer_profile
    report = get_object_or_404(WasteReport, pk=pk)
    
    # Check if buyer has already sent a request
    existing_request = PickupRequest.objects.filter(
        buyer=buyer,
        waste_report=report
    ).first()
    
    context = {
        'buyer': buyer,
        'report': report,
        'existing_request': existing_request,
    }
    return render(request, 'mainapp/waste_detail_buyer.html', context)


@login_required
def send_pickup_request(request, pk):
    """Send pickup request to user"""
    if not hasattr(request.user, 'buyer_profile'):
        messages.error(request, 'Access denied.')
        return redirect('home')
    
    if request.method != 'POST':
        return redirect('buyer_requests')
    
    buyer = request.user.buyer_profile
    report = get_object_or_404(WasteReport, pk=pk)
    
    # Check if already requested
    if PickupRequest.objects.filter(buyer=buyer, waste_report=report).exists():
        messages.warning(request, 'You have already sent a request for this waste.')
        return redirect('waste_detail_for_buyer', pk=pk)
    
    # Get form data
    offered_price = request.POST.get('offered_price', 0)
    message = request.POST.get('message', '')
    time_slot_1 = request.POST.get('time_slot_1', '')
    time_slot_2 = request.POST.get('time_slot_2', '')
    time_slot_3 = request.POST.get('time_slot_3', '')
    
    # Parse datetime strings
    from datetime import datetime
    proposed_time_1 = None
    proposed_time_2 = None
    proposed_time_3 = None
    
    try:
        if time_slot_1:
            proposed_time_1 = datetime.fromisoformat(time_slot_1)
        if time_slot_2:
            proposed_time_2 = datetime.fromisoformat(time_slot_2)
        if time_slot_3:
            proposed_time_3 = datetime.fromisoformat(time_slot_3)
    except ValueError:
        messages.error(request, 'Invalid date/time format.')
        return redirect('waste_detail_for_buyer', pk=pk)
    
    # Create pickup request
    pickup_request = PickupRequest.objects.create(
        waste_report=report,
        buyer=buyer,
        user=report.user,
        offered_price=offered_price,
        message=message,
        proposed_time_slot_1=proposed_time_1,
        proposed_time_slot_2=proposed_time_2,
        proposed_time_slot_3=proposed_time_3,
        status='pending'
    )
    
    messages.success(request, f'✅ Pickup request sent to {report.user.username}!')
    return redirect('buyer_my_pickups')


@login_required
def user_notifications(request):
    """View user's pickup request notifications"""
    
    # Archive expired scheduled pickups to history (where scheduled time has passed)
    now = timezone.now()
    expired_pickups = PickupRequest.objects.filter(
        user=request.user,
        status='scheduled',
        confirmed_pickup_time__lt=now
    ).select_related('buyer', 'waste_report')
    
    expired_count = 0
    for pickup in expired_pickups:
        # Save to history before deletion
        PickupHistory.objects.create(
            user=pickup.user,
            user_username=pickup.user.username,
            buyer_shop_name=pickup.buyer.shop_name,
            waste_type=pickup.waste_report.get_waste_type_display(),
            quantity=pickup.waste_report.quantity_display,
            location=f"{pickup.waste_report.city}, {pickup.waste_report.state}" if pickup.waste_report.city else "Location not specified",
            offered_price=pickup.offered_price,
            reported_at=pickup.waste_report.created_at,
            scheduled_at=pickup.confirmed_pickup_time,
            completed_at=now,  # Mark as expired at current time
            pickup_request=None  # Will be deleted
        )
        expired_count += 1
    
    if expired_count > 0:
        expired_pickups.delete()
        messages.info(request, f'{expired_count} expired pickup request(s) moved to history.')
    
    # Get all pickup requests for this user
    notifications = PickupRequest.objects.filter(
        user=request.user
    ).select_related('buyer', 'waste_report').prefetch_related('rating').order_by('-created_at')
    
    context = {
        'notifications': notifications,
    }
    return render(request, 'mainapp/user_notifications.html', context)


@login_required
def respond_to_pickup_request(request, pk):
    """User accepts or rejects pickup request"""
    pickup_request = get_object_or_404(PickupRequest, pk=pk, user=request.user)
    
    if request.method != 'POST':
        return redirect('user_notifications')
    
    action = request.POST.get('action')
    response_message = request.POST.get('response_message', '')
    selected_time_slot = request.POST.get('selected_time_slot', '')
    confirmed_address = request.POST.get('confirmed_address', '')
    
    if action == 'accept':
        pickup_request.status = 'accepted'
        pickup_request.accepted_at = timezone.now()
        pickup_request.user_response_message = response_message
        pickup_request.save()
        
        # Update waste report status
        pickup_request.waste_report.status = 'assigned'
        pickup_request.waste_report.save()
        
        messages.success(request, '✅ Pickup request accepted!')
    elif action == 'confirm_schedule':
        # User confirms a specific time slot and address
        from datetime import datetime
        try:
            if selected_time_slot:
                confirmed_time = datetime.fromisoformat(selected_time_slot)
                pickup_request.confirmed_pickup_time = confirmed_time
                pickup_request.status = 'scheduled'
                pickup_request.scheduled_at = timezone.now()
                pickup_request.user_response_message = response_message
                
                # Save confirmed pickup address
                if confirmed_address:
                    pickup_request.confirmed_pickup_address = confirmed_address
                else:
                    # Use waste report address as default
                    pickup_request.confirmed_pickup_address = pickup_request.waste_report.full_address or "Address not specified"
                
                pickup_request.save()
                
                # Update waste report status
                pickup_request.waste_report.status = 'assigned'
                pickup_request.waste_report.save()
                
                messages.success(request, f'✅ Pickup scheduled for {confirmed_time.strftime("%B %d, %Y at %I:%M %p")}!')
            else:
                messages.error(request, 'Please select a time slot.')
                return redirect('user_notifications')
        except ValueError:
            messages.error(request, 'Invalid time slot selected.')
            return redirect('user_notifications')
    elif action == 'reject':
        pickup_request.status = 'rejected'
        pickup_request.user_response_message = response_message
        pickup_request.save()
        messages.info(request, 'Pickup request rejected.')
    
    return redirect('user_notifications')


@login_required
def browse_buyers(request):
    """Show all buyers to users"""
    buyers = Buyer.objects.all().annotate(avg_rating=Avg('ratings__rating'))
    
    context = {
        'buyers': buyers,
    }
    return render(request, 'mainapp/browse_buyers.html', context)


@login_required
def buyer_profile_public(request, pk):
    """Public buyer profile view for users"""
    buyer = get_object_or_404(Buyer, pk=pk)
    
    # Get ratings with reviews
    ratings = buyer.ratings.select_related('user').order_by('-created_at')
    
    # Check if user has already rated this buyer
    user_rating = None
    if request.user.is_authenticated:
        user_rating = buyer.ratings.filter(user=request.user).first()
    
    context = {
        'buyer': buyer,
        'ratings': ratings,
        'user_rating': user_rating,
    }
    return render(request, 'mainapp/buyer_profile_public.html', context)


@login_required
def rate_buyer(request, pk):
    """Rate a buyer"""
    buyer = get_object_or_404(Buyer, pk=pk)
    
    if request.method != 'POST':
        return redirect('buyer_profile_public', pk=pk)
    
    # Get the pickup request ID if provided
    pickup_request_id = request.POST.get('pickup_request_id') or request.GET.get('pickup_request')
    pickup_request = None
    if pickup_request_id:
        pickup_request = get_object_or_404(PickupRequest, pk=pickup_request_id, user=request.user, status='completed')
    
    rating_value = request.POST.get('rating')
    review = request.POST.get('review', '')
    
    if not rating_value:
        messages.error(request, 'Please select a rating.')
        return redirect('buyer_profile_public', pk=pk)
    
    try:
        rating_value = int(rating_value)
        if rating_value < 1 or rating_value > 5:
            raise ValueError()
    except ValueError:
        messages.error(request, 'Invalid rating value.')
        return redirect('buyer_profile_public', pk=pk)
    
    # Create or update rating
    if pickup_request:
        rating, created = BuyerRating.objects.update_or_create(
            buyer=buyer,
            user=request.user,
            pickup_request=pickup_request,
            defaults={
                'rating': rating_value,
                'review': review,
            }
        )
    else:
        # Find any completed pickup request to associate with
        any_completed = PickupRequest.objects.filter(
            buyer=buyer,
            user=request.user,
            status='completed'
        ).first()
        
        if any_completed:
            rating, created = BuyerRating.objects.update_or_create(
                buyer=buyer,
                user=request.user,
                pickup_request=any_completed,
                defaults={
                    'rating': rating_value,
                    'review': review,
                }
            )
        else:
            messages.error(request, 'You can only rate buyers after completing a transaction.')
            return redirect('buyer_profile_public', pk=pk)
    
    if created:
        messages.success(request, '⭐ Rating submitted successfully!')
    else:
        messages.success(request, '⭐ Rating updated successfully!')
    
    return redirect('buyer_profile_public', pk=pk)


@login_required
def pickup_history(request):
    """View pickup history for both users and buyers"""
    if hasattr(request.user, 'buyer_profile'):
        # Buyer view: show all pickups they completed
        history = PickupHistory.objects.filter(
            pickup_request__buyer=request.user.buyer_profile
        ).order_by('-completed_at')
    else:
        # User view: show all their completed pickups
        history = PickupHistory.objects.filter(
            user=request.user
        ).order_by('-completed_at')
    
    context = {
        'history': history,
    }
    return render(request, 'mainapp/pickup_history.html', context)


@login_required
def buyer_profile(request):
    """Buyer profile view"""
    # Check if user is a buyer
    if not hasattr(request.user, 'buyer_profile'):
        messages.error(request, 'Access denied. You are not registered as a buyer.')
        return redirect('home')
    
    buyer = request.user.buyer_profile
    context = {
        'buyer': buyer,
    }
    return render(request, 'mainapp/buyer_profile.html', context)


# ============= AI CLASSIFICATION API =============


# ============= AI CLASSIFICATION API =============

@login_required
@csrf_exempt
def classify_waste_api(request):
    """API endpoint to classify waste from uploaded image"""
    if request.method == 'POST' and request.FILES.get('image'):
        try:
            image_file = request.FILES['image']
            
            # Log the request
            print(f"[AI Classification] Processing image: {image_file.name}, size: {image_file.size} bytes")
            
            # Classify the waste
            result = classify_waste_image(image_file)
            
            # Log the result
            print(f"[AI Classification] Result: {result}")
            
            if result.get('error'):
                return JsonResponse({
                    'success': False,
                    'error': result['error']
                }, status=500)
            
            return JsonResponse({
                'success': True,
                'data': result
            })
            
        except Exception as e:
            print(f"[AI Classification] Error: {str(e)}")
            import traceback
            traceback.print_exc()
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'error': 'No image provided'
    }, status=400)
