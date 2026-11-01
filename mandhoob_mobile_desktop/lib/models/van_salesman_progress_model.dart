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
  final String assignedRouteName; // E.g., 'مسار شمال الرياض - حي السليمانية والعليا'
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
}
