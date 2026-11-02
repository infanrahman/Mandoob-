import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/supplier_model.dart';
import '../../models/stock_transfer_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'payment_out_dialog.dart';

class SupplierDetailScreen extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        final currentSupp = db.suppliers.firstWhere(
          (s) => s.id == supplier.id,
          orElse: () => supplier,
        );

        final supplierPayments = db.paymentVouchers.where((v) => v.partyId == currentSupp.id).toList();
        final supplierBills = db.expenses
            .where((e) => e.description.contains(currentSupp.nameAr) || e.description.contains(currentSupp.nameEn))
            .toList();
        final creditUsedRatio = currentSupp.creditUtilizationRatio;

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? currentSupp.nameAr : currentSupp.nameEn),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Supplier Profile & Payables Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic ? currentSupp.nameAr : currentSupp.nameEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  lang.isArabic ? currentSupp.nameEn : currentSupp.nameAr,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showRecordPurchaseDialog(context, currentSupp, db, lang),
                                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                                  label: Text(lang.isArabic ? '+ فاتورة شراء' : '+ Purchase Bill'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PaymentOutDialog(supplier: currentSupp),
                                    );
                                  },
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: Text(lang.isArabic ? 'سند صرف' : 'Payment Out'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.purchaseBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.isArabic ? 'المستحق للمورد' : 'Payable',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentSupp.currentBalance.toStringAsFixed(2)} $curr',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.purchaseBlue),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    lang.isArabic ? 'سقف الائتمان' : 'Credit Limit',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentSupp.creditLimit.toStringAsFixed(0)} $curr',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.isArabic ? 'المتبقي للشراء' : 'Available',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentSupp.availableCredit.toStringAsFixed(2)} $curr',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: creditUsedRatio,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purchaseBlue),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${lang.isArabic ? "نسبة السقف المستخدم" : "Credit Utilized"}: ${(creditUsedRatio * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${lang.isArabic ? "شروط السداد" : "Credit Terms"}: ${currentSupp.creditPeriodDays} ${lang.isArabic ? "يوم" : "Days"}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(currentSupp.phone),
                            const Spacer(),
                            if (currentSupp.vatNumber != null)
                              Text('VAT: ${currentSupp.vatNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Statement of Account / Payments History
                Text(
                  lang.isArabic ? 'كشف حساب المورد وحركات السداد / Ledger' : 'Supplier Statement of Account / Payments',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                if (supplierPayments.isEmpty && supplierBills.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(child: Text(lang.isArabic ? 'لا توجد حركات مسجلة لهذا المورد' : 'No transactions recorded for this supplier')),
                  )
                else ...[
                  // Inward Purchase Bills (Credit / Payable In)
                  ...supplierBills.map((bill) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFEF3C7),
                            child: Icon(Icons.inventory_2, color: Colors.orange),
                          ),
                          title: Row(
                            children: [
                              Text(bill.expenseNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lang.isArabic ? 'فاتورة مشتريات' : 'Purchase Bill',
                                  style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('${bill.date.toString().substring(0, 16)} • ${bill.paymentMode}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+ ${bill.totalWithVat.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 14),
                              ),
                              Text(
                                lang.isArabic ? 'مشتريات واردة (دائن)' : 'Bill In (Credit)',
                                style: const TextStyle(fontSize: 11, color: Colors.deepOrange),
                              ),
                            ],
                          ),
                        ),
                      )),

                  // Payment Out Vouchers (Settlement / Debit)
                  ...supplierPayments.map((voucher) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.arrow_upward, color: AppColors.purchaseBlue),
                          ),
                          title: Row(
                            children: [
                              Text(voucher.voucherNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lang.isArabic ? voucher.typeDisplayNameAr : 'Payment Out',
                                  style: const TextStyle(fontSize: 10, color: AppColors.purchaseBlue, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('${voucher.date.toString().substring(0, 16)} • ${lang.isArabic ? voucher.paymentModeDisplayNameAr : "Transfer"}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '- ${voucher.amount.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue, fontSize: 14),
                              ),
                              Text(
                                lang.isArabic ? 'سداد دفعة (مدين)' : 'Payment Out (Debit)',
                                style: const TextStyle(fontSize: 11, color: AppColors.purchaseBlue),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecordPurchaseDialog(
    BuildContext context,
    SupplierModel supplier,
    DatabaseService db,
    AppLanguage lang,
  ) {
    final auth = AuthService();
    String selectedWarehouseId = 'WH-MAIN';
    String selectedProductId = db.products.isNotEmpty ? db.products.first.id : '';
    final qtyController = TextEditingController(text: '100');
    final unitCostController = TextEditingController(
      text: db.products.isNotEmpty ? db.products.first.wholesalePrice.toStringAsFixed(2) : '10',
    );
    String paymentMode = 'Credit - آجل';
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final qty = double.tryParse(qtyController.text) ?? 0.0;
            final cost = double.tryParse(unitCostController.text) ?? 0.0;
            final subtotal = qty * cost;
            final vat = subtotal * 0.15;
            final total = subtotal + vat;
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
                    Text(
                      '${lang.isArabic ? "تسجيل فاتورة شراء من" : "Record Bill from"}: ${supplier.nameAr}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: selectedWarehouseId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'مستودع الاستلام' : 'Receiving Warehouse'),
                      items: db.warehouses.map((w) {
                        return DropdownMenuItem(value: w.id, child: Text(w.nameAr, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedWarehouseId = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedProductId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'الصنف المستلم' : 'Product'),
                      items: db.products.map((p) {
                        return DropdownMenuItem(value: p.id, child: Text('${p.nameAr} (${p.sku})', overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedProductId = val;
                            final prod = db.products.firstWhere((p) => p.id == val);
                            unitCostController.text = prod.wholesalePrice.toStringAsFixed(2);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: lang.isArabic ? 'الكمية' : 'Quantity'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: unitCostController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: lang.isArabic ? 'سعر التكلفة (ر.س)' : 'Cost (SAR)'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: paymentMode,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'شروط السداد' : 'Payment Mode'),
                      items: const [
                        DropdownMenuItem(value: 'Credit - آجل', child: Text('آجل (زيادة الرصيد المستحق للمورد)')),
                        DropdownMenuItem(value: 'Cash - نقداً', child: Text('نقداً (خزينة المشتريات)')),
                        DropdownMenuItem(value: 'Bank - تحويل بنكي', child: Text('تحويل بنكي')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => paymentMode = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(labelText: lang.isArabic ? 'ملاحظات / رقم الفاتورة الورقية' : 'Notes / Vendor Invoice #'),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lang.isArabic ? 'الإجمالي شامل الضريبة 15%:' : 'Total Incl. 15% VAT:'),
                          Text('${total.toStringAsFixed(2)} SAR', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purchaseBlue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.purchaseBlue),
                        onPressed: () {
                          if (qty <= 0 || cost <= 0) return;
                          final prod = db.products.firstWhere((p) => p.id == selectedProductId);
                          final item = StockTransferItem(
                            productId: prod.id,
                            productName: prod.nameAr,
                            quantity: qty,
                            unit: prod.baseUnit,
                          );

                          db.recordPurchaseBill(
                            supplierId: supplier.id,
                            warehouseId: selectedWarehouseId,
                            items: [item],
                            subtotal: subtotal,
                            vatAmount: vat,
                            paymentMode: paymentMode,
                            createdByUserId: auth.currentUser.id,
                            createdByUserName: auth.currentUser.name,
                            notes: notesController.text.trim(),
                          );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.isArabic
                                    ? 'تم قيد فاتورة الشراء وزيادة المخزون والمستحقات بنجاح!'
                                    : 'Purchase bill recorded and stock added successfully!',
                              ),
                              backgroundColor: AppColors.saleGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(lang.isArabic ? 'اعتماد فاتورة الشراء' : 'Approve Bill', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
}
