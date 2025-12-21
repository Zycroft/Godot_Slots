# Roguelike Slots

A slot machine game built with Godot 4.5.1.

## Running the Project

### Using MCP Server (Recommended)
The project is configured to run via the Godot MCP server. Simply ask Claude to run the project:

```
"run my project"
```

Claude will execute:
```javascript
mcp__godot__run_project({ projectPath: "c:\\Users\\parke\\OneDrive\\Repos\\Godot_Slots" })
```

### Manual Run
You can also run the project directly with Godot:

```bash
"C:/Users/parke/OneDrive/Repos/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe" --path "c:\Users\parke\OneDrive\Repos\Godot_Slots"
```

## MCP Server Configuration

This project uses MCP (Model Context Protocol) servers for AI-assisted development. See [README_MCP.md](README_MCP.md) for full MCP setup documentation.

### Active MCP Servers

- **godot** - Godot engine integration for running projects, creating scenes, and managing nodes
- **image-openai** - Image generation using OpenAI's DALL-E API

### Configuration File

The MCP servers are configured in [.mcp.json](.mcp.json):

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["${MCP_SERVERS_PATH}/godot-mcp/build/index.js"],
      "env": {
        "GODOT_PATH": "C:/Users/parke/OneDrive/Repos/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe"
      }
    },
    "image-openai": {
      "command": "node",
      "args": ["${MCP_SERVERS_PATH}/mcp-image-openai/dist/index.js"],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}"
      }
    }
  }
}
```

## Project Structure

- **Scenes/** - Godot scene files
  - `Main.tscn` - Main game scene
- **Scripts/** - GDScript files
  - `SlotMachine.gd` - Slot machine logic
- **Assets/** - Game assets
- **Audio/** - Sound effects
- **UI/** - User interface elements
- **TexturePacker/** - Sprite sheet configurations

## Development

### Generating Assets

You can ask Claude to generate game assets using the image-openai MCP server:

```
"Generate a cherry symbol for the slot machine"
```

### Building Sprite Sheets

The project uses TexturePacker for sprite atlas generation. See the TexturePacker addon documentation in the original README.md.

## Requirements

- Godot 4.5.1 or newer
- Node.js (for MCP servers)
- OpenAI API key (for image generation)

## License

[MIT License](LICENSE)
