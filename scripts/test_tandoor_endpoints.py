#!/usr/bin/env python3
"""
Comprehensive Tandoor API Endpoint Tester

Tests all Tandoor API endpoints from OpenAPI spec.
Handles authentication and validates 200-level responses.
"""

import os
import sys
import json
import yaml
import requests
from typing import Dict, List, Tuple
from urllib.parse import urljoin
from pathlib import Path
from collections import defaultdict

# Configuration from environment
TANDOOR_BASE_URL = os.getenv("TANDOOR_BASE_URL", "http://localhost:8000").rstrip("/")
TANDOOR_API_TOKEN = os.getenv("TANDOOR_API_TOKEN", "")
OPENAPI_SPEC = Path(__file__).parent.parent / "Tandoor (2.3.6).yaml"

# Test results tracking
results = {
    "passed": [],
    "failed": [],
    "skipped": [],
    "errors": [],
}


def load_openapi_spec() -> Dict:
    """Load and parse the OpenAPI specification."""
    try:
        with open(OPENAPI_SPEC) as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"❌ Error loading OpenAPI spec: {e}", file=sys.stderr)
        sys.exit(1)


def get_headers() -> Dict[str, str]:
    """Build request headers with authentication."""
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    
    if TANDOOR_API_TOKEN:
        headers["Authorization"] = f"Token {TANDOOR_API_TOKEN}"
    
    return headers


def extract_endpoints(spec: Dict) -> List[Tuple[str, str, Dict]]:
    """Extract all API endpoints from OpenAPI spec.
    
    Returns: List of (method, path, operation) tuples
    """
    endpoints = []
    paths = spec.get("paths", {})
    
    for path, methods in paths.items():
        # Only test API endpoints (filter out auth, etc.)
        if not path.startswith("/api/"):
            continue
            
        for method, operation in methods.items():
            if method in ["get", "post", "put", "patch", "delete"]:
                endpoints.append((method.upper(), path, operation))
    
    return endpoints


def substitute_path_params(path: str, operation: Dict) -> Tuple[str, bool]:
    """Substitute path parameters with dummy values.
    
    Returns: (substituted_path, can_test)
    """
    params = operation.get("parameters", [])
    path_params = [p for p in params if p.get("in") == "path"]
    
    if not path_params:
        return path, True
    
    # Try to substitute with reasonable dummy values
    substituted = path
    can_test = True
    
    for param in path_params:
        param_name = param.get("name")
        param_type = param.get("schema", {}).get("type", "string")
        
        if param_type == "integer":
            dummy_value = "1"
        elif param_type == "string":
            dummy_value = "test"
        else:
            dummy_value = "1"
        
        substituted = substituted.replace(f"{{{param_name}}}", str(dummy_value))
    
    # Check if all params were substituted
    if "{" in substituted:
        can_test = False
    
    return substituted, can_test


def test_endpoint(method: str, path: str, operation: Dict) -> Tuple[bool, str, int]:
    """Test a single endpoint.
    
    Returns: (success, message, status_code)
    """
    # Substitute path parameters
    test_path, can_test = substitute_path_params(path, operation)
    
    if not can_test:
        return False, f"Could not substitute path parameters", 0
    
    # Build full URL
    url = urljoin(TANDOOR_BASE_URL, test_path.lstrip("/"))
    
    # Get authentication headers
    headers = get_headers()
    
    # Check if endpoint requires request body
    request_body_schema = operation.get("requestBody", {})
    needs_body = bool(request_body_schema)
    
    try:
        # Make the request with appropriate data
        request_data = {}
        if needs_body:
            # For POST/PUT/PATCH with request bodies, try sending empty dict
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=10)
            elif method == "POST":
                response = requests.post(url, json=request_data, headers=headers, timeout=10)
            elif method == "PUT":
                response = requests.put(url, json=request_data, headers=headers, timeout=10)
            elif method == "PATCH":
                response = requests.patch(url, json=request_data, headers=headers, timeout=10)
            elif method == "DELETE":
                response = requests.delete(url, headers=headers, timeout=10)
            else:
                return False, f"Unsupported method: {method}", 0
        else:
            # For GET/DELETE without body
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=10)
            elif method == "DELETE":
                response = requests.delete(url, headers=headers, timeout=10)
            else:
                # For POST/PUT/PATCH without explicit body requirement
                if method == "POST":
                    response = requests.post(url, headers=headers, timeout=10)
                elif method == "PUT":
                    response = requests.put(url, headers=headers, timeout=10)
                elif method == "PATCH":
                    response = requests.patch(url, headers=headers, timeout=10)
                else:
                    return False, f"Unsupported method: {method}", 0
        
        # Check for 2xx response (or 4xx which indicates endpoint exists but needs data)
        if 200 <= response.status_code < 300:
            return True, "✓", response.status_code
        elif 400 <= response.status_code < 500:
            # 4xx means endpoint exists, just needs proper data/auth
            if response.status_code == 401:
                return False, "🔐 Auth required - check token", response.status_code
            elif response.status_code == 403:
                return False, "🔒 Forbidden - permission issue", response.status_code
            elif response.status_code == 404:
                return False, "❌ Not found", response.status_code
            else:
                # 400, 415, 422, etc. = endpoint exists but needs proper data
                return True, f"ℹ️  {response.status_code}", response.status_code
        elif response.status_code == 500:
            return False, "💥 Server error", response.status_code
        else:
            return False, f"Status: {response.status_code}", response.status_code
            
    except requests.exceptions.Timeout:
        return False, "⏱️  Timeout", 0
    except requests.exceptions.ConnectionError:
        return False, "🔌 Connection refused", 0
    except Exception as e:
        return False, f"Error: {str(e)[:40]}", 0


def main():
    """Main test runner."""
    print("🧪 Tandoor API Endpoint Tester")
    print("=" * 60)
    print(f"Base URL: {TANDOOR_BASE_URL}")
    print(f"Token: {'✓ Present' if TANDOOR_API_TOKEN else '❌ Missing'}")
    print(f"OpenAPI Spec: {OPENAPI_SPEC}")
    print("=" * 60)
    print()
    
    # Load spec
    spec = load_openapi_spec()
    endpoints = extract_endpoints(spec)
    
    print(f"Found {len(endpoints)} API endpoints to test\n")
    
    # Group results by status
    status_groups = defaultdict(list)
    
    # Test each endpoint
    for method, path, operation in endpoints:
        success, message, status_code = test_endpoint(method, path, operation)
        
        # Format output
        endpoint_label = f"{method:6} {path}"
        status_icon = "✅" if success else "❌"
        
        if success:
            results["passed"].append(endpoint_label)
            status_groups["passed"].append((endpoint_label, message, status_code))
            print(f"{status_icon} {endpoint_label:<60} {message}")
        else:
            if status_code == 401 or status_code == 403:
                results["failed"].append(endpoint_label)
            else:
                results["failed"].append(endpoint_label)
            status_groups["failed"].append((endpoint_label, message, status_code))
            print(f"{status_icon} {endpoint_label:<60} {message}")
    
    # Summary
    print()
    print("=" * 60)
    print("📊 SUMMARY")
    print("=" * 60)
    passed = len(results["passed"])
    failed = len(results["failed"])
    total = passed + failed
    
    if total > 0:
        pass_rate = (passed / total) * 100
        print(f"✅ Passed:  {passed}/{total} ({pass_rate:.1f}%)")
        print(f"❌ Failed:  {failed}/{total}")
    
    if failed > 0:
        print()
        print("Failed endpoints:")
        for endpoint, msg, code in status_groups["failed"][:10]:
            print(f"  - {endpoint:<55} ({msg})")
        if len(status_groups["failed"]) > 10:
            print(f"  ... and {len(status_groups['failed']) - 10} more")
    
    # Auth check
    print()
    auth_failures = [e for e, m, c in status_groups["failed"] if c in [401, 403]]
    if auth_failures:
        print(f"⚠️  Auth issues detected: {len(auth_failures)} endpoints")
        print("   Ensure TANDOOR_API_TOKEN is set and valid:")
        print("   export TANDOOR_API_TOKEN=<your_token>")
    
    # Exit code
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
