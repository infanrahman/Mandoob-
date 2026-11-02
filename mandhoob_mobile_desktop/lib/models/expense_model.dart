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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expenseNumber': expenseNumber,
      'category': category.name,
      'amount': amount,
      'vatAmount': vatAmount,
      'date': date.toIso8601String(),
      'paymentMode': paymentMode,
      'vanId': vanId,
      'spentByUserId': spentByUserId,
      'spentByUserName': spentByUserName,
      'description': description,
      'hasReceiptAttachment': hasReceiptAttachment,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    ExpenseCategory parsedCat = ExpenseCategory.miscellaneous;
    try {
      parsedCat = ExpenseCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ExpenseCategory.miscellaneous,
      );
    } catch (_) {}

    return ExpenseModel(
      id: json['id'] as String? ?? 'EXP-${DateTime.now().millisecondsSinceEpoch}',
      expenseNumber: json['expenseNumber'] as String? ?? 'EXP-101',
      category: parsedCat,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) ?? DateTime.now() : DateTime.now(),
      paymentMode: json['paymentMode'] as String? ?? 'نقداً - Cash',
      vanId: json['vanId'] as String?,
      spentByUserId: json['spentByUserId'] as String? ?? 'USR-001',
      spentByUserName: json['spentByUserName'] as String? ?? 'Admin',
      description: json['description'] as String? ?? '',
      hasReceiptAttachment: json['hasReceiptAttachment'] as bool? ?? false,
    );
  }
}
