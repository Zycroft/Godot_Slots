# MCP Server Configuration

This project uses [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers to provide AI-powered tooling for game development.

## Required Environment Variables

Set these environment variables on your system before using the MCP servers:

| Variable | Required | Description |
|----------|----------|-------------|
| `MCP_SERVERS_PATH` | Yes | Base directory containing all MCP server folders |
| `GODOT_PATH` | Yes | Full path to the Godot executable |
| `OPENAI_API_KEY` | Optional | OpenAI API key (for image-openai server) |
| `ELEVENLABS_API_KEY` | Optional | ElevenLabs API key (for audio-elevenlabs server) |

### Windows (PowerShell)

```powershell
# Set environment variables (run as Administrator for system-wide, or regular for user)
[Environment]::SetEnvironmentVariable("MCP_SERVERS_PATH", "C:/Users/YourName", "User")
[Environment]::SetEnvironmentVariable("GODOT_PATH", "C:/Program Files/Godot/Godot_v4.5.1-stable_win64_console.exe", "User")
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "sk-your-openai-key", "User")
[Environment]::SetEnvironmentVariable("ELEVENLABS_API_KEY", "your-elevenlabs-key", "User")
```

### macOS/Linux (Bash)

Add to your `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
export MCP_SERVERS_PATH="$HOME"
export GODOT_PATH="/usr/local/bin/godot"
export OPENAI_API_KEY="sk-your-openai-key"
export ELEVENLABS_API_KEY="your-elevenlabs-key"
```

## MCP Servers

The following MCP servers are configured in `.mcp.json`:

### godot
Provides Godot engine integration for running projects, creating scenes, and managing nodes.

**Location:** `${MCP_SERVERS_PATH}/godot-mcp/`

### image-openai
Generates images using OpenAI's DALL-E API.

**Location:** `${MCP_SERVERS_PATH}/mcp-image-openai/`

### imagemagick
Image processing and manipulation using ImageMagick.

**Location:** `${MCP_SERVERS_PATH}/mcp-imagemagick/`

### texturepacker
Sprite atlas generation using TexturePacker.

**Location:** `${MCP_SERVERS_PATH}/mcp-texturepacker/`

### audio-elevenlabs
Sound effect generation using ElevenLabs AI. Generates actual synthesized audio (not voice-based).

**Location:** `${MCP_SERVERS_PATH}/mcp-audio-elevenlabs/`

## Setup Instructions

1. **Clone/Install MCP Servers**

   Ensure each MCP server is installed in the `MCP_SERVERS_PATH` directory:
   ```
   ${MCP_SERVERS_PATH}/
   ├── godot-mcp/
   ├── mcp-image-openai/
   ├── mcp-imagemagick/
   ├── mcp-texturepacker/
   └── mcp-audio-elevenlabs/
   ```

2. **Install Dependencies**

   For each server, run:
   ```bash
   cd ${MCP_SERVERS_PATH}/mcp-audio-elevenlabs
   npm install
   npm run build
   ```

3. **Set Environment Variables**

   Configure all required environment variables as shown above.

4. **Restart VS Code**

   After setting environment variables, restart VS Code to pick up the changes.

## API Keys

### OpenAI
1. Sign up at https://platform.openai.com
2. Go to API Keys section
3. Create a new secret key
4. Set as `OPENAI_API_KEY` environment variable

### ElevenLabs
1. Sign up at https://elevenlabs.io
2. Go to Profile > API Keys
3. Copy your API key
4. Set as `ELEVENLABS_API_KEY` environment variable

## Troubleshooting

### MCP servers not connecting
- Verify environment variables are set: `echo $MCP_SERVERS_PATH`
- Ensure servers are built: check for `dist/` or `build/` folders
- Restart VS Code after changing environment variables

### API errors
- Verify API keys are valid and have sufficient credits
- Check that the API key environment variables are set correctly
