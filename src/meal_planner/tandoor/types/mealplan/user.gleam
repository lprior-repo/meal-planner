/// Simplified user type for meal plan sharing
/// Contains minimal user information needed for meal plan operations
pub type User {
  User(
    /// Tandoor user ID
    id: Int,
    /// Username (required, 150 chars max, letters/digits/@/./+/-/_ only)
    username: String,
    /// User's first name
    first_name: String,
    /// User's last name
    last_name: String,
    /// Display name (computed from first/last name or username)
    display_name: String,
    /// Whether user has admin/staff permissions
    is_staff: Bool,
    /// Whether user has superuser permissions
    is_superuser: Bool,
    /// Whether user account is active
    is_active: Bool,
  )
}
