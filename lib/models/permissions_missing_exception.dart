import 'package:permission_handler/permission_handler.dart';

class PermissionsMissingException implements Exception {
  final List<Permission> missingPermissions;
  PermissionsMissingException(this.missingPermissions);
}
