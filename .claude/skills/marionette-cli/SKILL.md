---
name: marionette-cli
description: Use when driving, automating, or inspecting a running Flutter app in debug mode via the `marionette` CLI — tapping buttons, entering text, pressing keys, swiping/scrolling, taking screenshots, recording video, reading logs, listing interactive widgets, or triggering hot reload/restart against a live VM service URI. Trigger whenever the user wants to interact with or test a Flutter app that's already running (e.g. "tap the submit button", "screenshot the app", "what's on screen", "scroll to X", "record a demo video"), even if they don't say "marionette" by name.
---

# Marionette CLI (this project)

Drive a Flutter app running in debug mode from the command line. Use this to
inspect the widget tree, simulate user input, capture screenshots/video, read
logs, and hot reload — useful for manual verification, demos, and reproducing
UI flows without touching the app code.

> **回覆語言:除技術名詞外,一律用繁體中文回覆使用者。**

The binary is at `marionette` (installed via `~/.pub-cache/bin/marionette`).

## Connecting to an app

Every interaction command needs a target. Two modes:

- **Direct URI (`--uri`)** — stateless, no setup. Best for one-off
  interactions. Each command opens a fresh WebSocket, runs, disconnects.
  ```
  marionette --uri ws://127.0.0.1:8181/ws <command> [args]
  ```
- **Named instance (`-i`)** — register once, then use a short name for
  repeated interactions with the same app.
  ```
  marionette register my-app ws://127.0.0.1:8181/ws
  marionette -i my-app <command> [args]
  marionette unregister my-app   # clean up when done
  ```

Get the VM service URI from the `flutter run` console output (looks like
`ws://127.0.0.1:XXXXX/ws`). Prefer `--uri` unless you'll run many commands.

Global options: `--timeout <seconds>` (default 5), plus `-i`/`--uri`
(mutually exclusive).

## Recommended flow

1. **Discover before acting.** Run `get-interactive-elements` first to see what
   widgets exist and grab their keys/text — don't guess matchers.
2. **Prefer `--key` over `--text`.** Keys (`ValueKey<String>`) are stable; visible
   text changes with i18n and state.
3. **Act**, then re-check with `get-interactive-elements` or `take-screenshots`
   to confirm the result.

## Command index

Read `references/commands.md` for full options, output formats, and examples
of any command below before constructing a non-trivial invocation.

| Command | Purpose |
|---|---|
| `get-interactive-elements` | List tappable/typable widgets (type, key, text). Start here. |
| `tap` | Tap an element by `--key`/`--text`/`--type` or `--x --y`. |
| `secondary-tap` | Right-click / `onSecondaryTap` (desktop only). |
| `enter-text` | Set a text field's value (`--key`/`--text` + `--input`). |
| `press-key` | Send a real key event to the focused element (enter, tab, arrows, char) with optional `--modifiers`. |
| `press-back-button` | System back (Android back / iOS swipe-back); respects PopScope. |
| `swipe` | Swipe/drag by element+`--direction` or start/end coordinates. |
| `scroll-to` | Scroll until an element (`--key`/`--text`) is visible. |
| `take-screenshots` | Save PNG(s) to `--output`; multi-view apps get numbered files. |
| `record-video` | Record a `.webm` (`--output`, optional `--duration`); needs ffmpeg. |
| `get-logs` | Dump collected app logs. |
| `hot-reload` | Hot reload the app. |
| `hot-restart` | Full restart from `main()` (resets state); needs `flutter run`. |
| `register` / `unregister` / `list` | Manage named instances. |
| `doctor` | Check connectivity of all registered instances. |
| `mcp` | Run the Marionette MCP server. |

## Exit codes

- `0` success
- `1` runtime error (connection failed, command failed, app unreachable)
- `64` usage error (missing args, invalid options)

## When a command fails to connect

The app likely stopped or the URI changed.

- **`-i` mode:** run `marionette doctor`, then `marionette unregister <name>`
  for stale entries.
- **`--uri` mode:** confirm the app is still running and the URI is current;
  re-run `flutter run` and use the new URI if needed.
