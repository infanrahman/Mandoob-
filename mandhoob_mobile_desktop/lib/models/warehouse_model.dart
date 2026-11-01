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
}
