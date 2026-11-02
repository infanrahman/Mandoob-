class CompanyModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String vatNumber; // 15 digits starting and ending with 3
  final String crNumber; // 10 digits
  final String buildingNumber;
  final String street;
  final String district;
  final String city;
  final String postalCode;
  final String phone;
  final String email;
  final String? bankName;
  final String? iban;
  final String? logoUrl;
  final String createdBySuperAdminId;
  final DateTime createdAt;
  final bool isZatcaPhase2Enabled;
  final bool isActive;

  CompanyModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.vatNumber,
    required this.crNumber,
    required this.buildingNumber,
    required this.street,
    required this.district,
    required this.city,
    required this.postalCode,
    required this.phone,
    required this.email,
    this.bankName,
    this.iban,
    this.logoUrl,
    required this.createdBySuperAdminId,
    required this.createdAt,
    this.isZatcaPhase2Enabled = true,
    this.isActive = true,
  });

  CompanyModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? vatNumber,
    String? crNumber,
    String? buildingNumber,
    String? street,
    String? district,
    String? city,
    String? postalCode,
    String? phone,
    String? email,
    String? bankName,
    String? iban,
    String? logoUrl,
    String? createdBySuperAdminId,
    DateTime? createdAt,
    bool? isZatcaPhase2Enabled,
    bool? isActive,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      vatNumber: vatNumber ?? this.vatNumber,
      crNumber: crNumber ?? this.crNumber,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      street: street ?? this.street,
      district: district ?? this.district,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bankName: bankName ?? this.bankName,
      iban: iban ?? this.iban,
      logoUrl: logoUrl ?? this.logoUrl,
      createdBySuperAdminId: createdBySuperAdminId ?? this.createdBySuperAdminId,
      createdAt: createdAt ?? this.createdAt,
      isZatcaPhase2Enabled: isZatcaPhase2Enabled ?? this.isZatcaPhase2Enabled,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'vatNumber': vatNumber,
    'crNumber': crNumber,
    'buildingNumber': buildingNumber,
    'street': street,
    'district': district,
    'city': city,
    'postalCode': postalCode,
    'phone': phone,
    'email': email,
    'bankName': bankName,
    'iban': iban,
    'logoUrl': logoUrl,
    'createdBySuperAdminId': createdBySuperAdminId,
    'createdAt': createdAt.toIso8601String(),
    'isZatcaPhase2Enabled': isZatcaPhase2Enabled,
    'isActive': isActive,
  };

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    id: json['id'] as String,
    nameAr: json['nameAr'] as String? ?? '',
    nameEn: json['nameEn'] as String? ?? '',
    vatNumber: json['vatNumber'] as String? ?? '',
    crNumber: json['crNumber'] as String? ?? '',
    buildingNumber: json['buildingNumber'] as String? ?? '',
    street: json['street'] as String? ?? '',
    district: json['district'] as String? ?? '',
    city: json['city'] as String? ?? '',
    postalCode: json['postalCode'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    bankName: json['bankName'] as String?,
    iban: json['iban'] as String?,
    logoUrl: json['logoUrl'] as String?,
    createdBySuperAdminId: json['createdBySuperAdminId'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    isZatcaPhase2Enabled: json['isZatcaPhase2Enabled'] as bool? ?? true,
    isActive: json['isActive'] as bool? ?? true,
  );
}
