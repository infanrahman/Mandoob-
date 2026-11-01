import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class PermissionGate extends StatelessWidget {
  final bool Function(AppPermissions) check;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.check,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final hasPermission = AuthService().can(check);
        if (hasPermission) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
