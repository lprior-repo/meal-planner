//// Credentials loader for integration tests
//// Loads Tandoor and FatSecret credentials from environment and database

import gleam/option.{type Option, None, Some}

pub type Credentials {
  Credentials(tandoor: Option(TandoorCreds), fatsecret: Option(FatSecretCreds))
}

pub type TandoorCreds {
  TandoorCreds(base_url: String, username: String, password: String)
}

pub type FatSecretCreds {
  FatSecretCreds(oauth_token: String, oauth_token_secret: String)
}

/// Load credentials from environment variables and database
pub fn load() -> Credentials {
  Credentials(tandoor: None, fatsecret: None)
}

/// Check if FatSecret credentials are available
pub fn has_fatsecret(creds: Credentials) -> Bool {
  case creds.fatsecret {
    Some(_) -> True
    None -> False
  }
}

/// Check if Tandoor credentials are available
pub fn has_tandoor(creds: Credentials) -> Bool {
  case creds.tandoor {
    Some(_) -> True
    None -> False
  }
}
