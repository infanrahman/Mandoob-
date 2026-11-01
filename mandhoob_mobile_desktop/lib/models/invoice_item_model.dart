class InvoiceItemModel {
  final String productId;
  final String productNameAr;
  final String productNameEn;
  final String barcode;
  final double quantity;
  final String unit; // حبة أو كرتون
  final double unitPrice; // Price before VAT
  final double discount;
  final double vatRatePercent; // Default 15%

  InvoiceItemModel({
    required this.productId,
    required this.productNameAr,
    required this.productNameEn,
    required this.barcode,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.discount = 0.0,
    this.vatRatePercent = 15.0,
  });

  double get lineSubtotal => (quantity * unitPrice) - discount;
  double get lineVatAmount => lineSubtotal * (vatRatePercent / 100.0);
  double get lineTotalWithVat => lineSubtotal + lineVatAmount;
}
