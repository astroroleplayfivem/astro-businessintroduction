# Astro Business Introduction

- Astro Business Introduction is a QBCore business directory system designed for roleplay servers that want players to easily discover city businesses, see who owns them, check if they are hiring, and visit their locations. 
- Players can open a public business board through a PED interaction or command, browse listed businesses, filter by category, search by name/location/owner, and set a GPS waypoint directly to the business location. 
- Admins can manage the directory in-game through a built-in admin panel without needing to manually edit files every time a business changes.

---

## Features
- Browse city businesses in-game
- Business cards with image, owner, category, location, contact, status, and description
- Hiring status support
- Search bar for businesses, owners, locations, descriptions, and contact info
- Category filtering
- Hiring-only filter
- Set GPS waypoint to listed businesses
- PED interaction support
- Optional map blip for the directory PED
- Admin-only management panel
- Add new businesses in-game
- Edit existing businesses in-game
- Delete businesses in-game
- Live sync updates to open UIs
- Business data saved to JSON
- Discord CDN image validation support
- Configurable categories
- Configurable commands
- Configurable admin permissions
- Supports `qb-target` and `ox_target`

---

## Framework
This resource is built for:
- QBCore

---
## Dependencies
Required:
- `qb-core`
- `ox_lib`
- `qb-target`
- `ox_target`

The script will use `ox_target` first if it is started. If `ox_target` is not running, it will try to use `qb-target`.

---

## Commands

### Public Directory
```lua
/businessdirectory

Scripts that go together :
Player Introdcution : https://astro-scripts-webstore.tebex.io/package/7417140
Job Applications : 
Preview : 
