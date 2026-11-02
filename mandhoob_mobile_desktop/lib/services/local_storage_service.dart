import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/stock_transfer_model.dart';
import '../models/stock_adjustment_model.dart';
import '../models/invoice_model.dart';
import '../models/supplier_model.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _keyProducts = 'mandhoob_products_v1';
  static const String _keyCustomers = 'mandhoob_customers_v1';
  static const String _keyTransfers = 'mandhoob_transfers_v1';
  static const String _keyAdjustments = 'mandhoob_adjustments_v1';
  static const String _keyInvoices = 'mandhoob_invoices_v1';
  static const String _keySuppliers = 'mandhoob_suppliers_v1';
  static const String _keyExpenses = 'mandhoob_expenses_v1';
  static const String _keyUsers = 'mandhoob_users_v1';
  static const String _keyCompany = 'mandhoob_company_v1';
  static const String _keyLastSaved = 'mandhoob_last_saved_timestamp';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => CustomerModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => StockTransferModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => StockAdjustmentModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => InvoiceModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => SupplierModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
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
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Company Profile Details Local Persistence
  // ---------------------------------------------------------------------------
  Future<void> saveCompanyProfile(Map<String, String> profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCompany, jsonEncode(profile));
    await _updateLastSaved();
  }

  Future<Map<String, String>?> loadCompanyProfile() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyCompany);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
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
    final prefs = await _getPrefs();
    await prefs.setString(_keyLastSaved, DateTime.now().toIso8601String());
  }

  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyCustomers);
    await prefs.remove(_keyTransfers);
    await prefs.remove(_keyAdjustments);
    await prefs.remove(_keyInvoices);
    await prefs.remove(_keySuppliers);
    await prefs.remove(_keyExpenses);
    await prefs.remove(_keyUsers);
    await prefs.remove(_keyCompany);
    await prefs.remove(_keyLastSaved);
  }
}
