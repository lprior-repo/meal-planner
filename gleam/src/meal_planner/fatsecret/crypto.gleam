/// Encryption utilities for OAuth token secrets
///
/// Uses AES-256-GCM for authenticated encryption of sensitive data.
/// The encryption key should be stored in the OAUTH_ENCRYPTION_KEY environment variable.
import envoy
import gleam/bit_array
import gleam/crypto
import gleam/result
import gleam/string

pub type CryptoError {
  KeyNotConfigured
  KeyInvalidLength
  EncryptionFailed
  DecryptionFailed
  InvalidCiphertext
}

/// AES-256-GCM encryption using Erlang's crypto module
@external(erlang, "meal_planner_crypto_ffi", "aes_gcm_encrypt")
fn aes_gcm_encrypt(
  key: BitArray,
  iv: BitArray,
  aad: BitArray,
  plaintext: BitArray,
) -> BitArray

/// AES-256-GCM decryption using Erlang's crypto module
@external(erlang, "meal_planner_crypto_ffi", "aes_gcm_decrypt")
fn aes_gcm_decrypt(
  key: BitArray,
  iv: BitArray,
  aad: BitArray,
  ciphertext: BitArray,
  tag: BitArray,
) -> Result(BitArray, Nil)

/// Encrypt a plaintext string using AES-256-GCM
/// Returns base64-encoded ciphertext with prepended nonce and tag
pub fn encrypt(plaintext: String) -> Result(String, CryptoError) {
  use key <- result.try(get_encryption_key())

  let nonce = crypto.strong_random_bytes(12)
  let plaintext_bytes = <<plaintext:utf8>>
  let aad = <<>>

  let ciphertext_with_tag = aes_gcm_encrypt(key, nonce, aad, plaintext_bytes)

  let combined = bit_array.concat([nonce, ciphertext_with_tag])
  Ok(bit_array.base64_encode(combined, True))
}

/// Decrypt a base64-encoded ciphertext (with prepended nonce and appended tag)
pub fn decrypt(ciphertext_b64: String) -> Result(String, CryptoError) {
  use key <- result.try(get_encryption_key())

  case bit_array.base64_decode(ciphertext_b64) {
    Ok(combined) -> {
      case extract_nonce_ciphertext_tag(combined) {
        Ok(#(nonce, ciphertext, tag)) -> {
          let aad = <<>>
          case aes_gcm_decrypt(key, nonce, aad, ciphertext, tag) {
            Ok(plaintext_bytes) -> {
              case bit_array.to_string(plaintext_bytes) {
                Ok(plaintext) -> Ok(plaintext)
                Error(_) -> Error(DecryptionFailed)
              }
            }
            Error(_) -> Error(DecryptionFailed)
          }
        }
        Error(e) -> Error(e)
      }
    }
    Error(_) -> Error(InvalidCiphertext)
  }
}

/// Get the encryption key from environment
fn get_encryption_key() -> Result(BitArray, CryptoError) {
  case envoy.get("OAUTH_ENCRYPTION_KEY") {
    Ok(key_hex) -> {
      case string.is_empty(key_hex) {
        True -> Error(KeyNotConfigured)
        False -> {
          case bit_array.base16_decode(string.uppercase(key_hex)) {
            Ok(key_bytes) -> {
              case bit_array.byte_size(key_bytes) {
                32 -> Ok(key_bytes)
                _ -> Error(KeyInvalidLength)
              }
            }
            Error(_) -> Error(KeyInvalidLength)
          }
        }
      }
    }
    Error(_) -> Error(KeyNotConfigured)
  }
}

/// Extract the 12-byte nonce, ciphertext, and 16-byte tag
fn extract_nonce_ciphertext_tag(
  combined: BitArray,
) -> Result(#(BitArray, BitArray, BitArray), CryptoError) {
  let size = bit_array.byte_size(combined)
  case size > 28 {
    True -> {
      let nonce = bit_array.slice(combined, 0, 12) |> result.unwrap(<<>>)
      let ciphertext_len = size - 12 - 16
      let ciphertext =
        bit_array.slice(combined, 12, ciphertext_len) |> result.unwrap(<<>>)
      let tag =
        bit_array.slice(combined, 12 + ciphertext_len, 16) |> result.unwrap(<<>>)
      Ok(#(nonce, ciphertext, tag))
    }
    False -> Error(InvalidCiphertext)
  }
}

/// Check if encryption is configured
pub fn is_configured() -> Bool {
  case get_encryption_key() {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Generate a new random encryption key (for setup)
/// Returns a 32-byte hex string suitable for OAUTH_ENCRYPTION_KEY
pub fn generate_key() -> String {
  crypto.strong_random_bytes(32)
  |> bit_array.base16_encode
  |> string.lowercase
}
