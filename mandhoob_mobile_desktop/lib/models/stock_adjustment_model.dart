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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adjustmentNumber': adjustmentNumber,
      'date': date.toIso8601String(),
      'productId': productId,
      'productNameAr': productNameAr,
      'productNameEn': productNameEn,
      'warehouseId': warehouseId,
      'warehouseName': warehouseName,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'differenceQuantity': differenceQuantity,
      'reason': reason.name,
      'notes': notes,
      'adjustedByUserId': adjustedByUserId,
      'adjustedByUserName': adjustedByUserName,
    };
  }

  factory StockAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentModel(
      id: json['id'] as String,
      adjustmentNumber: json['adjustmentNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      productId: json['productId'] as String,
      productNameAr: json['productNameAr'] as String,
      productNameEn: json['productNameEn'] as String,
      warehouseId: json['warehouseId'] as String,
      warehouseName: json['warehouseName'] as String,
      previousQuantity: (json['previousQuantity'] as num).toDouble(),
      newQuantity: (json['newQuantity'] as num).toDouble(),
      differenceQuantity: (json['differenceQuantity'] as num).toDouble(),
      reason: AdjustmentReason.values.firstWhere(
        (r) => r.name == json['reason'],
        orElse: () => AdjustmentReason.physicalCount,
      ),
      notes: json['notes'] as String?,
      adjustedByUserId: json['adjustedByUserId'] as String,
      adjustedByUserName: json['adjustedByUserName'] as String,
    );
  }
}
