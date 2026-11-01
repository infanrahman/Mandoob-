class AppStrings {
  // Saudi Currency
  static const String currencySarEn = 'SAR';
  static const String currencySarAr = 'ر.س';

  // Tax Rate
  static const double vatRatePercent = 15.0; // Standard KSA VAT 15%

  // Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleSalesman = 'salesman';
  static const String roleAccountant = 'accountant';

  // Invoice Types
  static const String typeTaxInvoice = 'tax_invoice'; // B2B
  static const String typeSimplified = 'simplified'; // B2C / Van Sales
  static const String typeQuotation = 'quotation';
  static const String typeSalesReturn = 'sales_return';
  static const String typeDeliveryChallan = 'delivery_challan';

  // Payment Modes
  static const String payCash = 'cash';
  static const String payMada = 'mada_card';
  static const String payBank = 'bank_transfer';
  static const String payCredit = 'credit';
  static const String paySplit = 'split';
}
