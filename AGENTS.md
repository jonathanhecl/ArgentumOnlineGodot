# AGENTS.md — ArgentumOnlineGodot

Single source of truth for any human or AI agent working on this project. Read this **before** writing code, debugging, or touching the network/asset layers.

> This project is a **Godot 4 port of the Argentum Online 0.13.3 (Visual Basic 6) client**. It connects to an **existing VB6 server** whose binary protocol **cannot be changed**. Our job is faithful, bug-for-bug parity with the original client while modernizing the engine.

---

## 1. Golden Rules (read first)

1. **The wire protocol is immutable.** The VB6 server defines the byte format. Never change packet IDs, field order, sizes, endianness, or string encoding to make something "cleaner". If a packet looks wrong, the bug is almost always in our (de)serialization, not the server.
2. **Parity over elegance.** Where the original VB6 client had quirky behavior that affects gameplay/balance, replicate it ("bug-for-bug compatibility"). Document any intentional deviation in `LESSONS.md`.
3. **The server is authoritative — this is a real-time MMORPG.** Many players, creatures and spells act concurrently and we do **not** control world timing. Never add client-side cooldowns, gates, or timers that gate actions/state on assumed durations (e.g. spell/attack cooldowns, "you can't cast yet"). Those decisions belong to the server; the client sends intent and renders what the server reports. Client-side timers are only acceptable for **purely local presentation** (animations, FX lifetime, tweens) and must never block or delay sending/applying server-driven actions.
4. **Fix the root cause upstream, minimally.** Prefer a one-line correct fix over a downstream workaround. Don't over-engineer.
5. **Little-endian + Latin-1.** All multi-byte integers are little-endian; all strings are length-prefixed (`u16`) Latin-1 bytes. See §4.
6. **Never invent APIs.** Reference real symbols/paths only. Search the codebase first (existing helpers usually already exist).
7. **Keep files small and patterns consistent.** Aim for < 200–300 lines per file; reuse existing patterns instead of introducing new tech.
8. **Stay proactive & record what you learn.** Append non-obvious findings to `LESSONS.md` (see §10). Consult it before debugging.
9. **Use `godot-ai` for verification.** Validate scenes, scripts, runtime behavior and logs through the connected Godot editor. Do not run Godot from the shell or perform routine `git status`, `git diff`, `git diff --check`, or similar Git checks unless the user explicitly asks for Git work.

---

## 2. Tech Stack & How to Run

- **Engine:** Godot **4.7** (the `project.godot` declares features `4.7` + `GL Compatibility`). README states minimum 4.4.1; develop on 4.7.
- **Language:** GDScript only.
- **Renderer:** GL Compatibility (broad hardware support).
- **Display:** `viewport_width=1920`, `viewport_height=1080`, stretch mode `canvas_items`.
- **Entry point:** main scene `Main.tscn` / `Main.gd`. On boot it optionally loads resource packs (`index.pck`, `graphics.pck`, `sounds.pck`, `maps.pck`) for exported builds, emits `resources_loaded`, then switches to the Login screen via `ScreenController`.
- **Platforms:** Desktop (TCP socket) and Web (WebSocket). The transport auto-selects based on `OS.has_feature("web")`.

**Run:** open the project in Godot 4.6 and press Play, or run the `Main.tscn` scene. The `.pck` files are only used in exported builds; in-editor the project reads `res://Assets/...` directly.

---

## 3. Architecture & Repository Layout

### Autoload singletons (`project.godot` → `[autoload]`)
| Autoload | Script | Responsibility |
|---|---|---|
| `GameAssets` | `engine/autoload/game_assets.gd` | Loads/parses VB6 init data (`.ind`/`.dat`), holds Grh/animation/spell/color/font lists, texture & item-icon caching. |
| `AudioManager` | `engine/autoload/audio_manager.gd` | MIDI/wave playback. |
| `ScreenController` | `engine/autoload/screen_controller.gd` | Top-level screen switching. |
| `ClientInterface` | `engine/autoload/client_interface.gd` | TCP/WebSocket transport, send/receive, connection state. |
| `Security` | `engine/autoload/security.gd` | Optional packet encryption (only when server `AntiExternos` is on). |
| `Consts` | `engine/autoload/consts.gd` | Game constants, client version, limits, name maps. |
| `Global` | `engine/autoload/global.gd` | Global state, account info, user options/persistence, logging toggles. |
| `SavedCredentials` | `engine/autoload/saved_credentials.gd` | Stored login credentials. |
| `GameProtocol` | `engine/autoload/protocol_write_to_server.gd` | **Outgoing** packet writers (`class_name ProtocolWriteToServer`). |
| `ProtocolHandler` | `engine/autoload/protocol_handler.gd` | **Incoming** packet dispatch → signals. |
| `SpellMacroSystem` | `engine/autoload/spell_macro_system.gd` | Spell macro automation. |
| `HotkeyConfig` | `engine/autoload/hotkey_config.gd` | User-configurable input. |
| `MapNeighbors` | `engine/autoload/map_neighbors.gd` | Map adjacency graph for the continuous 3×3 map cache. |

### Directory map
- `engine/` — core runtime: `autoload/`, `character/`, `rendering/`, `game_world.gd`, `map_container.gd`.
- `network/commands/` — ~105 incoming packet classes (one per server packet).
- `common/` — shared, engine-agnostic code: `data/` (data classes), `enums/enums.gd`, `utils.gd`.
- `screens/` — full screens (login, character creation/selection).
- `ui/` — in-game UI panels (`hub/`, login panel, etc.).
- `Assets/` — original AO assets: `Gfx/` (PNG atlases), `Init/` (`.ind`/`.dat`/`.dat`-INI seed data), `Fonts/`, `Cursors/`.
- `Maps/` — exported Godot map scenes `Map*.tscn` (generated by the Exportador).
- `Resources/` — generated Godot resources: `Character/{Bodies,Heads,Helmets,Weapons,Shields}/*.tres`, `Fxs/*.tres`.
- `Tools/` — `Exportador.tscn` + `Exportador.gd` (the resource builder, see §5).
- `shaders/` — `.gdshader` effects (outline, spell trails, transitions).
- `Tests/` — protocol/string simulators.

---

## 4. Networking Layer (the protocol)

### Transport — `ClientInterface`
- Desktop uses `StreamPeerTCP`; web uses `WebSocketPeer` (binary mode). Selected at `_ready()`.
- `ConnectToHost(host, port)`, `DisconnectFromHost()`, `Send(data: PackedByteArray)`.
- Emits `connected`, `disconnected`, `connection_timeout`, `dataReceived(data)`.
- **Encryption:** the client only encrypts outbound data when `Security.anti_externos_enabled` is true. The AOGolang server does **not** use AntiExternos, so data is sent/received in clear. The server never encrypts what it sends.

### Outgoing — `GameProtocol` (`ProtocolWriteToServer`)
- Static methods named `Write*` (e.g. `WriteWalk`, `WriteLoginExistingAccount`, `WriteEquipItem`) write into a shared static `StreamPeerBuffer` (`_writer`).
- First byte of every packet is the `Enums.ClientPacketID` (`u8`).
- `Flush()` returns the accumulated bytes and clears the buffer; `IsEmpty()`, `Clear()` manage state.
- Outgoing logging gated by `Global.log_outgoing_packets`.

### Incoming — `ProtocolHandler`
- Subscribes to `ClientInterface.dataReceived`, queues into `_pending_messages`, drains in `_process`.
- A single received buffer may contain **multiple packets**; `_handle_incoming_data` loops `_handle_one_packet` until the stream is consumed.
- Dispatch is a `match packet_id` over `Enums.ServerPacketID`; each case constructs a command class and emits a typed signal consumed by UI / `GameWorld` / `HubController`.
- `packet_id == 0` is treated as a **desync** indicator (a data byte misread as a packet id) — it bails out rather than corrupting further. Keep this safeguard.
- Debug logging via `packet_debug_enabled` (and `ClientInterface.LOG_PACKETS`).

### Command classes — `network/commands/*.gd`
Canonical pattern:
```gdscript
extends RefCounted
class_name SomePacket

var some_field: int

func _init(reader: StreamPeerBuffer = null) -> void:
    if reader:
        Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
    some_field = reader.get_u8()
    # ... read fields in EXACT server order
```

### Wire conventions (critical for parity)
- **Endianness:** little-endian. Use `get_u8/get_16/get_32/get_float` and `put_u8/put_16/put_32`.
- **Strings:** `Utils.PutUnicodeString` / `Utils.GetUnicodeString` → `u16` length prefix + **Latin-1** bytes. Outbound text is converted UTF-8 → Latin-1 via `Utils.Utf8ToLatin1` (chars > 255 become `?`).
- **String arrays:** `Utils.GetUnicodeArrayString` reads a length-prefixed blob split on NUL (`0`) bytes.
- **Client version:** `Consts.CLIENT_VERSION_MAJOR/MINOR/REVISION` (currently `0.13.53`) is appended to login packets.
- Reading fields in the wrong order/size causes a cascading desync — the symptom (a later "unknown packet") is rarely where the real bug is.

---

## 5. Resource Creation Pipeline (VB6 → Godot)

This is how original VB6 assets become Godot-native content. **The tooling exists and works** — use it instead of hand-authoring resources.

### Source formats (in `Assets/Init/`, consumed by `GameAssets`)
- **`graficos.ind`** — binary GrhData index: `version (u32)`, `count (u32)`, then per-entry `grhId (u32)`, `frameCount (u16)`, and either animation frame ids + `speed (float)` (animated) or `fileId (u32)` + region `x,y,w,h (u16)` (single frame). Parsed in `GameAssets._LoadGrhData`.
- **`.dat` (INI format)** — loaded via `ConfigFile`: `armas.dat`, `escudos.dat`, `colores.dat`, `Hechizos.dat`, head/body/helmet definition files, etc. (e.g. `_LoadWeaponData`, `_LoadColours`).
- **Map data + server `.inf`** — `GameAssets.GetMap`/`GetMapInf` read terrain layers and TileExits (used to infer map adjacency).
- **`Assets/Gfx/<fileId>.png`** — texture atlases sliced via Grh regions (`GameAssets.GetTexture`, `GetItemIcon`).

### Runtime in-memory lists (`GameAssets`)
`GrhDataList`, `BodyAnimationList`, `HeadAnimationList`, `HelmetAnimationList`, `WeaponAnimationList`, `ShieldAnimationList`, `SpellDataList`, `ColoresPJ`, `FontDataList`. Loaded lazily after `Main.resources_loaded` (spells load immediately).

### The Exportador (`Tools/Exportador.tscn` + `Tools/Exportador.gd`)
Run by opening `Tools/Exportador.tscn` in the editor and playing it (it drives a `Label` status node). `_ExportAll()` regenerates:
- **Character `.tres`** via `SpriteFrames`: `_Bodies()`, `_Heads()`, `_Helmets()`, `_Weapons()`, `_Shields()`, `_Fxs()` → saved to `res://Resources/Character/<Kind>/<kind>_<id>.tres` and `res://Resources/Fxs/`. Bodies/weapons/shields build `idle_/walk_` animations per heading (`west/east/south/north`); offsets stored as `SpriteFrames` meta.
- **Maps** via `_ExportMaps()` → `res://Maps/Map<id>.tscn` with `Layer1`/`Layer2` as `TileMapLayer`s and `Layer3` as a `y_sort`ed `Node2D` of object sprites; map flags stored as node meta.
- **Map adjacency** via `_ExportMapAdjacency()` → writes `res://Assets/Init/map_neighbors.json`. It classifies `.inf` TileExits as cardinal crossings (N/S/E/W) vs interior portals using `ADJACENCY_BORDER_DIST`, resolves conflicts by vote/modal offset, and derives diagonals transitively.

**When to regenerate:** after changing/adding source `.ind`/`.dat` data, new graphics, or map data. Regenerate only the affected category when possible.

### Data classes (`common/data/`)
`GrhData`, `GrhAnimationData`, `MapData`, `SpellData`, `Item`, `ItemStack`, `Inventory`, `FontData`, `PlayerStats`, `GameContext`, `TickIntervals`, `ChatCommandArgs`.

---

## 6. Enums & Constants

- **`common/enums/enums.gd`** (`class_name Enums`): `Class`, `Race`, `Home`, `Heading`, `Skill`, `TileState`, `NickColor`, `FontTypeNames`, and the `ClientPacketID` / `ServerPacketID` tables. These IDs **must** match the server.
- **`engine/autoload/consts.gd`** (`Consts`): `MapSize=100`, `TileSize=32`, client version, inventory/bank/spell limits (`MaxInventorySlots`, `MaxBankInventorySlots`, `MaxUserHechizos`…), `ShipIds`, hit-location message templates, and `RaceNames`/`ClassNames`/`HomeNames`.

---

## 7. Coding Conventions

- **Naming:** files `snake_case.gd`; reusable types use `class_name` (PascalCase). Methods in the protocol/asset layers historically use PascalCase (`WriteWalk`, `Deserialize`, `GetTexture`) — match the surrounding file's style rather than mixing.
- **English in code identifiers**; Spanish inline comments are common and acceptable.
- **Signal-driven UI:** `ProtocolHandler` emits signals; screens/panels connect to them. Don't poll.
- **Autoloads are global** — reference them directly (`GameAssets`, `Consts`, `Global`, …).
- **Simplicity & DRY:** check for an existing helper (e.g. in `common/utils.gd`) before writing a new one. Avoid duplicate logic; remove the old path if you replace it.
- **No mock data in production paths** (tests only).
- **Don't add/remove comments or docs** unless asked.

---

## 8. Maps & Rendering Notes

- **Continuous 3×3 map cache** (`engine/map_container.gd`): only **static** scene content from `Map*.tscn` (terrain, trees, houses, base layers) may be cached and shown in adjacent maps.
- **Runtime entities must not be cached** or leak into neighbor maps: characters/creatures, dropped/server objects, damage text, runtime FX. These are flagged with `is_runtime_entity` / `is_server_object`; `Character` nodes are always runtime. Cached views are cleared of runtime nodes before promotion/recycling.
- **`MapNeighbors`** must not assume every map is a top-level key in `map_neighbors.json`. Some maps only appear as neighbors, so it materializes reverse links and derives diagonals iteratively until stable (prevents black diagonal holes).

---

## 9. Testing & Debugging

- **Tests:** `Tests/test_protocol_packet_simulator.gd`, `Tests/test_string_parsing.gd` plus root-level `test_*.gd` helpers.
- **Logging toggles:** `ClientInterface.LOG_PACKETS`, `ProtocolHandler.packet_debug_enabled`, `Global.log_outgoing_packets`. Incoming logs print packet id, length and raw bytes (decimal/hex via `Utils.BytesToDecimal` / `BytesToHex`).
- **Desync debugging:** start from the *first* malformed packet, not where the error surfaces. Verify each field's read order/size against the server's writer. `packet_id == 0` almost always means a previous packet read too few/many bytes.
- **VB6 parity:** when behavior is unclear, consult the original VB6 client/server source. VB6 files may not be UTF-8 — convert encoding before reading if needed.
- Record every non-trivial finding in `LESSONS.md`.

---

## 10. Continuous Learning & Proactivity

This project is long-horizon and protocol-sensitive. Agents are expected to **learn and prevent future blockers**, not just answer the immediate question.

**Be proactive:**
- Anticipate parity pitfalls (encoding, byte order, off-by-one fields) before they bite.
- Surface risks and propose preventive improvements when you notice fragile code.
- When fixing a bug, check whether the same class of bug exists elsewhere.

**Maintain `LESSONS.md` (living knowledge log):**
- **Append a new dated entry** whenever you discover a non-obvious gotcha, a protocol desync cause/fix, a VB6 behavior nuance, an asset/Exportador quirk, or a recurring mistake.
- Each entry uses: `Context / Problem / Root cause / Fix / Rule`.
- **Consult `LESSONS.md` first** when debugging — the answer may already be recorded.
- **Promote** stable, broadly-applicable lessons into this `AGENTS.md` (as rules/conventions) once they're permanent. Keep `AGENTS.md` authoritative and `LESSONS.md` chronological.

> If a lesson contradicts something in this document, update the document and note the change in `LESSONS.md`.
