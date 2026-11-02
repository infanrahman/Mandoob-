enum UserRole {
  superAdmin,
  admin,
  salesman,
  accountant,
}

class AppPermissions {
  final bool canViewDashboard;
  final bool canCreateSale;
  final bool canEditSale;
  final bool canDeleteSale;
  final bool canCreatePurchase;
  final bool canManageInventory;
  final bool canTransferVanStock;
  final bool canViewProfitAndCost;
  final bool canManageUsers;
  final bool canConfigureZatca;
  final bool canConfigurePrinter;
  final bool canViewReports;

  const AppPermissions({
    required this.canViewDashboard,
    required this.canCreateSale,
    required this.canEditSale,
    required this.canDeleteSale,
    required this.canCreatePurchase,
    required this.canManageInventory,
    required this.canTransferVanStock,
    required this.canViewProfitAndCost,
    required this.canManageUsers,
    required this.canConfigureZatca,
    required this.canConfigurePrinter,
    required this.canViewReports,
  });

  static AppPermissions fromRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const AppPermissions(
          canViewDashboard: true,
          canCreateSale: true,
          canEditSale: true,
          canDeleteSale: true,
          canCreatePurchase: true,
          canManageInventory: true,
          canTransferVanStock: true,
          canViewProfitAndCost: true,
          canManageUsers: true,
          canConfigureZatca: true,
          canConfigurePrinter: true,
          canViewReports: true,
        );
      case UserRole.admin:
        return const AppPermissions(
          canViewDashboard: true,
          canCreateSale: true,
          canEditSale: true,
          canDeleteSale: false,
          canCreatePurchase: true,
          canManageInventory: true,
          canTransferVanStock: true,
          canViewProfitAndCost: true,
          canManageUsers: true,
          canConfigureZatca: true,
          canConfigurePrinter: true,
          canViewReports: true,
        );
      case UserRole.salesman:
        return const AppPermissions(
          canViewDashboard: true, // restricted to own van stats
          canCreateSale: true,
          canEditSale: false,
          canDeleteSale: false,
          canCreatePurchase: false,
          canManageInventory: false,
          canTransferVanStock: true, // Load request
          canViewProfitAndCost: false, // Cannot see profit/cost margins
          canManageUsers: false,
          canConfigureZatca: false,
          canConfigurePrinter: true,
          canViewReports: false,
        );
      case UserRole.accountant:
        return const AppPermissions(
          canViewDashboard: true,
          canCreateSale: true,
          canEditSale: true,
          canDeleteSale: false,
          canCreatePurchase: true,
          canManageInventory: true,
          canTransferVanStock: true,
          canViewProfitAndCost: true,
          canManageUsers: false,
          canConfigureZatca: false,
          canConfigurePrinter: true,
          canViewReports: true,
        );
    }
  }
}

class UserModel {
  final String id;
  final String companyId; // The root company this user belongs to
  final String companyNameAr;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? assignedVanId; // E.g. 'VAN-01' for salesman
  final String? assignedVanName;
  final bool isActive;
  final AppPermissions permissions;

  UserModel({
    required this.id,
    this.companyId = 'COMP-001',
    this.companyNameAr = 'شركة المندوب للتوزيع والتجارة المحدودة',
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.assignedVanId,
    this.assignedVanName,
    this.isActive = true,
    AppPermissions? permissions,
  }) : permissions = permissions ?? AppPermissions.fromRole(role);

  String get roleDisplayNameAr {
    switch (role) {
      case UserRole.superAdmin:
        return 'المدير العام (Super Admin)';
      case UserRole.admin:
        return 'مدير النظام (Admin)';
      case UserRole.salesman:
        return 'مندوب مبيعات (Van Sales)';
      case UserRole.accountant:
        return 'محاسب (Accountant)';
    }
  }

  String get roleDisplayNameEn {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.salesman:
        return 'Van Salesman';
      case UserRole.accountant:
        return 'Accountant';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyNameAr': companyNameAr,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'assignedVanId': assignedVanId,
      'assignedVanName': assignedVanName,
      'isActive': isActive,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.salesman;
    try {
      parsedRole = UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.salesman,
      );
    } catch (_) {}

    return UserModel(
      id: json['id'] as String? ?? 'USR-${DateTime.now().millisecondsSinceEpoch}',
      companyId: json['companyId'] as String? ?? 'COMP-001',
      companyNameAr: json['companyNameAr'] as String? ?? 'شركة المندوب للتوزيع والتجارة المحدودة',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: parsedRole,
      assignedVanId: json['assignedVanId'] as String?,
      assignedVanName: json['assignedVanName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
