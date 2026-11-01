import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/expense_model.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        final totalExpenses = db.expenses.fold(0.0, (sum, exp) => sum + exp.totalWithVat);

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'المصروفات وإدارة العهدة' : 'Expenses & Float Management'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Expenses Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long, color: AppColors.expenseRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.isArabic ? 'إجمالي المصروفات المسجلة:' : 'Total Recorded Expenses:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${totalExpenses.toStringAsFixed(2)} $curr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.expenseRed),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  lang.isArabic ? 'سجل المصروفات' : 'Expense Records',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),

                if (db.expenses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(
                      child: Text(
                        lang.isArabic ? 'لا توجد مصروفات مسجلة' : 'No expense records found',
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: db.expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exp = db.expenses[index];
                      final catLabel = _getCategoryLabel(exp.category, lang);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.expenseRed.withOpacity(0.1),
                            child: const Icon(Icons.local_gas_station, color: AppColors.expenseRed),
                          ),
                          title: Text(catLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${exp.description}\n${lang.isArabic ? "بواسطة" : "By"}: ${exp.spentByUserName} • ${exp.paymentMode}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${exp.totalWithVat.toStringAsFixed(2)} $curr',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                              ),
                              Text('VAT: ${exp.vatAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddExpenseDialog(context, lang),
            backgroundColor: AppColors.expenseRed,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              lang.isArabic ? 'تسجيل مصروف جديد' : '+ Record Expense',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  static String _getCategoryLabel(ExpenseCategory cat, AppLanguage lang) {
    if (lang.isArabic) {
      switch (cat) {
        case ExpenseCategory.fuelAndVehicle:
          return 'وقود ومصاريف السيارة';
        case ExpenseCategory.maintenance:
          return 'صيانة وإصلاحات';
        case ExpenseCategory.foodAndPerDiem:
          return 'إعاشة وبدلات ميدانية';
        default:
          return 'مصروفات تشغيلية أخرى';
      }
    } else {
      switch (cat) {
        case ExpenseCategory.fuelAndVehicle:
          return 'Fuel & Vehicle Running';
        case ExpenseCategory.maintenance:
          return 'Maintenance & Repairs';
        case ExpenseCategory.foodAndPerDiem:
          return 'Per Diem & Meals';
        default:
          return 'Other Operating Expenses';
      }
    }
  }

  void _showAddExpenseDialog(BuildContext context, AppLanguage lang) {
    final db = DatabaseService();
    final auth = AuthService();
    ExpenseCategory selectedCategory = ExpenseCategory.fuelAndVehicle;
    double amount = 0.0;
    String description = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.isArabic ? 'تسجيل سند صرف جديد' : 'Record New Van Expense',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ExpenseCategory>(
                    isExpanded: true,
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: lang.isArabic ? 'بند المصروف' : 'Expense Category',
                    ),
                    items: ExpenseCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(_getCategoryLabel(cat, lang), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (c) {
                      if (c != null) setModalState(() => selectedCategory = c);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.isArabic ? 'المبلغ قبل الضريبة (ر.س)' : 'Amount Excl. VAT (SAR)',
                    ),
                    onChanged: (val) => amount = double.tryParse(val) ?? 0.0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: lang.isArabic
                          ? 'البيان والتفاصيل (مثل اسم المحطة / الورشة)'
                          : 'Description & Details (e.g. Gas Station / Workshop)',
                    ),
                    onChanged: (val) => description = val,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (amount <= 0) return;
                        final vat = amount * 0.15;
                        final newExp = ExpenseModel(
                          id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
                          expenseNumber: 'EXP-${db.expenses.length + 101}',
                          category: selectedCategory,
                          amount: amount,
                          vatAmount: vat,
                          date: DateTime.now(),
                          paymentMode: lang.isArabic ? 'نقداً - Cash' : 'Cash',
                          vanId: auth.currentUser.assignedVanId,
                          spentByUserId: auth.currentUser.id,
                          spentByUserName: auth.currentUser.name,
                          description: description.isEmpty
                              ? (lang.isArabic ? 'مصروف ميداني' : 'Field Expense')
                              : description,
                        );
                        db.addExpense(newExp);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.isArabic ? 'تم تسجيل المصروف بنجاح!' : 'Expense recorded successfully!',
                            ),
                            backgroundColor: AppColors.saleGreen,
                          ),
                        );
                      },
                      child: Text(lang.isArabic ? 'حفظ المصروف' : 'Save Expense'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
