# MCP Servers -- Extending Claude Code

> Connect Claude Code to databases, browsers, APIs, and any external system through the Model Context Protocol.

## What Is MCP?

The Model Context Protocol (MCP) is an open standard that lets AI tools communicate with external services through a unified interface. Instead of hacking together shell scripts to bridge Claude Code to your database or browser, MCP provides a structured way for servers to expose tools, resources, and prompts that Claude Code can use natively.

In practical terms: an MCP server is a process that runs alongside Claude Code and adds new tools to its toolkit. When you configure a database MCP server, Claude Code gains the ability to query your database directly -- no bash piping or manual copy-paste required.

## How MCP Servers Work

The architecture is straightforward:

```
Claude Code (client)
    |
    |-- stdio/SSE connection -->  MCP Server (process)
    |                                  |
    |                                  +-- Database
    |                                  +-- Browser
    |                                  +-- API
    |
    |-- stdio connection -->  Another MCP Server
                                   |
                                   +-- File system
                                   +-- Slack
```

Each MCP server:

1. Starts as a subprocess or connects over HTTP (SSE)
2. Declares which tools it provides (name, description, input schema)
3. Receives tool calls from Claude Code and returns results
4. Runs with whatever permissions its process has

Claude Code discovers the tools at startup and makes them available during your session. You see them listed alongside built-in tools like `Read`, `Write`, `Bash`, and `Edit`.

---

## Setting Up an MCP Server

MCP servers are configured in your settings files:

- **User-level**: `~/.claude/settings.json` -- available in all projects
- **Project-level**: `.claude/settings.json` -- shared with the team

### Configuration Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@some-org/mcp-server-something"],
      "env": {
        "API_KEY": "your-key-here"
      }
    }
  }
}
```

### Fields

- **`command`** -- the executable to run (e.g., `npx`, `node`, `python3`, `uvx`)
- **`args`** -- arguments passed to the command
- **`env`** -- environment variables passed to the server process (optional)

### Using the CLI

You can also add MCP servers through the command line:

```bash
claude mcp add server-name -- npx -y @some-org/mcp-server-something
```

To list configured servers:

```bash
claude mcp list
```

To remove one:

```bash
claude mcp remove server-name
```

---

## Step-by-Step: Setting Up the SQLite MCP Server

Here is a complete walkthrough of adding database access to Claude Code.

### 1. Install and Configure

```bash
claude mcp add sqlite -- npx -y @anthropic-ai/mcp-server-sqlite --db-path ./myapp.db
```

Or add it directly to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic-ai/mcp-server-sqlite",
        "--db-path",
        "./myapp.db"
      ]
    }
  }
}
```

### 2. Restart Claude Code

MCP servers are loaded at session startup. After adding a new server, start a new session:

```bash
claude
```

### 3. Verify It Works

Ask Claude to use the new tools:

```
> What tables are in the database? Show me the schema.
```

Claude Code will call the `list_tables` and `describe_table` tools provided by the SQLite MCP server. No bash commands, no manual SQL piping -- it talks directly to the database.

### 4. Use It for Real Work

```
> Find all users who signed up in the last 7 days but never completed onboarding.
  Show me the count and a few example rows.
```

Claude writes and executes SQL through the MCP server, interprets the results, and presents them. If you ask it to fix data, it can run UPDATE statements too -- with the same permission controls as any other tool.

---

## Popular MCP Servers

### Filesystem

Provides scoped file access with read, write, search, and directory tools. Useful when you want to give Claude access to files outside the project directory with controlled permissions.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-filesystem", "/path/to/allowed/dir"]
    }
  }
}
```

### PostgreSQL

Direct database access for Postgres databases:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    }
  }
}
```

### GitHub

Access issues, PRs, repos, and code search through the GitHub API:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

### Puppeteer (Browser)

Control a headless browser -- navigate pages, take screenshots, fill forms, click elements:

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-puppeteer"]
    }
  }
}
```

### Slack

Send messages, read channels, search history:

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-token"
      }
    }
  }
}
```

---

## Writing a Custom MCP Server

When no existing server covers your needs, you can write your own. MCP servers can be written in any language. Here is a minimal example in Python using the official SDK.

### Install the SDK

```bash
pip install mcp
```

### Minimal Server

```python
# my_server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-tools")

@mcp.tool()
def lookup_user(email: str) -> str:
    """Look up a user by email in the internal directory."""
    # Replace with your actual lookup logic
    import json
    import urllib.request

    url = f"https://internal-api.company.com/users?email={email}"
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + os.environ["API_TOKEN"]})
    resp = urllib.request.urlopen(req)
    data = json.loads(resp.read())

    if not data["users"]:
        return f"No user found for {email}"

    user = data["users"][0]
    return f"Name: {user['name']}, Team: {user['team']}, Role: {user['role']}"

@mcp.tool()
def search_wiki(query: str) -> str:
    """Search the internal wiki for documentation."""
    # Your search implementation here
    return f"Results for '{query}': ..."

if __name__ == "__main__":
    mcp.run()
```

### Configure It

```json
{
  "mcpServers": {
    "internal-tools": {
      "command": "python3",
      "args": ["/path/to/my_server.py"],
      "env": {
        "API_TOKEN": "your-internal-token"
      }
    }
  }
}
```

### Use It

```
> Look up the user john@company.com and find their onboarding docs in the wiki.
```

Claude Code will call `lookup_user` and `search_wiki` as naturally as it calls `Read` or `Bash`.

---

## MCP vs. Bash Commands

You might wonder -- why not just have Claude run `curl` or `psql` via Bash? Both work, but they serve different purposes.

| Factor | MCP Server | Bash Command |
|--------|-----------|--------------|
| **Structure** | Typed inputs/outputs, schema-defined | Free-form text parsing |
| **Safety** | Scoped permissions, controlled access | Full shell access |
| **Reliability** | Consistent tool interface | Output format may vary |
| **Setup cost** | Higher (install/configure server) | Lower (just run the command) |
| **Reusability** | Shared across team via settings | Ad hoc, per-session |
| **Error handling** | Built into protocol | Must parse stderr |

**Use MCP when:**
- Multiple team members need the same integration
- You want structured, reliable input/output
- The integration involves credentials that should not appear in shell history
- You need the tool available across many sessions automatically

**Use Bash when:**
- It is a one-off task
- The command is simple and well-known (e.g., `curl`, `grep`)
- You do not want setup overhead
- You are prototyping before deciding to build an MCP server

---

## Debugging MCP Servers

When an MCP server is not working:

**Check that the server starts manually:**

```bash
npx -y @anthropic-ai/mcp-server-sqlite --db-path ./myapp.db
```

If it fails here, it will fail in Claude Code too.

**Check the Claude Code logs:**

```bash
# Logs are in the session directory
cat ~/.claude/logs/mcp-*.log
```

**Verify the server appears in your session:**

At the start of a Claude Code session, configured MCP servers are loaded and their tools are listed. If you do not see the expected tools, the server likely failed to start.

**Common issues:**

- Missing `npx` or `node` in your PATH. Claude Code uses your shell environment.
- Incorrect database path or connection string. Test the connection outside Claude Code first.
- Environment variables not set. Double-check the `env` block in your config.
- Port conflicts for SSE-based servers.

---

## Security Considerations

MCP servers run with the permissions of your user account. A few things to keep in mind:

- **Credentials in config files**: Use environment variables rather than hardcoding tokens. For project-level configs committed to git, reference variables from your shell environment.
- **Database access**: A database MCP server can run any query. Consider using read-only credentials for exploratory work.
- **Network access**: MCP servers can make outbound network requests. Review third-party servers before installing them.
- **Project-level servers**: Any server in `.claude/settings.json` activates for everyone who clones the repo. Make sure the team agrees on what is included.

## Next Steps

- [Custom Skills](custom-skills.md) -- Build reusable slash commands for workflows involving MCP tools
- [Hooks & Automation](hooks.md) -- Trigger actions automatically around tool calls
- [Token Optimization](token-optimization.md) -- Manage context when MCP tools return large results
