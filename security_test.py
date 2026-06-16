"""Security test for Roblox game copying protection."""
import requests

s = requests.Session()
s.cookies.set(".ROBLOSECURITY",
    "_|WARNING:-DO-NOT-SHARE-THIS.--Sharing-this-will-allow-someone-to-log-in-as-you-and-to-steal-your-ROBUX-and-items.|_CAEaAhADIhsKBGR1aWQSEzgyMzMwODkxMjk3MTUwOTkyNTIoAw.cdPMYHOtt4fxJ23qKXVO7J64MOaZAKcBaY1XpGZDMY0Zefyd5sYTtziJRmbZUnIomheyUJhzflBqEYblWyDXRx5cRlQQtcVtgvM5EpyB5ss-eEfjqlebNuMv4oDurVyJ0CEhCOaltI15IM0TYFhWRs-VqXSJZAtk1fboiBxyoVqoxqb40P6bIPZv9iBjxApvgAHHywI6h6K1Fzlubyhjx-TCGDA-9uXrTENGQMRuoxU2exrU2QcgV8wyO49S3mlWCIdcO3iPa_PxfQF1UBCeA72jV4A9v2aeUGjQ6jwAKc34m5eDgWd4L52xgxGm_7pr0IOmWZau-fVN6Rqte5a1-qGtS6_NSIYdgWghUvSxEn5kn0KiwIR_S2aQC5yiDF2gjyfgWQDc-4Q_wbfie7kgVy_3hJaJpAZw_q-9BoEGsAEZKGn0UwcG4dlFrLom8AfKAWEBdo068eLjpJ3WKeXrBKFN-eRaTJfcw1KLGZPXKzOpkJE98GGfcmXaWal-t55RzDyDc8Uxpga8suBgzyS0Q2lM8ppGIJ2vi7N7wjfu5AOfBwnBOWU_Sq6Iz80eAc6LhIoP3prxMNnCuVp3N1FkC40JBrlCeI6aPz1NBeAMRw9ujb_22FCcaHTEwQ00JWnt3WQzy9tMAh3bIHYSod0rIBp2IbL_Uq1ciJPWIqg_Vc-O6aZs_oYGwCc7NhjJCr99yjWbqhd3IMloKjY24_pZZnwm_KjAdKvWDU1CSpRfuR7VsA1Ym_EIt4lCv49zf6f0vDiNNtEED7_bpzgER_kLfmfT98Uek1zRRiFIUbBxYcSLXmvWXA163h5Rmkcxd1ox-dir9qWJ5H4QbNaDVYKqPy1lRx2mIjiiDjekcc9SK-pRFyv0FFNw2nRtMp1t0OiOhpzfoEooOe52XsHzgdYTip2srGRfGMyCK7ZS6svED4UtxrhRKNT_NZfCyBrjgK3zXWUT0g",
    domain=".roblox.com")
s.headers.update({"User-Agent": "Mozilla/5.0"})

# Get CSRF
r = s.post("https://auth.roblox.com/v2/logout")
csrf = r.headers.get("x-csrf-token", "")
if csrf:
    s.headers["x-csrf-token"] = csrf

# Auth check
r = s.get("https://users.roblox.com/v1/users/authenticated")
user = r.json().get("name", "?") if r.status_code == 200 else "LOGIN FAILED"
print(f"\nLogged in as: {user}")

# Get game ID from user
game_id = input("\nGame / Place ID to test: ").strip()
if not game_id.isdigit():
    print("Invalid ID")
    exit()

print(f"\n=== Testing Game ID: {game_id} ===\n")

# Method 1: API check
r = s.get(f"https://games.roblox.com/v1/games/multiget-place-details?placeIds={game_id}")
if r.status_code == 200:
    d = r.json()
    if d and len(d) > 0:
        ic = d[0].get("isCopyable", "?")
        print(f"[API multiget] isCopyable = {ic}")

r = s.get(f"https://games.roblox.com/v1/games?universeIds={game_id}")
if r.status_code == 200:
    d = r.json()
    if d.get("data"):
        ca = d["data"][0].get("copyingAllowed", "?")
        print(f"[API games]     copyingAllowed = {ca}")

# Method 2: Actual download test
print(f"\n[Download test] assetdelivery.roblox.com...")
r = s.get(f"https://assetdelivery.roblox.com/v1/asset?id={game_id}")
is_html = "<!DOCTYPE" in r.text[:100] or "<html" in r.text[:100]
print(f"  HTTP {r.status_code} | {len(r.content)} bytes")

if is_html:
    print(f"  --> Got HTML page (DOWNLOAD BLOCKED) - Security is WORKING")
elif r.status_code == 409:
    print(f"  --> HTTP 409 Conflict (DOWNLOAD BLOCKED) - Security is WORKING")
elif r.status_code == 200 and not is_html:
    print(f"  --> Got binary file (DOWNLOAD SUCCEEDED) - Game is COPYABLE")
else:
    print(f"  --> Status: {r.status_code}")

# Method 3: Try /Download endpoint
print(f"\n[Download test] /Download endpoint...")
r = s.get(f"https://www.roblox.com/games/{game_id}/Download")
is_html = "<!DOCTYPE" in r.text[:100]
print(f"  HTTP {r.status_code} | {len(r.content)} bytes")
if r.status_code == 200 and not is_html:
    print(f"  --> Got binary file via /Download!")
elif is_html:
    print(f"  --> Got HTML page (blocked)")

print(f"\n{'='*50}")
print(f"  TEST COMPLETE")
print(f"{'='*50}")