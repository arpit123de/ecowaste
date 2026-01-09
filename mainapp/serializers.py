from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Task, Note, WasteReport, Buyer, PickupRequest, BuyerRating, PickupHistory, Notification


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    password2 = serializers.CharField(write_only=True, min_length=8)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2', 'first_name', 'last_name']
    
    def validate(self, data):
        if data['password'] != data['password2']:
            raise serializers.ValidationError("Passwords don't match")
        return data
    
    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user


class TaskSerializer(serializers.ModelSerializer):
    created_by_username = serializers.ReadOnlyField(source='created_by.username')
    
    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'status', 'created_by', 
                  'created_by_username', 'created_at', 'updated_at', 'due_date']
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']


class NoteSerializer(serializers.ModelSerializer):
    author_username = serializers.ReadOnlyField(source='author.username')
    
    class Meta:
        model = Note
        fields = ['id', 'title', 'content', 'author', 'author_username', 
                  'created_at', 'updated_at']
        read_only_fields = ['id', 'author', 'created_at', 'updated_at']


class WasteReportSerializer(serializers.ModelSerializer):
    user_username = serializers.ReadOnlyField(source='user.username')
    waste_type_display = serializers.ReadOnlyField(source='get_waste_type_display')
    quantity_type_display = serializers.ReadOnlyField(source='get_quantity_type_display')
    waste_condition_display = serializers.ReadOnlyField(source='get_waste_condition_display')
    status_display = serializers.ReadOnlyField(source='get_status_display')
    location_display = serializers.ReadOnlyField()
    
    class Meta:
        model = WasteReport
        fields = ['id', 'user', 'user_username', 'name', 'mobile_number', 'email',
                  'waste_type', 'waste_type_display', 'waste_type_other',
                  'quantity_type', 'quantity_type_display', 'exact_quantity',
                  'waste_condition', 'waste_condition_display',
                  'image', 'location_auto', 'latitude', 'longitude',
                  'area', 'city', 'state', 'landmark', 'full_address',
                  'additional_notes', 'status', 'status_display',
                  'location_display', 'created_at', 'updated_at',
                  'ai_classification', 'estimated_weight_kg', 'material_breakdown',
                  'recyclability_score', 'disposal_recommendations']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']


class WasteReportCreateSerializer(serializers.ModelSerializer):
    """Separate serializer for creating waste reports with image upload"""
    
    class Meta:
        model = WasteReport
        fields = ['name', 'mobile_number', 'email', 'waste_type', 'waste_type_other',
                  'quantity_type', 'exact_quantity', 'waste_condition', 'image',
                  'location_auto', 'latitude', 'longitude', 'area', 'city', 'state',
                  'landmark', 'full_address', 'additional_notes']


class BuyerSerializer(serializers.ModelSerializer):
    user_username = serializers.ReadOnlyField(source='user.username')
    average_rating = serializers.ReadOnlyField()
    total_ratings = serializers.ReadOnlyField()
    
    class Meta:
        model = Buyer
        fields = ['id', 'user', 'user_username', 'shop_name', 'contact_number',
                  'email', 'address', 'city', 'state', 'pincode',
                  'waste_types_accepted', 'trade_license', 'shop_photo',
                  'is_verified', 'created_at', 'updated_at',
                  'average_rating', 'total_ratings']
        read_only_fields = ['id', 'user', 'is_verified', 'created_at', 'updated_at']


class PickupRequestSerializer(serializers.ModelSerializer):
    waste_report_details = WasteReportSerializer(source='waste_report', read_only=True)
    buyer_details = BuyerSerializer(source='buyer', read_only=True)
    status_display = serializers.ReadOnlyField(source='get_status_display')
    
    class Meta:
        model = PickupRequest
        fields = ['id', 'waste_report', 'waste_report_details', 'buyer', 'buyer_details',
                  'status', 'status_display', 'requested_pickup_date', 'requested_pickup_time',
                  'message', 'confirmed_pickup_date', 'confirmed_pickup_time',
                  'confirmed_pickup_address', 'price_offer', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class PickupRequestCreateSerializer(serializers.ModelSerializer):
    """Separate serializer for creating pickup requests"""
    
    class Meta:
        model = PickupRequest
        fields = ['waste_report', 'offered_price', 'proposed_time_slot_1', 'proposed_time_slot_2', 'proposed_time_slot_3', 'message']


class BuyerRatingSerializer(serializers.ModelSerializer):
    user_username = serializers.ReadOnlyField(source='user.username')
    buyer_shop_name = serializers.ReadOnlyField(source='buyer.shop_name')
    
    class Meta:
        model = BuyerRating
        fields = ['id', 'user', 'user_username', 'buyer', 'buyer_shop_name',
                  'pickup_request', 'rating', 'review', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class PickupHistorySerializer(serializers.ModelSerializer):
    waste_report_details = WasteReportSerializer(source='waste_report', read_only=True)
    buyer_details = BuyerSerializer(source='buyer', read_only=True)
    user_username = serializers.ReadOnlyField(source='user.username')
    
    class Meta:
        model = PickupHistory
        fields = ['id', 'user', 'user_username', 'waste_report', 'waste_report_details',
                  'buyer', 'buyer_details', 'pickup_date', 'pickup_time',
                  'pickup_address', 'price_paid', 'notes', 'created_at']
        read_only_fields = ['id', 'created_at']


class NotificationSerializer(serializers.ModelSerializer):
    pickup_request_details = PickupRequestSerializer(source='pickup_request', read_only=True)
    waste_report_details = WasteReportSerializer(source='waste_report', read_only=True)
    notification_type_display = serializers.ReadOnlyField(source='get_notification_type_display')
    
    class Meta:
        model = Notification
        fields = ['id', 'user', 'notification_type', 'notification_type_display',
                  'title', 'message', 'is_read', 'created_at',
                  'pickup_request', 'pickup_request_details',
                  'waste_report', 'waste_report_details']
        read_only_fields = ['id', 'user', 'created_at']
