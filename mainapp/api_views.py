from rest_framework import viewsets, status, permissions, serializers
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db.models import Avg, Count, Sum
from django.db import transaction
from django.utils import timezone
from cryptography.fernet import Fernet
import json

from .models import Task, Note, WasteReport, Buyer, PickupRequest, BuyerRating, PickupHistory, Notification
from .serializers import (
    UserSerializer, UserRegistrationSerializer, TaskSerializer, NoteSerializer,
    WasteReportSerializer, WasteReportCreateSerializer, BuyerSerializer,
    PickupRequestSerializer, PickupRequestCreateSerializer,
    BuyerRatingSerializer, PickupHistorySerializer, NotificationSerializer
)
from .waste_classifier import classify_waste_image


# Encryption key for Aadhaar (in production, use environment variable)
ENCRYPTION_KEY = Fernet.generate_key()
cipher_suite = Fernet(ENCRYPTION_KEY)


# Authentication Views
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """Register a new user or buyer"""
    print(f"Registration request received: {request.data}")
    role = request.data.get('role', 'user').lower()
    print(f"Role: {role}")
    
    try:
        with transaction.atomic():
            # Create user account
            user_data = {
                'username': request.data.get('username'),
                'email': request.data.get('email'),
                'password': request.data.get('password'),
                'password2': request.data.get('password2'),
                'first_name': request.data.get('first_name', ''),
                'last_name': request.data.get('last_name', '')
            }
            
            print(f"User data: {user_data}")
            
            serializer = UserRegistrationSerializer(data=user_data)
            if not serializer.is_valid():
                print(f"Validation errors: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            user = serializer.save()
            print(f"User created: {user.username}")
            
            # If buyer role, create buyer profile
            if role == 'buyer':
                try:
                    mobile = request.data.get('mobile')
                    shop_name = request.data.get('shop_name')
                    shop_type = request.data.get('shop_type', 'other')
                    shop_address = request.data.get('shop_address')
                    aadhaar = request.data.get('aadhaar')
                    waste_types = request.data.get('waste_types', '[]')
                    
                    print(f"Buyer data - mobile: {mobile}, shop_name: {shop_name}, aadhaar: {aadhaar}")
                    print(f"User created: {user.id}, username: {user.username}")
                    
                    # Validate buyer-specific fields
                    if not all([mobile, shop_name, shop_address, aadhaar]):
                        print("Missing buyer fields")
                        user.delete()  # Rollback user creation
                        return Response({
                            'error': 'Missing required buyer fields: mobile, shop_name, shop_address, aadhaar'
                        }, status=status.HTTP_400_BAD_REQUEST)
                    
                    # Validate aadhaar length (strip whitespace)
                    aadhaar = str(aadhaar).strip()
                    if len(aadhaar) != 12 or not aadhaar.isdigit():
                        print(f"Invalid aadhaar: {aadhaar} (length: {len(aadhaar)})")
                        user.delete()  # Rollback user creation
                        return Response({
                            'error': 'Aadhaar must be exactly 12 digits'
                        }, status=status.HTTP_400_BAD_REQUEST)
                    
                    # Parse waste types
                    if isinstance(waste_types, str):
                        try:
                            waste_types = json.loads(waste_types)
                        except:
                            waste_types = []
                    
                    print(f"Waste types: {waste_types}")
                    
                    # Encrypt aadhaar
                    encrypted_aadhaar = cipher_suite.encrypt(aadhaar.encode()).decode()
                    aadhaar_last_4 = aadhaar[-4:]
                    
                    print(f"Creating buyer profile for user {user.id}...")
                    
                    # Create buyer profile
                    buyer = Buyer.objects.create(
                        user=user,
                        full_name=f"{user.first_name} {user.last_name}".strip() or user.username,
                        mobile_number=mobile,
                        shop_name=shop_name,
                        shop_type=shop_type,
                        shop_address=shop_address,
                        aadhaar_number=encrypted_aadhaar,
                        aadhaar_last_4=aadhaar_last_4,
                        waste_categories_handled=waste_types
                    )
                    
                    print(f"Buyer profile created successfully: {buyer.id} - {buyer.shop_name}")
                    
                    # Handle file uploads
                    if 'shop_photo' in request.FILES:
                        buyer.shop_photo = request.FILES['shop_photo']
                    
                    if 'trade_license' in request.FILES:
                        buyer.trade_license = request.FILES['trade_license']
                    
                    buyer.save()
                    print(f"Buyer profile saved with files")
                    
                    # Verify buyer profile was created
                    if hasattr(user, 'buyer_profile'):
                        print(f"✓ Buyer profile verification successful: {user.buyer_profile.shop_name}")
                    else:
                        print(f"✗ WARNING: Buyer profile not accessible via user.buyer_profile!")
                        
                except Exception as e:
                    print(f"ERROR creating buyer profile: {e}")
                    import traceback
                    traceback.print_exc()
                    user.delete()  # Rollback user creation
                    return Response({
                        'error': f'Failed to create buyer profile: {str(e)}'
                    }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            # Generate token
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({
                'token': token.key,
                'user': UserSerializer(user).data,
                'role': role,
                'message': f'{"Buyer" if role == "buyer" else "User"} registered successfully'
            }, status=status.HTTP_201_CREATED)
            
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """Login user and return token"""
    username = request.data.get('username')
    password = request.data.get('password')
    
    user = authenticate(username=username, password=password)
    if user:
        token, created = Token.objects.get_or_create(user=user)
        
        # Reload user from database to ensure all relations are loaded
        user = User.objects.select_related('buyer_profile').get(id=user.id)
        
        # Check if user is a buyer
        is_buyer = hasattr(user, 'buyer_profile')
        buyer_data = None
        
        print(f"Login - User: {username} (ID: {user.id}), Has buyer_profile: {is_buyer}")
        
        if is_buyer:
            try:
                buyer_profile = user.buyer_profile
                print(f"Buyer profile found: {buyer_profile.shop_name} (ID: {buyer_profile.id})")
                buyer_data = BuyerSerializer(buyer_profile).data
            except Buyer.DoesNotExist:
                print(f"Buyer profile DoesNotExist exception")
                is_buyer = False
                buyer_data = None
            except Exception as e:
                print(f"Error loading buyer profile: {e}")
                import traceback
                traceback.print_exc()
                is_buyer = False
                buyer_data = None
        else:
            print(f"User {username} does not have buyer_profile attribute")
        
        response_data = {
            'token': token.key,
            'user': UserSerializer(user).data,
            'is_buyer': is_buyer,
            'buyer': buyer_data
        }
        
        print(f"Login response: is_buyer={is_buyer}, buyer_data={'present' if buyer_data else 'null'}")
        
        return Response(response_data)
    return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    """Logout user by deleting token"""
    request.user.auth_token.delete()
    return Response({'message': 'Logged out successfully'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    """Get current user profile"""
    user = request.user
    
    # Check buyer status
    is_buyer = hasattr(user, 'buyer_profile')
    buyer_data = None
    
    if is_buyer:
        try:
            buyer_data = BuyerSerializer(user.buyer_profile).data
        except Exception as e:
            print(f"Error loading buyer profile in user_profile: {e}")
            is_buyer = False
    
    serializer = UserSerializer(user)
    return Response({
        'user': serializer.data,
        'is_buyer': is_buyer,
        'buyer': buyer_data
    })


# Task ViewSet
class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Task.objects.filter(created_by=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


# Note ViewSet
class NoteViewSet(viewsets.ModelViewSet):
    serializer_class = NoteSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Note.objects.filter(author=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)


# Waste Report ViewSet
class WasteReportViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return WasteReportCreateSerializer
        return WasteReportSerializer
    
    def get_queryset(self):
        user = self.request.user
        
        # If user is a buyer, show ALL pending waste reports from all users
        if hasattr(user, 'buyer_profile'):
            # Buyers can see all pending reports (except their own if they are also a user)
            return WasteReport.objects.filter(status='pending').order_by('-created_at')
        
        # Regular users only see their own reports
        return WasteReport.objects.filter(user=user)
    
    def perform_create(self, serializer):
        waste_report = serializer.save(user=self.request.user)
        
        # Classify waste using AI if image is provided
        if waste_report.image:
            try:
                classification_result = classify_waste_image(waste_report.image)
                if classification_result:
                    waste_report.ai_classification = classification_result.get('category', '')
                    waste_report.estimated_weight_kg = classification_result.get('estimated_weight_kg', 0)
                    waste_report.material_breakdown = classification_result.get('material_breakdown', {})
                    waste_report.recyclability_score = classification_result.get('recyclability_score', 0)
                    waste_report.disposal_recommendations = classification_result.get('disposal_recommendations', [])
                    waste_report.save()
            except Exception as e:
                print(f"AI Classification error: {e}")
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get user's waste report statistics"""
        reports = self.get_queryset()
        stats = {
            'total_reports': reports.count(),
            'pending': reports.filter(status='pending').count(),
            'scheduled': reports.filter(status='scheduled').count(),
            'completed': reports.filter(status='completed').count(),
            'by_type': {}
        }
        
        # Group by waste type
        for choice in WasteReport.WASTE_TYPE_CHOICES:
            count = reports.filter(waste_type=choice[0]).count()
            if count > 0:
                stats['by_type'][choice[0]] = {
                    'label': choice[1],
                    'count': count
                }
        
        return Response(stats)
    
    @action(detail=False, methods=['get'])
    def available(self, request):
        """Get all available (pending) waste reports for buyers - persists across app restarts"""
        # Only buyers should access this endpoint
        if not hasattr(request.user, 'buyer_profile'):
            return Response(
                {'error': 'Only buyers can access available waste'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get all pending waste reports from database (persisted data)
        available_waste = WasteReport.objects.filter(
            status='pending'
        ).select_related('user').order_by('-created_at')
        
        serializer = self.get_serializer(available_waste, many=True)
        return Response({
            'count': available_waste.count(),
            'results': serializer.data,
            'message': 'These reports are stored in database and persist across app restarts'
        })
    
    @action(detail=False, methods=['post'])
    def classify(self, request):
        """Classify waste image using AI"""
        if 'image' not in request.FILES:
            return Response(
                {'error': 'No image provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            image_file = request.FILES['image']
            classification_result = classify_waste_image(image_file)
            
            if classification_result:
                return Response(classification_result, status=status.HTTP_200_OK)
            else:
                return Response(
                    {'error': 'Classification failed'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )



# Buyer ViewSet
class BuyerViewSet(viewsets.ModelViewSet):
    serializer_class = BuyerSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Buyer.objects.annotate(
            average_rating=Avg('ratings__rating'),
            total_ratings=Count('ratings')
        )
        
        # Filter by waste type if provided
        waste_type = self.request.query_params.get('waste_type')
        if waste_type:
            queryset = queryset.filter(waste_types_accepted__contains=waste_type)
        
        # Filter by city
        city = self.request.query_params.get('city')
        if city:
            queryset = queryset.filter(city__icontains=city)
        
        return queryset.filter(is_verified=True)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get buyer statistics"""
        user = request.user
        
        if not hasattr(user, 'buyer_profile'):
            return Response({'error': 'Not a buyer'}, status=status.HTTP_403_FORBIDDEN)
        
        buyer = user.buyer_profile
        
        # Calculate stats
        completed_orders = PickupRequest.objects.filter(
            buyer=buyer,
            status='completed'
        ).count()
        
        active_orders = PickupRequest.objects.filter(
            buyer=buyer,
            status__in=['pending', 'accepted', 'scheduled']
        ).count()
        
        # Calculate total waste purchased from completed pickups
        total_waste = PickupHistory.objects.filter(
            buyer_shop_name=buyer.shop_name
        ).aggregate(
            total=Sum('quantity')
        )['total'] or 0
        
        # Get average rating
        avg_rating = BuyerRating.objects.filter(
            buyer=buyer
        ).aggregate(
            avg=Avg('rating')
        )['avg'] or 0.0
        
        return Response({
            'completed_orders': completed_orders,
            'active_orders': active_orders,
            'total_waste_kg': round(total_waste, 2),
            'average_rating': round(avg_rating, 1),
            'total_ratings': BuyerRating.objects.filter(buyer=buyer).count()
        })
    
    @action(detail=True, methods=['get'])
    def ratings(self, request, pk=None):
        """Get ratings for a specific buyer"""
        buyer = self.get_object()
        ratings = BuyerRating.objects.filter(buyer=buyer)
        serializer = BuyerRatingSerializer(ratings, many=True)
        return Response(serializer.data)


# Pickup Request ViewSet
class PickupRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return PickupRequestCreateSerializer
        return PickupRequestSerializer
    
    def get_queryset(self):
        user = self.request.user
        
        # If user is a buyer, show requests for their shop
        if hasattr(user, 'buyer_profile'):
            return PickupRequest.objects.filter(buyer=user.buyer_profile)
        
        # Otherwise show user's own requests
        return PickupRequest.objects.filter(waste_report__user=user)
    
    def perform_create(self, serializer):
        user = self.request.user
        
        print(f"Pickup request from user: {user.username}")
        print(f"Has buyer_profile attr: {hasattr(user, 'buyer_profile')}")
        
        # Check if user has buyer profile
        if not hasattr(user, 'buyer_profile'):
            print(f"ERROR: User {user.username} does not have buyer_profile attribute")
            raise serializers.ValidationError({
                'error': 'Only buyers can send pickup requests. Please register as a buyer first.'
            })
        
        try:
            buyer_profile = user.buyer_profile
            print(f"Buyer profile found: {buyer_profile.shop_name} (ID: {buyer_profile.id})")
        except Exception as e:
            print(f"ERROR accessing buyer_profile: {e}")
            raise serializers.ValidationError({
                'error': f'Buyer profile not found: {str(e)}'
            })
        
        if not buyer_profile:
            print(f"ERROR: buyer_profile is None for user {user.username}")
            raise serializers.ValidationError({
                'error': 'Buyer profile not found. Please complete your buyer registration.'
            })
        
        pickup_request = serializer.save(buyer=buyer_profile)
        print(f"Pickup request created successfully: ID {pickup_request.id}")
        
        # Create notification for the waste report owner
        waste_owner = pickup_request.waste_report.user
        buyer_shop = buyer_profile.shop_name
        
        Notification.objects.create(
            user=waste_owner,
            notification_type='pickup_request',
            title='New Pickup Request',
            message=f'{buyer_shop} wants to collect your {pickup_request.waste_report.get_waste_type_display()} waste. Price offered: ₹{pickup_request.offered_price}',
            pickup_request=pickup_request,
            waste_report=pickup_request.waste_report
        )
        
        print(f"Notification created for user {waste_owner.username}")
    
    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        """Buyer accepts a pickup request"""
        pickup_request = self.get_object()
        
        if not hasattr(request.user, 'buyer_profile'):
            return Response({'error': 'Only buyers can accept requests'}, 
                          status=status.HTTP_403_FORBIDDEN)
        
        pickup_request.status = 'accepted'
        pickup_request.confirmed_pickup_date = request.data.get('confirmed_pickup_date')
        pickup_request.confirmed_pickup_time = request.data.get('confirmed_pickup_time')
        pickup_request.confirmed_pickup_address = request.data.get('confirmed_pickup_address')
        pickup_request.price_offer = request.data.get('price_offer')
        pickup_request.save()
        
        # Update waste report status
        pickup_request.waste_report.status = 'scheduled'
        pickup_request.waste_report.save()
        
        serializer = PickupRequestSerializer(pickup_request)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """User approves a pickup request and provides address"""
        pickup_request = self.get_object()
        
        # Check if user is the waste report owner
        if pickup_request.waste_report.user != request.user:
            return Response({'error': 'Only the waste owner can approve this request'}, 
                          status=status.HTTP_403_FORBIDDEN)
        
        # Check if already approved or rejected
        if pickup_request.status not in ['pending']:
            return Response({'error': 'Request already processed'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Get address from request
        confirmed_address = request.data.get('confirmed_pickup_address')
        if not confirmed_address:
            return Response({'error': 'Please provide pickup address'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Update pickup request
        pickup_request.status = 'accepted'
        pickup_request.confirmed_pickup_address = confirmed_address
        pickup_request.confirmed_pickup_time = request.data.get('confirmed_pickup_time')
        pickup_request.confirmed_pickup_date = request.data.get('confirmed_pickup_date')
        pickup_request.save()
        
        # Update waste report status
        pickup_request.waste_report.status = 'scheduled'
        pickup_request.waste_report.save()
        
        # Create notification for buyer
        Notification.objects.create(
            user=pickup_request.buyer.user,
            notification_type='request_accepted',
            title='Pickup Request Approved',
            message=f'Your pickup request for {pickup_request.waste_report.get_waste_type_display()} waste has been approved. Address: {confirmed_address}',
            pickup_request=pickup_request,
            waste_report=pickup_request.waste_report
        )
        
        serializer = PickupRequestSerializer(pickup_request)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """User rejects a pickup request"""
        pickup_request = self.get_object()
        
        # Check if user is the waste report owner
        if pickup_request.waste_report.user != request.user:
            return Response({'error': 'Only the waste owner can reject this request'}, 
                          status=status.HTTP_403_FORBIDDEN)
        
        # Check if already approved or rejected
        if pickup_request.status not in ['pending']:
            return Response({'error': 'Request already processed'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Update pickup request
        pickup_request.status = 'rejected'
        pickup_request.save()
        
        # Create notification for buyer
        Notification.objects.create(
            user=pickup_request.buyer.user,
            notification_type='request_rejected',
            title='Pickup Request Rejected',
            message=f'Your pickup request for {pickup_request.waste_report.get_waste_type_display()} waste has been rejected.',
            pickup_request=pickup_request,
            waste_report=pickup_request.waste_report
        )
        
        serializer = PickupRequestSerializer(pickup_request)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark pickup as completed"""
        pickup_request = self.get_object()
        
        pickup_request.status = 'completed'
        pickup_request.save()
        
        # Update waste report status
        pickup_request.waste_report.status = 'completed'
        pickup_request.waste_report.save()
        
        # Create pickup history entry
        PickupHistory.objects.create(
            user=pickup_request.waste_report.user,
            user_username=pickup_request.waste_report.user.username,
            buyer_shop_name=pickup_request.buyer.shop_name,
            waste_type=pickup_request.waste_report.get_waste_type_display(),
            quantity=pickup_request.waste_report.quantity_display,
            location=pickup_request.confirmed_pickup_address or pickup_request.waste_report.full_address,
            offered_price=pickup_request.price_offer,
            reported_at=pickup_request.waste_report.created_at,
            scheduled_at=pickup_request.confirmed_pickup_time or pickup_request.created_at,
            completed_at=timezone.now(),
            pickup_request=pickup_request
        )
        
        # Create notification for user
        Notification.objects.create(
            user=pickup_request.waste_report.user,
            notification_type='pickup_completed',
            title='Pickup Completed',
            message=f'Pickup by {pickup_request.buyer.shop_name} has been completed.',
            pickup_request=pickup_request,
            waste_report=pickup_request.waste_report
        )
        
        serializer = PickupRequestSerializer(pickup_request)
        return Response(serializer.data)


# Buyer Rating ViewSet
class BuyerRatingViewSet(viewsets.ModelViewSet):
    serializer_class = BuyerRatingSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return BuyerRating.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# Pickup History ViewSet
class PickupHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PickupHistorySerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        # If user is a buyer, show pickups where their shop was involved
        if hasattr(user, 'buyer_profile'):
            buyer_shop = user.buyer_profile.shop_name
            return PickupHistory.objects.filter(buyer_shop_name=buyer_shop)
        
        # Otherwise show user's own history
        return PickupHistory.objects.filter(user=user)


# Notification ViewSet
class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a notification as read"""
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        serializer = NotificationSerializer(notification)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read"""
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'message': 'All notifications marked as read'})
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get count of unread notifications"""
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})
