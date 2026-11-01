import '../lib/models/customer_model.dart';
import '../lib/models/supplier_model.dart';
import '../lib/models/payment_voucher_model.dart';
import '../lib/services/database_service.dart';

void main() {
  print('=============================================');
  print('TESTING CREDIT TRACKING & AGING ENGINE');
  print('=============================================');

  final db = DatabaseService();

  // Test 1: Customer Credit Limit & Utilization
  final customer = db.customers.firstWhere((c) => c.id == 'CUST-101');
  print('Customer: ${customer.nameAr}');
  print('Credit Limit: ${customer.creditLimit} SAR');
  print('Current Balance: ${customer.currentBalance} SAR');
  print('Available Credit: ${customer.availableCredit} SAR');
  print('Credit Utilization Ratio: ${(customer.creditUtilizationRatio * 100).toStringAsFixed(1)}%');

  assert(customer.creditLimit == 30000.0, 'Credit limit mismatch');
  assert(customer.currentBalance == 7500.0, 'Balance mismatch');
  assert(customer.availableCredit == 22500.0, 'Available credit calculation error');

  // Test 2: Credit Limit Exceeded Check
  final safeInvoice = 10000.0;
  final excessiveInvoice = 25000.0;
  assert(!customer.isCreditExceeded(safeInvoice), '10,000 SAR should not exceed limit');
  assert(customer.isCreditExceeded(excessiveInvoice), '25,000 SAR should exceed limit');
  print('>>> Credit limit violation checks PASSED! <<<');

  // Test 3: Customer Payment In (سند قبض)
  print('\nProcessing Payment In (سند قبض) of 2,500 SAR...');
  final paymentInVoucher = PaymentVoucherModel(
    id: 'VCT-TEST-01',
    voucherNumber: 'RCT-TEST-01',
    type: VoucherType.paymentIn,
    partyId: customer.id,
    partyNameAr: customer.nameAr,
    partyNameEn: customer.nameEn,
    amount: 2500.0,
    date: DateTime.now(),
    paymentMode: VoucherPaymentMode.cash,
    collectedByUserId: 'USR-003',
    collectedByUserName: 'محمد الدوسري',
  );

  db.addPaymentIn(paymentInVoucher);

  final updatedCustomer = db.customers.firstWhere((c) => c.id == customer.id);
  print('Updated Customer Balance: ${updatedCustomer.currentBalance} SAR');
  assert(updatedCustomer.currentBalance == 5000.0, 'Balance should reduce from 7,500 to 5,000 SAR');
  print('>>> Payment In balance deduction PASSED! <<<');

  // Test 4: Supplier Credit Tracking & Payment Out (سند صرف)
  print('\nTesting Supplier Payables & Payment Out...');
  final supplier = db.suppliers.firstWhere((s) => s.id == 'SUPP-201');
  print('Supplier: ${supplier.nameAr}');
  print('Initial Payable Balance: ${supplier.currentBalance} SAR');
  print('Credit Limit granted: ${supplier.creditLimit} SAR');

  final paymentOutVoucher = PaymentVoucherModel(
    id: 'VCT-TEST-02',
    voucherNumber: 'PAY-TEST-02',
    type: VoucherType.paymentOut,
    partyId: supplier.id,
    partyNameAr: supplier.nameAr,
    partyNameEn: supplier.nameEn,
    amount: 4500.0,
    date: DateTime.now(),
    paymentMode: VoucherPaymentMode.bankTransfer,
    collectedByUserId: 'USR-001',
    collectedByUserName: 'سلطان القحطاني',
  );

  db.addPaymentOut(paymentOutVoucher);

  final updatedSupplier = db.suppliers.firstWhere((s) => s.id == supplier.id);
  print('Updated Supplier Payable: ${updatedSupplier.currentBalance} SAR');
  assert(updatedSupplier.currentBalance == 20000.0, 'Payable should reduce from 24,500 to 20,000 SAR');
  print('>>> Supplier Payment Out deduction PASSED! <<<');

  // Test 5: Aging Analysis Buckets
  print('\nTesting Aging Analysis Buckets (0-30, 31-60, 61-90, 90+ days)...');
  final portfolioAging = db.getPortfolioReceivablesAging();
  print('Aging 0-30 Days: ${portfolioAging['0_30']} SAR');
  print('Aging 31-60 Days: ${portfolioAging['31_60']} SAR');
  print('Aging 61-90 Days: ${portfolioAging['61_90']} SAR');
  print('Aging 90+ Days: ${portfolioAging['90_plus']} SAR');
  assert(portfolioAging['0_30']! >= 0, 'Aging 0-30 should be non-negative');
  assert(portfolioAging['31_60']! >= 0, 'Aging 31-60 should be non-negative');
  print('>>> Aging analysis computation PASSED! <<<');

  print('\n=============================================');
  print('ALL CREDIT TRACKING TESTS COMPLETED SUCCESSFULLY!');
  print('=============================================');
}
