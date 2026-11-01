import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel _currentUser = UserModel(
    id: 'USR-001',
    name: 'سلطان القحطاني - Sultan Al-Qahtani',
    email: 'sultan@mandhoob.sa',
    phone: '+966501234567',
    role: UserRole.superAdmin,
    assignedVanId: null,
    assignedVanName: null,
  );

  UserModel get currentUser => _currentUser;
  UserRole get currentRole => _currentUser.role;
  AppPermissions get permissions => _currentUser.permissions;

  // Switch active role (useful for demonstration and testing all permission restrictions)
  void switchRole(UserRole newRole) {
    if (newRole == UserRole.salesman) {
      _currentUser = UserModel(
        id: 'USR-003',
        name: 'محمد الدوسري - Mohammed Al-Dosari',
        email: 'mohammed.sales@mandhoob.sa',
        phone: '+966559876543',
        role: UserRole.salesman,
        assignedVanId: 'VAN-01',
        assignedVanName: 'سيارة 1 - الرياض شمال (Van 1)',
      );
    } else if (newRole == UserRole.admin) {
      _currentUser = UserModel(
        id: 'USR-002',
        name: 'فهد العتيبي - Fahad Al-Otaibi',
        email: 'fahad.mgr@mandhoob.sa',
        phone: '+966541112233',
        role: UserRole.admin,
      );
    } else if (newRole == UserRole.accountant) {
      _currentUser = UserModel(
        id: 'USR-004',
        name: 'عبدالله الشهري - Abdullah Al-Shehri',
        email: 'abdullah.acc@mandhoob.sa',
        phone: '+966567778899',
        role: UserRole.accountant,
      );
    } else {
      _currentUser = UserModel(
        id: 'USR-001',
        name: 'سلطان القحطاني - Sultan Al-Qahtani',
        email: 'sultan@mandhoob.sa',
        phone: '+966501234567',
        role: UserRole.superAdmin,
      );
    }
    notifyListeners();
  }

  bool can(bool Function(AppPermissions) check) {
    return check(_currentUser.permissions);
  }
}
