import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user.dart';

/// Current logged-in admin user state provider
final userProvider = StateNotifierProvider<UserNotifier, AdminUser?>(
  (ref) => UserNotifier(),
);

/// User state notifier to manage authentication state
class UserNotifier extends StateNotifier<AdminUser?> {
  UserNotifier() : super(null);

  /// Log in a user
  void login(
    String id,
    String email,
    String name,
    AdminRole role,
    String token,
  ) {
    state = AdminUser(
      id: id,
      email: email,
      name: name,
      role: role,
      token: token,
    );
  }

  /// Update user role (for role changes)
  void updateRole(AdminRole newRole) {
    if (state != null) {
      state = state!.copyWith(role: newRole);
    }
  }

  /// Log out current user
  void logout() {
    state = null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state != null;

  /// Get current user's role
  AdminRole? get currentRole => state?.role;
}

/// Extension for convenient role checking
extension RoleChecking on AdminUser {
  bool canManageInstitutions() => role.canManageInstitutions;
  bool canManageAdmins() => role.canManageAdmins;
  bool canAccessSettings() => role.canAccessSettings;
  bool canViewAuditLogs() => role.canViewAuditLogs;
}
