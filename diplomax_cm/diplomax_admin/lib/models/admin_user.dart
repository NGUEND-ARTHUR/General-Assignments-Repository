/// Admin user model with role information
class AdminUser {
  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.token,
  });
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final String? token;

  /// Copy with method for immutability
  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    AdminRole? role,
    String? token,
  }) => AdminUser(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    role: role ?? this.role,
    token: token ?? this.token,
  );
}

/// Admin role enumeration
enum AdminRole {
  // superadmin: Full control
  diplomaxSuperadmin,

  // admin: Can manage institutions and admins
  diplomaxAdmin,

  // ministry superadmin: Can approve institutions
  ministrySuperadmin,

  // ministry analyst: Read-only analytics
  ministryAnalyst;

  /// Get readable label for role
  String get label {
    switch (this) {
      case AdminRole.diplomaxSuperadmin:
        return 'Diplomax Superadmin';
      case AdminRole.diplomaxAdmin:
        return 'Diplomax Admin';
      case AdminRole.ministrySuperadmin:
        return 'Ministry Superadmin';
      case AdminRole.ministryAnalyst:
        return 'Ministry Analyst';
    }
  }

  /// Check if role can manage institutions
  bool get canManageInstitutions =>
      this == AdminRole.diplomaxSuperadmin ||
      this == AdminRole.diplomaxAdmin ||
      this == AdminRole.ministrySuperadmin;

  /// Check if role can manage admins
  bool get canManageAdmins => this == AdminRole.diplomaxSuperadmin;

  /// Check if role can access settings
  bool get canAccessSettings => this == AdminRole.diplomaxSuperadmin;

  /// Check if role can view analytics/dashboard
  bool get canViewDashboard {
    return true; // All roles can view dashboard
  }

  /// Check if role can view audit logs
  bool get canViewAuditLogs {
    return true; // All roles can view audit logs
  }

  /// Get from string (backend value)
  static AdminRole fromString(String value) {
    switch (value) {
      case 'diplomax_superadmin':
        return AdminRole.diplomaxSuperadmin;
      case 'diplomax_admin':
        return AdminRole.diplomaxAdmin;
      case 'ministry_superadmin':
        return AdminRole.ministrySuperadmin;
      case 'ministry_analyst':
        return AdminRole.ministryAnalyst;
      default:
        return AdminRole.ministryAnalyst;
    }
  }

  /// Convert to backend string format
  String toBackendString() {
    switch (this) {
      case AdminRole.diplomaxSuperadmin:
        return 'diplomax_superadmin';
      case AdminRole.diplomaxAdmin:
        return 'diplomax_admin';
      case AdminRole.ministrySuperadmin:
        return 'ministry_superadmin';
      case AdminRole.ministryAnalyst:
        return 'ministry_analyst';
    }
  }
}
