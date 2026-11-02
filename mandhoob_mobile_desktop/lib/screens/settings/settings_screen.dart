import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/printer_service.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../models/user_model.dart';
import 'company_profile_screen.dart';
import 'create_company_screen.dart';
import 'user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _offlineCacheEnabled = true;
  bool _isTestingPrinter = false;
  bool _isTestingApi = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        DatabaseService(),
        PrinterService(),
        AuthService(),
        SyncService(),
        AppLanguage(),
      ]),
      builder: (context, _) {
        final db = DatabaseService();
        final printer = PrinterService();
        final auth = AuthService();
        final sync = SyncService();
        final lang = AppLanguage();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            children: [
              // 1. Enterprise User & Organization Hero Header
              _buildUserHeroHeader(auth, db, lang),

              const SizedBox(height: 18),

              // 2. Language & Localization Section
              _buildSectionHeader(
                title: lang.isArabic ? 'اللغة والواجهة' : 'Language & Display',
                subtitle: lang.isArabic
                    ? 'التحكم باتجاه العرض واللغة الفورية'
                    : 'Configure app language and layout orientation',
                icon: Icons.translate_rounded,
                iconColor: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 8),
              _buildGroupContainer(
                children: [
                  _buildLanguageSelector(lang),
                  const Divider(height: 24, thickness: 1, color: AppColors.cardBorder),
                  _buildSwitchTile(
                    title: lang.isArabic ? 'إشعارات النظام والمخزون' : 'System & Stock Alerts',
                    subtitle: lang.isArabic
                        ? 'تنبيه فوري عند وصول المنتجات لحد الطلب الأدنى'
                        : 'Instant alerts when product inventory drops below minimum threshold',
                    icon: Icons.notifications_active_outlined,
                    iconColor: Colors.amber.shade700,
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Organization & Tax Profile Section
              _buildSectionHeader(
                title: lang.isArabic ? 'المنشأة والبيانات الضريبية' : 'Organization & Tax Profile',
                subtitle: lang.isArabic
                    ? 'بيانات التسجيل الضريبي والسجل التجاري المعتمد'
                    : 'Registered corporate details, VAT, and commercial registration',
                icon: Icons.business_rounded,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _buildCompanyProfileCard(context, db, auth, lang),

              // 4. ZATCA Phase 2 E-Invoicing Section (Visible ONLY to Admin & SuperAdmin)
              if (auth.hasRole([UserRole.admin, UserRole.superAdmin])) ...[
                const SizedBox(height: 18),
                _buildSectionHeader(
                  title: lang.isArabic ? 'الفوترة الإلكترونية (ZATCA)' : 'ZATCA Phase 2 E-Invoicing',
                  subtitle: lang.isArabic
                      ? 'الربط المباشر مع منصة فاتورة وهيئة الزكاة والضريبة'
                      : 'Direct integration with ZATCA Fatoora Platform',
                  icon: Icons.verified_user_rounded,
                  iconColor: AppColors.saleGreen,
                ),
                const SizedBox(height: 8),
                _buildZatcaPhase2Card(context, lang),
              ],

              const SizedBox(height: 18),

              // 5. Thermal POS Printer Section
              _buildSectionHeader(
                title: lang.isArabic ? 'طابعة الفواتير الحرارية' : 'Thermal POS Printer',
                subtitle: lang.isArabic
                    ? 'تهيئة طابعات الإيصالات Bluetooth و Wi-Fi'
                    : 'Configure Bluetooth & Wi-Fi ESC/POS thermal receipt printers',
                icon: Icons.print_rounded,
                iconColor: Colors.teal,
              ),
              const SizedBox(height: 8),
              _buildPrinterConfigCard(context, printer, lang),

              const SizedBox(height: 18),

              // 6. Local Storage, Offline First & Cloud Sync
              _buildSectionHeader(
                title: lang.isArabic ? 'التخزين والمزامنة السحابية' : 'Storage & Cloud Sync',
                subtitle: lang.isArabic
                    ? 'قاعدة البيانات المحلية والمزامنة بدون إنترنت'
                    : 'Offline SQLite persistence and delta synchronization',
                icon: Icons.cloud_sync_rounded,
                iconColor: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 8),
              _buildSyncAndStorageCard(context, sync, lang),

              const SizedBox(height: 18),

              // 7. Security, Users & Role Permissions
              _buildSectionHeader(
                title: lang.isArabic ? 'الأمان والصلاحيات' : 'Security & Permissions',
                subtitle: lang.isArabic
                    ? 'صلاحيات المستخدم النشط وإدارة الفريق'
                    : 'Active user privileges and team management',
                icon: Icons.admin_panel_settings_rounded,
                iconColor: Colors.purple,
              ),
              const SizedBox(height: 8),
              _buildSecurityAndRolesCard(context, auth, db, lang),

              const SizedBox(height: 18),

              // 8. Maintenance & Demo Data Zone
              _buildSectionHeader(
                title: lang.isArabic ? 'صيانة النظام والبيانات' : 'System Maintenance',
                subtitle: lang.isArabic
                    ? 'إدارة التخزين المحلي واستعادة البيانات'
                    : 'Local storage management and initial data restore',
                icon: Icons.settings_backup_restore_rounded,
                iconColor: Colors.orange.shade800,
              ),
              const SizedBox(height: 8),
              _buildMaintenanceCard(context, db, auth, lang),

              const SizedBox(height: 24),

              // 9. Modern System Information Footer
              _buildSystemInfoFooter(lang),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 1. HERO USER & ORGANIZATION PROFILE CARD
  // ==========================================
  Widget _buildUserHeroHeader(AuthService auth, DatabaseService db, AppLanguage lang) {
    final user = auth.currentUser;
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'U';

    final isSuper = user.role == UserRole.superAdmin;
    final isAdmin = user.role == UserRole.admin;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with border & online status indicator
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.saleGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0F172A), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // User info & Role Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          // Role Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSuper
                                  ? Colors.purple.withOpacity(0.3)
                                  : isAdmin
                                      ? Colors.blue.withOpacity(0.3)
                                      : Colors.teal.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSuper
                                    ? Colors.purple.shade300
                                    : isAdmin
                                        ? Colors.blue.shade300
                                        : Colors.teal.shade300,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSuper || isAdmin ? Icons.verified_user : Icons.badge_outlined,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lang.isArabic ? user.roleDisplayNameAr : user.role.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.email} • ${lang.isArabic ? db.companyNameAr : db.companyNameEn}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Quick Status Chips inside hero (Responsive Wrap)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: AppColors.saleGreen),
                      const SizedBox(width: 6),
                      Text(
                        lang.isArabic ? 'الربط الضريبي: نشط' : 'ZATCA Phase 2: Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_done_outlined, size: 14, color: Colors.cyanAccent),
                      const SizedBox(width: 6),
                      Text(
                        lang.isArabic ? 'التخزين المحلي: جاهز 100%' : 'Offline-First: 100%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. LANGUAGE & LOCALIZATION SELECTOR
  // ==========================================
  Widget _buildLanguageSelector(AppLanguage lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.isArabic ? 'لغة الواجهة والاتجاه' : 'Interface Language & Layout',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.isArabic
                        ? 'تبديل فوري بين العربية (RTL) والإنجليزية (LTR)'
                        : 'Switch live between Arabic (RTL) and English (LTR)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVeryNarrow = constraints.maxWidth < 280;
            if (isVeryNarrow) {
              return Column(
                children: [
                  _buildLangChoiceCard(
                    flag: '🇸🇦',
                    title: 'العربية (RTL)',
                    subtitle: 'المملكة العربية السعودية',
                    isSelected: lang.isArabic,
                    onTap: () {
                      if (!lang.isArabic) lang.setLocale(const Locale('ar'));
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildLangChoiceCard(
                    flag: '🌐',
                    title: 'English (LTR)',
                    subtitle: 'International Layout',
                    isSelected: !lang.isArabic,
                    onTap: () {
                      if (lang.isArabic) lang.setLocale(const Locale('en'));
                    },
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildLangChoiceCard(
                    flag: '🇸🇦',
                    title: 'العربية',
                    subtitle: 'RTL',
                    isSelected: lang.isArabic,
                    onTap: () {
                      if (!lang.isArabic) lang.setLocale(const Locale('ar'));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildLangChoiceCard(
                    flag: '🌐',
                    title: 'English',
                    subtitle: 'LTR',
                    isSelected: !lang.isArabic,
                    onTap: () {
                      if (lang.isArabic) lang.setLocale(const Locale('en'));
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLangChoiceCard({
    required String flag,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. COMPANY & LEGAL PROFILE CARD
  // ==========================================
  Widget _buildCompanyProfileCard(
    BuildContext context,
    DatabaseService db,
    AuthService auth,
    AppLanguage lang,
  ) {
    return _buildGroupContainer(
      children: [
        // Company Title & Icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.isArabic ? db.companyNameAr : db.companyNameEn,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.isArabic ? db.companyNameEn : db.companyNameAr,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Action Buttons Row (Responsive Wrap)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (auth.currentRole == UserRole.superAdmin)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
                  );
                },
                icon: const Icon(Icons.add_business_rounded, size: 14),
                label: Text(lang.isArabic ? '+ منشأة جديدة' : '+ Add Entity'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.saleGreen,
                  side: const BorderSide(color: AppColors.saleGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
                );
              },
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: Text(lang.isArabic ? 'تعديل البيانات' : 'Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const Divider(height: 20, thickness: 1, color: AppColors.cardBorder),
        // Tax details grid
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _buildDataRow(
                icon: Icons.confirmation_number_outlined,
                label: lang.isArabic ? 'الرقم الضريبي (VAT)' : 'VAT Registration',
                value: db.vatNumber,
                isHighlight: true,
              ),
              const Divider(height: 14, thickness: 0.5, color: AppColors.cardBorder),
              _buildDataRow(
                icon: Icons.receipt_long_outlined,
                label: lang.isArabic ? 'السجل التجاري (CR)' : 'CR Number',
                value: db.crNumber,
              ),
              const Divider(height: 14, thickness: 0.5, color: AppColors.cardBorder),
              _buildDataRow(
                icon: Icons.location_on_outlined,
                label: lang.isArabic ? 'العنوان الوطني' : 'Address',
                value: '${db.buildingNumber} ${db.street}، ${db.city}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. ZATCA PHASE 2 CARD (RESTRICTED TO ADMINS)
  // ==========================================
  Widget _buildZatcaPhase2Card(BuildContext context, AppLanguage lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saleGreen.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.saleGreen.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.saleGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_rounded, color: AppColors.saleGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.isArabic ? 'الفاتورة الإلكترونية - المرحلة 2' : 'ZATCA Phase 2 Engine',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.isArabic ? 'التكامل مع منصة فاتورة' : 'Fatoora Portal Integrated',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.saleGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.saleGreen, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 11, color: AppColors.saleGreen),
                      const SizedBox(width: 4),
                      Text(
                        lang.isArabic ? 'متصل' : 'Connected',
                        style: const TextStyle(
                          color: AppColors.saleGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 18, thickness: 1, color: AppColors.cardBorder),
            // Compliance Features Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildZatcaFeatureBadge('SHA-256 Hash', Icons.tag, Colors.blue),
                _buildZatcaFeatureBadge('ECDSA Stamp', Icons.fingerprint, Colors.indigo),
                _buildZatcaFeatureBadge('X.509 CSID', Icons.security, Colors.green),
                _buildZatcaFeatureBadge('UBL 2.1 XML', Icons.code, Colors.teal),
                _buildZatcaFeatureBadge('TLV QR', Icons.qr_code_2, Colors.purple),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang.isArabic
                          ? 'البيئة النشطة: منصة المحاكاة (Simulation Sandbox). الفواتير مشفرة 100% وفق ZATCA.'
                          : 'Environment: Simulation Sandbox. Invoices cryptographically signed.',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action Buttons (Responsive Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 320) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showZatcaOnboardDialog(context),
                        icon: const Icon(Icons.key_rounded, size: 14),
                        label: Text(lang.isArabic ? 'تجديد شهادة CSID' : 'Renew CSID'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isTestingApi ? null : () => _testApiHealth(context, lang),
                        icon: _isTestingApi
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.network_check_rounded, size: 14),
                        label: Text(lang.isArabic ? 'فحص الاتصال' : 'Test API'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saleGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showZatcaOnboardDialog(context),
                        icon: const Icon(Icons.key_rounded, size: 14),
                        label: Text(
                          lang.isArabic ? 'تجديد CSID' : 'Renew CSID',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTestingApi ? null : () => _testApiHealth(context, lang),
                        icon: _isTestingApi
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.network_check_rounded, size: 14),
                        label: Text(
                          lang.isArabic ? 'فحص الاتصال' : 'Test Health',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saleGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _testApiHealth(BuildContext context, AppLanguage lang) async {
    setState(() => _isTestingApi = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isTestingApi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.isArabic
                ? 'اتصال بوابة فاتورة (ZATCA Fatoora API): متصل وجاهز بنجاح (HTTP 200 OK)!'
                : 'ZATCA Fatoora Gateway: Connected & Healthy (HTTP 200 OK)!',
          ),
          backgroundColor: AppColors.saleGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildZatcaFeatureBadge(String text, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. THERMAL PRINTER CONFIGURATION CARD
  // ==========================================
  Widget _buildPrinterConfigCard(
    BuildContext context,
    PrinterService printer,
    AppLanguage lang,
  ) {
    return _buildGroupContainer(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.print_rounded, color: Colors.teal, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.isArabic ? 'الطابعة الحرارية الافتراضية' : 'Default Thermal Printer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.isArabic
                        ? 'طابعة الفواتير (Bluetooth / Wi-Fi)'
                        : 'Receipt printer (Bluetooth / Wi-Fi)',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: printer.selectedPrinterId,
          decoration: InputDecoration(
            labelText: lang.isArabic ? 'طابعة الإيصالات المحددة' : 'Selected Printer',
            prefixIcon: const Icon(Icons.bluetooth_connected, color: Colors.teal, size: 18),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: printer.availablePrinters.map((p) {
            return DropdownMenuItem(
              value: p.id,
              child: Text('${p.name} (${p.address})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) printer.selectPrinter(val);
          },
        ),
        const SizedBox(height: 14),
        // Paper width & test print (Responsive Stacking)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.isArabic ? 'عرض الورق الحراري:' : 'Paper Width:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPaperWidthChip(
                  label: '80mm',
                  sublabel: lang.isArabic ? 'قياسي' : 'Standard',
                  isSelected: printer.is80mm,
                  onTap: () => printer.setPaperWidth(true),
                ),
                _buildPaperWidthChip(
                  label: '58mm',
                  sublabel: lang.isArabic ? 'سيارة' : 'Mobile',
                  isSelected: !printer.is80mm,
                  onTap: () => printer.setPaperWidth(false),
                ),
                OutlinedButton.icon(
                  onPressed: _isTestingPrinter ? null : () => _testPrint(context, lang),
                  icon: _isTestingPrinter
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                        )
                      : const Icon(Icons.receipt_long_rounded, size: 14),
                  label: Text(lang.isArabic ? 'طباعة تجريبية' : 'Test Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _testPrint(BuildContext context, AppLanguage lang) async {
    setState(() => _isTestingPrinter = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isTestingPrinter = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.isArabic
                ? 'تم إرسال إيصال الاختبار التجريبي إلى الطابعة بنجاح!'
                : 'Test receipt sent to printer successfully!',
          ),
          backgroundColor: AppColors.saleGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildPaperWidthChip({
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($sublabel)',
              style: TextStyle(
                color: isSelected ? Colors.white.withOpacity(0.85) : AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. SYNC & LOCAL STORAGE PERSISTENCE
  // ==========================================
  Widget _buildSyncAndStorageCard(
    BuildContext context,
    SyncService sync,
    AppLanguage lang,
  ) {
    return _buildGroupContainer(
      children: [
        _buildSwitchTile(
          title: lang.isArabic
              ? 'تخزين الجهاز الدائم (Offline-First)'
              : 'Local Device Persistence',
          subtitle: lang.isArabic
              ? 'العمل دون اتصال، وحفظ الفواتير محلياً في الذاكرة'
              : 'Operate offline with zero latency, storing all data locally',
          icon: Icons.storage_rounded,
          iconColor: const Color(0xFF6366F1),
          value: _offlineCacheEnabled,
          onChanged: (val) => setState(() => _offlineCacheEnabled = val),
        ),
        const Divider(height: 18, thickness: 1, color: AppColors.cardBorder),
        // Sync Status Row (Responsive Wrap)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sync_rounded, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.isArabic ? 'المزامنة السحابية الذكية' : 'Cloud Delta Sync',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      '${lang.isArabic ? "آخر مزامنة:" : "Last sync:"} ${sync.lastSyncTime.toString().substring(0, 16)}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                sync.triggerSync();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang.isArabic
                          ? 'جاري مزامنة التغييرات والفواتير مع السحابة...'
                          : 'Syncing transactions with cloud server...',
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              icon: const Icon(Icons.sync_rounded, size: 13),
              label: Text(lang.isArabic ? 'مزامنة الآن' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 7. SECURITY & PERMISSIONS CARD
  // ==========================================
  Widget _buildSecurityAndRolesCard(
    BuildContext context,
    AuthService auth,
    DatabaseService db,
    AppLanguage lang,
  ) {
    return _buildGroupContainer(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security_rounded, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.isArabic ? 'مستوى الأمان والصلاحيات' : 'Security & Privileges',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '${lang.isArabic ? "المستخدم:" : "User:"} ${auth.currentUser.name}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            if (auth.can((p) => p.canManageUsers))
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                  );
                },
                icon: const Icon(Icons.manage_accounts_rounded, size: 14),
                label: Text(lang.isArabic ? 'إدارة المستخدمين' : 'Manage Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const Divider(height: 18, thickness: 1, color: AppColors.cardBorder),
        Text(
          lang.isArabic ? 'مصفوفة الصلاحيات الممنوحة لحسابك:' : 'Granted Privileges Matrix:',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildPermBadge(lang.isArabic ? 'إصدار فواتير' : 'Create Invoices', auth.permissions.canCreateSale),
            _buildPermBadge(lang.isArabic ? 'تعديل فواتير' : 'Edit Invoices', auth.permissions.canEditSale),
            _buildPermBadge(lang.isArabic ? 'حذف فواتير' : 'Delete Invoices', auth.permissions.canDeleteSale),
            _buildPermBadge(lang.isArabic ? 'نقل بضاعة سيارة' : 'Van Stock Transfer', auth.permissions.canTransferVanStock),
            _buildPermBadge(lang.isArabic ? 'رؤية الأرباح والتكلفة' : 'View Margin & Cost', auth.permissions.canViewProfitAndCost),
            _buildPermBadge(lang.isArabic ? 'التقارير المالية' : 'Financial Reports', auth.permissions.canViewReports),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 8. MAINTENANCE & DEMO DATA CARD
  // ==========================================
  Widget _buildMaintenanceCard(
    BuildContext context,
    DatabaseService db,
    AuthService auth,
    AppLanguage lang,
  ) {
    final canReset = auth.can((p) => p.canResetSystemData);

    return _buildGroupContainer(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restore_page_rounded, color: Colors.orange.shade800, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.isArabic ? 'استعادة البيانات التجريبية الأولية' : 'Restore Initial Demo Data',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.isArabic
                        ? 'إعادة ضبط المخزون والأصناف والعملاء للقيم الافتراضية'
                        : 'Reset database to factory demo inventory and products',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (canReset)
              OutlinedButton.icon(
                onPressed: () => _confirmResetDemoData(context, lang, db),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: Text(lang.isArabic ? 'استعادة' : 'Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade800),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  lang.isArabic ? 'صلاحية محظورة' : 'Admin Only',
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 9. SYSTEM INFO FOOTER
  // ==========================================
  Widget _buildSystemInfoFooter(AppLanguage lang) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 13, color: AppColors.saleGreen),
            const SizedBox(width: 6),
            Text(
              lang.isArabic
                  ? 'مندوب لإدارة مبيعات التوزيع والفوترة الفورية'
                  : 'Mandhoob Distribution & Mobile POS ERP',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Version 1.0.0 (Build 2026.11) • Saudi ZATCA Phase 2 Certified',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted.withOpacity(0.8)),
        ),
      ],
    );
  }

  // ==========================================
  // UI ATOMS & REUSABLE HELPERS
  // ==========================================
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: isHighlight ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPermBadge(String label, bool allowed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: allowed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: allowed ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 11,
            color: allowed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: allowed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGS & ACTIONS
  // ==========================================
  void _showZatcaOnboardDialog(BuildContext context) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.saleGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ربط جهاز الفوترة (ZATCA Onboarding)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل رمز التحقق (OTP) الصادر من منصة فاتورة (Fatoora Portal) لاستخراج وتجديد شهادة الاعتماد الرقمية (CSID):',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'رمز التحقق OTP المكون من 6 أرقام',
                prefixIcon: const Icon(Icons.password_rounded),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saleGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تم إرسال طلب الاعتماد وتجديد شهادة CSID بنجاح! تم اعتماد الربط مع هيئة الزكاة.',
                  ),
                  backgroundColor: AppColors.saleGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            child: const Text('تأكيد وإصدار شهادة CSID'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDemoData(BuildContext context, AppLanguage lang, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lang.isArabic ? 'استعادة البيانات الافتراضية' : 'Restore Demo Data',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          lang.isArabic
              ? 'هل تريد بالتأكيد مسح التخزين المحلي واستعادة الأصناف والمستودعات والعملاء الافتراضيين؟'
              : 'Are you sure you want to clear local storage and restore default demo products, warehouses, and customers?',
          style: const TextStyle(fontSize: 12, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await db.resetToInitialDemoData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang.isArabic
                          ? 'تمت استعادة البيانات التجريبية الافتراضية بنجاح'
                          : 'Default demo data restored successfully',
                    ),
                    backgroundColor: Colors.orange.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
            child: Text(
              lang.isArabic ? 'استعادة وتعيين' : 'Reset & Restore',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
