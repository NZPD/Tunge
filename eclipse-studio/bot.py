"""
Eclipse Studio Discord Bot
Monitors role ID 1514022192654979262 and updates the website's community members.
Run this bot 24/7 on a server, replit, or your own machine.

Setup:
1. pip install discord.py
2. Set your bot token below
3. Run: python bot.py
"""

import discord
import json
import os
import asyncio
from datetime import datetime

# ===== CONFIG =====
BOT_TOKEN = "YOUR_BOT_TOKEN_HERE"  # Replace with your bot token
ROLE_ID = 1514022192654979262      # The role to track
MEMBERS_FILE = "members.json"      # Where members are stored
# ==================

intents = discord.Intents.default()
intents.members = True
intents.guilds = True
client = discord.Client(intents=intents)

def load_members():
    if os.path.exists(MEMBERS_FILE):
        try:
            with open(MEMBERS_FILE, 'r') as f:
                return json.load(f)
        except:
            return []
    return []

def save_members(members):
    with open(MEMBERS_FILE, 'w') as f:
        json.dump(members, f, indent=2)
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Members saved: {len(members)} total")

async def update_member_list(guild):
    """Scan all members and update the list based on who has the role."""
    role = guild.get_role(ROLE_ID)
    if not role:
        print(f"Role {ROLE_ID} not found in guild {guild.name}")
        return
    
    members_with_role = []
    for member in guild.members:
        if role in member.roles:
            members_with_role.append({
                "id": str(member.id),
                "name": member.display_name,
                "global_name": member.global_name or member.name,
                "avatar": member.display_avatar.url if member.display_avatar else None,
                "added_at": datetime.now().isoformat()
            })
    
    save_members(members_with_role)
    print(f"Found {len(members_with_role)} members with role {role.name}")

@client.event
async def on_ready():
    print(f"Bot logged in as {client.user}")
    for guild in client.guilds:
        print(f"Scanning guild: {guild.name} (ID: {guild.id})")
        await update_member_list(guild)

@client.event
async def on_member_update(before, after):
    """Called when a member's roles change."""
    before_roles = {r.id for r in before.roles}
    after_roles = {r.id for r in after.roles}
    
    had_role = ROLE_ID in before_roles
    has_role = ROLE_ID in after_roles
    
    if had_role == has_role:
        return  # No change to our tracked role
    
    members = load_members()
    
    if has_role:
        # Role was added
        member_data = {
            "id": str(after.id),
            "name": after.display_name,
            "global_name": after.global_name or after.name,
            "avatar": after.display_avatar.url if after.display_avatar else None,
            "added_at": datetime.now().isoformat()
        }
        
        # Check if already in list
        existing_ids = {m["id"] for m in members}
        if member_data["id"] not in existing_ids:
            members.append(member_data)
            print(f"➕ Added: {after.display_name} ({after.id})")
        else:
            # Update existing entry
            for i, m in enumerate(members):
                if m["id"] == member_data["id"]:
                    members[i]["name"] = after.display_name
                    members[i]["avatar"] = member_data["avatar"]
                    break
            print(f"🔄 Updated: {after.display_name} ({after.id})")
    else:
        # Role was removed
        members = [m for m in members if m["id"] != str(after.id)]
        print(f"➖ Removed: {after.display_name} ({after.id})")
    
    save_members(members)

@client.event
async def on_guild_channel_update(before, after):
    pass  # Not needed but prevents errors

@client.event
async def on_guild_update(before, after):
    pass  # Not needed

@client.event
async def on_guild_join(guild):
    print(f"Joined new guild: {guild.name}")
    await update_member_list(guild)

if __name__ == "__main__":
    print("Starting Eclipse Studio Discord Bot...")
    print(f"Tracking role ID: {ROLE_ID}")
    print("Make sure to set your BOT_TOKEN!")
    client.run(BOT_TOKEN)