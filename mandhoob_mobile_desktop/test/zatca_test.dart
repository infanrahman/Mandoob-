import '../lib/core/utils/zatca_encoder.dart';
import '../lib/core/utils/esc_pos_generator.dart';

void main() {
  print('=============================================');
  print('TESTING SAUDI ARABIA ZATCA TLV QR CODE ENGINE');
  print('=============================================');

  final now = DateTime.parse('2026-10-29T19:14:00Z');
  final sellerName = 'شركة المندوب للتوزيع والتجارة';
  final vatNumber = '310123456700003';
  final invoiceTotal = 143.52;
  final vatTotal = 18.72;

  final qrBase64 = ZatcaTlvEncoder.generateQrCodeBase64(
    sellerName: sellerName,
    vatRegistrationNumber: vatNumber,
    timestamp: now,
    invoiceTotal: invoiceTotal,
    vatTotal: vatTotal,
  );

  print('Generated ZATCA Base64 QR:');
  print(qrBase64);

  // Decode back and verify
  final decoded = ZatcaTlvEncoder.decodeQrCode(qrBase64);
  print('\nDecoded TLV Elements:');
  print('Tag 1 (Seller Name): ${decoded[1]}');
  print('Tag 2 (VAT Number): ${decoded[2]}');
  print('Tag 3 (Timestamp): ${decoded[3]}');
  print('Tag 4 (Total with VAT): ${decoded[4]}');
  print('Tag 5 (VAT Amount): ${decoded[5]}');

  assert(decoded[1] == sellerName, 'Tag 1 mismatch');
  assert(decoded[2] == vatNumber, 'Tag 2 mismatch');
  assert(decoded[4] == '143.52', 'Tag 4 mismatch');
  assert(decoded[5] == '18.72', 'Tag 5 mismatch');
  print('>>> ZATCA TLV TEST PASSED SUCCESSFULLY! <<<\n');

  print('=============================================');
  print('TESTING ESC/POS 80mm THERMAL RECEIPT ENGINE');
  print('=============================================');

  final bytes = EscPosGenerator.buildVanSalesReceipt(
    companyName: sellerName,
    vatNumber: vatNumber,
    crNumber: '1010892341',
    invoiceNumber: 'INV-2026-001',
    date: now,
    salesmanName: 'محمد الدوسري',
    vanId: 'VAN-01',
    customerName: 'تموينات الأمانة',
    customerVat: '310554433200003',
    items: [
      ReceiptItem(name: 'حليب المراعي 1لتر', qty: 24, price: 5.20),
    ],
    subtotal: 124.80,
    vatTotal: 18.72,
    discount: 0.0,
    grandTotal: 143.52,
    paymentMode: 'نقداً (Cash)',
    qrBase64: qrBase64,
    is80mm: true,
  );

  print('Generated ESC/POS Byte Count: ${bytes.length} bytes');
  assert(bytes.isNotEmpty, 'Bytes must not be empty');
  print('>>> ESC/POS THERMAL RECEIPT TEST PASSED SUCCESSFULLY! <<<\n');
}
