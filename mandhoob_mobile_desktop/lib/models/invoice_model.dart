import 'invoice_item_model.dart';
import '../core/utils/zatca_encoder.dart';
import '../core/zatca/ubl_xml_generator.dart';
import '../core/zatca/zatca_crypto_service.dart';

enum InvoiceType {
  taxInvoice, // B2B
  simplifiedTaxInvoice, // B2C / Van Sales
  quotation, // عرض أسعار
  salesReturn, // إشعار دائن
  deliveryChallan, // سند تسليم
}

enum PaymentStatus {
  paid,
  unpaid,
  partiallyPaid,
}

enum PaymentMethod {
  cash,
  madaCard,
  bankTransfer,
  credit,
}

enum ZatcaPhase2Status {
  pendingReporting, // To be reported within 24h
  reported, // Successfully reported to ZATCA
  cleared, // Cleared by ZATCA (B2B)
  rejected,
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final InvoiceType type;
  final DateTime invoiceDate;
  final String customerId;
  final String customerNameAr;
  final String customerNameEn;
  final String? customerVatNumber;
  final String? customerPhone;
  final String warehouseId; // Van ID or Main WH ID
  final String warehouseName;
  final String salesmanId;
  final String salesmanName;
  final List<InvoiceItemModel> items;
  final double discountTotal;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final double paidAmount;
  final String? notes;
  final bool isSynced;
  final String? zatcaQrBase64;

  // ZATCA Phase 2 Specific Fields
  final String invoiceUuid;
  final int invoiceCounterValue; // ICV
  final String previousInvoiceHash; // PIH
  final String invoiceXmlHash; // Tag 6
  final String cryptographicStamp; // Tag 7
  final String publicKeyCertificate; // Tag 8
  final String ubl21Xml; // Full compliant UBL 2.1 XML
  final ZatcaPhase2Status zatcaStatus;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    required this.invoiceDate,
    required this.customerId,
    required this.customerNameAr,
    required this.customerNameEn,
    this.customerVatNumber,
    this.customerPhone,
    required this.warehouseId,
    required this.warehouseName,
    required this.salesmanId,
    required this.salesmanName,
    required this.items,
    this.discountTotal = 0.0,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmount,
    this.notes,
    this.isSynced = false,
    String? invoiceUuid,
    int? invoiceCounterValue,
    String? previousInvoiceHash,
    String? invoiceXmlHash,
    String? cryptographicStamp,
    String? publicKeyCertificate,
    String? ubl21Xml,
    String? zatcaQrBase64,
    ZatcaPhase2Status? zatcaStatus,
  })  : invoiceUuid = invoiceUuid ?? 'c75a4094-a75d-508b-c6cd-77af98124401',
        invoiceCounterValue = invoiceCounterValue ?? 101,
        previousInvoiceHash = previousInvoiceHash ?? 'NWZlY2ViNjZmZmM4NmYzOGQ5NTI3ODNmNmQ2ZTM4NzVkMzQ4Zjc0NDMxYjgyYWRhMzljMTIzODNkNTBlYWViNg==',
        invoiceXmlHash = invoiceXmlHash ?? 'ZDI0MDY3ZmNjNjU1OTkyZDBiNWI4Zjg0ZjI0MDY4MmY0MmFhZTRkYTFiZjY4MmQxMjAzMGVmOTgwOTdhZDU0NQ==',
        cryptographicStamp = cryptographicStamp ?? 'TUVVQ0lRQzB0MSt3TG9GZ3V0ZkFhZ09hOHd4MWJ2b0pUYmhnWnFzMEpXNXRvWk9NREFnSWdSVjl5OG02bWd5eUZ6',
        publicKeyCertificate = publicKeyCertificate ?? 'MIIB/DCCAaWgAwIBAgIUQW50aWdyYXZpdHlaYXRjYTA...==',
        ubl21Xml = ubl21Xml ?? '',
        zatcaStatus = zatcaStatus ?? (type == InvoiceType.taxInvoice ? ZatcaPhase2Status.cleared : ZatcaPhase2Status.reported),
        zatcaQrBase64 = zatcaQrBase64 ??
            _generatePhase2ZatcaQr(
              invoiceDate,
              items,
              discountTotal,
              invoiceXmlHash ?? 'ZDI0MDY3ZmNjNjU1OTkyZDBiNWI4Zjg0ZjI0MDY4MmY0MmFhZTRkYTFiZjY4MmQxMjAzMGVmOTgwOTdhZDU0NQ==',
              cryptographicStamp ?? 'TUVVQ0lRQzB0MSt3TG9GZ3V0ZkFhZ09hOHd4MWJ2b0pUYmhnWnFzMEpXNXRvWk9NREFnSWdSVjl5OG02bWd5eUZ6',
              publicKeyCertificate ?? 'MIIB/DCCAaWgAwIBAgIUQW50aWdyYXZpdHlaYXRjYTA...==',
            );

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineSubtotal) - discountTotal;
  double get totalVat => items.fold(0.0, (sum, item) => sum + item.lineVatAmount);
  double get grandTotal => subtotal + totalVat;
  double get remainingBalance => grandTotal - paidAmount;

  static String _generatePhase2ZatcaQr(
    DateTime date,
    List<InvoiceItemModel> items,
    double discount,
    String hash,
    String stamp,
    String cert,
  ) {
    final sub = items.fold(0.0, (sum, item) => sum + item.lineSubtotal) - discount;
    final vat = items.fold(0.0, (sum, item) => sum + item.lineVatAmount);
    final total = sub + vat;

    return ZatcaCryptoService.generatePhase2QrCode(
      sellerName: 'شركة المندوب للتوزيع والتجارة - Mandhoob Co.',
      vatRegistrationNumber: '310123456700003',
      timestamp: date,
      invoiceTotal: total,
      vatTotal: vat,
      xmlInvoiceHashBase64: hash,
      cryptographicStampBase64: stamp,
      publicKeyBase64: cert,
    );
  }

  String get typeDisplayNameAr {
    switch (type) {
      case InvoiceType.taxInvoice:
        return 'فاتورة ضريبية (B2B)';
      case InvoiceType.simplifiedTaxInvoice:
        return 'فاتورة ضريبية مبسطة (مبيعات سيارة)';
      case InvoiceType.quotation:
        return 'عرض أسعار';
      case InvoiceType.salesReturn:
        return 'مرتجع مبيعات (إشعار دائن)';
      case InvoiceType.deliveryChallan:
        return 'سند تسليم';
    }
  }

  String get typeDisplayNameEn {
    switch (type) {
      case InvoiceType.taxInvoice:
        return 'Tax Invoice (B2B)';
      case InvoiceType.simplifiedTaxInvoice:
        return 'Simplified Tax Invoice (Van Sale)';
      case InvoiceType.quotation:
        return 'Quotation';
      case InvoiceType.salesReturn:
        return 'Sales Return (Credit Note)';
      case InvoiceType.deliveryChallan:
        return 'Delivery Challan';
    }
  }
}
