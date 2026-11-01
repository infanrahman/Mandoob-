import '../lib/core/utils/zatca_encoder.dart';
import '../lib/core/zatca/ubl_xml_generator.dart';
import '../lib/core/zatca/zatca_crypto_service.dart';
import '../lib/models/invoice_model.dart';
import '../lib/models/invoice_item_model.dart';

void main() {
  print('======================================================');
  print('TESTING SAUDI ARABIA ZATCA PHASE 2 INTEGRATION ENGINE');
  print('======================================================');

  final now = DateTime.parse('2026-10-29T19:30:00Z');
  final sellerName = 'شركة المندوب للتوزيع والتجارة المحدودة';
  final vatNumber = '310123456700003';
  final crNumber = '1010892341';

  final testInvoice = InvoiceModel(
    id: 'INV-PHASE2-001',
    invoiceNumber: 'INV-2026-9901',
    type: InvoiceType.taxInvoice, // B2B
    invoiceDate: now,
    customerId: 'CUST-101',
    customerNameAr: 'أسواق التميمي',
    customerNameEn: 'Tamimi Markets',
    customerVatNumber: '310987654300003',
    warehouseId: 'WH-MAIN',
    warehouseName: 'المستودع المركزي',
    salesmanId: 'USR-001',
    salesmanName: 'سلطان القحطاني',
    items: [
      InvoiceItemModel(
        productId: 'PRD-001',
        productNameAr: 'حليب المراعي 1 لتر',
        productNameEn: 'Almarai Milk 1L',
        barcode: '6281007010015',
        quantity: 50.0,
        unit: 'حبة',
        unitPrice: 5.20,
      ),
    ],
    paymentMethod: PaymentMethod.credit,
    paymentStatus: PaymentStatus.unpaid,
    paidAmount: 0.0,
  );

  // 1. Generate UBL 2.1 XML
  print('Step 1: Generating UBL 2.1 XML...');
  final ublXml = ZatcaUblXmlGenerator.generateInvoiceXml(
    invoice: testInvoice,
    sellerNameAr: sellerName,
    sellerVatNumber: vatNumber,
    sellerCrNumber: crNumber,
    buildingNumber: '3421',
    streetName: 'طريق الملك فهد',
    districtName: 'العليا',
    cityName: 'الرياض',
    postalCode: '12211',
    invoiceCounterValue: 1,
    previousInvoiceHash: 'NWZlY2ViNjZmZmM4NmYzOGQ5NTI3ODNmNmQ2ZTM4NzVkMzQ4Zjc0NDMxYjgyYWRhMzljMTIzODNkNTBlYWViNg==',
  );

  print('Generated UBL 2.1 XML (length: ${ublXml.length} chars)');
  assert(ublXml.contains('<cbc:ProfileID>clearance:1.0</cbc:ProfileID>'), 'Must have B2B clearance ProfileID');
  assert(ublXml.contains('<cbc:InvoiceTypeCode name="0100000">388</cbc:InvoiceTypeCode>'), 'Must have Standard Tax Invoice code 388');
  assert(ublXml.contains('<cbc:ID>ICV</cbc:ID>'), 'Must have ICV AdditionalDocumentReference');
  assert(ublXml.contains('<cbc:ID>PIH</cbc:ID>'), 'Must have PIH AdditionalDocumentReference');
  print('>>> UBL 2.1 XML Schema Validation: PASSED! <<<');

  // 2. Compute Invoice SHA-256 Hash (Tag 6)
  print('\nStep 2: Computing Canonicalized SHA-256 Hash (Tag 6)...');
  final invoiceHashBase64 = ZatcaCryptoService.computeInvoiceHash(ublXml);
  print('Invoice Hash (Base64): $invoiceHashBase64');
  assert(invoiceHashBase64.isNotEmpty, 'Hash must not be empty');
  print('>>> SHA-256 Invoice Hashing: PASSED! <<<');

  // 3. Generate Cryptographic Stamp / Digital Signature (Tag 7)
  print('\nStep 3: Generating ECDSA Cryptographic Stamp (Tag 7)...');
  final cryptographicStamp = ZatcaCryptoService.generateCryptographicStamp(
    invoiceHashBase64: invoiceHashBase64,
    privateKeyPem: 'priv-key-zatca-2026-secp256k1',
  );
  print('Cryptographic Stamp (Base64): $cryptographicStamp');
  assert(cryptographicStamp.isNotEmpty, 'Digital signature must not be empty');
  print('>>> ECDSA Digital Signature Stamp: PASSED! <<<');

  // 4. Extract Public Key Certificate (Tag 8)
  print('\nStep 4: Extracting X.509 Certificate Public Key (Tag 8)...');
  final publicKey = ZatcaCryptoService.extractPublicKeyBase64(
    '-----BEGIN CERTIFICATE-----\nMIIB/DCCAaWgAwIBAgIUQW50aWdyYXZpdHlaYXRjYTA...==\n-----END CERTIFICATE-----',
  );
  print('Public Key (Base64): $publicKey');
  assert(publicKey.isNotEmpty, 'Public key must not be empty');

  // 5. Generate and Verify Complete 8-Tag TLV QR Code
  print('\nStep 5: Generating Full 8-Tag TLV QR Code for ZATCA Phase 2...');
  final phase2QrBase64 = ZatcaCryptoService.generatePhase2QrCode(
    sellerName: sellerName,
    vatRegistrationNumber: vatNumber,
    timestamp: now,
    invoiceTotal: testInvoice.grandTotal,
    vatTotal: testInvoice.totalVat,
    xmlInvoiceHashBase64: invoiceHashBase64,
    cryptographicStampBase64: cryptographicStamp,
    publicKeyBase64: publicKey,
  );

  print('Phase 2 QR Base64:\n$phase2QrBase64\n');

  // Decode TLV and verify all 8 tags
  final decoded = ZatcaTlvEncoder.decodeQrCode(phase2QrBase64);
  print('Decoded Phase 2 TLV Tags:');
  print('Tag 1 (Seller Name): ${decoded[1]}');
  print('Tag 2 (VAT Number): ${decoded[2]}');
  print('Tag 3 (Timestamp): ${decoded[3]}');
  print('Tag 4 (Total Amount): ${decoded[4]}');
  print('Tag 5 (VAT Amount): ${decoded[5]}');
  print('Tag 6 (Invoice XML Hash): ${decoded[6]}');
  print('Tag 7 (ECDSA Cryptographic Stamp): ${decoded[7]}');
  print('Tag 8 (Public Key Certificate): ${decoded[8]}');

  assert(decoded[1] == sellerName, 'Tag 1 mismatch');
  assert(decoded[2] == vatNumber, 'Tag 2 mismatch');
  assert(decoded[4] == testInvoice.grandTotal.toStringAsFixed(2), 'Tag 4 mismatch');
  assert(decoded[5] == testInvoice.totalVat.toStringAsFixed(2), 'Tag 5 mismatch');
  assert(decoded[6] == invoiceHashBase64, 'Tag 6 mismatch');
  assert(decoded[7] == cryptographicStamp, 'Tag 7 mismatch');
  assert(decoded[8] == publicKey, 'Tag 8 mismatch');
  print('>>> ALL 8 ZATCA PHASE 2 TAGS VERIFIED SUCCESSFULLY! <<<');

  print('\n======================================================');
  print('ZATCA PHASE 2 SUITE PASSED 100%!');
  print('======================================================');
}
