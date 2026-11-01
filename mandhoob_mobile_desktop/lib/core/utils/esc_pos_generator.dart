import 'dart:convert';
import 'dart:typed_data';

/// ESC/POS Thermal Receipt Byte Protocol Generator for Van Sales Bluetooth/Wi-Fi Printers
class EscPosGenerator {
  // ESC/POS Command Constants
  static const int esc = 0x1B;
  static const int gs = 0x1D;

  /// Generate a complete printable byte array for 58mm or 80mm thermal printers
  static Uint8List buildVanSalesReceipt({
    required String companyName,
    required String vatNumber,
    required String crNumber,
    required String invoiceNumber,
    required DateTime date,
    required String salesmanName,
    required String vanId,
    required String customerName,
    required String? customerVat,
    required List<ReceiptItem> items,
    required double subtotal,
    required double vatTotal,
    required double discount,
    required double grandTotal,
    required String paymentMode,
    required String qrBase64,
    bool is80mm = false,
  }) {
    final List<int> bytes = [];

    // Initialize printer
    bytes.addAll([esc, 0x40]); // ESC @ (Initialize)

    // Alignment: Center
    bytes.addAll([esc, 0x61, 0x01]);

    // Bold ON, Double Height/Width for Company Title
    bytes.addAll([esc, 0x45, 0x01]); // Bold on
    bytes.addAll([gs, 0x21, 0x11]); // Double height & width
    bytes.addAll(utf8.encode('$companyName\n'));

    // Reset font size
    bytes.addAll([gs, 0x21, 0x00]);
    bytes.addAll(utf8.encode('Tax Invoice / فاتورة ضريبية مبسطة\n'));
    bytes.addAll(utf8.encode('CR: $crNumber | VAT: $vatNumber\n'));
    bytes.addAll(utf8.encode('--------------------------------\n'));

    // Alignment: Left
    bytes.addAll([esc, 0x61, 0x00]);
    bytes.addAll([esc, 0x45, 0x00]); // Bold off

    bytes.addAll(utf8.encode('Inv #: $invoiceNumber\n'));
    bytes.addAll(utf8.encode('Date: ${date.toLocal().toString().substring(0, 19)}\n'));
    bytes.addAll(utf8.encode('Van / Rep: $vanId - $salesmanName\n'));
    bytes.addAll(utf8.encode('Customer: $customerName\n'));
    if (customerVat != null && customerVat.isNotEmpty) {
      bytes.addAll(utf8.encode('Customer VAT: $customerVat\n'));
    }
    bytes.addAll(utf8.encode('--------------------------------\n'));

    // Table Header
    bytes.addAll([esc, 0x45, 0x01]); // Bold
    if (is80mm) {
      bytes.addAll(utf8.encode('Item Name              Qty  Price    Total\n'));
    } else {
      bytes.addAll(utf8.encode('Item           Qty  Price  Total\n'));
    }
    bytes.addAll([esc, 0x45, 0x00]); // Bold off
    bytes.addAll(utf8.encode('--------------------------------\n'));

    // Items
    for (final item in items) {
      final name = item.name.length > 14 ? item.name.substring(0, 14) : item.name.padRight(14);
      final qty = item.qty.toStringAsFixed(item.qty.truncateToDouble() == item.qty ? 0 : 2).padLeft(4);
      final price = item.price.toStringAsFixed(2).padLeft(6);
      final total = (item.qty * item.price).toStringAsFixed(2).padLeft(6);
      bytes.addAll(utf8.encode('$name $qty $price $total\n'));
    }

    bytes.addAll(utf8.encode('--------------------------------\n'));

    // Totals Section (Right-aligned or indented)
    bytes.addAll([esc, 0x61, 0x02]); // Align Right
    bytes.addAll(utf8.encode('Subtotal (قبل الضريبة): ${subtotal.toStringAsFixed(2)} SAR\n'));
    if (discount > 0) {
      bytes.addAll(utf8.encode('Discount (الخصم): ${discount.toStringAsFixed(2)} SAR\n'));
    }
    bytes.addAll(utf8.encode('VAT 15% (ضريبة القيمة المضافة): ${vatTotal.toStringAsFixed(2)} SAR\n'));

    bytes.addAll([esc, 0x45, 0x01]); // Bold
    bytes.addAll([gs, 0x21, 0x01]); // Double height
    bytes.addAll(utf8.encode('Grand Total (الإجمالي): ${grandTotal.toStringAsFixed(2)} SAR\n'));
    bytes.addAll([gs, 0x21, 0x00]); // Normal size
    bytes.addAll([esc, 0x45, 0x00]); // Bold off

    bytes.addAll(utf8.encode('Payment (طريقة الدفع): $paymentMode\n\n'));

    // Center Align for ZATCA QR Code
    bytes.addAll([esc, 0x61, 0x01]);
    bytes.addAll(utf8.encode('ZATCA E-Invoice QR Code\n'));

    // Feed lines & Paper Cut
    bytes.addAll([0x0A, 0x0A, 0x0A]); // New lines
    bytes.addAll([gs, 0x56, 0x42, 0x00]); // GS V 66 0 (Cut paper)

    return Uint8List.fromList(bytes);
  }
}

class ReceiptItem {
  final String name;
  final double qty;
  final double price;

  const ReceiptItem({
    required this.name,
    required this.qty,
    required this.price,
  });
}
