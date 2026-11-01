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
}
