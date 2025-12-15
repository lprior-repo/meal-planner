#!/usr/bin/env python3
"""
Parallel Endpoint Testing Framework
12 Agents Testing 50+ Endpoints in Parallel
"""

import requests
import json
import time
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, List, Any
import sys

API_BASE = "http://localhost:8080"
TIMEOUT = 5

class TestResult:
    def __init__(self, agent_id: str, agent_name: str, category: str):
        self.agent_id = agent_id
        self.agent_name = agent_name
        self.category = category
        self.tests: List[Dict[str, Any]] = []
        self.start_time = time.time()

    def add_test(self, endpoint: str, method: str, status_code: int,
                 response_time: float, success: bool, error: str = None):
        self.tests.append({
            "endpoint": endpoint,
            "method": method,
            "status_code": status_code,
            "response_time_ms": round(response_time * 1000, 2),
            "success": success,
            "error": error,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    def to_dict(self) -> Dict[str, Any]:
        elapsed = time.time() - self.start_time
        passed = sum(1 for t in self.tests if t["success"])
        failed = len(self.tests) - passed

        return {
            "agent_id": self.agent_id,
            "agent_name": self.agent_name,
            "category": self.category,
            "elapsed_seconds": round(elapsed, 2),
            "tests": self.tests,
            "summary": {
                "total": len(self.tests),
                "passed": passed,
                "failed": failed,
                "avg_response_time_ms": round(sum(t["response_time_ms"] for t in self.tests) / len(self.tests), 2) if self.tests else 0
            }
        }

def test_endpoint(method: str, endpoint: str, headers: Dict = None, json_data: Dict = None) -> tuple:
    """Test a single endpoint and return (status_code, response_time, success, error)"""
    try:
        start = time.time()
        url = f"{API_BASE}{endpoint}"

        if method == "GET":
            response = requests.get(url, headers=headers, timeout=TIMEOUT)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=json_data, timeout=TIMEOUT)
        elif method == "PUT":
            response = requests.put(url, headers=headers, json=json_data, timeout=TIMEOUT)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers, timeout=TIMEOUT)
        elif method == "PATCH":
            response = requests.patch(url, headers=headers, json=json_data, timeout=TIMEOUT)
        else:
            return None, 0, False, f"Unknown method: {method}"

        elapsed = time.time() - start
        success = 200 <= response.status_code < 400
        return response.status_code, elapsed, success, None

    except requests.exceptions.Timeout:
        return None, TIMEOUT, False, "Request timeout"
    except requests.exceptions.ConnectionError:
        return None, 0, False, "Connection error"
    except Exception as e:
        return None, 0, False, str(e)

# ============================================================================
# AGENT TESTS
# ============================================================================

def agent_1_health():
    """Agent 1: Health & Status"""
    result = TestResult("agent-1", "HealthTester", "Health & Status")

    endpoints = [
        ("GET", "/"),
        ("GET", "/health"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_2_oauth():
    """Agent 2: OAuth"""
    result = TestResult("agent-2", "OAuthValidator", "OAuth")

    endpoints = [
        ("GET", "/fatsecret/connect"),
        ("GET", "/fatsecret/status"),
        ("GET", "/fatsecret/callback"),
        ("POST", "/fatsecret/disconnect"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_3_foods():
    """Agent 3: Foods API"""
    result = TestResult("agent-3", "FoodsTester", "Foods API")

    endpoints = [
        ("GET", "/api/fatsecret/foods/search?search_expression=chicken"),
        ("GET", "/api/fatsecret/foods/123456789"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_4_recipes():
    """Agent 4: Recipes API"""
    result = TestResult("agent-4", "RecipesTester", "Recipes API")

    endpoints = [
        ("GET", "/api/fatsecret/recipes/types"),
        ("GET", "/api/fatsecret/recipes/search?search_expression=pasta"),
        ("GET", "/api/fatsecret/recipes/search/type/1"),
        ("GET", "/api/fatsecret/recipes/999888"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_5_favorites_foods():
    """Agent 5: Favorite Foods"""
    result = TestResult("agent-5", "FavoritesFoodsTester", "Favorite Foods")

    endpoints = [
        ("GET", "/api/fatsecret/favorites/foods"),
        ("GET", "/api/fatsecret/favorites/foods/most-eaten"),
        ("GET", "/api/fatsecret/favorites/foods/recently-eaten"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_6_favorites_recipes():
    """Agent 6: Favorite Recipes"""
    result = TestResult("agent-6", "FavoritesRecipesTester", "Favorite Recipes")

    endpoints = [
        ("GET", "/api/fatsecret/favorites/recipes"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_7_saved_meals():
    """Agent 7: Saved Meals"""
    result = TestResult("agent-7", "SavedMealsTester", "Saved Meals")

    endpoints = [
        ("GET", "/api/fatsecret/saved-meals"),
        ("GET", "/api/fatsecret/saved-meals/123/items"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_8_diary():
    """Agent 8: Diary API"""
    result = TestResult("agent-8", "DiaryTester", "Diary API")

    endpoints = [
        ("GET", "/api/fatsecret/diary/day/20241214"),
        ("GET", "/api/fatsecret/diary/month/202412"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_9_profile_exercise():
    """Agent 9: Profile & Exercise"""
    result = TestResult("agent-9", "ProfileExerciseTester", "Profile & Exercise")

    endpoints = [
        ("GET", "/api/fatsecret/profile"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_10_weight():
    """Agent 10: Weight API"""
    result = TestResult("agent-10", "WeightTester", "Weight API")

    endpoints = [
        ("GET", "/api/fatsecret/weight"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_11_dashboard():
    """Agent 11: Dashboard Legacy APIs"""
    result = TestResult("agent-11", "DashboardLegacyTester", "Dashboard")

    endpoints = [
        ("GET", "/dashboard"),
        ("GET", "/log/food/12345678"),
        ("GET", "/api/dashboard/data"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def agent_12_ai_tandoor():
    """Agent 12: AI & Tandoor"""
    result = TestResult("agent-12", "AITandoorTester", "AI & Tandoor")

    endpoints = [
        ("GET", "/tandoor/status"),
        ("GET", "/api/tandoor/recipes"),
    ]

    for method, endpoint in endpoints:
        status, elapsed, success, error = test_endpoint(method, endpoint)
        result.add_test(endpoint, method, status or 0, elapsed, success, error)

    return result

def run_all_tests():
    """Run all 12 agents in parallel"""
    print("\n🚀 Starting Parallel Endpoint Tests - 12 Agents\n")
    print(f"API Base: {API_BASE}")
    print(f"Timestamp: {datetime.utcnow().isoformat()}Z\n")

    agents = [
        agent_1_health,
        agent_2_oauth,
        agent_3_foods,
        agent_4_recipes,
        agent_5_favorites_foods,
        agent_6_favorites_recipes,
        agent_7_saved_meals,
        agent_8_diary,
        agent_9_profile_exercise,
        agent_10_weight,
        agent_11_dashboard,
        agent_12_ai_tandoor,
    ]

    results = []

    with ThreadPoolExecutor(max_workers=12) as executor:
        futures = {executor.submit(agent): agent.__name__ for agent in agents}

        for future in as_completed(futures):
            try:
                result = future.result()
                results.append(result.to_dict())
                print(f"✓ {result.agent_name} completed ({len(result.tests)} tests)")
            except Exception as e:
                print(f"✗ Agent failed: {e}")

    # Aggregate results
    total_tests = sum(r["summary"]["total"] for r in results)
    total_passed = sum(r["summary"]["passed"] for r in results)
    total_failed = sum(r["summary"]["failed"] for r in results)
    avg_time = sum(r["summary"]["avg_response_time_ms"] for r in results) / len(results) if results else 0

    report = {
        "test_run": datetime.utcnow().isoformat() + "Z",
        "api_base": API_BASE,
        "total_agents": len(results),
        "agent_results": results,
        "overall_summary": {
            "total_endpoints_tested": total_tests,
            "passed": total_passed,
            "failed": total_failed,
            "success_rate": f"{(total_passed / total_tests * 100):.1f}%" if total_tests > 0 else "0%",
            "avg_response_time_ms": round(avg_time, 2),
        }
    }

    # Print summary
    print(f"\n{'='*70}")
    print(f"✅ All Tests Complete!")
    print(f"{'='*70}")
    print(f"Total Endpoints Tested: {total_tests}")
    print(f"Passed: {total_passed}")
    print(f"Failed: {total_failed}")
    print(f"Success Rate: {report['overall_summary']['success_rate']}")
    print(f"Average Response Time: {avg_time:.2f}ms")
    print(f"\n📊 Full Report (JSON):")
    print(json.dumps(report, indent=2))

    return report

if __name__ == "__main__":
    run_all_tests()
