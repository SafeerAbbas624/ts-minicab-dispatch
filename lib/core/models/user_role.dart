enum UserRole {
  admin,
  superAdmin,
  driver,
  demoAdmin,
  demoDriver;

  static UserRole fromApi(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      case 'driver':
        return UserRole.driver;
      case 'demo_admin':
        return UserRole.demoAdmin;
      case 'demo_driver':
        return UserRole.demoDriver;
      default:
        throw ArgumentError('Unknown role from API: $value');
    }
  }

  String toApi() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.driver:
        return 'driver';
      case UserRole.demoAdmin:
        return 'demo_admin';
      case UserRole.demoDriver:
        return 'demo_driver';
    }
  }

  bool get isAdminFamily =>
      this == UserRole.admin || this == UserRole.superAdmin || this == UserRole.demoAdmin;

  bool get isDriverFamily => this == UserRole.driver || this == UserRole.demoDriver;

  bool get isSuperAdmin => this == UserRole.superAdmin;
}
