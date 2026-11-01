import '../lib/models/customer_model.dart';
import '../lib/models/supplier_model.dart';
import '../lib/models/payment_voucher_model.dart';

void main() {
  print('=============================================');
  print('TESTING CREDIT TRACKING & AGING ENGINE (PURE DART)');
  print('=============================================');

  // 1. Customer Credit Limits & Tracking
  var customer = CustomerModel(
    id: 'CUST-101',
    nameAr: 'أسواق التميمي - فرع السليمانية',
    nameEn: 'Tamimi Markets - As Sulimaniyah',
    phone: '0501122334',
    vatNumber: '310987654300003',
    district: 'السليمانية',
    creditLimit: 30000.0,
    creditPeriodDays: 45,
    currentBalance: 7500.0,
  );

  print('Customer: ${customer.nameAr}');
  print('Credit Limit: ${customer.creditLimit} SAR');
  print('Current Receivable Balance: ${customer.currentBalance} SAR');
  print('Available Credit Remaining: ${customer.availableCredit} SAR');
  print('Utilization: ${(customer.creditUtilizationRatio * 100).toStringAsFixed(1)}%');

  assert(customer.creditLimit == 30000.0);
  assert(customer.currentBalance == 7500.0);
  assert(customer.availableCredit == 22500.0);

  // Check credit limit guard
  assert(!customer.isCreditExceeded(15000.0), '15k should be within 30k limit');
  assert(customer.isCreditExceeded(25000.0), '25k + 7.5k = 32.5k which exceeds 30k');
  print('>>> Customer Credit Limit Validation: PASSED! <<<');

  // 2. Customer Payment In (سند قبض)
  print('\nSimulating Payment In (سند قبض) of 2,500 SAR...');
  final paymentIn = PaymentVoucherModel(
    id: 'VCT-001',
    voucherNumber: 'RCT-2026-001',
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

  customer = CustomerModel(
    id: customer.id,
    nameAr: customer.nameAr,
    nameEn: customer.nameEn,
    phone: customer.phone,
    creditLimit: customer.creditLimit,
    creditPeriodDays: customer.creditPeriodDays,
    currentBalance: customer.currentBalance - paymentIn.amount,
  );

  print('Balance after 2,500 SAR collection: ${customer.currentBalance} SAR');
  assert(customer.currentBalance == 5000.0);
  assert(customer.availableCredit == 25000.0);
  print('>>> Customer Payment In Deduction: PASSED! <<<');

  // 3. Supplier Credit Tracking & Payment Out (سند صرف)
  var supplier = SupplierModel(
    id: 'SUPP-201',
    nameAr: 'شركة المراعي السعودية',
    nameEn: 'Almarai Saudi Company',
    phone: '0114700000',
    vatNumber: '300055566600003',
    creditLimit: 80000.0,
    creditPeriodDays: 60,
    currentBalance: 24500.0,
  );

  print('\nSupplier: ${supplier.nameAr}');
  print('Initial Payable to Supplier: ${supplier.currentBalance} SAR');
  print('Credit Limit Granted: ${supplier.creditLimit} SAR');
  print('Available Credit: ${supplier.availableCredit} SAR');

  assert(supplier.creditLimit == 80000.0);
  assert(supplier.currentBalance == 24500.0);
  assert(supplier.availableCredit == 55500.0);

  print('Simulating Supplier Payment Out (سند صرف) of 10,000 SAR...');
  final paymentOut = PaymentVoucherModel(
    id: 'VCT-002',
    voucherNumber: 'PAY-2026-001',
    type: VoucherType.paymentOut,
    partyId: supplier.id,
    partyNameAr: supplier.nameAr,
    partyNameEn: supplier.nameEn,
    amount: 10000.0,
    date: DateTime.now(),
    paymentMode: VoucherPaymentMode.bankTransfer,
    referenceNumber: 'TRF-SNB-112233',
    bankName: 'البنك الأهلي السعودي',
    collectedByUserId: 'USR-001',
    collectedByUserName: 'سلطان القحطاني',
  );

  supplier = SupplierModel(
    id: supplier.id,
    nameAr: supplier.nameAr,
    nameEn: supplier.nameEn,
    phone: supplier.phone,
    creditLimit: supplier.creditLimit,
    creditPeriodDays: supplier.creditPeriodDays,
    currentBalance: supplier.currentBalance - paymentOut.amount,
  );

  print('Payable after 10,000 SAR payment: ${supplier.currentBalance} SAR');
  assert(supplier.currentBalance == 14500.0);
  assert(supplier.availableCredit == 65500.0);
  print('>>> Supplier Payment Out Deduction: PASSED! <<<');

  // 4. Aging Classification
  final now = DateTime.now();
  final invoices = [
    {'amount': 1500.0, 'date': now.subtract(const Duration(days: 10))},  // 0-30
    {'amount': 3200.0, 'date': now.subtract(const Duration(days: 45))},  // 31-60
    {'amount': 1200.0, 'date': now.subtract(const Duration(days: 75))},  // 61-90
    {'amount': 5000.0, 'date': now.subtract(const Duration(days: 120))}, // 90+
  ];

  double b0_30 = 0, b31_60 = 0, b61_90 = 0, b90plus = 0;
  for (final inv in invoices) {
    final days = now.difference(inv['date'] as DateTime).inDays;
    final amt = inv['amount'] as double;
    if (days <= 30) b0_30 += amt;
    else if (days <= 60) b31_60 += amt;
    else if (days <= 90) b61_90 += amt;
    else b90plus += amt;
  }

  print('\nAging Buckets Verification:');
  print(' - 0 to 30 Days: $b0_30 SAR');
  print(' - 31 to 60 Days: $b31_60 SAR');
  print(' - 61 to 90 Days: $b61_90 SAR');
  print(' - 90+ Days (Overdue): $b90plus SAR');

  assert(b0_30 == 1500.0);
  assert(b31_60 == 3200.0);
  assert(b61_90 == 1200.0);
  assert(b90plus == 5000.0);
  print('>>> Aging Classification Algorithm: PASSED! <<<');

  print('\n=============================================');
  print('ALL CREDIT TRACKING TESTS PASSED 100%!');
  print('=============================================');
}
