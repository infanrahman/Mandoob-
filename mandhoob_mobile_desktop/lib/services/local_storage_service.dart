import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/supplier_model.dart';
import '../models/warehouse_model.dart';
import '../models/stock_transfer_model.dart';
import '../models/stock_adjustment_model.dart';
import '../models/invoice_model.dart';
import '../models/purchase_bill_model.dart';
import '../models/expense_model.dart';
import '../models/payment_voucher_model.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/van_salesman_progress_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _keyProducts = 'mandhoob_products_v2';
  static const String _keyCustomers = 'mandhoob_customers_v2';
  static const String _keySuppliers = 'mandhoob_suppliers_v2';
  static const String _keyWarehouses = 'mandhoob_warehouses_v2';
  static const String _keyTransfers = 'mandhoob_transfers_v2';
  static const String _keyAdjustments = 'mandhoob_adjustments_v2';
  static const String _keyInvoices = 'mandhoob_invoices_v2';
  static const String _keyPurchaseBills = 'mandhoob_purchase_bills_v2';
  static const String _keyExpenses = 'mandhoob_expenses_v2';
  static const String _keyVouchers = 'mandhoob_vouchers_v2';
  static const String _keyUsers = 'mandhoob_users_v2';
  static const String _keyCompanies = 'mandhoob_companies_v2';
  static const String _keySalesmenProgress = 'mandhoob_salesmen_progress_v2';
  static const String _keyCompanyProfile = 'mandhoob_company_profile_v2';
  static const String _keyDbInitialized = 'mandhoob_db_initialized_v2';
  static const String _keyLastSaved = 'mandhoob_last_saved_timestamp';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ---------------------------------------------------------------------------
  // Database Initialized Flag
  // ---------------------------------------------------------------------------
  Future<bool> isDatabaseInitialized() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyDbInitialized) ?? false;
  }

  Future<void> setDatabaseInitialized(bool initialized) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyDbInitialized, initialized);
    await _updateLastSaved();
  }

  // ---------------------------------------------------------------------------
  // Products Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveProducts(List<ProductModel> products) async {
    final prefs = await _getPrefs();
    final jsonList = products.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProducts, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<ProductModel>?> loadProducts() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyProducts);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading products from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Customers Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveCustomers(List<CustomerModel> customers) async {
    final prefs = await _getPrefs();
    final jsonList = customers.map((c) => c.toJson()).toList();
    await prefs.setString(_keyCustomers, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<CustomerModel>?> loadCustomers() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyCustomers);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => CustomerModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading customers from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Suppliers Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveSuppliers(List<SupplierModel> suppliers) async {
    final prefs = await _getPrefs();
    final jsonList = suppliers.map((s) => s.toJson()).toList();
    await prefs.setString(_keySuppliers, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<SupplierModel>?> loadSuppliers() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keySuppliers);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => SupplierModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading suppliers from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Warehouses Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveWarehouses(List<WarehouseModel> warehouses) async {
    final prefs = await _getPrefs();
    final jsonList = warehouses.map((w) => w.toJson()).toList();
    await prefs.setString(_keyWarehouses, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<WarehouseModel>?> loadWarehouses() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyWarehouses);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => WarehouseModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading warehouses from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Stock Transfers Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveStockTransfers(List<StockTransferModel> transfers) async {
    final prefs = await _getPrefs();
    final jsonList = transfers.map((t) => t.toJson()).toList();
    await prefs.setString(_keyTransfers, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<StockTransferModel>?> loadStockTransfers() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyTransfers);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => StockTransferModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading stock transfers from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Stock Adjustments (Audit) Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveStockAdjustments(List<StockAdjustmentModel> adjustments) async {
    final prefs = await _getPrefs();
    final jsonList = adjustments.map((a) => a.toJson()).toList();
    await prefs.setString(_keyAdjustments, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<StockAdjustmentModel>?> loadStockAdjustments() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyAdjustments);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => StockAdjustmentModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading stock adjustments from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Invoices Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveInvoices(List<InvoiceModel> invoices) async {
    final prefs = await _getPrefs();
    final jsonList = invoices.map((inv) => inv.toJson()).toList();
    await prefs.setString(_keyInvoices, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<InvoiceModel>?> loadInvoices() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyInvoices);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => InvoiceModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading invoices from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase Bills Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> savePurchaseBills(List<PurchaseBillModel> bills) async {
    final prefs = await _getPrefs();
    final jsonList = bills.map((b) => b.toJson()).toList();
    await prefs.setString(_keyPurchaseBills, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<PurchaseBillModel>?> loadPurchaseBills() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyPurchaseBills);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => PurchaseBillModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading purchase bills from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Expenses Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveExpenses(List<ExpenseModel> expenses) async {
    final prefs = await _getPrefs();
    final jsonList = expenses.map((e) => e.toJson()).toList();
    await prefs.setString(_keyExpenses, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<ExpenseModel>?> loadExpenses() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyExpenses);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading expenses from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Payment Vouchers (Collections & Payments) Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> savePaymentVouchers(List<PaymentVoucherModel> vouchers) async {
    final prefs = await _getPrefs();
    final jsonList = vouchers.map((v) => v.toJson()).toList();
    await prefs.setString(_keyVouchers, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<PaymentVoucherModel>?> loadPaymentVouchers() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyVouchers);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => PaymentVoucherModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading payment vouchers from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Company Users Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveCompanyUsers(List<UserModel> users) async {
    final prefs = await _getPrefs();
    final jsonList = users.map((u) => u.toJson()).toList();
    await prefs.setString(_keyUsers, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<UserModel>?> loadCompanyUsers() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyUsers);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading users from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Companies Local Persistence (Multi-company)
  // ---------------------------------------------------------------------------
  Future<void> saveCompanies(List<CompanyModel> companies) async {
    final prefs = await _getPrefs();
    final jsonList = companies.map((c) => c.toJson()).toList();
    await prefs.setString(_keyCompanies, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<CompanyModel>?> loadCompanies() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyCompanies);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => CompanyModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading companies from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Van Salesmen Live Tracking Progress
  // ---------------------------------------------------------------------------
  Future<void> saveSalesmenProgress(List<VanSalesmanProgressModel> progressList) async {
    final prefs = await _getPrefs();
    final jsonList = progressList.map((p) => p.toJson()).toList();
    await prefs.setString(_keySalesmenProgress, jsonEncode(jsonList));
    await _updateLastSaved();
  }

  Future<List<VanSalesmanProgressModel>?> loadSalesmenProgress() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keySalesmenProgress);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => VanSalesmanProgressModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading salesmen progress from local storage: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Company Profile Details Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveCompanyProfile(Map<String, String> profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCompanyProfile, jsonEncode(profile));
    await _updateLastSaved();
  }

  Future<Map<String, String>?> loadCompanyProfile() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyCompanyProfile);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      debugPrint('Error loading company profile: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Status & Clear Helpers
  // ---------------------------------------------------------------------------
  Future<DateTime?> getLastSavedTimestamp() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyLastSaved);
    if (raw != null) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> _updateLastSaved() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyLastSaved, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyCustomers);
    await prefs.remove(_keySuppliers);
    await prefs.remove(_keyWarehouses);
    await prefs.remove(_keyTransfers);
    await prefs.remove(_keyAdjustments);
    await prefs.remove(_keyInvoices);
    await prefs.remove(_keyPurchaseBills);
    await prefs.remove(_keyExpenses);
    await prefs.remove(_keyVouchers);
    await prefs.remove(_keyUsers);
    await prefs.remove(_keyCompanies);
    await prefs.remove(_keySalesmenProgress);
    await prefs.remove(_keyCompanyProfile);
    await prefs.remove(_keyDbInitialized);
    await prefs.remove(_keyLastSaved);
  }
}
