import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/expense_model.dart';
import '../../widgets/date_filter_bar.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  DateFilterPreset _datePreset = DateFilterPreset.all;
  DateTimeRange? _customDateRange;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage(), AuthService()]),
      builder: (context, _) {
        final db = DatabaseService();
        final lang = AppLanguage();
        final auth = AuthService();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';

        // Filter expenses by Date + Category + Search
        final filteredExpenses = db.expenses.where((exp) {
          // 1. Date filter
          if (!DateFilterHelper.matches(exp.date, _datePreset, _customDateRange)) {
            return false;
          }
          // 2. Category filter
          if (_selectedCategory != null && exp.category != _selectedCategory) {
            return false;
          }
          // 3. Search query (description, number, user, payment mode, van)
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase().trim();
            final matchesDesc = exp.description.toLowerCase().contains(q);
            final matchesNum = exp.expenseNumber.toLowerCase().contains(q);
            final matchesUser = exp.spentByUserName.toLowerCase().contains(q);
            final matchesMode = exp.paymentMode.toLowerCase().contains(q);
            final matchesVan = exp.vanId?.toLowerCase().contains(q) ?? false;
            return matchesDesc || matchesNum || matchesUser || matchesMode || matchesVan;
          }
          return true;
        }).toList();

        final totalFiltered = filteredExpenses.fold(0.0, (sum, exp) => sum + exp.totalWithVat);
        final hasActiveFilter = _searchQuery.isNotEmpty ||
            _selectedCategory != null ||
            _datePreset != DateFilterPreset.all;

        return Scaffold(
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: lang.isArabic
                            ? 'ابحث برقم السند أو البيان أو اسم الموظف...'
                            : 'Search expense #, description or employee...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: AppColors.expenseRed, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 6),
                    // Category Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip(
                            label: lang.isArabic ? 'كافة الفئات' : 'All Categories',
                            isSelected: _selectedCategory == null,
                            onTap: () => setState(() => _selectedCategory = null),
                          ),
                          const SizedBox(width: 6),
                          ...ExpenseCategory.values.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _buildCategoryChip(
                                label: _getCategoryLabel(cat, lang),
                                isSelected: _selectedCategory == cat,
                                onTap: () => setState(() => _selectedCategory = _selectedCategory == cat ? null : cat),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Date Filter Bar
                    DateFilterBar(
                      selectedPreset: _datePreset,
                      customRange: _customDateRange,
                      onPresetChanged: (preset) => setState(() => _datePreset = preset),
                      onCustomRangeChanged: (range) => setState(() => _customDateRange = range),
                    ),
                  ],
                ),
              ),

              // Total & Filter Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColors.expenseRed, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${lang.isArabic ? "المصروفات المعروضة" : "Displayed Expenses"}: ${filteredExpenses.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.expenseRed),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${totalFiltered.toStringAsFixed(2)} $curr',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.expenseRed),
                        ),
                        if (hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() {
                              _searchQuery = '';
                              _selectedCategory = null;
                              _datePreset = DateFilterPreset.all;
                              _customDateRange = null;
                            }),
                            child: Row(
                              children: [
                                const Icon(Icons.refresh, size: 12, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  lang.isArabic ? 'إعادة ضبط' : 'Reset',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Expenses List
              Expanded(
                child: filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              lang.isArabic
                                  ? 'لا توجد مصروفات مسجلة تطابق معايير البحث والتاريخ'
                                  : 'No expense records found matching filters',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredExpenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final exp = filteredExpenses[index];
                          final catLabel = _getCategoryLabel(exp.category, lang);
                          return Card(
                            elevation: 1,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.expenseRed.withOpacity(0.1),
                                child: const Icon(Icons.local_gas_station, color: AppColors.expenseRed),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(catLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    '${exp.totalWithVat.toStringAsFixed(2)} $curr',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed, fontSize: 13),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${exp.description}\n${exp.expenseNumber} • ${exp.date.toString().substring(0, 10)} • ${lang.isArabic ? "بواسطة" : "By"}: ${exp.spentByUserName} (${exp.paymentMode})',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
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

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.expenseRed : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.red.shade700 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const SizedBox(height: 14),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
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
                      child: Text(lang.isArabic ? 'حفظ المصروف' : 'Save Expense', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}
