// FatSecret OAuth Domain Binary Contracts
// Binaries: oauth_start, oauth_complete, oauth_callback, get_token, get_profile

package mealplanner

// =============================================================================
// fatsecret_oauth_start
// Initiate OAuth 3-legged flow, get request token and auth URL
// OAuth: 2-legged (to get request token)
// =============================================================================

#OAuthStartInput: {
	#FatSecret2LeggedInput
	callback_url: string  // "oob" for out-of-band, or callback URL
}

#OAuthStartOutput: {
	success:            true
	auth_url:           string & =~"^https://"  // user visits this URL
	oauth_token:        string                  // pending request token
	oauth_token_secret: string                  // pending token secret
} | #ErrorOutput

// =============================================================================
// fatsecret_oauth_complete
// Exchange request token + verifier for access token
// OAuth: 2-legged + request token
// =============================================================================

#OAuthCompleteInput: {
	#FatSecret2LeggedInput
	oauth_token:        string  // from oauth_start
	oauth_token_secret: string  // from oauth_start
	oauth_verifier:     string  // user authorization code
}

#OAuthCompleteOutput: {
	success:            true
	oauth_token:        string  // access token (store this!)
	oauth_token_secret: string  // access token secret (store this!)
} | #ErrorOutput

// =============================================================================
// fatsecret_oauth_callback
// Start HTTP server to receive OAuth callback
// Requires: DATABASE_URL env var for token storage
// =============================================================================

#OAuthCallbackInput: {
	port?:         int & >=1024 & <=65535  // default 8765
	timeout_secs?: int & >0                 // default 300 (5 min)
}

#OAuthCallbackOutput: {
	success: true
	message: string
} | #ErrorOutput

// =============================================================================
// fatsecret_get_token
// Retrieve stored access token from database
// Requires: DATABASE_URL env var
// =============================================================================

#GetTokenInput: {
	check_only?: bool  // default false, if true omits token values
}

#GetTokenOutput: {
	success:              true
	status:               "valid" | "not_found" | "old"
	days_since_connected?: int                   // if status is "old"
	oauth_token?:         string                // omitted if check_only or not_found
	oauth_token_secret?:  string                // omitted if check_only or not_found
} | #ErrorOutput

// =============================================================================
// fatsecret_get_profile
// Get authenticated user's profile
// OAuth: 3-legged (requires access token)
// Note: Uses oauth_token naming instead of access_token
// =============================================================================

#GetProfileInput: {
	#FatSecretOAuthTokenInput  // uses oauth_token/oauth_token_secret
}

#GetProfileOutput: {
	success: true
	profile: _  // user profile object
} | #ErrorOutput

// =============================================================================
// TOKEN OBJECT SCHEMAS
// =============================================================================

#RequestToken: {
	oauth_token:        string
	oauth_token_secret: string
	expires_at?:        string  // ISO timestamp
}

#AccessToken: {
	oauth_token:        string
	oauth_token_secret: string
	created_at?:        string  // ISO timestamp
}
