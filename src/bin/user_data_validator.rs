#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]
#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct UserData {
    name: String,
    email: String,
    age: u32,
}

#[derive(Debug, thiserror::Error)]
pub enum ValidationError {
    #[error("Name must not be empty")]
    EmptyName,
    #[error("Email must be valid")]
    InvalidEmail,
    #[error("Age must be between 1 and 150")]
    InvalidAge,
}

/// Validates user data using Railway-Oriented Programming patterns
fn validate_user_data(user_data: &UserData) -> Result<UserData, ValidationError> {
    // Start with the input data and chain operations using Result combinators
    let validated_name = validate_name(&user_data.name);
    let validated_email = validated_name.and_then(|data| validate_email(&data, &user_data.email));
    let validated_age = validated_email.and_then(|data| validate_age(&data, user_data.age));

    // Return the final validated result with original data
    validated_age.map(|_| user_data.clone())
}

/// Validates that name is not empty
fn validate_name(name: &str) -> Result<UserData, ValidationError> {
    if name.is_empty() {
        Err(ValidationError::EmptyName)
    } else {
        Ok(UserData {
            name: name.to_string(),
            email: String::new(),
            age: 0,
        })
    }
}

/// Validates that email is valid (basic check)
fn validate_email(_name_data: &UserData, email: &str) -> Result<UserData, ValidationError> {
    if !email.contains('@') || !email.contains('.') {
        Err(ValidationError::InvalidEmail)
    } else {
        Ok(UserData {
            name: String::new(),
            email: email.to_string(),
            age: 0,
        })
    }
}

/// Validates that age is between 1 and 150
fn validate_age(_email_data: &UserData, age: u32) -> Result<UserData, ValidationError> {
    if age < 1 || age > 150 {
        Err(ValidationError::InvalidAge)
    } else {
        Ok(UserData {
            name: String::new(),
            email: String::new(),
            age,
        })
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Example usage with test data
    let user_data = UserData {
        name: "John Doe".to_string(),
        email: "john@example.com".to_string(),
        age: 30,
    };

    match validate_user_data(&user_data) {
        Ok(validated_data) => {
            println!("Valid user data: {:?}", validated_data);
        }
        Err(e) => {
            eprintln!("Validation error: {}", e);
        }
    }

    // Test with invalid data
    let invalid_data = UserData {
        name: "".to_string(),
        email: "invalid-email".to_string(),
        age: 200,
    };

    match validate_user_data(&invalid_data) {
        Ok(validated_data) => {
            println!("Valid user data: {:?}", validated_data);
        }
        Err(e) => {
            eprintln!("Validation error: {}", e);
        }
    }

    Ok(())
}
