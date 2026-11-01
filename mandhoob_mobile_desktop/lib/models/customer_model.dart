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
}
