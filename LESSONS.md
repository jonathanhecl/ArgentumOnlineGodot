# LESSONS.md — Living Knowledge Log

Chronological log of non-obvious findings for ArgentumOnlineGodot. **Read this before debugging.** See `AGENTS.md` §10 for the workflow.

## How to use this file

- Append a **new dated entry** whenever you learn something non-obvious: a protocol desync cause/fix, a VB6 behavior nuance, an asset/Exportador quirk, or a recurring mistake.
- Newest entries go **at the top** of the "Entries" section.
- Use the template below. Keep it short and factual.
- When a lesson becomes a permanent convention, promote it into `AGENTS.md` and note the promotion here.

### Entry template
```
### YYYY-MM-DD — <short title>
- **Context:** where/what you were working on.
- **Problem:** the observed symptom.
- **Root cause:** the actual underlying cause.
- **Fix:** what resolved it (reference files/symbols).
- **Rule:** the takeaway to prevent recurrence.
```

---

## Entries

### 2026-08-03 — La geometría del viewport de juego se define solo en `game_screen.tscn` y todo lo demás la sigue dinámicamente
- **Context:** Pedido de extender la zona de juego hasta arriba (se veía una franja negra superior).
- **Problem:** El área jugable quedaba limitada a `y=238..991`, dejando la franja superior `0..238` sin render del mapa.
- **Root cause:** `MainViewportContainer` (SubViewportContainer) usaba `offset_top = 238` y el `SubViewport` un `size` fijo de `1452x753`; la `PeripheralFogOverlay` copiaba esos offsets.
- **Fix:** En `screens/game_screen.tscn`: `MainViewportContainer.offset_top = 4` (4px de margen para la interfaz), `custom_minimum_size = (1451, 987)`, `Viewport.size = Vector2i(1452, 987)` y `PeripheralFogOverlay.offset_top = 4`. Nada en código GDScript fija estas medidas (no hay referencias a 238/753).
- **Rule:** La geometría del área de juego (posición, tamaño del SubViewport, overlays `PeripheralFogOverlay`/`RainOverlay`) se centraliza en `game_screen.tscn`. FOV, visibilidad, clics y conversión a tiles leen el viewport dinámicamente (`get_viewport_rect().size`, `ScreenToTile`), así que redimensionar el viewport no requiere tocar código. El FOV (`CORE_VIEW_SIZE`/`CREATURE_VIEW_SIZE`) queda centrado en el personaje y no cambia su radio de visión al agrandar la pantalla.

### 2026-07-27 — Luz del proyectil: z_index negativo la hunde bajo el terreno y deja artefactos
- **Context:** Efecto de luz circular del `SpellProjectile` (`engine/character/spell_projectile.gd`).
- **Problem:** La luz agregada como hija con `z_index = -1` no se veía (quedaba dibujada debajo del mapa) y aparecían artefactos brillantes intermitentes en la esquina superior izquierda de la pantalla mientras el proyectil volaba.
- **Root cause:** El proyectil vive en `Layer3` con `z_index = 0`/`z_as_relative`; un hijo con z relativo -1 cae por debajo de los TileMapLayers del terreno. Además el proyectil no estaba marcado como entidad runtime, por lo que `_ClearRuntimeNodes` del caché 3×3 de mapas no lo liberaba al reciclar vistas.
- **Fix:** Usar `show_behind_parent = true` en la luz (se dibuja detrás del orbe pero dentro de la misma capa, sobre el terreno) y `set_meta("is_runtime_entity", true)` en `_ready()` del proyectil.
- **Rule:** Nunca usar z_index negativo para "dibujar debajo" dentro de `Layer3`; usar `show_behind_parent`. Todo nodo visual que se agrega a capas del mapa en runtime debe marcarse `is_runtime_entity`.

### 2026-07-20 — El límite de aparición de criaturas debe ser independiente del FOV
- **Context:** Visibilidad de personajes y contornos de depuración en `MapContainer`.
- **Problem:** Las criaturas usaban el rectángulo rojo del FOV, aunque debían comenzar a dibujarse un tile antes de alcanzarlo y el FOV cambiará de tamaño.
- **Root cause:** `_apply_initial_visibility` y `_check_entity_visibility` reutilizaban `_get_core_rect` y el metadato `_in_core`.
- **Fix:** `CREATURE_VIEW_SIZE`, `_get_creature_rect` y `_in_creature_view` separan el límite de criaturas; su contorno cian es un tile más amplio por cada lado que el rojo actual.
- **Rule:** Mantener independientes los tamaños y estados de visibilidad de criaturas y FOV; los objetos siguen clasificados por `_get_core_rect`.

### 2026-07-20 — El borde de visión debe centralizar la clasificación, no bloquear clicks de debug
- **Context:** Área central dibujada por `MapContainer` y clicks del mundo procesados por `HubController`.
- **Problem:** Un NPC visualmente dentro del borde inferior se clasificaba fuera, y un rectángulo obsoleto impedía enviar clicks cerca o fuera del FOV para depuración.
- **Root cause:** `HubController` filtraba con un rectángulo independiente de 541×413; además, la visibilidad usaba los pies del personaje y fórmulas manuales de cámara, por lo que el borde inferior excluía tiles visibles.
- **Fix:** `MapContainer.IsScreenPointInCore` y `ScreenToTile` centralizan la clasificación/conversión con transforms de canvas; entidades y objetos se evalúan desde el centro lógico del tile. Los clicks manuales siempre se envían dentro del viewport y el FOV solo se informa como `IN FOV`/`OUTSIDE FOV`. Se quitaron los gates locales que cancelaban `WriteWorkLeftClick`.
- **Rule:** El rectángulo de `MapContainer` es la única fuente de verdad para dibujar y clasificar el FOV, pero no debe bloquear clicks de depuración. Nunca mantener tamaños paralelos ni bloquear paquetes de acción con temporizadores locales.

### 2026-07-06 — WriteQuit en mapa inseguro desconecta al cliente completamente
- **Context:** Flujo "Volver a selección de personajes" desde `GameScreen` (`screens/game_screen.gd`).
- **Problem:** Al enviar `WriteQuit` desde un mapa no seguro, el servidor inicia una cuenta regresiva y luego **desconecta por completo** al cliente (no envía `account_logged`). El cliente caía a la pantalla de login manual en lugar de la lista de personajes.
- **Root cause:** El flujo original asumía que el servidor relogueaba la cuenta tras `WriteQuit`; en realidad corta la conexión TCP/WebSocket.
- **Fix:** Cachear en memoria (`Global.session_host/port/username/password`) los datos de la sesión al conectar desde `LoginScreen._ConnectToHost`. En `GameScreen._OnDisconnected`, si el logout era para volver a la selección, instanciar `login_screen` con `request_auto_login()` para reconectar y reloguear la cuenta automáticamente. La caché de sesión se limpia al cerrar sesión explícitamente (`character_selection_screen._on_logout_pressed`, `login_screen._on_logout_requested`).
- **Rule:** `WriteQuit` siempre termina en desconexión total; para volver a la selección de personajes hay que reconectar y reloguear la cuenta desde cero. No asumir que el servidor envía `account_logged` tras un quit. Además, `Global.username` se sobrescribe con el nombre del personaje al seleccionarlo (`character_selection_screen.gd`), por lo que nunca debe usarse como username de cuenta para un re-login.

### 2026-06-01 — No client-side cooldowns/timers for gameplay (server is authoritative)
- **Context:** Real-time MMORPG client connected to the VB6 server; many players/creatures/spells act concurrently.
- **Problem:** Tempting to add client-side cooldowns/gates (e.g. spell/attack timers, "you can't cast yet") to "smooth" behavior.
- **Root cause:** We don't control world timing; only the server knows true cooldowns, ping, and concurrent actions. Client timers desync from reality and block legitimate actions.
- **Fix:** Send player intent immediately and render what the server reports. Limit client timers to purely local presentation (animations, FX lifetime, tweens) — e.g. `spell_projectile.gd` clamps per-frame delta with `MAX_PROCESS_STEP` only to keep the orb's flight visible, never to gate the action.
- **Rule:** Never gate gameplay actions/state on assumed client-side durations. Local timers may only affect visuals and must never delay sending/applying server-driven actions.

### 2026-06-01 — Seed: known foundational lessons

- **Strings are Latin-1, length-prefixed.** All protocol strings use a `u16` length prefix + Latin-1 bytes (`Utils.PutUnicodeString` / `GetUnicodeString`). UTF-8 → Latin-1 conversion (`Utils.Utf8ToLatin1`) maps chars > 255 to `?`. Never assume UTF-8 on the wire.
- **`packet_id == 0` means desync.** In `ProtocolHandler._handle_one_packet`, a `0` packet id is a data byte misread as a packet id — i.e. a previous packet read the wrong number of bytes. Fix the *earlier* packet's deserialization, not the symptom. Keep the bail-out safeguard.
- **One TCP buffer can hold many packets.** `_handle_incoming_data` loops `_handle_one_packet` until the stream is consumed. Don't assume one read == one packet.
- **Server data is unencrypted.** The client only encrypts outbound data when `Security.anti_externos_enabled` is true; the server never encrypts. Don't add decryption on the receive path.
- **Map cache must exclude runtime entities.** `engine/map_container.gd` may only cache static scene content. Runtime nodes (`is_runtime_entity` / `is_server_object`, and all `Character` nodes) must be cleared before a cached view is reused, or they leak into neighbor maps.
- **`MapNeighbors` needs reverse links.** `map_neighbors.json` doesn't list every map as a top-level key; some maps appear only as neighbors. Materialize reverse links and derive diagonals iteratively until stable to avoid black diagonal holes in the 3×3 cache.
