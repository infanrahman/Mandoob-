import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import '../models/company_model.dart';
import '../models/customer_model.dart';
import '../models/supplier_model.dart';
import '../models/product_model.dart';
import '../models/warehouse_model.dart';
import '../models/stock_transfer_model.dart';
import '../models/stock_adjustment_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/expense_model.dart';
import '../models/payment_voucher_model.dart';
import '../models/van_salesman_progress_model.dart';
import '../models/user_model.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _seedInitialData();
    _loadFromLocalStorage();
  }

  final LocalStorageService _storage = LocalStorageService();
  bool _isLocalStorageLoaded = false;
  bool get isLocalStorageLoaded => _isLocalStorageLoaded;

  Future<void> _loadFromLocalStorage() async {
    try {
      final storedProducts = await _storage.loadProducts();
      if (storedProducts != null && storedProducts.isNotEmpty) {
        _products.clear();
        _products.addAll(storedProducts);
      }

      final storedCustomers = await _storage.loadCustomers();
      if (storedCustomers != null && storedCustomers.isNotEmpty) {
        _customers.clear();
        _customers.addAll(storedCustomers);
      }

      final storedTransfers = await _storage.loadStockTransfers();
      if (storedTransfers != null && storedTransfers.isNotEmpty) {
        _stockTransfers.clear();
        _stockTransfers.addAll(storedTransfers);
      }

      final storedAdjustments = await _storage.loadStockAdjustments();
      if (storedAdjustments != null && storedAdjustments.isNotEmpty) {
        _stockAdjustments.clear();
        _stockAdjustments.addAll(storedAdjustments);
      }

      final storedInvoices = await _storage.loadInvoices();
      if (storedInvoices != null && storedInvoices.isNotEmpty) {
        _invoices.clear();
        _invoices.addAll(storedInvoices);
      }

      final storedSuppliers = await _storage.loadSuppliers();
      if (storedSuppliers != null && storedSuppliers.isNotEmpty) {
        _suppliers.clear();
        _suppliers.addAll(storedSuppliers);
      }

      final storedExpenses = await _storage.loadExpenses();
      if (storedExpenses != null && storedExpenses.isNotEmpty) {
        _expenses.clear();
        _expenses.addAll(storedExpenses);
      }

      final storedUsers = await _storage.loadCompanyUsers();
      if (storedUsers != null && storedUsers.isNotEmpty) {
        _companyUsers.clear();
        _companyUsers.addAll(storedUsers);
      }

      final storedCompany = await _storage.loadCompanyProfile();
      if (storedCompany != null && storedCompany.isNotEmpty) {
        companyNameAr = storedCompany['nameAr'] ?? companyNameAr;
        companyNameEn = storedCompany['nameEn'] ?? companyNameEn;
        vatNumber = storedCompany['vatNumber'] ?? vatNumber;
        crNumber = storedCompany['crNumber'] ?? crNumber;
        buildingNumber = storedCompany['buildingNumber'] ?? buildingNumber;
        street = storedCompany['street'] ?? street;
        district = storedCompany['district'] ?? district;
        city = storedCompany['city'] ?? city;
        postalCode = storedCompany['postalCode'] ?? postalCode;
      }

      if (storedProducts == null) {
        await _saveAllToStorage();
      }

      _isLocalStorageLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLocalStorageLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveAllToStorage() async {
    await _storage.saveProducts(_products);
    await _storage.saveCustomers(_customers);
    await _storage.saveStockTransfers(_stockTransfers);
    await _storage.saveStockAdjustments(_stockAdjustments);
    await _storage.saveInvoices(_invoices);
    await _storage.saveSuppliers(_suppliers);
    await _storage.saveExpenses(_expenses);
    await _storage.saveCompanyUsers(_companyUsers);
    await _saveCompanyProfileToStorage();
  }

  Future<void> _saveCompanyProfileToStorage() async {
    await _storage.saveCompanyProfile({
      'nameAr': companyNameAr,
      'nameEn': companyNameEn,
      'vatNumber': vatNumber,
      'crNumber': crNumber,
      'buildingNumber': buildingNumber,
      'street': street,
      'district': district,
      'city': city,
      'postalCode': postalCode,
    });
  }

  Future<void> resetToInitialDemoData() async {
    await _storage.clearAll();
    _products.clear();
    _customers.clear();
    _suppliers.clear();
    _warehouses.clear();
    _stockTransfers.clear();
    _stockAdjustments.clear();
    _invoices.clear();
    _expenses.clear();
    _companyUsers.clear();
    _paymentVouchers.clear();
    _salesmenProgress.clear();
    _seedInitialData();
    await _saveAllToStorage();
    notifyListeners();
  }

  // Company Settings
  String companyNameAr = 'شركة المندوب للتوزيع والتجارة المحدودة';
  String companyNameEn = 'Mandhoob Distribution & Trading Co. Ltd.';
  String vatNumber = '310123456700003';
  String crNumber = '1010892341';
  String buildingNumber = '3421';
  String street = 'طريق الملك فهد - King Fahd Road';
  String district = 'العليا - Al Olaya';
  String city = 'الرياض - Riyadh';
  String postalCode = '12211';

  /// Update Company Profile Details across the entire system
  void updateCompanyProfile({
    required String nameAr,
    required String nameEn,
    required String vatNumber,
    required String crNumber,
    required String buildingNumber,
    required String street,
    required String district,
    required String city,
    required String postalCode,
  }) {
    companyNameAr = nameAr;
    companyNameEn = nameEn;
    this.vatNumber = vatNumber;
    this.crNumber = crNumber;
    this.buildingNumber = buildingNumber;
    this.street = street;
    this.district = district;
    this.city = city;
    this.postalCode = postalCode;
    _saveCompanyProfileToStorage();
    notifyListeners();
  }

  // In-Memory Data Collections
  final List<CompanyModel> _companies = [];
  final List<CustomerModel> _customers = [];
  final List<SupplierModel> _suppliers = [];
  final List<ProductModel> _products = [];
  final List<WarehouseModel> _warehouses = [];
  final List<StockTransferModel> _stockTransfers = [];
  final List<InvoiceModel> _invoices = [];
  final List<ExpenseModel> _expenses = [];
  final List<PaymentVoucherModel> _paymentVouchers = [];
  final List<VanSalesmanProgressModel> _salesmenProgress = [];
  final List<StockAdjustmentModel> _stockAdjustments = [];
  final List<UserModel> _companyUsers = [];

  List<CompanyModel> get companies => List.unmodifiable(_companies);
  List<CustomerModel> get customers => List.unmodifiable(_customers);
  List<SupplierModel> get suppliers => List.unmodifiable(_suppliers);
  List<ProductModel> get products => List.unmodifiable(_products);
  List<WarehouseModel> get warehouses => List.unmodifiable(_warehouses);
  List<StockTransferModel> get stockTransfers => List.unmodifiable(_stockTransfers);
  List<StockAdjustmentModel> get stockAdjustments => List.unmodifiable(_stockAdjustments);
  List<InvoiceModel> get invoices => List.unmodifiable(_invoices);
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);
  List<UserModel> get companyUsers => List.unmodifiable(_companyUsers);
  List<PaymentVoucherModel> get paymentVouchers => List.unmodifiable(_paymentVouchers);
  List<VanSalesmanProgressModel> get salesmenProgress => _salesmenProgress;

  /// Add a newly created company (by Super Admin)
  void addCompany(CompanyModel company) {
    _companies.add(company);
    notifyListeners();
  }

  /// Switch active working company
  void switchActiveCompany(String companyId) {
    final comp = _companies.firstWhere((c) => c.id == companyId, orElse: () => _companies.first);
    companyNameAr = comp.nameAr;
    companyNameEn = comp.nameEn;
    vatNumber = comp.vatNumber;
    crNumber = comp.crNumber;
    buildingNumber = comp.buildingNumber;
    street = comp.street;
    district = comp.district;
    city = comp.city;
    postalCode = comp.postalCode;
    notifyListeners();
  }

  // Financial KPI calculations
  double get todaySalesTotal {
    final now = DateTime.now();
    return _invoices
        .where((inv) =>
            inv.invoiceDate.year == now.year &&
            inv.invoiceDate.month == now.month &&
            inv.invoiceDate.day == now.day &&
            inv.type != InvoiceType.salesReturn &&
            inv.type != InvoiceType.quotation)
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }

  double get cashInHandTotal {
    final cashInSales = _invoices
        .where((inv) =>
            inv.paymentMethod == PaymentMethod.cash &&
            inv.type != InvoiceType.salesReturn &&
            inv.type != InvoiceType.quotation)
        .fold(0.0, (sum, inv) => sum + inv.paidAmount);

    final cashCollections = _paymentVouchers
        .where((v) => v.type == VoucherType.paymentIn && v.paymentMode == VoucherPaymentMode.cash)
        .fold(0.0, (sum, v) => sum + v.amount);

    final cashExpenses = _expenses
        .where((exp) => exp.paymentMode.toLowerCase() == 'cash' || exp.paymentMode == 'نقداً')
        .fold(0.0, (sum, exp) => sum + exp.totalWithVat);

    final cashSupplierPayments = _paymentVouchers
        .where((v) => v.type == VoucherType.paymentOut && v.paymentMode == VoucherPaymentMode.cash)
        .fold(0.0, (sum, v) => sum + v.amount);

    return (cashInSales + cashCollections - cashExpenses - cashSupplierPayments) + 2500.0;
  }

  double get totalReceivables {
    return _customers.fold(0.0, (sum, cust) => sum + (cust.currentBalance > 0 ? cust.currentBalance : 0.0));
  }

  double get totalPayables {
    return _suppliers.fold(0.0, (sum, supp) => sum + (supp.currentBalance > 0 ? supp.currentBalance : 0.0));
  }

  double getVanStockValue(String vanId) {
    double total = 0.0;
    for (final p in _products) {
      final qty = p.stockByWarehouse[vanId] ?? 0.0;
      total += (qty * p.retailPrice);
    }
    return total;
  }

  // --- CREDIT TRACKING & PAYMENT COLLECTION METHODS ---

  /// Record Customer Payment In (سند قبض)
  void addPaymentIn(PaymentVoucherModel voucher) {
    _paymentVouchers.insert(0, voucher);

    // Deduct collected amount from customer's outstanding balance
    final cIndex = _customers.indexWhere((c) => c.id == voucher.partyId);
    if (cIndex != -1) {
      final cust = _customers[cIndex];
      final newBalance = (cust.currentBalance - voucher.amount).clamp(0.0, 9999999.0);

      _customers[cIndex] = CustomerModel(
        id: cust.id,
        nameAr: cust.nameAr,
        nameEn: cust.nameEn,
        phone: cust.phone,
        email: cust.email,
        vatNumber: cust.vatNumber,
        crNumber: cust.crNumber,
        buildingNumber: cust.buildingNumber,
        street: cust.street,
        district: cust.district,
        city: cust.city,
        postalCode: cust.postalCode,
        routeArea: cust.routeArea,
        creditLimit: cust.creditLimit,
        creditPeriodDays: cust.creditPeriodDays,
        openingBalance: cust.openingBalance,
        currentBalance: newBalance,
      );
    }

    notifyListeners();
  }

  /// Record Supplier Payment Out (سند صرف للمورد)
  void addPaymentOut(PaymentVoucherModel voucher) {
    _paymentVouchers.insert(0, voucher);

    // Deduct paid amount from supplier's payable balance
    final sIndex = _suppliers.indexWhere((s) => s.id == voucher.partyId);
    if (sIndex != -1) {
      final supp = _suppliers[sIndex];
      final newBalance = (supp.currentBalance - voucher.amount).clamp(0.0, 9999999.0);

      _suppliers[sIndex] = SupplierModel(
        id: supp.id,
        nameAr: supp.nameAr,
        nameEn: supp.nameEn,
        phone: supp.phone,
        email: supp.email,
        vatNumber: supp.vatNumber,
        crNumber: supp.crNumber,
        city: supp.city,
        creditLimit: supp.creditLimit,
        creditPeriodDays: supp.creditPeriodDays,
        openingBalance: supp.openingBalance,
        currentBalance: newBalance,
      );
    }

    notifyListeners();
  }

  /// Customer Aging Analysis (0-30, 31-60, 61-90, 90+ days)
  Map<String, double> getCustomerAging(String customerId) {
    final now = DateTime.now();
    double bucket0To30 = 0.0;
    double bucket31To60 = 0.0;
    double bucket61To90 = 0.0;
    double bucket90Plus = 0.0;

    final custInvoices = _invoices.where((inv) =>
        inv.customerId == customerId &&
        inv.paymentStatus != PaymentStatus.paid &&
        inv.type != InvoiceType.salesReturn &&
        inv.type != InvoiceType.quotation);

    for (final inv in custInvoices) {
      final unpaid = inv.remainingBalance;
      if (unpaid <= 0) continue;

      final ageDays = now.difference(inv.invoiceDate).inDays;
      if (ageDays <= 30) {
        bucket0To30 += unpaid;
      } else if (ageDays <= 60) {
        bucket31To60 += unpaid;
      } else if (ageDays <= 90) {
        bucket61To90 += unpaid;
      } else {
        bucket90Plus += unpaid;
      }
    }

    return {
      '0_30': bucket0To30,
      '31_60': bucket31To60,
      '61_90': bucket61To90,
      '90_plus': bucket90Plus,
      'total': bucket0To30 + bucket31To60 + bucket61To90 + bucket90Plus,
    };
  }

  /// Overall Portfolio Receivables Aging
  Map<String, double> getPortfolioReceivablesAging() {
    double total0To30 = 0.0;
    double total31To60 = 0.0;
    double total61To90 = 0.0;
    double total90Plus = 0.0;

    for (final cust in _customers) {
      final aging = getCustomerAging(cust.id);
      total0To30 += aging['0_30']!;
      total31To60 += aging['31_60']!;
      total61To90 += aging['61_90']!;
      total90Plus += aging['90_plus']!;
    }

    return {
      '0_30': total0To30,
      '31_60': total31To60,
      '61_90': total61To90,
      '90_plus': total90Plus,
      'total': total0To30 + total31To60 + total61To90 + total90Plus,
    };
  }

  /// Add a customer directly to the system
  void addCustomer(CustomerModel customer) {
    _customers.insert(0, customer);
    _storage.saveCustomers(_customers);
    notifyListeners();
  }

  /// Update an existing customer's details and credit terms
  void updateCustomer(CustomerModel customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      _storage.saveCustomers(_customers);
      notifyListeners();
    }
  }

  /// Delete a customer from the system
  void deleteCustomer(String customerId) {
    _customers.removeWhere((c) => c.id == customerId);
    _storage.saveCustomers(_customers);
    notifyListeners();
  }

  /// Add a newly onboarded customer directly into a specific van's delivery route
  void addCustomerToVanRoute({
    required String vanId,
    required CustomerModel customer,
  }) {
    _customers.insert(0, customer);
    _storage.saveCustomers(_customers);
    final vIndex = _salesmenProgress.indexWhere((p) => p.vanId == vanId);
    if (vIndex != -1) {
      final prog = _salesmenProgress[vIndex];
      final newStop = CustomerRouteStop(
        customerId: customer.id,
        customerNameAr: customer.nameAr,
        district: customer.district ?? customer.routeArea ?? '',
        phone: customer.phone,
        currentBalance: customer.currentBalance,
        creditLimit: customer.creditLimit,
        sequenceOrder: prog.routeStops.length + 1,
        status: StopVisitStatus.pending,
      );
      prog.routeStops.add(newStop);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Suppliers Management
  // ---------------------------------------------------------------------------
  void addSupplier(SupplierModel supplier) {
    _suppliers.insert(0, supplier);
    _storage.saveSuppliers(_suppliers);
    notifyListeners();
  }

  void updateSupplier(SupplierModel supplier) {
    final index = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      _suppliers[index] = supplier;
      _storage.saveSuppliers(_suppliers);
      notifyListeners();
    }
  }

  void deleteSupplier(String supplierId) {
    _suppliers.removeWhere((s) => s.id == supplierId);
    _storage.saveSuppliers(_suppliers);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Inward Purchase Bill Recording (تسجيل فاتورة شراء وتحديث المخزون ومستحقات المورد)
  // ---------------------------------------------------------------------------
  void recordPurchaseBill({
    required String supplierId,
    required String warehouseId,
    required List<StockTransferItem> items,
    required double subtotal,
    required double vatAmount,
    required String paymentMode,
    required String createdByUserId,
    required String createdByUserName,
    String? billNumber,
    String? notes,
  }) {
    final grandTotal = subtotal + vatAmount;
    final bNum = billNumber?.isNotEmpty == true
        ? billNumber!
        : 'PUR-${DateTime.now().year}-${_expenses.length + 101}';

    // 1. Increase stock in the target warehouse
    for (final item in items) {
      final pIndex = _products.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        final prod = _products[pIndex];
        final currentStock = prod.stockByWarehouse[warehouseId] ?? 0.0;
        prod.stockByWarehouse[warehouseId] = currentStock + item.quantity;
      }
    }
    _storage.saveProducts(_products);

    // 2. If credit purchase, increase supplier payable balance
    final isCredit = paymentMode == 'Credit' || paymentMode == 'آجل' || paymentMode.contains('Credit');
    if (isCredit) {
      final sIndex = _suppliers.indexWhere((s) => s.id == supplierId);
      if (sIndex != -1) {
        final supp = _suppliers[sIndex];
        _suppliers[sIndex] = SupplierModel(
          id: supp.id,
          nameAr: supp.nameAr,
          nameEn: supp.nameEn,
          phone: supp.phone,
          email: supp.email,
          vatNumber: supp.vatNumber,
          crNumber: supp.crNumber,
          city: supp.city,
          creditLimit: supp.creditLimit,
          creditPeriodDays: supp.creditPeriodDays,
          openingBalance: supp.openingBalance,
          currentBalance: supp.currentBalance + grandTotal,
        );
        _storage.saveSuppliers(_suppliers);
      }
    }

    // 3. Record expense / purchase ledger entry
    final supp = _suppliers.firstWhere((s) => s.id == supplierId, orElse: () => _suppliers.first);
    final expense = ExpenseModel(
      id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
      expenseNumber: bNum,
      category: ExpenseCategory.miscellaneous,
      amount: subtotal,
      vatAmount: vatAmount,
      date: DateTime.now(),
      paymentMode: paymentMode,
      spentByUserId: createdByUserId,
      spentByUserName: createdByUserName,
      description: 'فاتورة شراء بضاعة من ${supp.nameAr} - مستودع $warehouseId ${notes?.isNotEmpty == true ? "($notes)" : ""}',
    );
    _expenses.insert(0, expense);
    _storage.saveExpenses(_expenses);

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Company Users Management
  // ---------------------------------------------------------------------------
  void addCompanyUser(UserModel user) {
    _companyUsers.add(user);
    _storage.saveCompanyUsers(_companyUsers);
    notifyListeners();
  }

  void updateCompanyUser(UserModel user) {
    final index = _companyUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _companyUsers[index] = user;
      _storage.saveCompanyUsers(_companyUsers);
      notifyListeners();
    }
  }

  void deleteCompanyUser(String userId) {
    _companyUsers.removeWhere((u) => u.id == userId);
    _storage.saveCompanyUsers(_companyUsers);
    notifyListeners();
  }

  /// Update a stop visit status on a route (visited / skipped / invoice / collection)
  void updateRouteStopStatus({
    required String vanId,
    required String customerId,
    required StopVisitStatus status,
    double? invoiceAmount,
    double? collectedAmount,
  }) {
    final vIndex = _salesmenProgress.indexWhere((p) => p.vanId == vanId);
    if (vIndex != -1) {
      final prog = _salesmenProgress[vIndex];
      final sIndex = prog.routeStops.indexWhere((s) => s.customerId == customerId);
      if (sIndex != -1) {
        final oldStop = prog.routeStops[sIndex];
        prog.routeStops[sIndex] = oldStop.copyWith(
          status: status,
          visitedAt: DateTime.now(),
          invoiceAmount: invoiceAmount ?? oldStop.invoiceAmount,
          collectedAmount: collectedAmount ?? oldStop.collectedAmount,
        );
      }
    }
    notifyListeners();
  }

  /// Get pending (unpaid / partial credit) invoices for a specific customer
  List<InvoiceModel> getPendingInvoicesForCustomer(String customerId) {
    return _invoices
        .where((inv) =>
            inv.customerId == customerId &&
            inv.paymentStatus != PaymentStatus.paid &&
            inv.type != InvoiceType.salesReturn &&
            inv.type != InvoiceType.quotation)
        .toList();
  }

  /// Get collected (paid / partial) invoices for a customer
  List<InvoiceModel> getCollectedInvoicesForCustomer(String customerId) {
    return _invoices
        .where((inv) =>
            inv.customerId == customerId &&
            (inv.paidAmount > 0 || inv.paymentStatus == PaymentStatus.paid))
        .toList();
  }

  /// Get payment vouchers (سندات القبض) for a customer
  List<PaymentVoucherModel> getPaymentVouchersForCustomer(String customerId) {
    return _paymentVouchers
        .where((v) => v.partyId == customerId && v.type == VoucherType.paymentIn)
        .toList();
  }

  /// Get all operations executed by a van salesman today (audit feed)
  List<Map<String, dynamic>> getSalesmanOperationsLog(String vanId) {
    final List<Map<String, dynamic>> ops = [];

    // Invoices issued
    for (final inv in _invoices.where((i) => i.warehouseId == vanId)) {
      ops.add({
        'type': 'invoice',
        'title': '${inv.invoiceNumber} - ${inv.typeDisplayNameAr}',
        'subtitle': '${inv.customerNameAr} • ${inv.grandTotal.toStringAsFixed(2)} ر.س',
        'amount': inv.grandTotal,
        'date': inv.invoiceDate,
        'icon': Icons.receipt,
        'color': inv.type == InvoiceType.salesReturn ? Colors.red : Colors.green,
        'invoice': inv,
      });
    }

    // Expenses recorded
    for (final exp in _expenses.where((e) => e.vanId == vanId)) {
      ops.add({
        'type': 'expense',
        'title': 'سند صرف مصروف: ${exp.description}',
        'subtitle': '${exp.spentByUserName} • ${exp.totalWithVat.toStringAsFixed(2)} ر.س',
        'amount': exp.totalWithVat,
        'date': exp.date,
        'icon': Icons.local_gas_station,
        'color': Colors.orange.shade800,
      });
    }

    // Stock transfers loaded
    for (final trf in _stockTransfers.where((t) => t.toVanId == vanId)) {
      ops.add({
        'type': 'stock_transfer',
        'title': 'تحميل بضاعة من المستودع: ${trf.transferNumber}',
        'subtitle': '${trf.items.length} أصناف تم استلامها بالسيارة',
        'amount': 0.0,
        'date': trf.date,
        'icon': Icons.move_to_inbox,
        'color': Colors.blue,
      });
    }

    // Collections vouchers
    for (final v in _paymentVouchers.where((v) => v.type == VoucherType.paymentIn)) {
      ops.add({
        'type': 'collection',
        'title': 'سند قبض تحصيل: ${v.partyNameAr}',
        'subtitle': '${v.voucherNumber} • ${v.amount.toStringAsFixed(2)} ر.س (${v.paymentMode.name})',
        'amount': v.amount,
        'date': v.date,
        'icon': Icons.payments,
        'color': Colors.teal,
        'voucher': v,
      });
    }

    ops.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return ops;
  }

  // Adding an invoice
  void addInvoice(InvoiceModel invoice) {
    _invoices.insert(0, invoice);

    // Deduct stock from the chosen warehouse / van
    for (final item in invoice.items) {
      final index = _products.indexWhere((p) => p.id == item.productId);
      if (index != -1) {
        final prod = _products[index];
        final currentStock = prod.stockByWarehouse[invoice.warehouseId] ?? 0.0;
        final deduction = invoice.type == InvoiceType.salesReturn ? -item.quantity : item.quantity;
        final newStock = (currentStock - deduction).clamp(0.0, 999999.0);

        prod.stockByWarehouse[invoice.warehouseId] = newStock;
      }
    }

    // Update Customer outstanding balance if credit or partial payment
    final custIndex = _customers.indexWhere((c) => c.id == invoice.customerId);
    if (custIndex != -1) {
      final cust = _customers[custIndex];
      final unpaidDifference = invoice.grandTotal - invoice.paidAmount;
      if (invoice.type == InvoiceType.salesReturn) {
        _customers[custIndex] = CustomerModel(
          id: cust.id,
          nameAr: cust.nameAr,
          nameEn: cust.nameEn,
          phone: cust.phone,
          email: cust.email,
          vatNumber: cust.vatNumber,
          crNumber: cust.crNumber,
          buildingNumber: cust.buildingNumber,
          street: cust.street,
          district: cust.district,
          city: cust.city,
          postalCode: cust.postalCode,
          routeArea: cust.routeArea,
          creditLimit: cust.creditLimit,
          creditPeriodDays: cust.creditPeriodDays,
          openingBalance: cust.openingBalance,
          currentBalance: (cust.currentBalance - invoice.grandTotal).clamp(0.0, 9999999.0),
        );
      } else if (unpaidDifference > 0) {
        _customers[custIndex] = CustomerModel(
          id: cust.id,
          nameAr: cust.nameAr,
          nameEn: cust.nameEn,
          phone: cust.phone,
          email: cust.email,
          vatNumber: cust.vatNumber,
          crNumber: cust.crNumber,
          buildingNumber: cust.buildingNumber,
          street: cust.street,
          district: cust.district,
          city: cust.city,
          postalCode: cust.postalCode,
          routeArea: cust.routeArea,
          creditLimit: cust.creditLimit,
          creditPeriodDays: cust.creditPeriodDays,
          openingBalance: cust.openingBalance,
          currentBalance: cust.currentBalance + unpaidDifference,
        );
      }
    }

    _storage.saveInvoices(_invoices);
    _storage.saveProducts(_products);
    _storage.saveCustomers(_customers);
    notifyListeners();
  }

  // Adding an expense
  void addExpense(ExpenseModel expense) {
    _expenses.insert(0, expense);
    _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  void deleteExpense(String expenseId) {
    _expenses.removeWhere((e) => e.id == expenseId);
    _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  // Transfer stock from Warehouse to Van
  void transferStockToVan({
    required String fromWarehouseId,
    required String toVanId,
    required List<StockTransferItem> items,
    required String requestedByUserId,
    required String requestedByUserName,
  }) {
    for (final item in items) {
      final pIndex = _products.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        final prod = _products[pIndex];
        final fromStock = prod.stockByWarehouse[fromWarehouseId] ?? 0.0;
        final toStock = prod.stockByWarehouse[toVanId] ?? 0.0;

        prod.stockByWarehouse[fromWarehouseId] = (fromStock - item.quantity).clamp(0.0, 999999.0);
        prod.stockByWarehouse[toVanId] = toStock + item.quantity;
      }
    }

    final transfer = StockTransferModel(
      id: 'TRF-${DateTime.now().millisecondsSinceEpoch}',
      transferNumber: 'TRF-${DateTime.now().year}-${_stockTransfers.length + 101}',
      fromWarehouseId: fromWarehouseId,
      fromWarehouseName: 'المستودع الرئيسي - Central WH',
      toVanId: toVanId,
      toVanName: _warehouses.firstWhere((w) => w.id == toVanId).nameAr,
      requestedByUserId: requestedByUserId,
      requestedByUserName: requestedByUserName,
      date: DateTime.now(),
      items: items,
      status: TransferStatus.loaded,
      notes: 'تحميل بضاعة لسيارة التوزيع - Morning Van Stock Loading',
    );

    _stockTransfers.insert(0, transfer);
    _storage.saveProducts(_products);
    _storage.saveStockTransfers(_stockTransfers);
    notifyListeners();
  }

  // Add a new product
  void addProduct(ProductModel product) {
    _products.add(product);
    _storage.saveProducts(_products);
    notifyListeners();
  }

  // Update existing product
  void updateProduct(ProductModel product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      _storage.saveProducts(_products);
      notifyListeners();
    }
  }

  // Delete product
  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    _storage.saveProducts(_products);
    notifyListeners();
  }

  // Record Stock Adjustment (جرد وتسوية كميات المخزون)
  void recordStockAdjustment({
    required String productId,
    required String warehouseId,
    required double newQuantity,
    required AdjustmentReason reason,
    String? notes,
    required String userId,
    required String userName,
  }) {
    final pIndex = _products.indexWhere((p) => p.id == productId);
    if (pIndex != -1) {
      final prod = _products[pIndex];
      final prevQty = prod.stockByWarehouse[warehouseId] ?? 0.0;
      final diff = newQuantity - prevQty;
      prod.stockByWarehouse[warehouseId] = newQuantity.clamp(0.0, 9999999.0);

      final wMatch = _warehouses.where((w) => w.id == warehouseId);
      final wName = wMatch.isNotEmpty ? wMatch.first.nameAr : warehouseId;

      final adj = StockAdjustmentModel(
        id: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
        adjustmentNumber: 'ADJ-${DateTime.now().year}-${_stockAdjustments.length + 101}',
        date: DateTime.now(),
        productId: prod.id,
        productNameAr: prod.nameAr,
        productNameEn: prod.nameEn,
        warehouseId: warehouseId,
        warehouseName: wName,
        previousQuantity: prevQty,
        newQuantity: newQuantity,
        differenceQuantity: diff,
        reason: reason,
        notes: notes,
        adjustedByUserId: userId,
        adjustedByUserName: userName,
      );

      _stockAdjustments.insert(0, adj);
      _storage.saveProducts(_products);
      _storage.saveStockAdjustments(_stockAdjustments);
      notifyListeners();
    }
  }

  // Generalized Multi-Item Stock Transfer (نقل وتفريغ مخزني بين الفروع والسيارات)
  void transferStockBetweenWarehouses({
    required String fromWarehouseId,
    required String toWarehouseId,
    required List<StockTransferItem> items,
    required String requestedByUserId,
    required String requestedByUserName,
    String? notes,
  }) {
    final fromWh = _warehouses.firstWhere((w) => w.id == fromWarehouseId, orElse: () => _warehouses.first);
    final toWh = _warehouses.firstWhere((w) => w.id == toWarehouseId, orElse: () => _warehouses.last);

    for (final item in items) {
      final pIndex = _products.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        final prod = _products[pIndex];
        final fromStock = prod.stockByWarehouse[fromWarehouseId] ?? 0.0;
        final toStock = prod.stockByWarehouse[toWarehouseId] ?? 0.0;

        prod.stockByWarehouse[fromWarehouseId] = (fromStock - item.quantity).clamp(0.0, 9999999.0);
        prod.stockByWarehouse[toWarehouseId] = toStock + item.quantity;
      }
    }

    final transfer = StockTransferModel(
      id: 'TRF-${DateTime.now().millisecondsSinceEpoch}',
      transferNumber: 'TRF-${DateTime.now().year}-${_stockTransfers.length + 101}',
      fromWarehouseId: fromWarehouseId,
      fromWarehouseName: fromWh.nameAr,
      toVanId: toWarehouseId,
      toVanName: toWh.nameAr,
      requestedByUserId: requestedByUserId,
      requestedByUserName: requestedByUserName,
      date: DateTime.now(),
      items: items,
      status: TransferStatus.loaded,
      notes: notes ?? 'نقل مخزني بين المستودعات وسيارات التوزيع',
    );

    _stockTransfers.insert(0, transfer);
    _storage.saveProducts(_products);
    _storage.saveStockTransfers(_stockTransfers);
    notifyListeners();
  }

  // Seed Data
  void _seedInitialData() {
    // 0. Primary Seed Company
    _companies.add(
      CompanyModel(
        id: 'COMP-001',
        nameAr: companyNameAr,
        nameEn: companyNameEn,
        vatNumber: vatNumber,
        crNumber: crNumber,
        buildingNumber: buildingNumber,
        street: street,
        district: district,
        city: city,
        postalCode: postalCode,
        phone: '0112345678',
        email: 'info@mandhoob.sa',
        bankName: 'مصرف الراجحي - Al Rajhi Bank',
        iban: 'SA0380000000608010167519',
        createdBySuperAdminId: 'USR-001',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
    );

    // 1. Warehouses & Vans
    _warehouses.addAll([
      WarehouseModel(
        id: 'WH-MAIN',
        nameAr: 'المستودع المركزي - الرياض',
        nameEn: 'Central Main Warehouse - Riyadh',
        type: WarehouseType.mainWarehouse,
      ),
      WarehouseModel(
        id: 'VAN-01',
        nameAr: 'سيارة 1 - الرياض شمال (محمد)',
        nameEn: 'Van 1 - Riyadh North (Mohammed)',
        type: WarehouseType.vanWarehouse,
        assignedDriverId: 'USR-003',
        assignedDriverName: 'محمد الدوسري - Mohammed Al-Dosari',
        vehiclePlateNumber: 'أ ب ج 4321',
      ),
      WarehouseModel(
        id: 'VAN-02',
        nameAr: 'سيارة 2 - الرياض شرق (أحمد)',
        nameEn: 'Van 2 - Riyadh East (Ahmed)',
        type: WarehouseType.vanWarehouse,
        assignedDriverId: 'USR-005',
        assignedDriverName: 'أحمد الغامدي - Ahmed Al-Ghamdi',
        vehiclePlateNumber: 'د ر س 9876',
      ),
    ]);

    // 2. Customers with rich Credit Limits and Balances
    _customers.addAll([
      CustomerModel(
        id: 'CUST-101',
        nameAr: 'أسواق التميمي - فرع السليمانية',
        nameEn: 'Tamimi Markets - As Sulimaniyah',
        phone: '0501122334',
        vatNumber: '310987654300003',
        crNumber: '1010345678',
        district: 'السليمانية',
        routeArea: 'مسار الرياض شمال - North Route',
        creditLimit: 30000.0,
        creditPeriodDays: 45,
        currentBalance: 7500.0,
      ),
      CustomerModel(
        id: 'CUST-102',
        nameAr: 'تموينات الأمانة الحديثة',
        nameEn: 'Al-Amanah Modern Grocery',
        phone: '0554433221',
        vatNumber: '310554433200003',
        crNumber: '1010776655',
        district: 'العليا',
        routeArea: 'مسار الرياض شمال - North Route',
        creditLimit: 10000.0,
        creditPeriodDays: 30,
        currentBalance: 3200.0,
      ),
      CustomerModel(
        id: 'CUST-103',
        nameAr: 'مجمع أسواق الجزيرة',
        nameEn: 'Al Jazeera Supermarket Complex',
        phone: '0569988776',
        vatNumber: '310887766500003',
        crNumber: '1010998877',
        district: 'الروضة',
        routeArea: 'مسار الرياض شرق - East Route',
        creditLimit: 20000.0,
        creditPeriodDays: 30,
        currentBalance: 12500.0,
      ),
      CustomerModel(
        id: 'CUST-104',
        nameAr: 'عميل نقدي فوري (عام)',
        nameEn: 'Walk-in Cash Customer',
        phone: '0500000000',
        district: 'متنقل',
        routeArea: 'عام',
        creditLimit: 0.0,
        creditPeriodDays: 0,
        currentBalance: 0.0,
      ),
    ]);

    // 3. Suppliers with Credit limits and Payables
    _suppliers.addAll([
      SupplierModel(
        id: 'SUPP-201',
        nameAr: 'شركة المراعي السعودية',
        nameEn: 'Almarai Saudi Company',
        phone: '0114700000',
        vatNumber: '300055566600003',
        crNumber: '1010037322',
        creditLimit: 80000.0,
        creditPeriodDays: 60,
        currentBalance: 24500.0,
      ),
      SupplierModel(
        id: 'SUPP-202',
        nameAr: 'شركة كوكاكولا لتعبئة وتوزيع المشروبات',
        nameEn: 'Coca-Cola Bottling & Distribution Co.',
        phone: '0112651111',
        vatNumber: '300112233400003',
        crNumber: '1010156789',
        creditLimit: 40000.0,
        creditPeriodDays: 45,
        currentBalance: 11200.0,
      ),
    ]);

    // 4. Products
    _products.addAll([
      ProductModel(
        id: 'PRD-001',
        sku: 'ALM-MILK-1L',
        barcode: '6281007010015',
        nameAr: 'حليب المراعي طازج كامل الدسم 1 لتر',
        nameEn: 'Almarai Fresh Milk Full Fat 1L',
        category: 'ألبان - Dairy',
        baseUnit: 'حبة - Piece',
        secondaryUnit: 'كرتون - Carton',
        conversionFactor: 12.0,
        costPrice: 4.50,
        wholesalePrice: 5.20,
        retailPrice: 6.00,
        stockByWarehouse: {
          'WH-MAIN': 450.0,
          'VAN-01': 85.0,
          'VAN-02': 40.0,
        },
        batchNumber: 'B-2610-A',
        expiryDate: DateTime.now().add(const Duration(days: 14)),
      ),
      ProductModel(
        id: 'PRD-002',
        sku: 'ALM-JUICE-MANGO',
        barcode: '6281007020021',
        nameAr: 'عصير مانجو المراعي بدون سكر 1.4 لتر',
        nameEn: 'Almarai Mango Juice No Added Sugar 1.4L',
        category: 'عصائر - Juices',
        baseUnit: 'حبة - Piece',
        secondaryUnit: 'كرتون - Carton',
        conversionFactor: 6.0,
        costPrice: 7.00,
        wholesalePrice: 8.50,
        retailPrice: 10.00,
        stockByWarehouse: {
          'WH-MAIN': 320.0,
          'VAN-01': 60.0,
          'VAN-02': 35.0,
        },
        batchNumber: 'B-2609-M',
        expiryDate: DateTime.now().add(const Duration(days: 45)),
      ),
      ProductModel(
        id: 'PRD-003',
        sku: 'COCA-CAN-330',
        barcode: '5449000000996',
        nameAr: 'مشروب كوكاكولا علبة 330 مل',
        nameEn: 'Coca Cola Can 330ml',
        category: 'مشروبات غازية - Beverages',
        baseUnit: 'حبة - Piece',
        secondaryUnit: 'كرتون - Carton (24)',
        conversionFactor: 24.0,
        costPrice: 2.10,
        wholesalePrice: 2.60,
        retailPrice: 3.00,
        stockByWarehouse: {
          'WH-MAIN': 1200.0,
          'VAN-01': 140.0,
          'VAN-02': 90.0,
        },
        batchNumber: 'B-2608-C',
        expiryDate: DateTime.now().add(const Duration(days: 200)),
      ),
      ProductModel(
        id: 'PRD-004',
        sku: 'WATER-BERAIN-330',
        barcode: '6281093000013',
        nameAr: 'مياه بيرين كرتون 40 × 330 مل',
        nameEn: 'Berain Water Carton 40 x 330ml',
        category: 'مياه - Water',
        baseUnit: 'كرتون - Carton',
        costPrice: 13.50,
        wholesalePrice: 16.00,
        retailPrice: 19.50,
        stockByWarehouse: {
          'WH-MAIN': 500.0,
          'VAN-01': 35.0,
          'VAN-02': 20.0,
        },
        batchNumber: 'B-2605-W',
        expiryDate: DateTime.now().add(const Duration(days: 360)),
      ),
    ]);

    // 4b. Initial Stock Transfers Seed Data
    _stockTransfers.addAll([
      StockTransferModel(
        id: 'TRF-2026-001',
        transferNumber: 'TRF-2026-101',
        fromWarehouseId: 'WH-MAIN',
        fromWarehouseName: 'المستودع المركزي - الرياض',
        toVanId: 'VAN-01',
        toVanName: 'سيارة 1 - الرياض شمال (محمد)',
        requestedByUserId: 'USR-003',
        requestedByUserName: 'محمد الدوسري - Mohammed Al-Dosari',
        date: DateTime.now().subtract(const Duration(hours: 6)),
        items: [
          StockTransferItem(
            productId: 'PRD-001',
            productName: 'حليب المراعي طازج كامل الدسم 1 لتر',
            quantity: 50.0,
            unit: 'حبة',
          ),
          StockTransferItem(
            productId: 'PRD-002',
            productName: 'عصير مانجو المراعي بدون سكر 1.4 لتر',
            quantity: 30.0,
            unit: 'حبة',
          ),
          StockTransferItem(
            productId: 'PRD-003',
            productName: 'مشروب كوكاكولا علبة 330 مل',
            quantity: 80.0,
            unit: 'حبة',
          ),
        ],
        status: TransferStatus.loaded,
        notes: 'تحميل الصباح - Morning Load Van 1',
      ),
      StockTransferModel(
        id: 'TRF-2026-002',
        transferNumber: 'TRF-2026-102',
        fromWarehouseId: 'WH-MAIN',
        fromWarehouseName: 'المستودع المركزي - الرياض',
        toVanId: 'VAN-02',
        toVanName: 'سيارة 2 - الرياض شرق (أحمد)',
        requestedByUserId: 'USR-005',
        requestedByUserName: 'أحمد الغامدي - Ahmed Al-Ghamdi',
        date: DateTime.now().subtract(const Duration(hours: 7)),
        items: [
          StockTransferItem(
            productId: 'PRD-003',
            productName: 'مشروب كوكاكولا علبة 330 مل',
            quantity: 60.0,
            unit: 'حبة',
          ),
          StockTransferItem(
            productId: 'PRD-004',
            productName: 'مياه بيرين كرتون 40 × 330 مل',
            quantity: 20.0,
            unit: 'كرتون',
          ),
        ],
        status: TransferStatus.loaded,
        notes: 'تحميل الصباح - Morning Load Van 2',
      ),
    ]);

    // 4c. Initial Stock Adjustments Seed Data
    _stockAdjustments.addAll([
      StockAdjustmentModel(
        id: 'ADJ-2026-001',
        adjustmentNumber: 'ADJ-2026-101',
        date: DateTime.now().subtract(const Duration(days: 2)),
        productId: 'PRD-001',
        productNameAr: 'حليب المراعي طازج كامل الدسم 1 لتر',
        productNameEn: 'Almarai Fresh Milk Full Fat 1L',
        warehouseId: 'WH-MAIN',
        warehouseName: 'المستودع المركزي - الرياض',
        previousQuantity: 460.0,
        newQuantity: 450.0,
        differenceQuantity: -10.0,
        reason: AdjustmentReason.damaged,
        notes: 'تلف عبوات أثناء تفريغ الشحنة من المورد',
        adjustedByUserId: 'USR-002',
        adjustedByUserName: 'سارة المنصور - مستودعات',
      ),
      StockAdjustmentModel(
        id: 'ADJ-2026-002',
        adjustmentNumber: 'ADJ-2026-102',
        date: DateTime.now().subtract(const Duration(days: 5)),
        productId: 'PRD-004',
        productNameAr: 'مياه بيرين كرتون 40 × 330 مل',
        productNameEn: 'Berain Water Carton 40 x 330ml',
        warehouseId: 'WH-MAIN',
        warehouseName: 'المستودع المركزي - الرياض',
        previousQuantity: 495.0,
        newQuantity: 500.0,
        differenceQuantity: 5.0,
        reason: AdjustmentReason.physicalCount,
        notes: 'مطابقة الجرد الفعلي الأسبوعي',
        adjustedByUserId: 'USR-002',
        adjustedByUserName: 'سارة المنصور - مستودعات',
      ),
    ]);

    // 5. Invoices (with historical credit invoices for aging)
    _invoices.addAll([
      InvoiceModel(
        id: 'INV-2026-001',
        invoiceNumber: 'INV-2026-001',
        type: InvoiceType.simplifiedTaxInvoice,
        invoiceDate: DateTime.now().subtract(const Duration(hours: 2)),
        customerId: 'CUST-102',
        customerNameAr: 'تموينات الأمانة الحديثة',
        customerNameEn: 'Al-Amanah Modern Grocery',
        customerVatNumber: '310554433200003',
        customerPhone: '0554433221',
        warehouseId: 'VAN-01',
        warehouseName: 'سيارة 1 - الرياض شمال',
        salesmanId: 'USR-003',
        salesmanName: 'محمد الدوسري - Mohammed Al-Dosari',
        items: [
          InvoiceItemModel(
            productId: 'PRD-001',
            productNameAr: 'حليب المراعي طازج كامل الدسم 1 لتر',
            productNameEn: 'Almarai Fresh Milk Full Fat 1L',
            barcode: '6281007010015',
            quantity: 24.0,
            unit: 'حبة',
            unitPrice: 5.20,
          ),
        ],
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.paid,
        paidAmount: 143.52,
        isSynced: true,
      ),
      InvoiceModel(
        id: 'INV-2026-002',
        invoiceNumber: 'INV-2026-002',
        type: InvoiceType.taxInvoice,
        invoiceDate: DateTime.now().subtract(const Duration(days: 15)), // Within 0-30 days
        customerId: 'CUST-101',
        customerNameAr: 'أسواق التميمي - فرع السليمانية',
        customerNameEn: 'Tamimi Markets - As Sulimaniyah',
        customerVatNumber: '310987654300003',
        customerPhone: '0501122334',
        warehouseId: 'VAN-01',
        warehouseName: 'سيارة 1 - الرياض شمال',
        salesmanId: 'USR-003',
        salesmanName: 'محمد الدوسري - Mohammed Al-Dosari',
        items: [
          InvoiceItemModel(
            productId: 'PRD-004',
            productNameAr: 'مياه بيرين كرتون 40 × 330 مل',
            productNameEn: 'Berain Water Carton 40 x 330ml',
            barcode: '6281093000013',
            quantity: 100.0,
            unit: 'كرتون',
            unitPrice: 16.00,
          ),
        ],
        paymentMethod: PaymentMethod.credit,
        paymentStatus: PaymentStatus.unpaid,
        paidAmount: 0.0,
        isSynced: true,
      ),
      InvoiceModel(
        id: 'INV-2026-003',
        invoiceNumber: 'INV-2026-003',
        type: InvoiceType.taxInvoice,
        invoiceDate: DateTime.now().subtract(const Duration(days: 42)), // 31-60 days bucket
        customerId: 'CUST-103',
        customerNameAr: 'مجمع أسواق الجزيرة',
        customerNameEn: 'Al Jazeera Supermarket Complex',
        customerVatNumber: '310887766500003',
        customerPhone: '0569988776',
        warehouseId: 'VAN-02',
        warehouseName: 'سيارة 2 - الرياض شرق',
        salesmanId: 'USR-005',
        salesmanName: 'أحمد الغامدي',
        items: [
          InvoiceItemModel(
            productId: 'PRD-003',
            productNameAr: 'مشروب كوكاكولا علبة 330 مل',
            productNameEn: 'Coca Cola Can 330ml',
            barcode: '5449000000996',
            quantity: 120.0,
            unit: 'حبة',
            unitPrice: 2.60,
          ),
        ],
        paymentMethod: PaymentMethod.credit,
        paymentStatus: PaymentStatus.unpaid,
        paidAmount: 0.0,
        isSynced: true,
      ),
    ]);

    // 6. Payment Vouchers Seed Data
    _paymentVouchers.addAll([
      PaymentVoucherModel(
        id: 'VCT-2026-001',
        voucherNumber: 'VCT-26-01',
        type: VoucherType.paymentIn,
        partyId: 'CUST-101',
        partyNameAr: 'أسواق التميمي - فرع السليمانية',
        partyNameEn: 'Tamimi Markets',
        amount: 5000.0,
        date: DateTime.now().subtract(const Duration(days: 3)),
        paymentMode: VoucherPaymentMode.bankTransfer,
        referenceNumber: 'TRF-SNB-998812',
        bankName: 'البنك الأهلي السعودي (SNB)',
        collectedByUserId: 'USR-003',
        collectedByUserName: 'محمد الدوسري',
        notes: 'دفعة سداد بموجب حوالة بنكية على الحساب',
      ),
      PaymentVoucherModel(
        id: 'VCT-2026-002',
        voucherNumber: 'VCT-26-02',
        type: VoucherType.paymentOut,
        partyId: 'SUPP-201',
        partyNameAr: 'شركة المراعي السعودية',
        partyNameEn: 'Almarai Saudi Company',
        amount: 10000.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        paymentMode: VoucherPaymentMode.bankTransfer,
        referenceNumber: 'TRF-ARB-112233',
        bankName: 'مصرف الراجحي',
        collectedByUserId: 'USR-001',
        collectedByUserName: 'سلطان القحطاني',
        notes: 'سداد دفعة للمورد المراعي عن فواتير الألبان',
      ),
    ]);

    // 7. Expenses
    _expenses.addAll([
      ExpenseModel(
        id: 'EXP-001',
        expenseNumber: 'EXP-26-01',
        category: ExpenseCategory.fuelAndVehicle,
        amount: 150.0,
        vatAmount: 22.50,
        date: DateTime.now().subtract(const Duration(hours: 6)),
        paymentMode: 'نقداً - Cash',
        vanId: 'VAN-01',
        spentByUserId: 'USR-003',
        spentByUserName: 'محمد الدوسري',
        description: 'بنزين سيارة التوزيع رقم 1 - محطة الدريس',
      ),
    ]);

    // 8. Van Salesmen Progress & Routes
    _salesmenProgress.addAll([
      VanSalesmanProgressModel(
        salesmanId: 'USR-003',
        salesmanName: 'محمد الدوسري (Van 1)',
        phone: '0559876543',
        vanId: 'VAN-01',
        vanName: 'سيارة 1 - الرياض شمال',
        vehiclePlateNumber: 'أ ب ج 4321',
        date: DateTime.now(),
        dailySalesTarget: 6000.0,
        actualSalesAchieved: 4850.0,
        dailyCollectionTarget: 3500.0,
        actualCollectionsAchieved: 2500.0,
        assignedRouteName: 'مسار شمال الرياض (السليمانية، العليا، الورود)',
        morningOpeningStockValue: 12500.0,
        totalSalesStockValue: 4850.0,
        returnsStockValue: 0.0,
        remainingEveningStockValue: 7650.0,
        routeStops: [
          CustomerRouteStop(
            customerId: 'CUST-101',
            customerNameAr: 'أسواق التميمي - فرع السليمانية',
            district: 'السليمانية',
            phone: '0501122334',
            currentBalance: 7500.0,
            creditLimit: 30000.0,
            sequenceOrder: 1,
            status: StopVisitStatus.visited,
            visitedAt: DateTime.now().subtract(const Duration(hours: 3)),
            invoiceAmount: 2400.0,
            collectedAmount: 1500.0,
          ),
          CustomerRouteStop(
            customerId: 'CUST-102',
            customerNameAr: 'تموينات الأمانة الحديثة',
            district: 'العليا',
            phone: '0554433221',
            currentBalance: 3200.0,
            creditLimit: 10000.0,
            sequenceOrder: 2,
            status: StopVisitStatus.visited,
            visitedAt: DateTime.now().subtract(const Duration(hours: 1)),
            invoiceAmount: 1450.0,
            collectedAmount: 1000.0,
          ),
          CustomerRouteStop(
            customerId: 'CUST-104',
            customerNameAr: 'ميني ماركت النور',
            district: 'الورود',
            phone: '0560001122',
            currentBalance: 1200.0,
            creditLimit: 5000.0,
            sequenceOrder: 3,
            status: StopVisitStatus.pending,
          ),
        ],
        settlement: DailyVanSettlement(
          openingCashFloat: 500.0,
          totalCashSales: 2850.0,
          totalMadaSales: 1200.0,
          totalCreditSales: 800.0,
          totalCollections: 2500.0,
          totalVanExpenses: 150.0,
          expectedCashHandover: 500.0 + 2850.0 + 2500.0 - 150.0,
        ),
      ),
      VanSalesmanProgressModel(
        salesmanId: 'USR-005',
        salesmanName: 'أحمد الغامدي (Van 2)',
        phone: '0551122445',
        vanId: 'VAN-02',
        vanName: 'سيارة 2 - الرياض شرق',
        vehiclePlateNumber: 'د ر س 9876',
        date: DateTime.now(),
        dailySalesTarget: 5000.0,
        actualSalesAchieved: 3100.0,
        dailyCollectionTarget: 2000.0,
        actualCollectionsAchieved: 1200.0,
        assignedRouteName: 'مسار شرق الرياض (الروضة، النسيم، القدس)',
        morningOpeningStockValue: 9800.0,
        totalSalesStockValue: 3100.0,
        returnsStockValue: 0.0,
        remainingEveningStockValue: 6700.0,
        routeStops: [
          CustomerRouteStop(
            customerId: 'CUST-103',
            customerNameAr: 'مجمع أسواق الجزيرة',
            district: 'الروضة',
            phone: '0569988776',
            currentBalance: 12500.0,
            creditLimit: 20000.0,
            sequenceOrder: 1,
            status: StopVisitStatus.visited,
            visitedAt: DateTime.now().subtract(const Duration(hours: 4)),
            invoiceAmount: 3100.0,
            collectedAmount: 1200.0,
          ),
          CustomerRouteStop(
            customerId: 'CUST-105',
            customerNameAr: 'بقالة الوفاء',
            district: 'النسيم',
            phone: '0543322110',
            currentBalance: 400.0,
            creditLimit: 3000.0,
            sequenceOrder: 2,
            status: StopVisitStatus.pending,
          ),
        ],
        settlement: DailyVanSettlement(
          openingCashFloat: 500.0,
          totalCashSales: 1900.0,
          totalMadaSales: 800.0,
          totalCreditSales: 400.0,
          totalCollections: 1200.0,
          totalVanExpenses: 100.0,
          expectedCashHandover: 500.0 + 1900.0 + 1200.0 - 100.0,
        ),
      ),
    ]);

    // 9. Initial Company Users
    _companyUsers.addAll([
      UserModel(
        id: 'USR-001',
        companyId: 'COMP-001',
        companyNameAr: companyNameAr,
        name: 'سلطان القحطاني - Sultan Al-Qahtani',
        email: 'sultan@mandhoob.sa',
        phone: '0501234567',
        role: UserRole.superAdmin,
      ),
      UserModel(
        id: 'USR-002',
        companyId: 'COMP-001',
        companyNameAr: companyNameAr,
        name: 'فهد العتيبي - Fahad Al-Otaibi',
        email: 'fahad.mgr@mandhoob.sa',
        phone: '0541112233',
        role: UserRole.admin,
      ),
      UserModel(
        id: 'USR-003',
        companyId: 'COMP-001',
        companyNameAr: companyNameAr,
        name: 'محمد الدوسري - Mohammed Al-Dosari',
        email: 'mohammed.sales@mandhoob.sa',
        phone: '0559876543',
        role: UserRole.salesman,
        assignedVanId: 'VAN-01',
        assignedVanName: 'سيارة 1 - الرياض شمال',
      ),
      UserModel(
        id: 'USR-004',
        companyId: 'COMP-001',
        companyNameAr: companyNameAr,
        name: 'عبدالله الشهري - Abdullah Al-Shehri',
        email: 'abdullah.acc@mandhoob.sa',
        phone: '0567778899',
        role: UserRole.accountant,
      ),
      UserModel(
        id: 'USR-005',
        companyId: 'COMP-001',
        companyNameAr: companyNameAr,
        name: 'أحمد الغامدي - Ahmed Al-Ghamdi',
        email: 'ahmed.sales@mandhoob.sa',
        phone: '0551122445',
        role: UserRole.salesman,
        assignedVanId: 'VAN-02',
        assignedVanName: 'سيارة 2 - الرياض شرق',
      ),
    ]);
  }
}
