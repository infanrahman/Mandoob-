enum RouteStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum StopVisitStatus {
  pending,
  visited,
  skipped,
}

class CustomerRouteStop {
  final String customerId;
  final String customerNameAr;
  final String district;
  final String phone;
  final double currentBalance;
  final double creditLimit;
  final int sequenceOrder; // 1, 2, 3... order on the delivery route
  final StopVisitStatus status;
  final DateTime? visitedAt;
  final String? invoiceId;
  final double? invoiceAmount;
  final double? collectedAmount;

  CustomerRouteStop({
    required this.customerId,
    required this.customerNameAr,
    required this.district,
    required this.phone,
    required this.currentBalance,
    required this.creditLimit,
    required this.sequenceOrder,
    this.status = StopVisitStatus.pending,
    this.visitedAt,
    this.invoiceId,
    this.invoiceAmount,
    this.collectedAmount,
  });

  CustomerRouteStop copyWith({
    StopVisitStatus? status,
    DateTime? visitedAt,
    String? invoiceId,
    double? invoiceAmount,
    double? collectedAmount,
  }) {
    return CustomerRouteStop(
      customerId: customerId,
      customerNameAr: customerNameAr,
      district: district,
      phone: phone,
      currentBalance: currentBalance,
      creditLimit: creditLimit,
      sequenceOrder: sequenceOrder,
      status: status ?? this.status,
      visitedAt: visitedAt ?? this.visitedAt,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
    );
  }

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'customerNameAr': customerNameAr,
    'district': district,
    'phone': phone,
    'currentBalance': currentBalance,
    'creditLimit': creditLimit,
    'sequenceOrder': sequenceOrder,
    'status': status.name,
    'visitedAt': visitedAt?.toIso8601String(),
    'invoiceId': invoiceId,
    'invoiceAmount': invoiceAmount,
    'collectedAmount': collectedAmount,
  };

  factory CustomerRouteStop.fromJson(Map<String, dynamic> json) => CustomerRouteStop(
    customerId: json['customerId'] as String? ?? '',
    customerNameAr: json['customerNameAr'] as String? ?? '',
    district: json['district'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
    creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
    sequenceOrder: json['sequenceOrder'] as int? ?? 1,
    status: StopVisitStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => StopVisitStatus.pending,
    ),
    visitedAt: json['visitedAt'] != null ? DateTime.parse(json['visitedAt'] as String) : null,
    invoiceId: json['invoiceId'] as String?,
    invoiceAmount: (json['invoiceAmount'] as num?)?.toDouble(),
    collectedAmount: (json['collectedAmount'] as num?)?.toDouble(),
  );
}

class DailyVanSettlement {
  final double openingCashFloat; // Starting morning cash in van (e.g., 500 SAR)
  final double totalCashSales;
  final double totalMadaSales;
  final double totalCreditSales;
  final double totalCollections; // Payment in for old customer debts
  final double totalVanExpenses; // Fuel, maintenance
  final double expectedCashHandover; // Float + Cash Sales + Collections - Expenses
  final double? actualCashHandedOver;
  final bool isReconciledByAdmin;
  final String? adminReconciliationNotes;

  DailyVanSettlement({
    this.openingCashFloat = 500.0,
    required this.totalCashSales,
    required this.totalMadaSales,
    required this.totalCreditSales,
    required this.totalCollections,
    required this.totalVanExpenses,
    required this.expectedCashHandover,
    this.actualCashHandedOver,
    this.isReconciledByAdmin = false,
    this.adminReconciliationNotes,
  });

  Map<String, dynamic> toJson() => {
    'openingCashFloat': openingCashFloat,
    'totalCashSales': totalCashSales,
    'totalMadaSales': totalMadaSales,
    'totalCreditSales': totalCreditSales,
    'totalCollections': totalCollections,
    'totalVanExpenses': totalVanExpenses,
    'expectedCashHandover': expectedCashHandover,
    'actualCashHandedOver': actualCashHandedOver,
    'isReconciledByAdmin': isReconciledByAdmin,
    'adminReconciliationNotes': adminReconciliationNotes,
  };

  factory DailyVanSettlement.fromJson(Map<String, dynamic> json) => DailyVanSettlement(
    openingCashFloat: (json['openingCashFloat'] as num?)?.toDouble() ?? 0.0,
    totalCashSales: (json['totalCashSales'] as num?)?.toDouble() ?? 0.0,
    totalMadaSales: (json['totalMadaSales'] as num?)?.toDouble() ?? 0.0,
    totalCreditSales: (json['totalCreditSales'] as num?)?.toDouble() ?? 0.0,
    totalCollections: (json['totalCollections'] as num?)?.toDouble() ?? 0.0,
    totalVanExpenses: (json['totalVanExpenses'] as num?)?.toDouble() ?? 0.0,
    expectedCashHandover: (json['expectedCashHandover'] as num?)?.toDouble() ?? 0.0,
    actualCashHandedOver: (json['actualCashHandedOver'] as num?)?.toDouble(),
    isReconciledByAdmin: json['isReconciledByAdmin'] as bool? ?? false,
    adminReconciliationNotes: json['adminReconciliationNotes'] as String?,
  );
}

class VanSalesmanProgressModel {
  final String salesmanId;
  final String salesmanName;
  final String phone;
  final String vanId;
  final String vanName;
  final String vehiclePlateNumber;
  final DateTime date;

  // 1. Target & Actual KPIs
  final double dailySalesTarget;
  final double actualSalesAchieved;
  final double dailyCollectionTarget;
  final double actualCollectionsAchieved;

  // 2. Journey & Stops
  final String assignedRouteName;
  final List<CustomerRouteStop> routeStops;

  // 3. Van Stock Values
  final double morningOpeningStockValue;
  final double totalSalesStockValue;
  final double returnsStockValue;
  final double remainingEveningStockValue;

  // 4. Daily Settlement
  final DailyVanSettlement settlement;
  final RouteStatus routeStatus;

  VanSalesmanProgressModel({
    required this.salesmanId,
    required this.salesmanName,
    required this.phone,
    required this.vanId,
    required this.vanName,
    required this.vehiclePlateNumber,
    required this.date,
    this.dailySalesTarget = 5000.0,
    required this.actualSalesAchieved,
    this.dailyCollectionTarget = 3000.0,
    required this.actualCollectionsAchieved,
    required this.assignedRouteName,
    required this.routeStops,
    required this.morningOpeningStockValue,
    required this.totalSalesStockValue,
    required this.returnsStockValue,
    required this.remainingEveningStockValue,
    required this.settlement,
    this.routeStatus = RouteStatus.inProgress,
  });

  int get totalStopsCount => routeStops.length;
  int get visitedStopsCount => routeStops.where((s) => s.status == StopVisitStatus.visited).length;
  int get pendingStopsCount => routeStops.where((s) => s.status == StopVisitStatus.pending).length;
  double get routeCompletionRatio => totalStopsCount > 0 ? (visitedStopsCount / totalStopsCount) : 0.0;
  double get salesTargetRatio => dailySalesTarget > 0 ? (actualSalesAchieved / dailySalesTarget).clamp(0.0, 2.0) : 0.0;

  Map<String, dynamic> toJson() => {
    'salesmanId': salesmanId,
    'salesmanName': salesmanName,
    'phone': phone,
    'vanId': vanId,
    'vanName': vanName,
    'vehiclePlateNumber': vehiclePlateNumber,
    'date': date.toIso8601String(),
    'dailySalesTarget': dailySalesTarget,
    'actualSalesAchieved': actualSalesAchieved,
    'dailyCollectionTarget': dailyCollectionTarget,
    'actualCollectionsAchieved': actualCollectionsAchieved,
    'assignedRouteName': assignedRouteName,
    'routeStops': routeStops.map((s) => s.toJson()).toList(),
    'morningOpeningStockValue': morningOpeningStockValue,
    'totalSalesStockValue': totalSalesStockValue,
    'returnsStockValue': returnsStockValue,
    'remainingEveningStockValue': remainingEveningStockValue,
    'settlement': settlement.toJson(),
    'routeStatus': routeStatus.name,
  };

  factory VanSalesmanProgressModel.fromJson(Map<String, dynamic> json) => VanSalesmanProgressModel(
    salesmanId: json['salesmanId'] as String? ?? '',
    salesmanName: json['salesmanName'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    vanId: json['vanId'] as String? ?? '',
    vanName: json['vanName'] as String? ?? '',
    vehiclePlateNumber: json['vehiclePlateNumber'] as String? ?? '',
    date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
    dailySalesTarget: (json['dailySalesTarget'] as num?)?.toDouble() ?? 5000.0,
    actualSalesAchieved: (json['actualSalesAchieved'] as num?)?.toDouble() ?? 0.0,
    dailyCollectionTarget: (json['dailyCollectionTarget'] as num?)?.toDouble() ?? 3000.0,
    actualCollectionsAchieved: (json['actualCollectionsAchieved'] as num?)?.toDouble() ?? 0.0,
    assignedRouteName: json['assignedRouteName'] as String? ?? '',
    routeStops: (json['routeStops'] as List<dynamic>?)
            ?.map((s) => CustomerRouteStop.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    morningOpeningStockValue: (json['morningOpeningStockValue'] as num?)?.toDouble() ?? 0.0,
    totalSalesStockValue: (json['totalSalesStockValue'] as num?)?.toDouble() ?? 0.0,
    returnsStockValue: (json['returnsStockValue'] as num?)?.toDouble() ?? 0.0,
    remainingEveningStockValue: (json['remainingEveningStockValue'] as num?)?.toDouble() ?? 0.0,
    settlement: json['settlement'] != null
        ? DailyVanSettlement.fromJson(json['settlement'] as Map<String, dynamic>)
        : DailyVanSettlement(
            totalCashSales: 0.0,
            totalMadaSales: 0.0,
            totalCreditSales: 0.0,
            totalCollections: 0.0,
            totalVanExpenses: 0.0,
            expectedCashHandover: 0.0,
          ),
    routeStatus: RouteStatus.values.firstWhere(
      (r) => r.name == json['routeStatus'],
      orElse: () => RouteStatus.inProgress,
    ),
  );
}
