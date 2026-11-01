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
}
