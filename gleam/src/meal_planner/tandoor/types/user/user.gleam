/// User type for Tandoor SDK
///
/// This module defines the User type representing a Tandoor user account.
/// User data is readonly from the API perspective - users can only view
/// their own account and other users referenced in objects.
import meal_planner/tandoor/core/ids.{type UserId}

/// Tandoor user account
///
/// Represents a user in the Tandoor system. This is a readonly type - user
/// data is managed by Tandoor's authentication system.
pub type User {
  User(
    /// Unique user ID
    id: UserId,
    /// Username (readonly, required, max 150 chars)
    /// Letters, digits and @/./+/-/_ only
    username: String,
    /// User's first name (max 150 chars)
    first_name: String,
    /// User's last name (max 150 chars)
    last_name: String,
    /// Display name (readonly, computed from first/last or username)
    display_name: String,
    /// Whether user can access admin site (readonly)
    is_staff: Bool,
    /// Whether user has all permissions (readonly)
    is_superuser: Bool,
    /// Whether user account is active (readonly)
    is_active: Bool,
  )
}
