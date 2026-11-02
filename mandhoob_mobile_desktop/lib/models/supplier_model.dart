class SupplierModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String phone;
  final String? email;
  final String? vatNumber; // 15 digits
  final String? crNumber;
  final String? city;
  final double creditLimit; // سقف الائتمان الممنوح لنا
  final int creditPeriodDays; // فترة السداد بالأيام (e.g. 45 days)
  final double openingBalance;
  final double currentBalance; // Positive means we owe supplier (Payable)

  SupplierModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.phone,
    this.email,
    this.vatNumber,
    this.crNumber,
    this.city = 'الرياض - Riyadh',
    this.creditLimit = 50000.0,
    this.creditPeriodDays = 45,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
  });

  double get availableCredit => (creditLimit - currentBalance).clamp(0.0, creditLimit);

  double get creditUtilizationRatio {
    if (creditLimit <= 0) return 0.0;
    return (currentBalance / creditLimit).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'phone': phone,
      'email': email,
      'vatNumber': vatNumber,
      'crNumber': crNumber,
      'city': city,
      'creditLimit': creditLimit,
      'creditPeriodDays': creditPeriodDays,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
    };
  }

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String? ?? 'SUPP-${DateTime.now().millisecondsSinceEpoch}',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      vatNumber: json['vatNumber'] as String?,
      crNumber: json['crNumber'] as String?,
      city: json['city'] as String? ?? 'الرياض - Riyadh',
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 50000.0,
      creditPeriodDays: (json['creditPeriodDays'] as num?)?.toInt() ?? 45,
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
