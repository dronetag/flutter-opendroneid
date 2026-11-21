import 'package:permission_handler/permission_handler.dart';

/// Thrown by [FlutterOpenDroneId.startScan] when required permissions are not
/// granted.
class PermissionsMissingException implements Exception {
  /// Permissions that must be granted before scanning can start.
  final List<Permission> missingPermissions;

  PermissionsMissingException(this.missingPermissions);

  @override
  String toString() =>
      'PermissionsMissingException{ missing: $missingPermissions }';
}
