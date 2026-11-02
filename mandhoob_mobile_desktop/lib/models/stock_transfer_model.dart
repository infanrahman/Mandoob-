enum TransferStatus {
  pending,
  approved,
  loaded,
  received,
  rejected,
}

class StockTransferItem {
  final String productId;
  final String productName;
  final double quantity;
  final String unit;

  StockTransferItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unit': unit,
  };

  factory StockTransferItem.fromJson(Map<String, dynamic> json) => StockTransferItem(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
  );
}

class StockTransferModel {
  final String id;
  final String transferNumber;
  final String fromWarehouseId;
  final String fromWarehouseName;
  final String toVanId;
  final String toVanName;
  final String requestedByUserId;
  final String requestedByUserName;
  final DateTime date;
  final List<StockTransferItem> items;
  final TransferStatus status;
  final String? notes;

  StockTransferModel({
    required this.id,
    required this.transferNumber,
    required this.fromWarehouseId,
    required this.fromWarehouseName,
    required this.toVanId,
    required this.toVanName,
    required this.requestedByUserId,
    required this.requestedByUserName,
    required this.date,
    required this.items,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'transferNumber': transferNumber,
    'fromWarehouseId': fromWarehouseId,
    'fromWarehouseName': fromWarehouseName,
    'toVanId': toVanId,
    'toVanName': toVanName,
    'requestedByUserId': requestedByUserId,
    'requestedByUserName': requestedByUserName,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'status': status.name,
    'notes': notes,
  };

  factory StockTransferModel.fromJson(Map<String, dynamic> json) => StockTransferModel(
    id: json['id'] as String,
    transferNumber: json['transferNumber'] as String,
    fromWarehouseId: json['fromWarehouseId'] as String,
    fromWarehouseName: json['fromWarehouseName'] as String,
    toVanId: json['toVanId'] as String,
    toVanName: json['toVanName'] as String,
    requestedByUserId: json['requestedByUserId'] as String,
    requestedByUserName: json['requestedByUserName'] as String,
    date: DateTime.parse(json['date'] as String),
    items: (json['items'] as List<dynamic>)
        .map((i) => StockTransferItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    status: TransferStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => TransferStatus.loaded,
    ),
    notes: json['notes'] as String?,
  );
}
