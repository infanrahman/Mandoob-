import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/van_salesman_progress_model.dart';
import '../../services/database_service.dart';
import 'salesman_live_tracking_screen.dart';

class VanOperationsHubScreen extends StatefulWidget {
  const VanOperationsHubScreen({super.key});

  @override
  State<VanOperationsHubScreen> createState() => _VanOperationsHubScreenState();
}

class _VanOperationsHubScreenState extends State<VanOperationsHubScreen> {
  late List<VanSalesmanProgressModel> _salesmenProgress;

  @override
  void initState() {
    super.initState();
    _salesmenProgress = [
      VanSalesmanProgressModel(
        salesmanId: 'USR-003',
        salesmanName: 'محمد الدوسري (Van 1)',
        phone: '0559876543',
        vanId: 'VAN-01',
        vanName: 'سيارة 1 - الرياض شمال',
        vehiclePlateNumber: 'أ ب ج 4321',
        date: DateTime.now(),
        dailySalesTarget: 6000.0,
        actualSalesAchieved: 4850.0,
        dailyCollectionTarget: 3500.0,
        actualCollectionsAchieved: 2500.0,
        assignedRouteName: 'مسار شمال الرياض (السليمانية، العليا، الورود)',
        morningOpeningStockValue: 12500.0,
        totalSalesStockValue: 4850.0,
        returnsStockValue: 0.0,
        remainingEveningStockValue: 7650.0,
        routeStops: [
          CustomerRouteStop(
            customerId: 'CUST-101',
            customerNameAr: 'أسواق التميمي - فرع السليمانية',
            district: 'السليمانية',
            phone: '0501122334',
            currentBalance: 7500.0,
            creditLimit: 30000.0,
            sequenceOrder: 1,
            status: StopVisitStatus.visited,
            visitedAt: DateTime.now().subtract(const Duration(hours: 3)),
            invoiceAmount: 2400.0,
            collectedAmount: 1500.0,
          ),
          CustomerRouteStop(
            customerId: 'CUST-102',
            customerNameAr: 'تموينات الأمانة الحديثة',
            district: 'العليا',
            phone: '0554433221',
            currentBalance: 3200.0,
            creditLimit: 10000.0,
            sequenceOrder: 2,
            status: StopVisitStatus.visited,
            visitedAt: DateTime.now().subtract(const Duration(hours: 1)),
            invoiceAmount: 1450.0,
            collectedAmount: 1000.0,
          ),
          CustomerRouteStop(
            customerId: 'CUST-104',
            customerNameAr: 'ميني ماركت النور',
            district: 'الورود',
            phone: '0560001122',
            currentBalance: 1200.0,
            creditLimit: 5000.0,
            sequenceOrder: 3,
            status: StopVisitStatus.pending,
          ),
        ],
        settlement: DailyVanSettlement(
          openingCashFloat: 500.0,
          totalCashSales: 2850.0,
          totalMadaSales: 1200.0,
          totalCreditSales: 800.0,
          totalCollections: 2500.0,
          totalVanExpenses: 150.0, // Gas
          expectedCashHandover: 500.0 + 2850.0 + 2500.0 - 150.0, // 5700 SAR
        ),
      ),
      VanSalesmanProgressModel(
        salesmanId: 'USR-005',
        salesmanName: 'أحمد الغامدي (Van 2)',
        phone: '0551122445',
        vanId: 'VAN-02',
        vanName: 'سيارة 2 - الرياض شرق',
        vehiclePlateNumber: 'د ر س 9876',
        date: DateTime.now(),
        dailySalesTarget: 5000.0,
        actualSalesAchieved: 3100.0,
        dailyCollectionTarget: 2000.0,
        actualCollectionsAchieved: 1200.0,
        assignedRouteName: 'مسار شرق الرياض (الروضة، النسيم، القدس)',
        morningOpeningStockValue: 9800.0,
        totalSalesStockValue: 3100.0,
        returnsStockValue: 0.0,
        remainingEveningStockValue: 6700.0,
        routeStops: [
          CustomerRouteStop(
            customerId: 'CUST-103',
            customerNameAr: 'مجمع أسواق الجزيرة',
            district: 'الروضة',
            phone: '0569988776',
            currentBalance: 12500.0,
            creditLimit: 20000.0,
            sequenceOrder: 1,
            status: StopVisitStatus.visited,
            visitedAt: DateTime.now().subtract(const Duration(hours: 4)),
            invoiceAmount: 3100.0,
            collectedAmount: 1200.0,
          ),
          CustomerRouteStop(
            customerId: 'CUST-105',
            customerNameAr: 'بقالة الوفاء',
            district: 'النسيم',
            phone: '0543322110',
            currentBalance: 800.0,
            creditLimit: 4000.0,
            sequenceOrder: 2,
            status: StopVisitStatus.pending,
          ),
        ],
        settlement: DailyVanSettlement(
          openingCashFloat: 300.0,
          totalCashSales: 1600.0,
          totalMadaSales: 1500.0,
          totalCreditSales: 0.0,
          totalCollections: 1200.0,
          totalVanExpenses: 120.0,
          expectedCashHandover: 300.0 + 1600.0 + 1200.0 - 120.0, // 2980 SAR
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AppLanguage()]),
      builder: (context, _) {
        final db = DatabaseService();
        final list = db.salesmenProgress.isNotEmpty ? db.salesmenProgress : _salesmenProgress;
        final lang = AppLanguage();
        final curr = lang.isArabic ? 'ر.س' : 'SAR';
        final totalFleetSales = list.fold(0.0, (sum, v) => sum + v.actualSalesAchieved);
        final totalFleetTarget = list.fold(0.0, (sum, v) => sum + v.dailySalesTarget);
        final totalFleetCash = list.fold(0.0, (sum, v) => sum + v.settlement.expectedCashHandover);

        return Scaffold(
          appBar: AppBar(
            title: Text(lang.isArabic ? 'غرفة عمليات المناديب والسيارات' : 'Van Operations Command Hub'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Fleet Command KPIs
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1E40AF)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              lang.isArabic
                                  ? 'متابعة أداء أسطول سيارات التوزيع اليوم:'
                                  : "Fleet Daily Van Operations:",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${list.length} ${lang.isArabic ? "سيارات نشطة" : "Active Vans"}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderKpi(lang.isArabic ? 'مبيعات الأسطول' : 'Fleet Sales', '${totalFleetSales.toStringAsFixed(0)} $curr', Colors.greenAccent),
                          _buildHeaderKpi(lang.isArabic ? 'المستهدف الإجمالي' : 'Total Target', '${totalFleetTarget.toStringAsFixed(0)} $curr', Colors.white),
                          _buildHeaderKpi(lang.isArabic ? 'نقد الخزينة المتوقع' : 'Expected Cash', '${totalFleetCash.toStringAsFixed(0)} $curr', Colors.amberAccent),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  lang.isArabic
                      ? 'المناديب النشطون في الميدان (Active Van Representatives):'
                      : 'Active Van Representatives in the Field:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final prog = list[index];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFFEFF6FF),
                                      child: Icon(Icons.directions_car, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prog.salesmanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(
                                          '${prog.vanName} • ${lang.isArabic ? "اللوحة" : "Plate"}: ${prog.vehiclePlateNumber}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SalesmanLiveTrackingScreen(progress: prog),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.analytics, size: 14),
                                  label: Text(lang.isArabic ? 'متابعة وتسوية' : 'Track & Settle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 20),

                            // Route Progress Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${lang.isArabic ? "إنجاز المسار" : "Route"}: ${prog.assignedRouteName.split(' ')[1]}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(prog.routeCompletionRatio * 100).toInt()}% (${prog.visitedStopsCount}/${prog.totalStopsCount} ${lang.isArabic ? "محطة" : "Stops"})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: prog.routeCompletionRatio,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saleGreen),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Financial & Van Stock KPI Metrics
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(lang.isArabic ? 'مبيعات اليوم' : "Today's Sales", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${prog.actualSalesAchieved.toStringAsFixed(0)} $curr',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.saleGreen),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(lang.isArabic ? 'التحصيل' : 'Collections', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${prog.actualCollectionsAchieved.toStringAsFixed(0)} $curr',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(lang.isArabic ? 'المتبقي بالسيارة' : 'Van Stock', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${prog.remainingEveningStockValue.toStringAsFixed(0)} $curr',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderKpi(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
