class Buyer {
  final int id;
  final String shopName;
  final String contactNumber;
  final String? email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final List<String> wasteTypesAccepted;
  final String? shopPhoto;
  final bool isVerified;
  final double? averageRating;
  final int? totalRatings;

  Buyer({
    required this.id,
    required this.shopName,
    required this.contactNumber,
    this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.wasteTypesAccepted,
    this.shopPhoto,
    this.isVerified = false,
    this.averageRating,
    this.totalRatings,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: json['id'],
      shopName: json['shop_name'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      email: json['email'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      wasteTypesAccepted: json['waste_types_accepted'] != null
          ? List<String>.from(json['waste_types_accepted'])
          : [],
      shopPhoto: json['shop_photo'],
      isVerified: json['is_verified'] ?? false,
      averageRating: json['average_rating']?.toDouble(),
      totalRatings: json['total_ratings'],
    );
  }
}
