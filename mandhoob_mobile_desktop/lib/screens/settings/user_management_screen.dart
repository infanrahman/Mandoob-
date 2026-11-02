import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/access_denied_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), AuthService()]),
      builder: (context, _) {
        if (!AuthService().can((p) => p.canManageUsers)) {
          return Scaffold(
            appBar: AppBar(title: const Text('إدارة مستخدمي المنشأة')),
            body: const AccessDeniedWidget(
              requiredPermissionName: 'canManageUsers',
              customMessage: 'لا تمتلك صلاحية إدارة مستخدمي المنشأة والأدوار.',
            ),
          );
        }

        final db = DatabaseService();
        final companyUsers = db.companyUsers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('إدارة مستخدمي المنشأة والصلاحيات'),
          ),
          body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Affiliation Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المستخدمون التابعون للمنشأة (Company Users Hierarchy):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                        ),
                        Text(
                          db.companyNameAr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                        Text(
                          'كافة المدراء والمحاسبين ومناديب السيارات مسجلين تحت هذه المنشأة برقم ضريبي: ${db.vatNumber}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'فريق العمل المسجل (${companyUsers.length} مستخدمين)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('إضافة مستخدم للشركة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: companyUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = companyUsers[index];
                Color roleColor = Colors.blue;
                IconData roleIcon = Icons.badge;

                if (user.role == UserRole.superAdmin) {
                  roleColor = Colors.blue.shade900;
                  roleIcon = Icons.admin_panel_settings;
                } else if (user.role == UserRole.admin) {
                  roleColor = Colors.purple;
                  roleIcon = Icons.security;
                } else if (user.role == UserRole.salesman) {
                  roleColor = Colors.green;
                  roleIcon = Icons.directions_car;
                } else if (user.role == UserRole.accountant) {
                  roleColor = Colors.orange.shade800;
                  roleIcon = Icons.calculate;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: roleColor.withOpacity(0.12),
                              child: Icon(roleIcon, color: roleColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: roleColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          user.roleDisplayNameAr.split(' ')[0],
                                          style: TextStyle(
                                            color: roleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'هاتف: ${user.phone} • بريد: ${user.email}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  if (user.assignedVanName != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_car, size: 14, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          'السيارة المخصصة: ${user.assignedVanName}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'switch', child: Text('تسجيل الدخول بهذا المستخدم')),
                                const PopupMenuItem(value: 'edit', child: Text('تعديل الصلاحيات')),
                                const PopupMenuItem(value: 'delete', child: Text('حذف المستخدم', style: TextStyle(color: Colors.red))),
                              ],
                              onSelected: (val) {
                                if (val == 'switch') {
                                  AuthService().switchRole(user.role);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم التبديل إلى المستخدم: ${user.name}'),
                                      backgroundColor: AppColors.saleGreen,
                                    ),
                                  );
                                } else if (val == 'delete') {
                                  db.deleteCompanyUser(user.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم حذف المستخدم: ${user.name} بنجاح'),
                                      backgroundColor: AppColors.expenseRed,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المنشأة: ${user.companyNameAr.substring(0, 20)}...',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                const Text('نشط (Active)', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
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

  void _showAddUserDialog(BuildContext context) {
    final db = DatabaseService();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.salesman;
    String? selectedVanId = 'VAN-01';

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
                  const Text('إضافة موظف جديد تحت المنشأة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم الموظف الثلاثي *', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الجوال *', prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    isExpanded: true,
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'الدور الوظيفي / الصلاحية'),
                    items: const [
                      DropdownMenuItem(value: UserRole.admin, child: Text('مدير عمليات (Admin)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: UserRole.salesman, child: Text('مندوب مبيعات سيارة (Van Sales)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: UserRole.accountant, child: Text('محاسب مالي (Accountant)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (r) {
                      if (r != null) setModalState(() => selectedRole = r);
                    },
                  ),
                  if (selectedRole == UserRole.salesman) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedVanId,
                      decoration: const InputDecoration(labelText: 'تخصيص سيارة التوزيع (Assigned Van)'),
                      items: db.warehouses.where((w) => w.isVan).map((v) {
                        return DropdownMenuItem(value: v.id, child: Text(v.nameAr, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedVanId = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;

                        db.addCompanyUser(
                          UserModel(
                            id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
                            companyId: 'COMP-001',
                            companyNameAr: db.companyNameAr,
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: phoneController.text.trim(),
                            role: selectedRole,
                            assignedVanId: selectedRole == UserRole.salesman ? selectedVanId : null,
                            assignedVanName: selectedRole == UserRole.salesman
                                ? db.warehouses.firstWhere((w) => w.id == selectedVanId).nameAr
                                : null,
                          ),
                        );

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تسجيل ${nameController.text} بنجاح تحت منشأة ${db.companyNameAr}!'),
                            backgroundColor: AppColors.saleGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('تسجيل الموظف في المنشأة'),
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
