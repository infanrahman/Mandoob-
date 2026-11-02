class ProductModel {
  final String id;
  final String sku;
  final String barcode;
  final String nameAr;
  final String nameEn;
  final String category;
  final String baseUnit; // حبة - Piece
  final String? secondaryUnit; // كرتون - Carton
  final double conversionFactor; // E.g., 24 (1 carton = 24 pieces)
  final double costPrice;
  final double wholesalePrice;
  final double retailPrice;
  final double vatRatePercent; // 15%
  final double minStockAlert;
  final Map<String, double> stockByWarehouse; // warehouseId -> quantity in base unit
  final String? batchNumber;
  final DateTime? expiryDate;

  ProductModel({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.baseUnit,
    this.secondaryUnit,
    this.conversionFactor = 1.0,
    required this.costPrice,
    required this.wholesalePrice,
    required this.retailPrice,
    this.vatRatePercent = 15.0,
    this.minStockAlert = 10.0,
    required this.stockByWarehouse,
    this.batchNumber,
    this.expiryDate,
  });

  double getTotalStock() {
    return stockByWarehouse.values.fold(0.0, (sum, qty) => sum + qty);
  }

  double getStockFor(String warehouseId) {
    return stockByWarehouse[warehouseId] ?? 0.0;
  }

  bool isLowStock(String warehouseId) {
    return getStockFor(warehouseId) <= minStockAlert;
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysRemaining = expiryDate!.difference(DateTime.now()).inDays;
    return daysRemaining <= 30; // Expiring within 30 days
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'category': category,
      'baseUnit': baseUnit,
      'secondaryUnit': secondaryUnit,
      'conversionFactor': conversionFactor,
      'costPrice': costPrice,
      'wholesalePrice': wholesalePrice,
      'retailPrice': retailPrice,
      'vatRatePercent': vatRatePercent,
      'minStockAlert': minStockAlert,
      'stockByWarehouse': stockByWarehouse,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawStock = json['stockByWarehouse'];
    final Map<String, double> parsedStock = {};
    if (rawStock is Map) {
      rawStock.forEach((k, v) {
        parsedStock[k.toString()] = (v as num).toDouble();
      });
    }

    return ProductModel(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      category: json['category'] as String? ?? 'عام - General',
      baseUnit: json['baseUnit'] as String? ?? 'حبة',
      secondaryUnit: json['secondaryUnit'] as String?,
      conversionFactor: (json['conversionFactor'] as num?)?.toDouble() ?? 1.0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      retailPrice: (json['retailPrice'] as num?)?.toDouble() ?? 0.0,
      vatRatePercent: (json['vatRatePercent'] as num?)?.toDouble() ?? 15.0,
      minStockAlert: (json['minStockAlert'] as num?)?.toDouble() ?? 10.0,
      stockByWarehouse: parsedStock,
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'] as String) : null,
    );
  }
}
