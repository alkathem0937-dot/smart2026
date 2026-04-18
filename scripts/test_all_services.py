"""Quick smoke test for all running services."""
import urllib.request
import json
import sys

GATEWAY = "http://127.0.0.1:9000"
DJANGO  = "http://127.0.0.1:8080"
INHERIT = "http://127.0.0.1:8001"

passed = 0
failed = 0

def check(label, url, method="GET", body=None, expect_codes=(200,)):
    global passed, failed
    try:
        headers = {}
        if body:
            body = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        r = urllib.request.urlopen(req)
        code = r.status
        data = r.read().decode()
    except urllib.error.HTTPError as e:
        code = e.code
        data = e.read().decode()
    except Exception as e:
        print(f"  FAIL  {label} -> {e}")
        failed += 1
        return

    ok = code in expect_codes
    mark = "OK" if ok else "FAIL"
    if ok:
        passed += 1
    else:
        failed += 1
    detail = data[:120].replace("\n", " ")
    print(f"  {mark:4s}  [{code}]  {label}")
    if not ok:
        print(f"        expected {expect_codes}, body: {detail}")
    return data


print("=" * 55)
print("  SmartJudi — Full Service Smoke Test")
print("=" * 55)

# --- Direct health checks ---
print("\n[1] Health Checks")
check("Django direct", f"{DJANGO}/health/")
check("Inheritance direct", f"{INHERIT}/health/")
check("Gateway direct", f"{GATEWAY}/health/")

# --- Gateway -> Django proxy ---
print("\n[2] Gateway -> Django Proxy")
check("api/info", f"{GATEWAY}/api/info/")
check("swagger", f"{GATEWAY}/swagger/")
check("lawsuits (auth required)", f"{GATEWAY}/api/lawsuits/", expect_codes=(401,))
check("courts (auth required)", f"{GATEWAY}/api/courts/", expect_codes=(401,))
check("profiles (auth required)", f"{GATEWAY}/api/profiles/", expect_codes=(401,))

# --- Gateway -> Inheritance proxy ---
print("\n[3] Gateway -> Inheritance Proxy")
body = {
    "estate_value": 1000000,
    "debts": 50000,
    "bequests": 0,
    "heirs": [
        {"type": "son", "count": 2},
        {"type": "daughter", "count": 1},
        {"type": "wife", "count": 1},
    ],
}
raw = check("inheritance calculate", f"{GATEWAY}/api/inheritance/calculate/", method="POST", body=body)
if raw:
    result = json.loads(raw)
    print(f"        Totals: {result.get('totals', {})}")
    for s in result.get("shares", []):
        print(f"        {s['heir_type']:12s} x{s['count']}  = {s['total_amount']}")
    if result.get("notes"):
        print(f"        Notes: {result['notes']}")

# --- Token endpoint ---
print("\n[4] Authentication")
check("token (bad creds)", f"{GATEWAY}/api/token/", method="POST",
      body={"username": "test", "password": "wrong"}, expect_codes=(401,))

# --- Summary ---
print("\n" + "=" * 55)
total = passed + failed
print(f"  Result: {passed}/{total} passed, {failed} failed")
if failed == 0:
    print("  All services are running correctly!")
else:
    print("  Some checks failed - review above.")
print("=" * 55)
sys.exit(0 if failed == 0 else 1)
