"""
Roblox Game Downloader - downloads .rbxm using .ROBLOSECURITY cookie
Only works for games where the creator has enabled copying.
"""

import os
import sys
import re
import time
import requests
from pathlib import Path

COOKIE = "_|WARNING:-DO-NOT-SHARE-THIS.--Sharing-this-will-allow-someone-to-log-in-as-you-and-to-steal-your-ROBUX-and-items.|_CAEaAhADIhsKBGR1aWQSEzgyMzMwODkxMjk3MTUwOTkyNTIoAw.cdPMYHOtt4fxJ23qKXVO7J64MOaZAKcBaY1XpGZDMY0Zefyd5sYTtziJRmbZUnIomheyUJhzflBqEYblWyDXRx5cRlQQtcVtgvM5EpyB5ss-eEfjqlebNuMv4oDurVyJ0CEhCOaltI15IM0TYFhWRs-VqXSJZAtk1fboiBxyoVqoxqb40P6bIPZv9iBjxApvgAHHywI6h6K1Fzlubyhjx-TCGDA-9uXrTENGQMRuoxU2exrU2QcgV8wyO49S3mlWCIdcO3iPa_PxfQF1UBCeA72jV4A9v2aeUGjQ6jwAKc34m5eDgWd4L52xgxGm_7pr0IOmWZau-fVN6Rqte5a1-qGtS6_NSIYdgWghUvSxEn5kn0KiwIR_S2aQC5yiDF2gjyfgWQDc-4Q_wbfie7kgVy_3hJaJpAZw_q-9BoEGsAEZKGn0UwcG4dlFrLom8AfKAWEBdo068eLjpJ3WKeXrBKFN-eRaTJfcw1KLGZPXKzOpkJE98GGfcmXaWal-t55RzDyDc8Uxpga8suBgzyS0Q2lM8ppGIJ2vi7N7wjfu5AOfBwnBOWU_Sq6Iz80eAc6LhIoP3prxMNnCuVp3N1FkC40JBrlCeI6aPz1NBeAMRw9ujb_22FCcaHTEwQ00JWnt3WQzy9tMAh3bIHYSod0rIBp2IbL_Uq1ciJPWIqg_Vc-O6aZs_oYGwCc7NhjJCr99yjWbqhd3IMloKjY24_pZZnwm_KjAdKvWDU1CSpRfuR7VsA1Ym_EIt4lCv49zf6f0vDiNNtEED7_bpzgER_kLfmfT98Uek1zRRiFIUbBxYcSLXmvWXA163h5Rmkcxd1ox-dir9qWJ5H4QbNaDVYKqPy1lRx2mIjiiDjekcc9SK-pRFyv0FFNw2nRtMp1t0OiOhpzfoEooOe52XsHzgdYTip2srGRfGMyCK7ZS6svED4UtxrhRKNT_NZfCyBrjgK3zXWUT0g"


def fmt(b):
    for u in ['B', 'KB', 'MB', 'GB']:
        if b < 1024:
            return f"{b:.2f} {u}"
        b /= 1024
    return f"{b:.2f} TB"


def main():
    print("=" * 60)
    print("     ROBLOX GAME DOWNLOADER (rbxm)")
    print("=" * 60)
    print(" Only works for games where copying is enabled.")
    print("=" * 60)

    game_id = input("\nGame ID (from roblox.com/games/[ID]): ").strip()
    if not game_id.isdigit():
        print("Invalid ID.")
        sys.exit(1)

    game_name = input("Game name (for folder name): ").strip() or f"game_{game_id}"

    # Session
    s = requests.Session()
    s.cookies.set(".ROBLOSECURITY", COOKIE, domain=".roblox.com")
    s.headers.update({
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    })

    # CSRF
    r = s.post("https://auth.roblox.com/v2/logout")
    csrf = r.headers.get("x-csrf-token", "")
    if csrf:
        s.headers["x-csrf-token"] = csrf

    # Auth verify
    r = s.get("https://users.roblox.com/v1/users/authenticated")
    if r.status_code == 200:
        print(f"\nLogged in as: {r.json().get('name', '?')}")
    else:
        print(f"Auth failed.")
        sys.exit(1)

    # Resolve ID
    place_id = game_id
    universe_id = None

    r = s.get(f"https://apis.roblox.com/universes/v1/places/{game_id}")
    if r.status_code == 200:
        d = r.json()
        if "universeId" in d:
            place_id = game_id
            universe_id = d["universeId"]

    if not universe_id:
        r = s.get(f"https://games.roblox.com/v1/games?universeIds={game_id}")
        if r.status_code == 200:
            d = r.json()
            if d.get("data"):
                universe_id = game_id
                place_id = d["data"][0].get("rootPlaceId", game_id)

    # Check copy permission
    copy_allowed = False
    if universe_id:
        r = s.get(f"https://games.roblox.com/v1/games?universeIds={universe_id}")
        if r.status_code == 200:
            d = r.json()
            if d.get("data"):
                copy_allowed = d["data"][0].get("copyingAllowed", False)

    if not copy_allowed:
        r = s.get(f"https://games.roblox.com/v1/games/multiget-place-details?placeIds={place_id}")
        if r.status_code == 200:
            d = r.json()
            if d and len(d) > 0:
                copy_allowed = d[0].get("isCopyable", False)

    print(f"\nPlace ID: {place_id}")
    print(f"Copying allowed: {copy_allowed}")

    if not copy_allowed:
        print("\n[!] This game does NOT allow copying.")
        print("    Roblox blocks the download server-side.")
        print("    Only games where the creator enabled 'Copying' can be downloaded.")
        print("    Game info will be saved instead.")
        # Save info only
        sname = re.sub(r'[^\w\s\-\.]', '_', game_name).strip()
        odir = Path(f"Roblox_{sname}_{place_id}")
        odir.mkdir(parents=True, exist_ok=True)
        (odir / "game_info.txt").write_text(
            f"Game: {game_name}\n"
            f"Place ID: {place_id}\n"
            f"Universe ID: {universe_id or 'N/A'}\n"
            f"Copying Allowed: No\n"
            f"Fetched: {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())}\n",
            encoding="utf-8"
        )
        print(f"Saved info to: {odir / 'game_info.txt'}")
        sys.exit(0)

    # Download
    print(f"\n[*] Downloading .rbxm...")
    sname = re.sub(r'[^\w\s\-\.]', '_', game_name).strip()
    odir = Path(f"Roblox_{sname}_{place_id}")
    odir.mkdir(parents=True, exist_ok=True)
    path = odir / f"{sname}_{place_id}.rbxm"

    url = f"https://assetdelivery.roblox.com/v1/asset?id={place_id}"
    r = s.get(url, stream=True, timeout=60)
    if r.status_code == 200 and len(r.content) > 100:
        path.write_bytes(r.content)
        print(f"  SUCCESS: {fmt(len(r.content))}")
        print(f"  Saved: {path}")
    else:
        print(f"  Failed (HTTP {r.status_code})")
        sys.exit(1)

    (odir / "game_info.txt").write_text(
        f"Game: {game_name}\n"
        f"Place ID: {place_id}\n"
        f"Universe ID: {universe_id or 'N/A'}\n"
        f"Size: {fmt(len(r.content))}\n"
        f"Fetched: {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())}\n",
        encoding="utf-8"
    )

    print(f"\n{'=' * 60}")
    print(f"  DONE - file in: {odir}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()