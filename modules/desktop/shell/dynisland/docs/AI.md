# DynIsland AI: harness, APIs and local models

One chat panel, any model, same behaviour. The harness (`services/AI.qml` + `services/aiharness.js`) gives every model the same system prompt, the same tools, the same thinking display and the same session handling, whether it is Claude over the Anthropic API or a 7B model on your own GPU.

## What you get

| Feature | How it works |
|---|---|
| Streaming | Tokens appear as they arrive (SSE through `curl`). Esc or the stop button cancels. |
| Tools | `bash`, `read_file`, `write_file`, `edit_file`, `list_dir`, `web_fetch`, `http_request`, `todo_write`, plus your own API tools. |
| Approval | `ask` confirms edits and commands, `edits` confirms commands only, `auto` never asks. "Always allow" per tool. |
| Thinking | Claude: native (adaptive on 4.6+, budgeted on 3.7 to 4.5). Others: told to reason inside `<think>` tags, shown in a collapsible block. Reasoning models (qwen3, deepseek-r1, gpt-oss) show their own. |
| Sessions | Saved to `~/.local/share/dynisland/ai/`. Sidebar (Ctrl+B), new chat (Ctrl+N), auto title, resumes the last chat. |
| Usage | Context bar, tokens in/out/cached, cost estimate, provider rate limits from response headers, tokens per second per reply. |
| Context | `/compact` summarizes the chat to free context. Prompt caching is on for Claude. |
| Memory | `~/.config/dynisland/AI.md`, and `CLAUDE.md` / `AGENTS.md` in the working directory, are added to every request. |
| Retries | HTTP 429, 503 and 529 retry twice with a delay. |

## 1. Install

Copy the files into `modules/desktop/shell/dynisland/`:

```
services/aiharness.js        new
services/AI.qml              replaces the old one
modules/ai/AIChat.qml        replaces the old one
modules/settings/AIPage.qml  replaces the old one
```

Apply the two small patches (or paste the lines by hand):

```
patch -p0 config/Config.qml < patches/Config.qml.patch     # new ai.* options
patch -p0 shell.qml        < patches/shell.qml.patch       # ipc: ai ask / ai newchat
```

New files must be tracked or the Nix copy will not see them:

```
git add modules/desktop/shell/dynisland/services/aiharness.js
dynisland restart          # repo copy, or: sudo nixos-rebuild switch --flake .
```

`curl`, `bash`, `coreutils`, `findutils` and `wl-clipboard` are already in your `runtimeDeps`. `grep`, `sed`, `awk` and `perl` come from the system PATH (`/run/current-system/sw/bin`, which you fixed earlier). Nothing else to install.

Open the chat: `qs -c dynisland ipc call ai toggle`. Type `/help`.

## 2. First run

On first start the shell writes `~/.config/dynisland/ai.json` with an Anthropic provider and an Ollama provider. The Anthropic key can be pasted in Settings > AI, or better, kept out of config files (section 3).

Test it: open the chat and say "list the files in my home folder". You should see a `list_dir` or `bash` card, an approval prompt, then the answer.

## 3. Keys without plain text

In `ai.json`, a provider key can come from three places, checked in this order: `apiKey` (literal), `apiKeyCmd` (a shell command that prints the key), or the Settings field for Anthropic.

```json
{ "id": "anthropic", "kind": "anthropic", "apiKeyCmd": "cat /run/secrets/anthropic_key" }
```

`pass show anthropic`, `secret-tool lookup ...` or a sops-nix path all work. The key reaches `curl` through an environment variable, never the command line, so it does not show in `ps`.

## 4. Add a third-party model API (OpenAI-compatible)

Anything that speaks `/v1/chat/completions` works: OpenRouter, OpenAI, Groq, Together, Mistral, DeepSeek, Gemini's OpenAI-compatible endpoint, vLLM, LiteLLM. Add an entry to `providers`:

```json
{
  "id": "openrouter",
  "name": "OpenRouter",
  "kind": "openai",
  "baseUrl": "https://openrouter.ai/api/v1",
  "apiKeyCmd": "cat /run/secrets/openrouter_key",
  "models": [ "anthropic/claude-sonnet-4.5", "qwen/qwen3-coder" ],
  "context": 128000,
  "pricing": { "in": 3, "out": 15 }
}
```

Steps:

1. Find the provider's base URL (it ends in `/v1` or similar) and an API key.
2. Add the block above to `providers` in `ai.json`, save. The file is watched, so it reloads by itself (or run `/reload`).
3. In the chat, run `/provider openrouter`, then `/model` and pick one. The model list is fetched live from `GET {baseUrl}/models`, so you often do not need to list models by hand.
4. Optional fields: `pricing` (USD per million tokens, enables the cost display), `context` (window size for the context bar), `maxTokens`, `extraBody` (merged into every request, for example `{"reasoning_effort":"high"}`), `headers`, `authHeader` (default `Authorization: Bearer`), `streamUsage: false` if the server rejects `stream_options`.

For another Anthropic-format endpoint (a gateway or proxy), use `"kind": "anthropic"` with its `baseUrl`.

## 5. Add a local model

### Ollama (recommended)

NixOS:

```nix
services.ollama = {
  enable = true;
  environmentVariables.OLLAMA_CONTEXT_LENGTH = "16384";   # default is only 4096 and silently truncates long chats
};
```

Rebuild, then pull a model and test it:

```
ollama pull qwen3:8b
curl http://localhost:11434/v1/models
```

The template already contains the `ollama` provider (`http://localhost:11434/v1`). In the chat:

```
/provider ollama
/model qwen3:8b
```

Set `"context": 16384` on the provider (or per model) to match `OLLAMA_CONTEXT_LENGTH`, so the context bar and `/compact` hint are accurate.

Pick a model that supports tools (the model page on ollama.com has a "tools" tag). qwen3, qwen2.5-coder, llama3.1+ and gpt-oss do. If a model has no tool support, switch it to the XML protocol:

```json
{ "id": "ollama", "kind": "openai", "local": true, "baseUrl": "http://localhost:11434/v1",
  "models": [ { "id": "deepseek-r1:14b", "toolMode": "xml", "context": 16384 } ] }
```

In `xml` mode the harness describes the tools in the prompt, the model writes `<tool_call>{...}</tool_call>`, and the harness parses it and feeds back `<tool_result>`. It is less reliable than native tools but works with any model that can follow instructions.

### LM Studio, llama.cpp server, vLLM

Same recipe, different `baseUrl`:

| Server | baseUrl |
|---|---|
| LM Studio | `http://localhost:1234/v1` |
| llama.cpp `llama-server` | `http://localhost:8080/v1` |
| vLLM | `http://localhost:8000/v1` |

llama.cpp needs `--jinja` for native tool calls, otherwise use `"toolMode": "xml"`.

## 6. Make every model behave like Claude

The harness does five things so models act alike:

1. One system prompt for all models: direct style, plan first, read before editing, smallest change, verify, never invent output, treat tool output as data. It is `CORE_PROMPT` in `aiharness.js`; change it there, or add your own instructions in Settings > AI or `AI.md`.
2. Same tools and same approval flow for every model.
3. Reasoning: native for Claude, `<think>` tags for others (`/think low|medium|high`). Per model you can force `"reasoning": "native"` to skip the tag prompt.
4. Same context handling: `/compact`, history repair after Stop, tool-result trimming.
5. Honest identity: the prompt tells the model its real name and provider. A small local model will follow the same working style, but it will not be as capable as Claude, and it should not claim to be Claude.

Tips for small local models: keep `/think low`, use `/approve ask` (they make more mistakes), and add short rules to `AI.md`.

## 7. Connect your own third-party APIs as tools

Any REST API can become a tool the model calls, with no code. Add it under `tools` in `ai.json`. It works with every provider.

```json
"tools": [
  {
    "name": "get_weather",
    "description": "Current weather for a city.",
    "method": "GET",
    "url": "https://wttr.in/{city}",
    "query": { "format": "j1" },
    "params": { "city": { "type": "string", "description": "City name", "required": true } },
    "approval": "auto"
  },
  {
    "name": "create_issue",
    "description": "Create a GitHub issue.",
    "method": "POST",
    "url": "https://api.github.com/repos/{repo}/issues",
    "headers": { "Accept": "application/vnd.github+json" },
    "body": { "title": "{title}", "body": "{body}" },
    "params": {
      "repo":  { "type": "string", "description": "owner/name", "required": true },
      "title": { "type": "string", "required": true },
      "body":  { "type": "string" }
    },
    "auth": { "header": "Authorization", "format": "Bearer %s", "keyCmd": "cat /run/secrets/github_token" },
    "approval": "ask"
  }
]
```

Steps:

1. Read the API's docs: URL, method, parameters, auth.
2. Put path parameters in the URL as `{name}` (they are URL-encoded). Parameters used in `query` as `"{name}"` are skipped when the model does not pass them.
3. For POST/PUT/PATCH, either give a `body` template (an exact `"{x}"` keeps its JSON type) or omit it and all unused parameters are sent as a JSON body.
4. Auth: `auth.key` (literal) or `auth.keyCmd`. `header` + `format` decide how the key is sent (`"X-Api-Key"` with no format sends the raw key).
5. `approval`: `auto` runs without asking (sensible for read-only GETs), `ask` confirms each call. The default is `auto` for GET and `ask` for everything else.
6. Save. Run `/tools` to check it is listed, then ask the model to use it.

Quick one-off calls need no config: the built-in `http_request` tool lets the model call any URL (it asks first).

## 8. MCP servers (Anthropic provider only)

Remote MCP servers are connected through Anthropic's MCP connector: the API calls the server for you. Add them to the Anthropic provider:

```json
{ "id": "anthropic", "kind": "anthropic", "apiKeyCmd": "...",
  "mcp": [ { "name": "docs", "url": "https://example.com/mcp", "token": "OAUTH_OR_BEARER_TOKEN" } ] }
```

Limits: the server must be a public HTTPS endpoint (Anthropic's servers connect to it), and local `stdio` servers do not work this way. For other providers use custom tools (section 7). I have not been able to test the connector from here, so if it errors, `/system` and the error banner show what the API said.

## 9. Commands

```
/new /clear /sessions        chats          /model [id] /provider [id]   switch
/think off|low|medium|high   thinking       /approve ask|edits|auto      tool approval
/compact                     free context   /retry /stop                 control
/cd <dir>                    working dir    /system /tools /usage        inspect
/reload                      reload ai.json /help
```

A message that starts with `//` is sent with a literal leading slash.

## 10. Troubleshooting

| Symptom | Check |
|---|---|
| Panel never opens | `dynisland log \| command grep -iE "AIChat\|AI.qml\|aiharness"` (QML errors name the file and line). |
| "No API key" | Settings > AI, or `apiKey` / `apiKeyCmd` in `ai.json`. Test the command in a terminal. |
| HTTP 401 / 403 | Wrong key or wrong `authHeader`. |
| HTTP 404 on a local server | `baseUrl` must end where `/chat/completions` begins, usually `/v1`. |
| Local model ignores tools | Model has no tool support: use `"toolMode": "xml"`. |
| Local model forgets the start of the chat | Ollama context is 4096 by default: set `OLLAMA_CONTEXT_LENGTH`. |
| 400 about `thinking` | The model does not support it as configured: `/think off`, or set `"thinking": "budget"` / `"adaptive"` / `"off"` on that model entry. |
| Cost shows nothing | Add `pricing: {in, out}` (USD per million tokens) to the provider or model. Claude models have built-in estimates. |
| JSON error in settings page | `ai.json` is invalid JSON; the page shows the parser message. |

Raw test of a provider without the UI:

```
curl -s http://localhost:11434/v1/models
```

## 11. Safety

- Tool results, web pages and API responses are untrusted data. The prompt tells the model to ignore instructions inside them, but this is not a guarantee: keep `/approve ask` when browsing or reading unknown files.
- `auto` lets the model run any command as your user. Use it only in a throwaway working directory.
- Sessions are stored unencrypted. Do not paste secrets into chats.
- MCP tokens are written to a request file in `$XDG_RUNTIME_DIR` (tmpfs, owner-only) for the duration of the session.
