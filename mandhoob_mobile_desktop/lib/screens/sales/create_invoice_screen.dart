import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/printer_service.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_item_model.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import 'invoice_detail_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final InvoiceType defaultType;
  final CustomerModel? preselectedCustomer;
  final String? preselectedWarehouseId;

  const CreateInvoiceScreen({
    super.key,
    this.defaultType = InvoiceType.simplifiedTaxInvoice,
    this.preselectedCustomer,
    this.preselectedWarehouseId,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late InvoiceType _selectedType;
  CustomerModel? _selectedCustomer;
  late String _selectedWarehouseId;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  final List<InvoiceItemModel> _items = [];
  final double _discountTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
    final auth = AuthService();
    final db = DatabaseService();

    // Default to salesman's van or first warehouse
    _selectedWarehouseId = widget.preselectedWarehouseId ??
        auth.currentUser.assignedVanId ??
        (db.warehouses.isNotEmpty ? db.warehouses.first.id : 'WH-MAIN');

    // Default to preselected or first customer
    if (widget.preselectedCustomer != null) {
      _selectedCustomer = widget.preselectedCustomer;
    } else if (db.customers.isNotEmpty) {
      _selectedCustomer = db.customers.first;
    }
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.lineSubtotal) - _discountTotal;
  double get _vatTotal => _items.fold(0.0, (sum, i) => sum + i.lineVatAmount);
  double get _grandTotal => _subtotal + _vatTotal;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguage(),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              lang.isArabic ? 'إنشاء فاتورة مبيعات' : 'Create Sales Invoice',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: lang.isArabic ? 'حفظ وطباعة إيصال حراري' : 'Save & Print',
                onPressed: _items.isEmpty ? null : () => _saveAndPrintInvoice(context, true),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Invoice Type Selector Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypePill(
                        type: InvoiceType.simplifiedTaxInvoice,
                        label: lang.isArabic ? 'فاتورة مبسطة (سيارة)' : 'Simplified (Van Sale)',
                      ),
                      const SizedBox(width: 8),
                      _buildTypePill(
                        type: InvoiceType.taxInvoice,
                        label: lang.isArabic ? 'ضريبية (B2B)' : 'Standard Tax (B2B)',
                      ),
                      const SizedBox(width: 8),
                      _buildTypePill(
                        type: InvoiceType.salesReturn,
                        label: lang.isArabic ? 'مرتجع مبيعات' : 'Sales Return',
                      ),
                      const SizedBox(width: 8),
                      _buildTypePill(
                        type: InvoiceType.quotation,
                        label: lang.isArabic ? 'عرض أسعار' : 'Quotation',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Customer Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lang.isArabic ? 'العميل' : 'Customer',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (_selectedCustomer != null)
                              Flexible(
                                child: Text(
                                  '${lang.isArabic ? "الرصيد" : "Balance"}: ${_selectedCustomer!.currentBalance.toStringAsFixed(2)} $curr',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _selectedCustomer!.currentBalance > 0 ? AppColors.expenseRed : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<CustomerModel>(
                          isExpanded: true,
                          value: _selectedCustomer,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person, color: AppColors.primary),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: db.customers.map((c) {
                            final name = lang.isArabic ? c.nameAr : c.nameEn;
                            final dist = c.district != null && c.district!.isNotEmpty ? ' (${c.district})' : '';
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                '$name$dist',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (c) => setState(() => _selectedCustomer = c),
                        ),
                        if (_selectedCustomer != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${lang.isArabic ? "سقف الائتمان" : "Limit"}: ${_selectedCustomer!.creditLimit.toStringAsFixed(0)} $curr',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${lang.isArabic ? "المتبقي" : "Available"}: ${_selectedCustomer!.availableCredit.toStringAsFixed(2)} $curr',
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedCustomer!.availableCredit < 1000 ? AppColors.expenseRed : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedPaymentMethod == PaymentMethod.credit &&
                              _selectedCustomer!.isCreditExceeded(_grandTotal)) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lang.isArabic
                                          ? 'تنبيه: قيمة هذه الفاتورة الآجلة (${_grandTotal.toStringAsFixed(2)} $curr) ستتجاوز سقف الائتمان المسموح به (${_selectedCustomer!.creditLimit.toStringAsFixed(0)} $curr)!'
                                          : 'Warning: This credit invoice (${_grandTotal.toStringAsFixed(2)} $curr) will exceed credit limit (${_selectedCustomer!.creditLimit.toStringAsFixed(0)} $curr)!',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Warehouse / Van Location Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: AppColors.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedWarehouseId,
                            decoration: InputDecoration(
                              labelText: lang.isArabic ? 'المستودع / سيارة الصرف' : 'Warehouse / Van',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: db.warehouses.map((w) {
                              return DropdownMenuItem(
                                value: w.id,
                                child: Text(
                                  lang.isArabic ? w.nameAr : w.nameEn,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (w) {
                              if (w != null) setState(() => _selectedWarehouseId = w);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Line Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.isArabic ? 'الأصناف' : 'Invoice Items',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddItemDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(lang.isArabic ? 'إضافة صنف' : '+ Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saleGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          lang.isArabic
                              ? 'لم يتم إضافة أصناف بعد، اضغط على زر "إضافة صنف"'
                              : 'No items added yet, tap "+ Add Item"',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      lang.isArabic ? item.productNameAr : item.productNameEn,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() => _items.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quantity Controls
                                  Row(
                                    children: [
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.remove, size: 15),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        padding: EdgeInsets.zero,
                                        onPressed: item.quantity > 1
                                            ? () {
                                                setState(() {
                                                  _items[index] = InvoiceItemModel(
                                                    productId: item.productId,
                                                    productNameAr: item.productNameAr,
                                                    productNameEn: item.productNameEn,
                                                    barcode: item.barcode,
                                                    quantity: item.quantity - 1,
                                                    unit: item.unit,
                                                    unitPrice: item.unitPrice,
                                                    discount: item.discount,
                                                  );
                                                });
                                              }
                                            : null,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          '${item.quantity.toInt()} ${item.unit}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.add, size: 15),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          setState(() {
                                            _items[index] = InvoiceItemModel(
                                              productId: item.productId,
                                              productNameAr: item.productNameAr,
                                              productNameEn: item.productNameEn,
                                              barcode: item.barcode,
                                              quantity: item.quantity + 1,
                                              unit: item.unit,
                                              unitPrice: item.unitPrice,
                                              discount: item.discount,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  // Price & Line Total
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item.unitPrice.toStringAsFixed(2)} × ${item.quantity.toInt()}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        '${item.lineTotalWithVat.toStringAsFixed(2)} $curr',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        lang.isArabic ? 'شامل 15% ضريبة' : 'Incl. 15% VAT',
                                        style: const TextStyle(fontSize: 9, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // Payment Mode Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.isArabic ? 'طريقة التحصيل' : 'Payment Method',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildPaymentChip(PaymentMethod.cash, lang.isArabic ? 'نقداً (Cash)' : 'Cash', Icons.money),
                            _buildPaymentChip(PaymentMethod.madaCard, lang.isArabic ? 'شبكة / مدى (Mada)' : 'Mada / Card', Icons.credit_card),
                            _buildPaymentChip(PaymentMethod.bankTransfer, lang.isArabic ? 'تحويل بنكي' : 'Bank Transfer', Icons.account_balance),
                            _buildPaymentChip(PaymentMethod.credit, lang.isArabic ? 'آجل (على الحساب)' : 'Credit (Account)', Icons.receipt_long),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Financial Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(lang.isArabic ? 'المجموع قبل الضريبة' : 'Subtotal (Excl. VAT)', '${_subtotal.toStringAsFixed(2)} $curr'),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        lang.isArabic ? 'ضريبة القيمة المضافة 15%' : 'VAT 15%',
                        '${_vatTotal.toStringAsFixed(2)} $curr',
                        isTax: true,
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        lang.isArabic ? 'الإجمالي النهائي المستحق' : 'Grand Total Due',
                        '${_grandTotal.toStringAsFixed(2)} $curr',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.isArabic ? 'الإجمالي النهائي' : 'Grand Total',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${_grandTotal.toStringAsFixed(2)} $curr',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _items.isEmpty ? null : () => _saveAndPrintInvoice(context, true),
                    icon: const Icon(Icons.print, size: 17),
                    label: Text(
                      lang.isArabic ? 'حفظ وطباعة' : 'Save & Print',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saleGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypePill({required InvoiceType type, required String label}) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return ChoiceChip(
      selected: isSelected,
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
      label: Text(label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedPaymentMethod = method),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTax = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTax ? Colors.green.shade700 : AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final db = DatabaseService();
    final lang = AppLanguage();
    if (db.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isArabic ? 'لا توجد منتجات مسجلة بالمخزون. يرجى إضافة أصناف أولاً.' : 'No products in inventory. Please add products first.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }
    ProductModel selectedProd = db.products.first;
    double qty = 1.0;
    String unit = selectedProd.baseUnit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final vanStock = selectedProd.stockByWarehouse[_selectedWarehouseId] ?? 0.0;
            final lang = AppLanguage();
            final curr = lang.isArabic ? 'ر.س' : 'SAR';
            final mediaQuery = MediaQuery.of(modalCtx);
            final keyboard = mediaQuery.viewInsets.bottom;
            final systemBottom = mediaQuery.viewPadding.bottom;

            return SafeArea(
              top: false,
              bottom: true,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 14,
                  bottom: keyboard > 0 ? keyboard + 16 : (systemBottom > 0 ? systemBottom + 12 : 28),
                ),
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.9,
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang.isArabic ? 'اختر الصنف من المخزون' : 'Select Product from Stock',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductModel>(
                    isExpanded: true,
                    value: selectedProd,
                    items: db.products.map((p) {
                      final name = lang.isArabic ? p.nameAr : p.nameEn;
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          '$name (${p.retailPrice.toStringAsFixed(2)} $curr)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (p) {
                      if (p != null) {
                        setModalState(() {
                          selectedProd = p;
                          unit = p.baseUnit;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: vanStock > 10 ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 16,
                          color: vanStock > 10 ? Colors.green : Colors.amber.shade900,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lang.isArabic
                                ? 'الرصيد المتاح في هذا الموقع: ${vanStock.toInt()} ${selectedProd.baseUnit}'
                                : 'Available stock in location: ${vanStock.toInt()} ${selectedProd.baseUnit}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: vanStock > 10 ? Colors.green.shade800 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'الوحدة' : 'Unit',
                          ),
                          items: [
                            DropdownMenuItem(
                              value: selectedProd.baseUnit,
                              child: Text(selectedProd.baseUnit),
                            ),
                            if (selectedProd.secondaryUnit != null)
                              DropdownMenuItem(
                                value: selectedProd.secondaryUnit!,
                                child: Text(selectedProd.secondaryUnit!),
                              ),
                          ],
                          onChanged: (u) {
                            if (u != null) setModalState(() => unit = u);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: '1',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.isArabic ? 'الكمية' : 'Quantity',
                          ),
                          onChanged: (val) {
                            qty = double.tryParse(val) ?? 1.0;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _items.add(
                            InvoiceItemModel(
                              productId: selectedProd.id,
                              productNameAr: selectedProd.nameAr,
                              productNameEn: selectedProd.nameEn,
                              barcode: selectedProd.barcode,
                              quantity: qty,
                              unit: unit,
                              unitPrice: selectedProd.retailPrice,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(lang.isArabic ? 'إضافة إلى الفاتورة' : 'Add to Invoice'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
);
}

  void _saveAndPrintInvoice(BuildContext context, bool triggerPrint) {
    if (_selectedCustomer == null || _items.isEmpty) return;

    final db = DatabaseService();
    final auth = AuthService();
    final newInvNumber = 'INV-2026-${db.invoices.length + 101}';
    final lang = AppLanguage();

    final invoice = InvoiceModel(
      id: newInvNumber,
      invoiceNumber: newInvNumber,
      type: _selectedType,
      invoiceDate: DateTime.now(),
      customerId: _selectedCustomer!.id,
      customerNameAr: _selectedCustomer!.nameAr,
      customerNameEn: _selectedCustomer!.nameEn,
      customerVatNumber: _selectedCustomer!.vatNumber,
      customerPhone: _selectedCustomer!.phone,
      warehouseId: _selectedWarehouseId,
      warehouseName: db.warehouses.any((w) => w.id == _selectedWarehouseId)
          ? db.warehouses.firstWhere((w) => w.id == _selectedWarehouseId).nameAr
          : (db.warehouses.isNotEmpty ? db.warehouses.first.nameAr : _selectedWarehouseId),
      salesmanId: auth.currentUser.id,
      salesmanName: auth.currentUser.name,
      items: List.from(_items),
      discountTotal: _discountTotal,
      paymentMethod: _selectedPaymentMethod,
      paymentStatus: _selectedPaymentMethod == PaymentMethod.credit ? PaymentStatus.unpaid : PaymentStatus.paid,
      paidAmount: _selectedPaymentMethod == PaymentMethod.credit ? 0.0 : _grandTotal,
      isSynced: false,
    );

    db.addInvoice(invoice);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.isArabic
              ? 'تم إنشاء الفاتورة رقم $newInvNumber بنجاح!'
              : 'Invoice $newInvNumber created successfully!',
        ),
        backgroundColor: AppColors.saleGreen,
      ),
    );

    if (triggerPrint) {
      PrinterService().printInvoiceThermal(invoice);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoice: invoice),
      ),
    );
  }
}
