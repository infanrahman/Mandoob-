class PermissionDeniedException implements Exception {
  final String message;
  final String permission;
  final String? requiredRole;

  const PermissionDeniedException(
    this.message, {
    required this.permission,
    this.requiredRole,
  });

  @override
  String toString() => 'PermissionDeniedException: $message ($permission)';
}
