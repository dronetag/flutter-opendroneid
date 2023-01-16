class PermissionMissingException implements Exception {
  final String description;

  PermissionMissingException(this.description);
}
