enum WarehouseType {
  mainWarehouse,
  vanWarehouse,
}

class WarehouseModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final WarehouseType type;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? vehiclePlateNumber;

  WarehouseModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    this.assignedDriverId,
    this.assignedDriverName,
    this.vehiclePlateNumber,
  });

  bool get isVan => type == WarehouseType.vanWarehouse;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'type': type.name,
    'assignedDriverId': assignedDriverId,
    'assignedDriverName': assignedDriverName,
    'vehiclePlateNumber': vehiclePlateNumber,
  };

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => WarehouseModel(
    id: json['id'] as String,
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    type: WarehouseType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => WarehouseType.mainWarehouse,
    ),
    assignedDriverId: json['assignedDriverId'] as String?,
    assignedDriverName: json['assignedDriverName'] as String?,
    vehiclePlateNumber: json['vehiclePlateNumber'] as String?,
  );
}
