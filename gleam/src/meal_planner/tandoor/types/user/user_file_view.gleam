/// UserFileView type for Tandoor SDK
///
/// This module defines the UserFileView type for viewing uploaded user files
/// such as profile images. This is a readonly view - file uploads are handled
/// separately.
import meal_planner/tandoor/types/user/user.{type User}

/// View of a user-uploaded file (readonly)
///
/// Used for displaying uploaded files like profile avatars in user preferences.
/// All fields are readonly - file management happens through separate upload APIs.
pub type UserFileView {
  UserFileView(
    /// Unique file ID
    id: Int,
    /// File name (max 128 chars)
    name: String,
    /// Download URL for the file
    file_download: String,
    /// Preview/thumbnail URL
    preview: String,
    /// File size in kilobytes
    file_size_kb: Int,
    /// User who created/uploaded the file
    created_by: User,
    /// ISO 8601 timestamp when file was created
    created_at: String,
  )
}
