%% AES-256-GCM Encryption/Decryption for OAuth token storage
%% Provides FFI interface for Gleam code to call Erlang's crypto module

-module(meal_planner_crypto_ffi).
-export([aes_gcm_encrypt/4, aes_gcm_decrypt/5]).

%% AES-256-GCM encryption
%% Returns: {Ciphertext, Tag} where Tag is the 16-byte authentication tag
aes_gcm_encrypt(Key, IV, AAD, Plaintext) ->
    {Ciphertext, Tag} = crypto:crypto_one_time_aead(
        aes_256_gcm,
        Key,
        IV,
        AAD,
        Plaintext,
        true  % Encrypt flag
    ),
    <<Ciphertext/binary, Tag/binary>>.

%% AES-256-GCM decryption
%% Input: Ciphertext (includes tag at end), Tag (separate), Key, IV, AAD
%% Returns: {ok, Plaintext} | {error, nil}
aes_gcm_decrypt(Key, IV, AAD, Ciphertext, Tag) ->
    case crypto:crypto_one_time_aead(
        aes_256_gcm,
        Key,
        IV,
        AAD,
        Ciphertext,
        Tag,
        false  % Decrypt flag
    ) of
        Plaintext when is_binary(Plaintext) ->
            {ok, Plaintext};
        error ->
            {error, nil}
    end.
