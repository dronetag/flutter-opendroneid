class PermissionsMissingException implements Exception {
  final String description;

  PermissionsMissingException(this.description);
}
