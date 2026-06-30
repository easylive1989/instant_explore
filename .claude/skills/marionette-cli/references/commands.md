# Marionette CLI — full command reference

Detailed options, output, and examples for every command. The SKILL.md has the
quick index and connection workflow; read this when you need exact flags or
output shapes.

## Table of contents

- [Instance management](#instance-management): `register`, `unregister`, `list`, `doctor`
- [Inspection](#inspection): `get-interactive-elements`, `get-logs`
- [Input](#input): `tap`, `secondary-tap`, `enter-text`, `press-key`, `press-back-button`, `swipe`, `scroll-to`
- [Capture](#capture): `take-screenshots`, `record-video`
- [Lifecycle](#lifecycle): `hot-reload`, `hot-restart`
- [MCP server](#mcp-server): `mcp`

All interaction commands require `-i <instance>` or `--uri <ws-uri>`.

---

## Instance management

### register \<name\> \<uri\>

Register a Flutter app instance.

- `name` — alphanumeric identifier `[a-zA-Z0-9_-]+`
- `uri` — VM service WebSocket URI (e.g. `ws://127.0.0.1:8181/ws`)

```
marionette register my-app ws://127.0.0.1:8181/ws
```

Output (stdout): `Registered instance "my-app" → ws://127.0.0.1:8181/ws`
Overwriting (stderr): `Updated existing instance "my-app" → ws://127.0.0.1:8181/ws`
Exit codes: `0` success, `64` invalid name/usage.

### unregister \<name\>

Remove a registered instance.

```
marionette unregister my-app
```

Output: `Unregistered instance "my-app".`
Not found (stderr, exit 1): `Instance "my-app" not found.`

### list

List all registered instances.

```
marionette list
```

Output:
```
Registered instances:

  my-app
    URI: ws://127.0.0.1:8181/ws
    Registered: 2026-02-12 15:30:00.000
```
Empty: `No instances registered.`

### doctor

Check connectivity of all registered instances.

```
marionette doctor
```

Output:
```
Checking 2 instance(s)...

  my-app (ws://127.0.0.1:8181/ws) ... OK
  other-app (ws://127.0.0.1:9090/ws) ... FAILED

Some instances are unreachable. Use "marionette unregister <name>" to remove stale entries.
```
Exit codes: `0` all reachable, `1` any unreachable.

---

## Inspection

### get-interactive-elements

List interactive UI elements in the app's widget tree. Run this first to
discover matchers.

```
marionette -i my-app get-interactive-elements
marionette --uri ws://127.0.0.1:8181/ws get-interactive-elements
```

Output, one line per element:
```
Found 3 interactive element(s):

Type: ElevatedButton, Key: "submit_button", Text: "Submit"
Type: TextField, Key: "email_field"
Type: IconButton, Text: ""
```

Each element may have type, key, text, and additional properties. Use the key
or text as matchers for `tap`, `enter-text`, `scroll-to`.

### get-logs

Retrieve collected application logs.

```
marionette -i my-app get-logs
```

Output:
```
Collected 5 log entries:

[INFO] App started
[DEBUG] Loading data...
...
```
Empty: `No logs collected.`

---

## Input

### tap

Tap an element. Provide exactly one matching strategy.

- `--key <string>` — match by `ValueKey<String>` (most reliable)
- `--text <string>` — match by visible text
- `--type <string>` — match by widget type name (e.g. `ElevatedButton`)
- `--x <number>` / `--y <number>` — screen coordinates (use together)

```
marionette -i my-app tap --key submit_button
marionette -i my-app tap --text "Submit"
marionette -i my-app tap --x 100 --y 200
```

Output: `Tapped element matching {key: submit_button}`

### secondary-tap

Secondary (right mouse button) tap. **Desktop only** — triggers Flutter's
`onSecondaryTap` (e.g. context menus). Same matching options as `tap`.

```
marionette -i my-app secondary-tap --key file_item
marionette -i my-app secondary-tap --x 100 --y 200
```

Output: `Secondary tapped element matching {key: file_item}`

### enter-text

Enter text into a text field. Rewrites the field's value directly.

- `--key <string>` or `--text <string>` — match the field
- `--input <string>` — text to enter (mandatory)

```
marionette -i my-app enter-text --key email_field --input "user@example.com"
```

Output: `Entered text into element matching {key: email_field}`

### press-key

Press a keyboard key on the currently focused element. Unlike `enter-text`
(which rewrites a field's value), this sends a real key event through the focus
system, so `onSubmitted`, Shortcuts/Actions, and focus traversal all respond.
Focus a target first (e.g. with `tap`).

- `--key <string>` (mandatory) — named keys: `enter, tab, escape, backspace,
  delete, space, arrowUp, arrowDown, arrowLeft, arrowRight, home, end, pageUp,
  pageDown`. Also a single character `a-z` or `0-9`.
- `--modifiers <list>` — comma-separated: `control, shift, alt, meta`. On macOS
  use `meta` for the Command key.

```
marionette -i my-app press-key --key enter
marionette -i my-app press-key --key a --modifiers control
marionette --uri ws://127.0.0.1:8181/ws press-key --key arrowDown
```

Output: `Pressed key: enter` / `Pressed key: control+a`

Notes:
- A character is only typed for an unmodified (or shift-only) printable key;
  `control+a` activates select-all rather than typing "a".
- Modifier combos match Flutter Shortcuts / `SingleActivator`.

### press-back-button

Simulate a system back button press (Android back / iOS swipe-back).

```
marionette -i my-app press-back-button
```

Output: `Back button pressed, route was popped`
On root route: `Back button pressed, no route to pop (app may exit)`

Notes:
- Works with Navigator, GoRouter, and other routing solutions.
- On the root route the system may minimize or close the app.
- Respects `PopScope` / `WillPopScope`.

### swipe

Swipe/drag on the app. Useful for PageView, Dismissible, Drawer, Slider. Use
either element-based mode (matcher + direction) or coordinate-based mode.

Element-based:
- `--key` / `--text` / `--type` — matcher
- `--direction <dir>` — `left, right, up, down` (required for this mode)
- `--distance <number>` — pixels (default 200)

Coordinate-based (all required together):
- `--start-x`, `--start-y`, `--end-x`, `--end-y`

```
marionette -i my-app swipe --type PageView --direction left
marionette -i my-app swipe --key carousel --direction right --distance 300
marionette -i my-app swipe --start-x 300 --start-y 400 --end-x 50 --end-y 400
```

Output:
```
Swiped left on element matching: {type: PageView}
Swiped from (300.0, 400.0) to (50.0, 400.0)
```

### scroll-to

Scroll until an element becomes visible.

- `--key <string>` or `--text <string>`

```
marionette -i my-app scroll-to --text "Bottom Item"
```

Output: `Scrolled to element matching {text: Bottom Item}`

---

## Capture

### take-screenshots

Capture screenshots and save to PNG files.

- `-o, --output <path>` — output file path (mandatory)
- `--open` — open the file after saving

```
marionette -i my-app take-screenshots --output ./screenshot.png
```

Output: `Saved screenshot: ./screenshot.png`
Multi-view apps produce numbered files:
```
Saved screenshot: ./screenshot.png
Saved screenshot: ./screenshot_1.png
```

### record-video

Record a video of the running app to a WebM file. **Requires ffmpeg.**

- `-o, --output <path>` — mandatory, must end with `.webm`
- `-d, --duration <seconds>` — records until Ctrl+C if not set
- `--width <pixels>` / `--height <pixels>`
- `--open` — open the video after recording
- `--ffmpeg-path <path>` — ffmpeg binary (default `ffmpeg`)
- `-v, --verbose` — diagnostic details (probe response, frame counts)
- `--transport <mode>` — frame transport: `auto` (default; try TCP, fall back
  to reverse-WS via adb), `tcp` (force TCP), `ws` (force reverse-WS, needs adb)
- `--frame-port <port>` — specific TCP port instead of auto-negotiation
  (mutually exclusive with `--transport ws`)

```
marionette -i my-app record-video --output ./recording.webm
marionette -i my-app record-video -o ./demo.webm -d 10
marionette --uri ws://127.0.0.1:8181/ws record-video -o ./recording.webm --width 1280 --height 720
marionette -i my-app record-video -o ./demo.webm --transport ws
```

Output:
```
Starting screencast...
Recording 640x480 video to ./recording.webm...
Press Ctrl+C to stop recording.
Recording complete: ./recording.webm (10s, 250 frames)
```

Prerequisites — ffmpeg on PATH (or `--ffmpeg-path`):
- macOS: `brew install ffmpeg`
- Ubuntu: `sudo apt install ffmpeg`
- Windows: `winget install ffmpeg`

Exit codes: `0` success, `1` ffmpeg not found or recording failed, `64` invalid options.

---

## Lifecycle

### hot-reload

Perform a hot reload of the Flutter app.

```
marionette -i my-app hot-reload
```

Output (exit 0): `Hot reload completed successfully.`
Failure (stderr, exit 1): `Hot reload failed. The app may need a full restart.`

### hot-restart

Full restart from `main()`, resetting all state. Use it for changes a hot
reload can't pick up (e.g. `main()`/bootstrap edits, global singletons, state
shape). Requires the app running via `flutter run`.

```
marionette -i my-app hot-restart
```

Output (exit 0): `Hot restart completed successfully.`
Failure (stderr, exit 1): `Hot restart failed or is unavailable. Make sure the app is running via 'flutter run'.`

---

## MCP server

### mcp

Run the Marionette MCP server (preserves original `marionette_mcp` behavior).

- `-l, --log-level <level>` — `FINEST|FINER|FINE|CONFIG|INFO|WARNING|SEVERE` (default `INFO`)
- `--log-file <path>` — log file path (default stderr)
- `--sse-port <port>` — use SSE transport on this port (default stdio)

```
marionette mcp
marionette mcp --sse-port 3000
```

---

## Tips

- Prefer `--uri` for one-off interactions (no setup/cleanup overhead).
- Prefer `-i` for repeated interactions with the same app (shorter commands).
- Prefer `--key` over `--text` (keys are stable, text changes).
- Run `get-interactive-elements` first to discover what's on screen.
- Instance names: `[a-zA-Z0-9_-]+`.
- Commands are stateless — each opens a fresh connection, no session management.
