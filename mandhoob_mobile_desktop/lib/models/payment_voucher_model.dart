enum VoucherType {
  paymentIn, // سند قبض من عميل (Customer Collection)
  paymentOut, // سند صرف لمورد (Supplier Payment)
}

enum VoucherPaymentMode {
  cash, // نقداً
  madaCard, // شبكة / مدى
  bankTransfer, // تحويل بنكي
  cheque, // شيك
}

class PaymentVoucherModel {
  final String id;
  final String voucherNumber;
  final VoucherType type;
  final String partyId; // Customer ID or Supplier ID
  final String partyNameAr;
  final String partyNameEn;
  final double amount;
  final DateTime date;
  final VoucherPaymentMode paymentMode;
  final String? referenceNumber; // E.g., Bank transfer reference or Cheque number
  final String? bankName;
  final String? vanId; // If collected on van route
  final String collectedByUserId;
  final String collectedByUserName;
  final String? notes;
  final String? linkedInvoiceId; // Optional link to specific invoice

  PaymentVoucherModel({
    required this.id,
    required this.voucherNumber,
    required this.type,
    required this.partyId,
    required this.partyNameAr,
    required this.partyNameEn,
    required this.amount,
    required this.date,
    required this.paymentMode,
    this.referenceNumber,
    this.bankName,
    this.vanId,
    required this.collectedByUserId,
    required this.collectedByUserName,
    this.notes,
    this.linkedInvoiceId,
  });

  String get paymentModeDisplayNameAr {
    switch (paymentMode) {
      case VoucherPaymentMode.cash:
        return 'نقداً (Cash)';
      case VoucherPaymentMode.madaCard:
        return 'مدى / بطاقة (Mada)';
      case VoucherPaymentMode.bankTransfer:
        return 'تحويل بنكي (Transfer)';
      case VoucherPaymentMode.cheque:
        return 'شيك بنكي (Cheque)';
    }
  }

  String get typeDisplayNameAr {
    return type == VoucherType.paymentIn ? 'سند قبض' : 'سند صرف';
  }
}
