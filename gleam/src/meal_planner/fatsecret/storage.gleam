/// FatSecret OAuth token storage
///
/// Database operations for storing OAuth request tokens (temporary)
/// and access tokens (long-term) for the 3-legged OAuth flow.
///
/// Security: Token secrets are encrypted using AES-256-GCM before storage.
/// The encryption key must be set in OAUTH_ENCRYPTION_KEY environment variable.
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/fatsecret/client.{type AccessToken, type RequestToken}
import meal_planner/fatsecret/crypto
import pog

pub type StorageError {
  DatabaseError(message: String)
  NotFound
  EncryptionError(message: String)
}

/// Store a pending request token (Step 1 of OAuth flow)
/// These expire after 15 minutes
/// The token secret is encrypted before storage
pub fn store_pending_token(
  conn: pog.Connection,
  token: RequestToken,
) -> Result(Nil, StorageError) {
  use encrypted_secret <- result.try(
    crypto.encrypt(token.oauth_token_secret)
    |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) }),
  )

  let sql =
    "INSERT INTO fatsecret_oauth_pending (oauth_token, oauth_token_secret)
     VALUES ($1, $2)
     ON CONFLICT (oauth_token) DO UPDATE SET
       oauth_token_secret = EXCLUDED.oauth_token_secret,
       created_at = NOW(),
       expires_at = NOW() + INTERVAL '15 minutes'"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(token.oauth_token))
    |> pog.parameter(pog.text(encrypted_secret))
    |> pog.execute(conn)
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(pog_error_to_string(e)))
  }
}

/// Retrieve and delete a pending request token
/// Returns the decrypted token secret needed to complete the OAuth flow
pub fn get_pending_token(
  conn: pog.Connection,
  oauth_token: String,
) -> Result(String, StorageError) {
  let sql =
    "DELETE FROM fatsecret_oauth_pending
     WHERE oauth_token = $1 AND expires_at > NOW()
     RETURNING oauth_token_secret"

  let decoder = decode.at([0], decode.string)

  case
    pog.query(sql)
    |> pog.parameter(pog.text(oauth_token))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Ok(pog.Returned(_, [encrypted_secret])) -> {
      crypto.decrypt(encrypted_secret)
      |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) })
    }
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(_) -> Error(NotFound)
    Error(e) -> Error(DatabaseError(pog_error_to_string(e)))
  }
}

/// Store the access token after successful OAuth flow
/// This is a singleton (single user app)
/// Both token and secret are encrypted before storage
pub fn store_access_token(
  conn: pog.Connection,
  token: AccessToken,
) -> Result(Nil, StorageError) {
  use encrypted_token <- result.try(
    crypto.encrypt(token.oauth_token)
    |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) }),
  )
  use encrypted_secret <- result.try(
    crypto.encrypt(token.oauth_token_secret)
    |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) }),
  )

  let sql =
    "INSERT INTO fatsecret_oauth_token (id, oauth_token, oauth_token_secret)
     VALUES (1, $1, $2)
     ON CONFLICT (id) DO UPDATE SET
       oauth_token = EXCLUDED.oauth_token,
       oauth_token_secret = EXCLUDED.oauth_token_secret,
       connected_at = NOW()"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(encrypted_token))
    |> pog.parameter(pog.text(encrypted_secret))
    |> pog.execute(conn)
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(pog_error_to_string(e)))
  }
}

/// Get the stored access token (decrypted)
pub fn get_access_token(
  conn: pog.Connection,
) -> Result(AccessToken, StorageError) {
  let sql =
    "SELECT oauth_token, oauth_token_secret FROM fatsecret_oauth_token WHERE id = 1"

  let decoder = {
    use encrypted_token <- decode.field(0, decode.string)
    use encrypted_secret <- decode.field(1, decode.string)
    decode.success(#(encrypted_token, encrypted_secret))
  }

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Ok(pog.Returned(_, [#(encrypted_token, encrypted_secret)])) -> {
      use oauth_token <- result.try(
        crypto.decrypt(encrypted_token)
        |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) }),
      )
      use oauth_token_secret <- result.try(
        crypto.decrypt(encrypted_secret)
        |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) }),
      )
      Ok(client.AccessToken(oauth_token:, oauth_token_secret:))
    }
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(_) -> Error(NotFound)
    Error(e) -> Error(DatabaseError(pog_error_to_string(e)))
  }
}

/// Check if we have a stored access token
pub fn is_connected(conn: pog.Connection) -> Bool {
  case get_access_token(conn) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Get access token as Option
pub fn get_access_token_opt(conn: pog.Connection) -> Option(AccessToken) {
  case get_access_token(conn) {
    Ok(token) -> Some(token)
    Error(_) -> None
  }
}

/// Remove the access token (disconnect)
pub fn delete_access_token(conn: pog.Connection) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM fatsecret_oauth_token WHERE id = 1"

  case pog.query(sql) |> pog.execute(conn) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(pog_error_to_string(e)))
  }
}

/// Update last_used_at timestamp
pub fn touch_access_token(conn: pog.Connection) -> Result(Nil, StorageError) {
  let sql = "UPDATE fatsecret_oauth_token SET last_used_at = NOW() WHERE id = 1"

  case pog.query(sql) |> pog.execute(conn) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(pog_error_to_string(e)))
  }
}

/// Cleanup expired pending tokens
pub fn cleanup_expired_pending(
  conn: pog.Connection,
) -> Result(Int, StorageError) {
  let sql = "SELECT cleanup_fatsecret_pending_tokens()"

  let decoder = decode.at([0], decode.int)

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Ok(pog.Returned(_, [count])) -> Ok(count)
    Ok(_) -> Ok(0)
    Error(e) -> Error(DatabaseError(pog_error_to_string(e)))
  }
}

fn pog_error_to_string(error: pog.QueryError) -> String {
  case error {
    pog.ConstraintViolated(message, constraint, _) ->
      "Constraint " <> constraint <> ": " <> message
    pog.PostgresqlError(code, name, message) ->
      "PostgreSQL " <> code <> " (" <> name <> "): " <> message
    pog.UnexpectedArgumentCount(_, _) -> "Unexpected argument count"
    pog.UnexpectedArgumentType(expected, got) ->
      "Expected type " <> expected <> ", got " <> got
    pog.UnexpectedResultType(_) -> "Unexpected result type"
    pog.ConnectionUnavailable -> "Connection unavailable"
    pog.QueryTimeout -> "Query timeout"
  }
}

fn crypto_error_to_string(error: crypto.CryptoError) -> String {
  case error {
    crypto.KeyNotConfigured -> "OAUTH_ENCRYPTION_KEY not set"
    crypto.KeyInvalidLength ->
      "OAUTH_ENCRYPTION_KEY must be 64 hex chars (32 bytes)"
    crypto.EncryptionFailed -> "Encryption failed"
    crypto.DecryptionFailed -> "Decryption failed"
    crypto.InvalidCiphertext -> "Invalid ciphertext"
  }
}

/// Check if encryption is properly configured
pub fn encryption_configured() -> Bool {
  crypto.is_configured()
}
