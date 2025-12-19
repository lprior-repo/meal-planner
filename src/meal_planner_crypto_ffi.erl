-module(meal_planner_crypto_ffi).
-export([aes_gcm_encrypt/4, aes_gcm_decrypt/5]).

%% AES-256-GCM encryption
%% Returns ciphertext with appended 16-byte tag
aes_gcm_encrypt(Key, IV, AAD, Plaintext) ->
    {Ciphertext, Tag} = crypto:crypto_one_time_aead(
        aes_256_gcm,
        Key,
        IV,
        Plaintext,
        AAD,
        16,  % Tag length in bytes
        true % Encrypt
    ),
    <<Ciphertext/binary, Tag/binary>>.

%% AES-256-GCM decryption
%% Returns {ok, Plaintext} or error
aes_gcm_decrypt(Key, IV, AAD, Ciphertext, Tag) ->
    case crypto:crypto_one_time_aead(
        aes_256_gcm,
        Key,
        IV,
        Ciphertext,
        AAD,
        Tag,
        false % Decrypt
    ) of
        error -> {error, nil};
        Plaintext -> {ok, Plaintext}
    end.
