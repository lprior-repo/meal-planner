-module('meal_planner@fatsecret@crypto_ffi').
-export([hmac_sha1/2]).

hmac_sha1(Key, Data) ->
    crypto:mac(hmac, sha, Key, Data).
