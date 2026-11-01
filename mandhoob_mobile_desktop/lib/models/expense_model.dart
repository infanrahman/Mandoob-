enum ExpenseCategory {
  fuelAndVehicle,
  foodAndPerDiem,
  maintenance,
  rentAndUtilities,
  salaries,
  officeSupplies,
  miscellaneous,
}

class ExpenseModel {
  final String id;
  final String expenseNumber;
  final ExpenseCategory category;
  final double amount;
  final double vatAmount;
  final DateTime date;
  final String paymentMode; // Cash, Card, Transfer
  final String? vanId;
  final String spentByUserId;
  final String spentByUserName;
  final String description;
  final bool hasReceiptAttachment;

  ExpenseModel({
    required this.id,
    required this.expenseNumber,
    required this.category,
    required this.amount,
    this.vatAmount = 0.0,
    required this.date,
    required this.paymentMode,
    this.vanId,
    required this.spentByUserId,
    required this.spentByUserName,
    required this.description,
    this.hasReceiptAttachment = false,
  });

  double get totalWithVat => amount + vatAmount;

  String get categoryNameAr {
    switch (category) {
      case ExpenseCategory.fuelAndVehicle:
        return 'وقود ومصاريف السيارة';
      case ExpenseCategory.foodAndPerDiem:
        return 'إعاشة وبدلات ميدانية';
      case ExpenseCategory.maintenance:
        return 'صيانة وإصلاحات';
      case ExpenseCategory.rentAndUtilities:
        return 'إيجار وخدمات عامة';
      case ExpenseCategory.salaries:
        return 'رواتب ومكافآت';
      case ExpenseCategory.officeSupplies:
        return 'أدوات مكتبية ومطبوعات';
      case ExpenseCategory.miscellaneous:
        return 'مصاريف أخرى متنوعة';
    }
  }
}
