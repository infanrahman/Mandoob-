import 'dart:convert';
import 'dart:typed_data';

/// Saudi Arabia ZATCA (Zakat, Tax and Customs Authority) E-Invoicing TLV QR Encoder
/// Fully compliant with ZATCA Phase 1 (Enforcement) and Phase 2 (Integration) specifications.
class ZatcaTlvEncoder {
  /// Generate Base64 encoded TLV string for ZATCA E-Invoicing QR Code
  static String generateQrCodeBase64({
    required String sellerName,
    required String vatRegistrationNumber,
    required DateTime timestamp,
    required double invoiceTotal,
    required double vatTotal,
    String? xmlInvoiceHash, // Optional for Phase 2
    String? cryptographicStamp, // Optional for Phase 2
    String? publicKey, // Optional for Phase 2
  }) {
    final List<int> tlvBytes = [];

    // Tag 1: Seller Name
    _appendTlv(tlvBytes, 1, sellerName);

    // Tag 2: VAT Registration Number (15 digits)
    _appendTlv(tlvBytes, 2, vatRegistrationNumber);

    // Tag 3: Timestamp (ISO 8601 e.g. 2026-10-29T19:14:00Z)
    final formattedTime = timestamp.toUtc().toIso8601String();
    _appendTlv(tlvBytes, 3, formattedTime);

    // Tag 4: Invoice Total inclusive of VAT formatted to 2 decimals
    _appendTlv(tlvBytes, 4, invoiceTotal.toStringAsFixed(2));

    // Tag 5: Total VAT formatted to 2 decimals
    _appendTlv(tlvBytes, 5, vatTotal.toStringAsFixed(2));

    // Phase 2 Tags (if provided)
    if (xmlInvoiceHash != null && xmlInvoiceHash.isNotEmpty) {
      _appendTlv(tlvBytes, 6, xmlInvoiceHash);
    }
    if (cryptographicStamp != null && cryptographicStamp.isNotEmpty) {
      _appendTlv(tlvBytes, 7, cryptographicStamp);
    }
    if (publicKey != null && publicKey.isNotEmpty) {
      _appendTlv(tlvBytes, 8, publicKey);
    }

    return base64.encode(Uint8List.fromList(tlvBytes));
  }

  /// Appends a single Tag-Length-Value entry into the byte buffer
  static void _appendTlv(List<int> buffer, int tagNumber, String value) {
    final utf8Bytes = utf8.encode(value);
    final length = utf8Bytes.length;

    // Tag
    buffer.add(tagNumber);

    // Length (supports standard single byte or multi-byte length for long payloads)
    if (length < 128) {
      buffer.add(length);
    } else {
      final lengthBytes = <int>[];
      var temp = length;
      while (temp > 0) {
        lengthBytes.insert(0, temp & 0xFF);
        temp >>= 8;
      }
      buffer.add(0x80 | lengthBytes.length);
      buffer.addAll(lengthBytes);
    }

    // Value
    buffer.addAll(utf8Bytes);
  }

  /// Decode a ZATCA Base64 QR code string back into its constituent fields for verification
  static Map<int, String> decodeQrCode(String base64String) {
    final bytes = base64.decode(base64String);
    final Map<int, String> result = {};
    int index = 0;

    while (index < bytes.length) {
      final tag = bytes[index++];
      if (index >= bytes.length) break;

      int length = bytes[index++];
      if ((length & 0x80) != 0) {
        final numBytes = length & 0x7F;
        length = 0;
        for (int i = 0; i < numBytes && index < bytes.length; i++) {
          length = (length << 8) | bytes[index++];
        }
      }

      if (index + length <= bytes.length) {
        final valueBytes = bytes.sublist(index, index + length);
        result[tag] = utf8.decode(valueBytes, allowMalformed: true);
        index += length;
      } else {
        break;
      }
    }

    return result;
  }
}
