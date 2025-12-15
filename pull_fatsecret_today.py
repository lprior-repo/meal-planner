#!/usr/bin/env python3
"""Pull today's FatSecret food data for 2025-12-15"""

import os
import sys
import base64
import psycopg2
import hmac
import hashlib
from datetime import datetime
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from urllib.parse import quote
import requests
import json

# Load environment
env_file = "/home/lewis/src/meal-planner/.env"
env_vars = {}
with open(env_file) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, val = line.split("=", 1)
            env_vars[key.strip()] = val.strip()

OAUTH_ENCRYPTION_KEY = env_vars.get("OAUTH_ENCRYPTION_KEY")
DATABASE_URL = env_vars.get("DATABASE_URL")
FATSECRET_CONSUMER_KEY = env_vars.get("FATSECRET_CONSUMER_KEY")
FATSECRET_CONSUMER_SECRET = env_vars.get("FATSECRET_CONSUMER_SECRET")

if not OAUTH_ENCRYPTION_KEY:
    print("❌ OAUTH_ENCRYPTION_KEY not found in .env")
    sys.exit(1)

print("✅ Environment loaded")

# Get encrypted OAuth token from database
try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    cur.execute(
        "SELECT oauth_token, oauth_token_secret FROM fatsecret_oauth_token WHERE id = 1"
    )
    result = cur.fetchone()
    cur.close()
    conn.close()

    if not result:
        print("❌ No OAuth token found in database")
        sys.exit(1)

    encrypted_token, encrypted_token_secret = result
    print("✅ OAuth token loaded from database")
except Exception as e:
    print(f"❌ Database error: {e}")
    sys.exit(1)

# Decrypt the OAuth token using AES-256-GCM
def decrypt_aes_gcm(ciphertext_b64: str, key_hex: str) -> str:
    """Decrypt AES-256-GCM ciphertext (nonce + ciphertext + tag)"""
    key = bytes.fromhex(key_hex)
    combined = base64.b64decode(ciphertext_b64)

    # Extract: 12-byte nonce + ciphertext + 16-byte tag
    nonce = combined[:12]
    tag = combined[-16:]
    ciphertext = combined[12:-16]

    cipher = AESGCM(key)
    plaintext = cipher.decrypt(nonce, ciphertext + tag, None)
    return plaintext.decode("utf-8")

try:
    oauth_token = decrypt_aes_gcm(encrypted_token, OAUTH_ENCRYPTION_KEY)
    oauth_token_secret = decrypt_aes_gcm(encrypted_token_secret, OAUTH_ENCRYPTION_KEY)
    print(f"🔐 OAuth token decrypted (first 20 chars): {oauth_token[:20]}...")
except Exception as e:
    print(f"❌ Decryption error: {e}")
    sys.exit(1)

# FatSecret API OAuth 1.0a signing
import time
import random
import string

def generate_nonce():
    return "".join(random.choices(string.ascii_letters + string.digits, k=32))

def sign_request(method, url, params, consumer_key, consumer_secret, oauth_token, oauth_token_secret):
    """Sign request with OAuth 1.0a"""
    nonce = generate_nonce()
    timestamp = str(int(time.time()))

    # Build OAuth params
    oauth_params = {
        "oauth_consumer_key": consumer_key,
        "oauth_token": oauth_token,
        "oauth_signature_method": "HMAC-SHA1",
        "oauth_timestamp": timestamp,
        "oauth_nonce": nonce,
        "oauth_version": "1.0",
    }

    # Combine all params for signature
    all_params = {**params, **oauth_params}
    param_string = "&".join(
        f"{quote(str(k), safe='')}={quote(str(v), safe='')}"
        for k, v in sorted(all_params.items())
    )

    # Create signature base string
    base_string = f"{method}&{quote(url, safe='')}&{quote(param_string, safe='')}"

    # Sign with consumer_secret&token_secret
    signing_key = f"{consumer_secret}&{oauth_token_secret}"
    signature = base64.b64encode(
        hmac.new(
            signing_key.encode(),
            base_string.encode(),
            hashlib.sha1,
        ).digest()
    ).decode()

    oauth_params["oauth_signature"] = signature

    # Build Authorization header
    auth_header = "OAuth " + ", ".join(
        f'{k}="{quote(str(v), safe="")}"'
        for k, v in sorted(oauth_params.items())
    )

    return auth_header

# Call FatSecret API
method = "POST"
url = "https://platform.fatsecret.com/rest/server.api"
params = {
    "method": "food_entries.get",
    "date_int": "20558",  # 2025-12-15
}

print("📡 Calling FatSecret API...")
print("   Date: 2025-12-15 (date_int: 20558)")

auth_header = sign_request(
    method,
    url,
    params,
    FATSECRET_CONSUMER_KEY,
    FATSECRET_CONSUMER_SECRET,
    oauth_token,
    oauth_token_secret,
)

try:
    response = requests.post(
        url,
        data=params,
        headers={
            "Authorization": auth_header,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        timeout=10,
    )

    print("\n" + "=" * 63)
    print("📊 FOOD ENTRIES FOR 2025-12-15")
    print("=" * 63)

    # Try to parse as JSON first
    try:
        data = response.json()
        print(json.dumps(data, indent=2))
    except:
        # If not JSON, parse as XML
        print(response.text)

    print("\n✅ Done!")

except Exception as e:
    print(f"❌ API call error: {e}")
    sys.exit(1)
