import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../models/product_model.dart';
import '../sales/invoice_detail_screen.dart';
import '../customers/customer_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  String _query = '';
  String _sectionFilter = 'ALL'; // ALL, INVOICES, CUSTOMERS, PRODUCTS
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // 1. Invoices Match
        final matchedInvoices = db.invoices.where((inv) {
          if (_sectionFilter != 'ALL' && _sectionFilter != 'INVOICES') return false;
          if (_selectedDateRange != null) {
            if (inv.invoiceDate.isBefore(_selectedDateRange!.start) ||
                inv.invoiceDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
              return false;
            }
          }
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            return inv.invoiceNumber.toLowerCase().contains(q) ||
                inv.customerNameAr.toLowerCase().contains(q) ||
                inv.customerNameEn.toLowerCase().contains(q) ||
                inv.warehouseName.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        // 2. Customers Match
        final matchedCustomers = db.customers.where((c) {
          if (_sectionFilter != 'ALL' && _sectionFilter != 'CUSTOMERS') return false;
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            return c.nameAr.toLowerCase().contains(q) ||
                c.nameEn.toLowerCase().contains(q) ||
                c.phone.contains(q) ||
                (c.vatNumber?.contains(q) ?? false);
          }
          return true;
        }).toList();

        // 3. Products Match
        final matchedProducts = db.products.where((p) {
          if (_sectionFilter != 'ALL' && _sectionFilter != 'PRODUCTS') return false;
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            return p.nameAr.toLowerCase().contains(q) ||
                p.nameEn.toLowerCase().contains(q) ||
                p.barcode.contains(q) ||
                p.sku.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'البحث الشامل والتصفية' : 'Global Search & Date Filters'),
          ),
          body: Column(
            children: [
              // Search Input & Filter Options
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: lang.isArabic
                            ? 'ابحث في كل أقسام التطبيق (فاتورة، عميل، صنف، باركود)...'
                            : 'Search across all sections (Invoice, Customer, Item, Barcode)...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _query = ''))
                            : null,
                      ),
                      onChanged: (val) => setState(() => _query = val),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Date Range Filter Button
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                                initialDateRange: _selectedDateRange,
                              );
                              if (picked != null) {
                                setState(() => _selectedDateRange = picked);
                              }
                            },
                            icon: const Icon(Icons.date_range, size: 16),
                            label: Text(
                              _selectedDateRange == null
                                  ? (lang.isArabic ? 'تصفية بالتاريخ' : 'Date Range Filter')
                                  : '${_selectedDateRange!.start.toString().substring(0, 10)} - ${_selectedDateRange!.end.toString().substring(0, 10)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          if (_selectedDateRange != null) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _selectedDateRange = null),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Section Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text(lang.isArabic ? 'كل الأقسام (All)' : 'All Sections'),
                            selected: _sectionFilter == 'ALL',
                            onSelected: (_) => setState(() => _sectionFilter = 'ALL'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(lang.isArabic ? 'الفواتير (${matchedInvoices.length})' : 'Invoices (${matchedInvoices.length})'),
                            selected: _sectionFilter == 'INVOICES',
                            onSelected: (_) => setState(() => _sectionFilter = 'INVOICES'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(lang.isArabic ? 'العملاء (${matchedCustomers.length})' : 'Customers (${matchedCustomers.length})'),
                            selected: _sectionFilter == 'CUSTOMERS',
                            onSelected: (_) => setState(() => _sectionFilter = 'CUSTOMERS'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(lang.isArabic ? 'الأصناف (${matchedProducts.length})' : 'Products (${matchedProducts.length})'),
                            selected: _sectionFilter == 'PRODUCTS',
                            onSelected: (_) => setState(() => _sectionFilter = 'PRODUCTS'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Search Results
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Invoices Section
                    if (matchedInvoices.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          lang.isArabic ? 'نتائج الفواتير (Invoices):' : 'Invoices Results:',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      ...matchedInvoices.map((inv) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.receipt, color: AppColors.saleGreen),
                              title: Text('${inv.invoiceNumber} - ${lang.isArabic ? inv.customerNameAr : inv.customerNameEn}'),
                              subtitle: Text('${inv.warehouseName} • ${inv.invoiceDate.toString().substring(0, 16)}'),
                              trailing: Text(
                                '${inv.grandTotal.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
                                );
                              },
                            ),
                          )),
                      const SizedBox(height: 14),
                    ],

                    // Customers Section
                    if (matchedCustomers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          lang.isArabic ? 'نتائج العملاء (Customers):' : 'Customers Results:',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      ...matchedCustomers.map((c) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.person, color: AppColors.primary),
                              title: Text(lang.isArabic ? c.nameAr : c.nameEn),
                              subtitle: Text('${lang.isArabic ? "هاتف" : "Phone"}: ${c.phone} • ${c.routeArea}'),
                              trailing: Text(
                                '${c.currentBalance.toStringAsFixed(2)} $curr',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: c.currentBalance > 0 ? AppColors.expenseRed : Colors.green,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
                                );
                              },
                            ),
                          )),
                      const SizedBox(height: 14),
                    ],

                    // Products Section
                    if (matchedProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          lang.isArabic ? 'نتائج الأصناف (Products):' : 'Products & Stock Results:',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      ...matchedProducts.map((p) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2, color: AppColors.secondary),
                              title: Text(lang.isArabic ? p.nameAr : p.nameEn),
                              subtitle: Text('${lang.isArabic ? "باركود" : "Barcode"}: ${p.barcode} • ${lang.isArabic ? "الرصيد" : "Stock"}: ${p.getTotalStock().toInt()} ${p.baseUnit}'),
                              trailing: Text(
                                '${p.retailPrice.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onTap: () => _showProductStockBreakdown(context, p, db, lang, curr),
                            ),
                          )),
                    ],

                    if (matchedInvoices.isEmpty && matchedCustomers.isEmpty && matchedProducts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(lang.isArabic ? 'لا توجد نتائج مطابقة لبحثك' : 'No results found matching your search'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProductStockBreakdown(
    BuildContext context,
    ProductModel product,
    DatabaseService db,
    AppLanguage lang,
    String curr,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.isArabic ? product.nameAr : product.nameEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('SKU: ${product.sku} • Barcode: ${product.barcode}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(
                lang.isArabic ? 'توزيع الرصيد في المستودعات والسيارات:' : 'Stock Distribution per Location:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...db.warehouses.map((w) {
                final stock = product.stockByWarehouse[w.id] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(w.isVan ? Icons.local_shipping : Icons.warehouse, size: 16, color: w.isVan ? AppColors.primary : Colors.grey),
                          const SizedBox(width: 8),
                          Text(w.nameAr, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Text(
                        '${stock.toInt()} ${product.baseUnit}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: stock > 0 ? AppColors.primaryDark : Colors.red),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang.isArabic ? 'سعر الجملة:' : 'Wholesale:'),
                  Text('${product.wholesalePrice.toStringAsFixed(2)} $curr', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang.isArabic ? 'سعر البيع بالتجزئة (شامل الضريبة):' : 'Retail Price (Incl. VAT):'),
                  Text('${product.retailPrice.toStringAsFixed(2)} $curr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saleGreen)),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
}
