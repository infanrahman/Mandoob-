import 'stock_transfer_model.dart';

class PurchaseBillModel {
  final String id;
  final String billNumber;
  final String supplierId;
  final String supplierNameAr;
  final String supplierNameEn;
  final String warehouseId;
  final String warehouseName;
  final DateTime date;
  final List<StockTransferItem> items;
  final double subtotal;
  final double vatAmount;
  final double grandTotal;
  final String paymentMode;
  final String createdByUserId;
  final String createdByUserName;
  final String? notes;

  PurchaseBillModel({
    required this.id,
    required this.billNumber,
    required this.supplierId,
    required this.supplierNameAr,
    required this.supplierNameEn,
    required this.warehouseId,
    required this.warehouseName,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.grandTotal,
    required this.paymentMode,
    required this.createdByUserId,
    required this.createdByUserName,
    this.notes,
  });

  bool get isCredit =>
      paymentMode.toLowerCase().contains('credit') ||
      paymentMode.contains('آجل');

  Map<String, dynamic> toJson() => {
    'id': id,
    'billNumber': billNumber,
    'supplierId': supplierId,
    'supplierNameAr': supplierNameAr,
    'supplierNameEn': supplierNameEn,
    'warehouseId': warehouseId,
    'warehouseName': warehouseName,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'vatAmount': vatAmount,
    'grandTotal': grandTotal,
    'paymentMode': paymentMode,
    'createdByUserId': createdByUserId,
    'createdByUserName': createdByUserName,
    'notes': notes,
  };

  factory PurchaseBillModel.fromJson(Map<String, dynamic> json) => PurchaseBillModel(
    id: json['id'] as String,
    billNumber: json['billNumber'] as String? ?? 'PUR-000',
    supplierId: json['supplierId'] as String? ?? '',
    supplierNameAr: json['supplierNameAr'] as String? ?? '',
    supplierNameEn: json['supplierNameEn'] as String? ?? '',
    warehouseId: json['warehouseId'] as String? ?? '',
    warehouseName: json['warehouseName'] as String? ?? '',
    date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
    items: (json['items'] as List<dynamic>?)
            ?.map((i) => StockTransferItem.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [],
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0.0,
    grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
    paymentMode: json['paymentMode'] as String? ?? 'Cash',
    createdByUserId: json['createdByUserId'] as String? ?? '',
    createdByUserName: json['createdByUserName'] as String? ?? '',
    notes: json['notes'] as String?,
  );
}
