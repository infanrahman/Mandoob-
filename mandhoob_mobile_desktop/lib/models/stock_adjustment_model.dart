enum AdjustmentReason {
  physicalCount, // جرد دوري فعلي
  damaged,       // تالف
  expired,       // منتهي الصلاحية
  missing,       // عجز / مفقود
  sample,        // عينات وهدايا
  other,         // أخرى
}

class StockAdjustmentModel {
  final String id;
  final String adjustmentNumber;
  final DateTime date;
  final String productId;
  final String productNameAr;
  final String productNameEn;
  final String warehouseId;
  final String warehouseName;
  final double previousQuantity;
  final double newQuantity;
  final double differenceQuantity;
  final AdjustmentReason reason;
  final String? notes;
  final String adjustedByUserId;
  final String adjustedByUserName;

  StockAdjustmentModel({
    required this.id,
    required this.adjustmentNumber,
    required this.date,
    required this.productId,
    required this.productNameAr,
    required this.productNameEn,
    required this.warehouseId,
    required this.warehouseName,
    required this.previousQuantity,
    required this.newQuantity,
    required this.differenceQuantity,
    required this.reason,
    this.notes,
    required this.adjustedByUserId,
    required this.adjustedByUserName,
  });

  String reasonDisplayName(bool isArabic) {
    switch (reason) {
      case AdjustmentReason.physicalCount:
        return isArabic ? 'جرد فعلي دوري' : 'Physical Stock Audit';
      case AdjustmentReason.damaged:
        return isArabic ? 'تالف ومكسور' : 'Damaged / Broken';
      case AdjustmentReason.expired:
        return isArabic ? 'منتهي الصلاحية' : 'Expired Stock';
      case AdjustmentReason.missing:
        return isArabic ? 'عجز في المستودع' : 'Missing / Shrinkage';
      case AdjustmentReason.sample:
        return isArabic ? 'عينات تسويقية' : 'Marketing Sample';
      case AdjustmentReason.other:
        return isArabic ? 'تسوية يدوية أخرى' : 'Other Adjustment';
    }
  }
}
