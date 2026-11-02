class CustomerModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String phone;
  final String? email;
  final String? vatNumber; // 15 digits (starts & ends with 3)
  final String? crNumber; // Commercial Registration
  final String? buildingNumber;
  final String? street;
  final String? district;
  final String? city;
  final String? postalCode;
  final String? routeArea; // Van distribution route
  final double creditLimit; // سقف الائتمان
  final int creditPeriodDays; // فترة الائتمان المسموح بها (أيام)
  final double openingBalance; // رصيد بداية المدة
  final double currentBalance; // Positive means customer owes us (Receivable)
  final double? latitude;
  final double? longitude;

  CustomerModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.phone,
    this.email,
    this.vatNumber,
    this.crNumber,
    this.buildingNumber,
    this.street,
    this.district,
    this.city = 'الرياض - Riyadh',
    this.postalCode,
    this.routeArea = 'المسار العام - General Route',
    this.creditLimit = 15000.0,
    this.creditPeriodDays = 30,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.latitude,
    this.longitude,
  });

  bool get isVatRegistered => vatNumber != null && vatNumber!.trim().length == 15;

  double get availableCredit => (creditLimit - currentBalance).clamp(0.0, creditLimit);

  double get creditUtilizationRatio {
    if (creditLimit <= 0) return 1.0;
    return (currentBalance / creditLimit).clamp(0.0, 1.0);
  }

  bool isCreditExceeded(double newSaleAmount) {
    if (creditLimit <= 0) return false;
    return (currentBalance + newSaleAmount) > creditLimit;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'phone': phone,
    'email': email,
    'vatNumber': vatNumber,
    'crNumber': crNumber,
    'buildingNumber': buildingNumber,
    'street': street,
    'district': district,
    'city': city,
    'postalCode': postalCode,
    'routeArea': routeArea,
    'creditLimit': creditLimit,
    'creditPeriodDays': creditPeriodDays,
    'openingBalance': openingBalance,
    'currentBalance': currentBalance,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    id: json['id'] as String,
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String?,
    vatNumber: json['vatNumber'] as String?,
    crNumber: json['crNumber'] as String?,
    buildingNumber: json['buildingNumber'] as String?,
    street: json['street'] as String?,
    district: json['district'] as String?,
    city: json['city'] as String? ?? 'الرياض - Riyadh',
    postalCode: json['postalCode'] as String?,
    routeArea: json['routeArea'] as String? ?? 'المسار العام - General Route',
    creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 15000.0,
    creditPeriodDays: (json['creditPeriodDays'] as num?)?.toInt() ?? 30,
    openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
    currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}
