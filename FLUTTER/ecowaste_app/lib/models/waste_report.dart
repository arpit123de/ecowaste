class WasteReport {
  final int? id;
  final String? name;
  final String mobileNumber;
  final String? email;
  final String wasteType;
  final String? wasteTypeOther;
  final String quantityType;
  final double? exactQuantity;
  final String wasteCondition;
  final String? imagePath;
  final bool locationAuto;
  final String? latitude;
  final String? longitude;
  final String? area;
  final String? city;
  final String? state;
  final String? landmark;
  final String? fullAddress;
  final String? additionalNotes;
  final String status;
  final DateTime? createdAt;
  final String? wasteTypeDisplay;
  final String? statusDisplay;

  WasteReport({
    this.id,
    this.name,
    required this.mobileNumber,
    this.email,
    required this.wasteType,
    this.wasteTypeOther,
    required this.quantityType,
    this.exactQuantity,
    required this.wasteCondition,
    this.imagePath,
    this.locationAuto = false,
    this.latitude,
    this.longitude,
    this.area,
    this.city,
    this.state,
    this.landmark,
    this.fullAddress,
    this.additionalNotes,
    this.status = 'pending',
    this.createdAt,
    this.wasteTypeDisplay,
    this.statusDisplay,
  });

  factory WasteReport.fromJson(Map<String, dynamic> json) {
    return WasteReport(
      id: json['id'],
      name: json['name'],
      mobileNumber: json['mobile_number'] ?? '',
      email: json['email'],
      wasteType: json['waste_type'] ?? '',
      wasteTypeOther: json['waste_type_other'],
      quantityType: json['quantity_type'] ?? '',
      exactQuantity: json['exact_quantity']?.toDouble(),
      wasteCondition: json['waste_condition'] ?? '',
      imagePath: json['image'],
      locationAuto: json['location_auto'] ?? false,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      area: json['area'],
      city: json['city'],
      state: json['state'],
      landmark: json['landmark'],
      fullAddress: json['full_address'],
      additionalNotes: json['additional_notes'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      wasteTypeDisplay: json['waste_type_display'],
      statusDisplay: json['status_display'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'mobile_number': mobileNumber,
      if (email != null) 'email': email,
      'waste_type': wasteType,
      if (wasteTypeOther != null) 'waste_type_other': wasteTypeOther,
      'quantity_type': quantityType,
      if (exactQuantity != null) 'exact_quantity': exactQuantity.toString(),
      'waste_condition': wasteCondition,
      'location_auto': locationAuto.toString(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (area != null) 'area': area,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (landmark != null) 'landmark': landmark,
      if (fullAddress != null) 'full_address': fullAddress,
      if (additionalNotes != null) 'additional_notes': additionalNotes,
    };
  }

  String get quantityDisplay {
    if (exactQuantity != null) {
      return '${exactQuantity!.toStringAsFixed(1)} kg';
    }
    return quantityType.toLowerCase();
  }
}
