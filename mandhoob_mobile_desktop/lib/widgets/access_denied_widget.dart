import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AccessDeniedWidget extends StatelessWidget {
  final String? requiredPermissionName;
  final String? customMessage;
  final VoidCallback? onReturnHome;

  const AccessDeniedWidget({
    super.key,
    this.requiredPermissionName,
    this.customMessage,
    this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthService(), AppLanguage()]),
      builder: (context, _) {
        final auth = AuthService();
        final lang = AppLanguage();

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade200, width: 2),
                  ),
                  child: const Icon(Icons.lock_person, size: 60, color: AppColors.expenseRed),
                ),
                const SizedBox(height: 20),
                Text(
                  lang.isArabic ? 'تم حظر الوصول - غير مصرح' : 'Access Denied - Restricted',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  customMessage ??
                      (lang.isArabic
                          ? 'حسابك الحالي لا يمتلك الصلاحيات الكافية لتنفيذ هذا الإجراء أو عرض هذا القسم.'
                          : 'Your current account does not have sufficient permissions to access this module.'),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang.isArabic ? 'الدور الحالي: ' : 'Active Role: ',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            auth.currentUser.roleDisplayNameAr,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (requiredPermissionName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang.isArabic ? 'الصلاحية المطلوبة: ' : 'Required Permission: ',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            Text(
                              requiredPermissionName!,
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.expenseRed),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (onReturnHome != null)
                      OutlinedButton.icon(
                        onPressed: onReturnHome,
                        icon: const Icon(Icons.home, size: 16),
                        label: Text(lang.isArabic ? 'العودة للرئيسية' : 'Go to Dashboard'),
                      ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Fast switch to admin for authorized review
                        auth.switchRole(UserRole.admin);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.isArabic ? 'تم التبديل إلى مدير النظام (Admin)' : 'Switched to Admin',
                            ),
                            backgroundColor: AppColors.saleGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.security, size: 16, color: Colors.white),
                      label: Text(
                        lang.isArabic ? 'تبديل الصلاحية للتجربة' : 'Switch Role (Test)',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A widget that renders [child] if the permission test passes, or [fallback] if not.
class PermissionGate extends StatelessWidget {
  final bool Function(AppPermissions) can;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.can,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        if (AuthService().can(can)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
