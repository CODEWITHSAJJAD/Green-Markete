class Partner {
  final String id;
  final String fullName;
  final String? role;
  final String? accessLevel;

  Partner({
    required this.id,
    required this.fullName,
    this.role,
    this.accessLevel,
  });
}
