# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Roguelike Slots is a Godot 4.5.1 slot machine game with roguelike progression elements. Players spin reels, earn credits, and purchase "loyalty cards" that upgrade the slot machine (add reels, paylines, or symbols).

**Entry Point:** `res://Scenes/Main.tscn`
**Resolution:** 1920x1080 (canvas_items stretch mode)
**Platforms:** Web (primary), Desktop

## Running the Project

```bash
# Run with Godot CLI
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/zycroft/Documents/apps/godot/Godot_Slots

# Or use the godot MCP tool
mcp__godot__run_project with projectPath: /Users/zycroft/Documents/apps/godot/Godot_Slots
```

## Core Architecture

### GameConfig Singleton (Scripts/GameConfig.gd)
Central state manager autoloaded at startup. Manages:
- Slot machine configuration (num_reels, visible_rows, reelslots)
- Player resources (credits, hours_remaining)
- Difficulty settings (Easy/Normal/Hard with cost multipliers)
- Loyalty card system (purchased upgrades)
- Symbol textures (cached on load from `Config/game_config.json`)

Key signals: `config_changed`, `card_purchased(card_id)`, `game_reset`

### SlotMachine (Scripts/SlotMachine.gd)
Handles reel spinning, animation, and user input:
- Dynamically builds reels from GameConfig
- Lever/spacebar triggers spin with 4-frame animation
- Per-reel staggered stopping with deceleration
- Coin drop animation on spin completion
- Responds to card purchases (add reel/payline/symbol)

Constants: `SYMBOL_HEIGHT=100`, `BASE_SPEED=2000`, `DECEL_RATE=800`

### UI Components
- **StartScreen.gd** - Difficulty selection overlay (layer 10)
- **StoreUI.gd** - Shop with animated teller sprite, offers 3 random cards
- **CardDisplay.gd** - Left sidebar showing purchased cards
- **MarkerAnimation.gd** - HUD showing credits/hours with fly-in animation

### Signal Flow
```
GameConfig ──config_changed──> SlotMachine (rebuild reels)
          ──card_purchased──> SlotMachine, CardDisplay, StoreUI
          ──game_reset─────> StartScreen (show), all UI (reset)

SlotMachine ──spin complete──> spawn coins, update credits/hours
StartScreen ──start_game(difficulty)──> GameConfig, hide self
StoreUI ──buy_card()──> GameConfig ──card_purchased──> all listeners
```

## Asset Pipeline

### MCP Tools Integration (.mcp.json)
Project is configured for AI-assisted asset creation:
- **image-openai** - Generate sprites with DALL-E 3
- **imagemagick** - Batch process/resize images
- **texturepacker** - Create sprite atlases (godot4-atlas format)
- **audio-elevenlabs** - Generate sound effects
- **godot** - Run project, create scenes/nodes

### Asset Locations
- `Assets/SingleImages/output/` - Symbol PNGs, coin strips, lever sprites
- `Assets/sprite_sheet_256_5px.png` - Teller animation (13x12 grid, 256px each)
- `assets.sprites/` - Generated .tres AtlasTexture resources
- `Audio/SFX/` - Sound effects (spin, reel_stop, coin_land, etc.)
- `Config/game_config.json` - Reel/symbol/payline configuration

## Key Implementation Details

### Reel System
Each reel is a Panel containing ClipContainer (clip_contents=true) with SymbolStrip VBoxContainer. Symbols wrap using modulo arithmetic with WRAP_BUFFER=3 extra symbols for seamless looping.

### Loyalty Card Types
Defined in `GameConfig.CARD_DEFINITIONS`:
- `"reel"` - Adds new reel with shuffled symbols (base: 50 credits)
- `"payline"` - Adds visible row (base: 30 credits)
- `"symbol"` - Adds unlockable symbol to all reels (base: 100 credits)

Costs are multiplied by difficulty (Easy: 0.5x, Normal: 1x, Hard: 2x)

### Current Limitations
- Win detection not implemented (coins spawn on every spin)
- Paylines are visual only (no matching/payout logic)
- No persistent save system for player progress
- No mobile/touch input handling

## Build & Export

Web export configured in `export_presets.cfg`. The SConstruct file is for C++ GDExtension (not used in gameplay scripts).
