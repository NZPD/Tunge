#!/usr/bin/env python3
"""
Roblox Game Copier
Downloads Roblox games as .rbxm files using .ROBLOSECURITY cookie.
"""

import os
import sys
import json
import time
import requests
from pathlib import Path


def fmt(size):
    for u in ['B','KB','MB','GB']:
        if size < 1024: return f"{size:.2f} {u}"
        size /= 1024
    return f"{size:.2f} TB"


def csrf(session):
    r = session.post("https://auth.roblox.com/v2/logout", timeout=10)
    tok = r.headers.get("x-csrf-token", "")
    if tok:
        session.headers["x-csrf-token"] = tok


def login(session, cookie):
    session.cookies.set(".ROBLOSECURITY", cookie, domain=".roblox.com")
    r = session.get("https://users.roblox.com/v1/users/authenticated", timeout=10)
    if r.status_code == 200:
        d = r.json()
        print(f"Logged in as: {d.get('name','?')} (ID: {d.get('id','?')})")
        csrf(session)
        return True
    print("Login failed.")
    return False


def g(session, url, label=""):
    try:
        r = session.get(url, timeout=10)
        if r.status_code == 200:
            return r.json()
        if r.status_code == 403:
            csrf(session)
            r = session.get(url, timeout=10)
            if r.status_code == 200:
                return r.json()
        return None
    except Exception as e:
        if label: print(f"  [{label}] {e}")
        return None


def main():
    print("=" * 60)
    print("     ROBLOX GAME COPIER (rbxm)")
    print("=" * 60)

    # Cookie
    cookie = input("\n.ROBLOSECURITY cookie: ").strip()
    if not cookie:
        print("No cookie provided.")
        sys.exit(1)

    sess = requests.Session()
    sess.headers.update({
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json",
    })

    if not login(sess, cookie):
        sys.exit(1)

    # Game ID
    raw = input("\nGame / Place / Universe ID: ").strip()
    if not raw.isdigit():
        print("Invalid ID.")
        sys.exit(1)
    gid = int(raw)

    # Resolve
    print(f"\n[*] Resolving ID: {gid}")
    place_id = None
    universe_id = None

    d = g(sess, f"https://apis.roblox.com/universes/v1/places/{gid}")
    if d and "universeId" in d:
        place_id = gid
        universe_id = d["universeId"]
        print(f"  Place ID: {place_id} -> Universe ID: {universe_id}")
    else:
        d = g(sess, f"https://games.roblox.com/v1/games?universeIds={gid}")
        if d and d.get("data"):
            universe_id = gid
            place_id = d["data"][0].get("rootPlaceId")
            print(f"  Universe ID: {universe_id} -> Root Place ID: {place_id}")

    if not place_id:
        print("Could not resolve game ID.")
        sys.exit(1)

    # Fetch details
    print(f"\n[*] Fetching game info...")
    game = g(sess, f"https://games.roblox.com/v1/games?universeIds={universe_id}")
    details = g(sess, f"https://games.roblox.com/v1/games/multiget-place-details?placeIds={place_id}")

    name = "Unknown"
    copying = False
    creator = ""

    if game and game.get("data"):
        gd = game["data"][0]
        name = gd.get("name", name)
        creator = gd.get("creator", {}).get("name", "")
        copying = gd.get("copyingAllowed", False)

    if details and len(details) > 0:
        copying = details[0].get("isCopyable", copying)
        if details[0].get("name"): name = details[0]["name"]
        if details[0].get("creatorName"): creator = details[0]["creatorName"]
        if not creator and details[0].get("creatorId"):
            creator = str(details[0]["creatorId"])

    # Save info
    sname = "".join(c if c.isalnum() or c in " _-" else "_" for c in name).strip()
    odir = Path(f"Roblox_{sname}_{place_id}")
    odir.mkdir(parents=True, exist_ok=True)

    txt = f"""
Game: {name}
Place ID: {place_id}
Universe ID: {universe_id}
Creator: {creator}
Copying Allowed: {copying}
Fetched: {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())}
""".strip()

    (odir / "game_info.txt").write_text(txt, encoding="utf-8")
    print(f"[*] Saved info to: {odir / 'game_info.txt'}")

    # Download as .rbxm
    if copying:
        print(f"\n[*] Downloading {place_id} as .rbxm...")
        url = f"https://assetdelivery.roblox.com/v1/asset?id={place_id}"
        try:
            r = sess.get(url, stream=True, timeout=60)
            if r.status_code == 200:
                total = int(r.headers.get("content-length", 0))
                dl = 0
                path = odir / f"{sname}_{place_id}.rbxm"
                with open(path, "wb") as f:
                    for chunk in r.iter_content(8192):
                        if chunk:
                            f.write(chunk)
                            dl += len(chunk)
                            if total:
                                pct = dl / total * 100
                                print(f"\r  {pct:.1f}% ({fmt(dl)} / {fmt(total)})", end="")
                            else:
                                print(f"\r  Downloaded {fmt(dl)}", end="")
                print(f"\n  Saved: {path}")
            else:
                print(f"  HTTP {r.status_code} - download failed")
                if r.status_code == 403:
                    print("  (Invalid/expired cookie)")
        except Exception as e:
            print(f"  Error: {e}")
    else:
        print(f"\n  Copying not allowed for this game. Info saved only.")

    print(f"\n{'=' * 60}")
    print(f"  DONE - output in: {odir}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nCancelled.")
        sys.exit(0)
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)