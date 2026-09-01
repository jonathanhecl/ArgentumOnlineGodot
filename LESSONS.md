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

### 2026-08-31 — El mapa 1 ancla el continente y los dungeons son componentes separados
- **Context:** Construcción del layout completo del mapa mundial en `ui/hub/world_map_view.gd`.
- **Problem:** Centrar y construir el layout desde el mapa actual mezclaba componentes, mientras que los dungeons y sus TPs podían parecer parte del continente.
- **Root cause:** El layout iniciaba el BFS desde el mapa actual y luego trataba todos los mapas restantes como una única bolsa de desconectados, sin distinguir componentes unidos por pasos normales de portales sin continuidad.
- **Fix:** El layout inicia en el mapa `1`, coloca cada componente geográfico normal con su continuidad interna y deja los mapas sin pasos normales para la cuadrícula secundaria de teletransportes.
- **Rule:** El mundo geográfico debe tener un ancla estable (`mapa 1`); los TPs nunca deben definir la posición del continente y cada componente normal separado debe conservar su propia topología.

### 2026-08-31 — Los portales internos de dungeon no son adyacencias geográficas
- **Context:** Clasificación de enlaces de `MapNeighbors` en `ui/hub/world_map_view.gd` y generación de `Assets/Init/map_neighbors.json`.
- **Problem:** La cadena de mapas `264–268` aparecía pegada al mundo como si fueran mapas contiguos, aunque `264.Inf` sólo contiene un portal interno con 4 exits hacia `265`.
- **Root cause:** El exportador y el visor aceptaban grupos pequeños de exits alineados cerca de bordes como cruces cardinales; además, el visor confiaba en enlaces antiguos de `map_neighbors.json` sin validarlos contra los `.Inf` actuales.
- **Fix:** Los cruces geográficos requieren al menos 5 exits consistentes y salida/llegada por bordes opuestos. El visor valida también los enlaces del seed con esa evidencia; los portales internos se conservan como teletransportes.
- **Rule:** No tratar una coordenada cercana a un borde como prueba suficiente de continuidad; validar cantidad de exits, orientación y borde opuesto antes de colocar mapas juntos.

### 2026-08-31 — Priorizar adyacencias cardinales en el layout del mapa mundial
- **Context:** Distribución de miniaturas contiguas en `ui/hub/world_map_view.gd`.
- **Problem:** Algunos mapas geográficamente contiguos aparecían separados porque una diagonal ocupaba primero una celda y la resolución de colisiones desplazaba después al vecino cardinal.
- **Root cause:** `_bfs_layout()` procesaba direcciones en el orden de iteración del diccionario y `_find_free_cell()` movía cualquier conflicto a otra celda, rompiendo la continuidad esperada.
- **Fix:** El BFS ahora resuelve primero todas las direcciones cardinales y después las diagonales; las colisiones inevitables sólo se desplazan después de respetar la red cardinal.
- **Rule:** En layouts de mapas, las conexiones N/S/E/O deben tener prioridad geométrica sobre las diagonales y los enlaces secundarios.

### 2026-08-31 — Las flechas de TP usan TileExit.x/y y dest_x/dest_y
- **Context:** Líneas y flechas de teletransporte en `ui/hub/world_map_view.gd`.
- **Problem:** Las conexiones se dibujaban entre los centros de las miniaturas, no desde el punto aproximado donde salía y llegaba cada TP.
- **Root cause:** `GameAssets.GetMapInf()` ya devuelve `x/y` de salida y `dest_x/dest_y` de llegada, pero `_teleport_links` sólo conservaba los ids y las direcciones.
- **Fix:** Cada dirección conserva sus `TileExit`, se promedian varios exits hacia el mismo destino y se transforman con el mismo recorte `11..90` usado por la miniatura y el punto del jugador.
- **Rule:** Para representar conexiones sobre miniaturas recortadas, transformar las coordenadas del asset con la misma función en origen y destino; no usar los centros de los mapas como sustituto.

### 2026-08-31 — El mapa mundial muestra las entradas del mapa seleccionado
- **Context:** Interacción del visor del mapa mundial (`ui/hub/world_map_view.gd`, `world_map_window.tscn`).
- **Problem:** El usuario podía ver el grafo, pero no saber qué mapas llevaban a una miniatura concreta.
- **Root cause:** El visor sólo tenía hover, zoom y arrastre; no había estado de selección ni una vista de conexiones entrantes.
- **Fix:** El clic sin arrastre selecciona la miniatura, resalta su borde y muestra los mapas de entrada geográfica con dirección y los teletransportes de entrada en `SelectionInfo`.
- **Rule:** En un grafo visual interactivo, separar hover de selección persistente y mostrar los datos de entrada del nodo seleccionado sin afectar la navegación.

### 2026-08-31 — El layout de teletransportes no debe formar un anillo
- **Context:** Visor del mapa mundial abierto desde el minimapa (`ui/hub/minimap.gd`, `ui/hub/world_map_view.gd`).
- **Problem:** Las zonas subterráneas conectadas sólo por teletransporte se distribuían en un círculo grande, con flechas muy dominantes y miniaturas no visitadas demasiado oscuras.
- **Root cause:** `_place_disconnected_ring()` colocaba todos los mapas sin adyacencia geográfica sobre un anillo; además, `COLOR_TELEPORT` tenía alpha `0.95` y `COLOR_UNVISITED` multiplicaba el terreno por `0.28`.
- **Fix:** Los mapas desconectados se organizan en una cuadrícula compacta, se añade un fondo uniforme, las miniaturas no visitadas usan un tinte `0.62` y las conexiones de teletransporte pasan a alpha `0.18` con menor grosor. El doble clic del minimapa abre el visor; `Ctrl+clic` conserva el warp de depuración.
- **Rule:** En vistas de grafos geográficos, agrupar los nodos sin continuidad en una cuadrícula o sección secundaria; no distribuirlos radialmente alrededor del mapa del jugador.

### 2026-08-10 — Mapas visitados por personaje, no por cuenta
- **Context:** La exploración del mapa del mundo se persistía en `Global._visited_maps` (`user://visited_maps.json`) con clave `account_name`.
- **Problem:** Todos los personajes de una misma cuenta compartían el mismo registro de mapas visitados; el usuario pidió que cada personaje tenga el suyo propio.
- **Root cause:** `_visited_key()` devolvía sólo `account_name` (o "default"), así que dos personajes de la misma cuenta sobreescribían/leían el mismo set.
- **Fix:** Nuevo campo de sesión `Global.character_name` (rellenado en `character_selection_screen._on_connect_pressed`, `login_screen._on_character_selected` y `character_creation_screen._HandleLogged`; limpiado en logout/retorno a selección). `_visited_key()` ahora devuelve `account_name + "/" + character_name`, aislando cada personaje de cada cuenta.
- **Rule:** La exploración es estado por cuenta Y por personaje; cualquier estado persistente per-jugador debe incluir el identificador del personaje en la clave, no sólo la cuenta. `Global.username` se reutiliza para email (login) y nombre (juego), por eso se añadió `character_name` dedicado.

### 2026-08-04 — El mapa mundial debe centrarse en el mapa del jugador, no en el centro del clúster
- **Context:** Al pararte en un mapa sin continuaciones (p.ej. `202`, `98`) y abrir el mapa del mundo, "marcaba un mapa al azar".
- **Problem:** Tu mapa quedaba en una esquina y el centro lo ocupaban mapas lejanos del componente conexo, con aspecto de aleatorio.
- **Root cause:** `_build_layout` hacía un BFS sin límite sobre todo el componente conexo y `_fit_to_content` centraba en el bounding box del clúster (no en el mapa actual).
- **Fix:** En `ui/hub/world_map_view.gd`: `MAX_BFS_HOPS := 2` limita el layout a las continuaciones cercanas, y `_fit_to_content` centra en `_grid[_current_map_id]` (verificado: `rect` del mapa actual == centro del viewport para `202` y `98`).
- **Rule:** Un visor local de continuaciones se reconstruye SIEMPRE desde el mapa del jugador (BFS acotado + centrado en él); nunca centrar en el centroide del grafo.

### 2026-08-04 — Los mapas sin `.Inf` sólo pueden aportar reciprocidades
- **Context:** Auditoría del mapa mundial y del exportador de adyacencias para la zona `84/255/81/82/202/12/13/18/19/98`.
- **Problem:** Algunas celdas quedan vacías y parece faltar una continuación.
- **Root cause:** `GetMapInf()` sólo puede descubrir salidas desde `MapaN.Inf`; varios mapas destino (`81`, `98`, `202`, `203`, `255`) sólo tienen `.map`, así que son extremos desde la evidencia disponible. Además el exportador omitía esos destinos del seed aunque fueran vecinos válidos.
- **Fix:** Materializar enlaces cardinales recíprocos en `Tools/Exportador.gd`, filtrar `_ExportMaps()` para procesar sólo `.map` y usar la ruta exacta `MapaN.Inf` en `GameAssets.GetMapInf()`.
- **Rule:** No inventar un mapa intermedio cuando no existe un `TileExit` que lo pruebe; si un mapa carece de `.Inf`, sólo se puede conservar la conexión inversa conocida.

### 2026-08-04 — Recortar miniaturas antes de dibujar el mapa mundial
- **Context:** Vista de minimapa y mapa mundial (`ui/hub/minimap.gd`, `ui/hub/world_map_view.gd`).
- **Problem:** Cada miniatura mostraba también contenido del mapa contiguo en sus bordes; el punto del jugador necesitaba un offset manual de -3 tiles.
- **Root cause:** Los BMP tienen un margen de tiles alrededor del área lógica de 100×100 y se dibujaban completos, haciendo visible ese margen en cada celda.
- **Fix:** Recortar dinámicamente el rectángulo central de 100×100 al cargar/dibujar la textura y eliminar el offset X del punto del jugador.
- **Rule:** Las miniaturas deben representar exclusivamente los tiles 1..100 del mapa; no compensar márgenes de assets con offsets de gameplay.

### 2026-08-03 — Adyacencia de mapas: clasificar cruces por GRUPO de exits y con reciprocidad; el seed debe mandar sobre `user://map_neighbors.json`
- **Context:** Revisión del "importar mapas" tras ver el mapa del mundo con enlaces mal dibujados.
- **Problem:** Algunos mapas se enlazaban mal: `163.S->165` mientras `165.E->163` (contradicción), `167<->168` en N y S a la vez, y se perdían cruces reales cuyo destino caía justo fuera de la banda estricta (`dest_x=85` con `ADJACENCY_BORDER_DIST=15` exige `>=86`). Además `user://map_neighbors.json` (runtime, viejo) PISABA los enlaces del seed al cargar.
- **Root cause:** (1) `_ClassifyExit` clasificaba cada exit por separado con banda estricta; en cruces de esquina el destino queda a 1 tile fuera y se caía a la dirección equivocada (163 S en vez de W). (2) El mapa portal 167/168 tiene cruces por N y por S al mismo destino (doble enlace opuesto). (3) `_merge_from_file` sobreescribía `existing[d]` con el archivo del usuario sin importar el seed.
- **Fix:** En `Tools/Exportador.gd`: `_ClassifyExitCandidates` (banda `+1`, devuelve 0-2 direcciones), resolución por votos por casilla `(mapa,dir)`, `_ReconcileCardinalPairs` (deja la pareja recíproca con más votos; desempata por eje vertical/horizontal del segmento de exits vía `_IsExitSegmentVertical`) y `_RemoveOppositeDoubleLinks` (mismo vecino en N y S / E y W -> quedarse con más votos). Regeneré `Assets/Init/map_neighbors.json` (mismos 106 mapas, corrige 163/165 y 167/168, recupera 5 enlaces reales, elimina 1 falso). En `engine/autoload/map_neighbors.gd`: `_merge_from_file(path, overwrite)`, seed con `overwrite=true`, usuario con `overwrite=false` (solo rellena huecos). Borré el `user://map_neighbors.json` obsoleto (respaldo `.bak`).
- **Rule:** Para inferir adyacencia de mapas, clasificar por grupo de exits (orientación del segmento + borde + destino) y validar reciprocidad, nunca por exit individual con banda rígida. El seed derivado de `.inf` es autoritativo: los datos de runtime no deben sobreescribir enlaces que el seed ya conoce.

### 2026-08-03 — Mapa del mundo: grafo `MapNeighbors` + miniaturas 100×100 para layout BFS; cuidado con `Input.is_action_pressed` y ventanas `exclusive`
- **Context:** Feature "clic en el minimapa abre el mapa del mundo" (`ui/hub/world_map_window.*`, `world_map_view.gd`, `hub_controller`, `minimap.gd`, `game_screen`).
- **Problem:** Había dos trampas: (1) en un `const` de GDScript no se puede usar `MapNeighbors.N` (constante de autoload) como clave de diccionario — no compila; (2) una `Window` con `exclusive = true` NO bloquea el estado global de `Input.is_action_pressed`, así que el jugador seguía caminando con el mapa abierto.
- **Root cause:** `Input` acumula estado de acciones a nivel global sin importar a qué subventana se rutearon los eventos; `_CheckKeys` (game_screen) sondea `Input.is_action_pressed` por frame. El layout BFS se construye desde el mapa actual con `MapNeighbors.get_neighbor_info` (8 direcciones) y las miniaturas `.bmp` de 100×100 px (1px = 1 tile) se dibujan con `draw_texture_rect`.
- **Fix:** Usar literales `"N"/"S"/...` como claves de `DIR_OFFSET` (coinciden con `MapNeighbors.N/...`); guardar `_CheckKeys` con `_gameInput.is_world_map_open()` y el flujo de Esc (pressed en game_screen cierra el mapa, released en hub consume con `_map_close_pending` para no mandar `WriteQuit`). El auto-fit inicial se difiere con `_pending_fit` + señal `resized` porque el `View` aún tiene `size=0` al instanciar la ventana.
- **Rule:** Las ventanas modales (`exclusive=true`) bloquean la entrega de eventos de input a otros controles, pero NO el muestreo de `Input.is_action_*` en `_process`; hay que guardar manualmente el movimiento/acciones mientras una ventana modal está abierta. Nunca usar constantes de autoloads en `const` de GDScript (usar literales o `var`).

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

### 2026-08-10 — Miniaturas .bmp ya vienen con ~10px del mapa contiguo en cada borde: recortar interior 80×80 en runtime
- **Context:** Minimapa HUD y mapa del mundo (`ui/hub/minimap.gd`, `ui/hub/world_map_view.gd`).
- **Problem:** Aunque los `.bmp` de `Assets/minimap_thumbnails/` son exactamente 100×100 px, su CONTENIDO ya trae ~10px del mapa contiguo por cada borde (el generador VB6 capturó un área mayor y la encajó en 100×100). Al dibujarlos completos, la unión entre mapas se ve extraña (sangra terreno del vecino).
- **Root cause:** El tamaño del archivo no es indicativo del contenido: 100×100 px con bordes contaminados ≠ 100×100 tiles limpios. El crop centrado previo (`(source - 100)/2`) era un no-op porque el archivo ya media 100×100.
- **Fix:** `BORDER_PX := 10`, `INNER_SIZE := MAP_TILE_SIZE - 2*BORDER_PX` (=80). `_crop_thumbnail`/`_get_thumbnail_region` recortan la región central 80×80 (origen `(source-INNER)/2 = (10,10)`) y se estira al widget. El punto del jugador y el clic re-mapean los tiles 11..90 a `[0,size]` (`clampi(tile, 11, 90)`, luego `(tile-11)/79 * size`); los tiles 1..10 y 91..100 quedan fuera y se anclan al borde. El clic del minimapa ahora emite tiles visibles en vez de píxeles crudos (`hub_controller._on_minimap_click` los usa como tile de warp).
- **Rule:** El tamaño de un asset no garantiza su contenido; verificar qué representa cada píxel antes de asumir que no hay margen. Al recortar, mapear coordenadas (dot, clic) con la MISMA transformación de recorte que la textura, o el punto y el warp quedan desfasados.

### 2026-08-10 — Mapa del mundo completo + oscurecer mapas no visitados
- **Context:** Feature "abrir el mapa del mundo muestra todo el mundo; los no visitados se ven oscuros pero visibles" (`ui/hub/world_map_view.gd`, `engine/autoload/map_neighbors.gd`, `engine/autoload/global.gd`, `engine/autoload/protocol_handler.gd`).
- **Problem:** El layout BFS limitado a `MAX_BFS_HOPS=2` solo mostraba el vecindario del jugador, y no había registro de mapas visitados para distinguir exploración.
- **Root cause:** Falta de API para enumerar todos los mapas del grafo (`MapNeighbors._connections` era privado) y falta de persistencia de exploración.
- **Fix:** `MapNeighbors.get_all_map_ids()` expone todas las claves del grafo. `_build_layout` hace BFS sin límite sobre todo el grafo (con `_bfs_layout` para componentes desconectados, colocados debajo del contenido ya ubicado). `Global` persiste `{account_key: {map_id: true}}` en `user://visited_maps.json` con `mark_map_visited`/`is_map_visited`/`_visited_key` (clave por `account_name`, "default" si está vacío); `protocol_handler` marca visitado en el paquete `ChangeMap`. En `_draw`, la miniatura usa `Color.WHITE` si visitado o `COLOR_UNVISITED (0.28,0.28,0.28)` si no (oscura pero visible).
- **Rule:** Para "mostrar el mundo entero" hay que enumerar el grafo (BFS completo) y NO limitar por saltos; las coordenadas de los componentes desconectados se siembran debajo del contenido. La exploración es estado por cuenta: persistir en disco con clave por `account_name`. Verificación runtime (game_eval): 191 mapas colocados, miniaturas cargan, modulación correcta.

### 2026-08-10 — Teletransportes (TileExit) en el mapa del mundo: líneas encima de los mapas + lectura en tiempo real de los .inf
- **Context:** Mapa del mundo (`ui/hub/world_map_view.gd`, `engine/autoload/game_assets.gd`, `Tools/Exportador.gd`).
- **Problem:** Las líneas entre mapas se dibujaban DEBAJO de las miniaturas (quedaban ocultas) y, peor, solo representaban la adyacencia geográfica: los teletransportes de mazmorras/interiores (`TileExit` que no son cruces de borde) se descartaban en el export ("portales ignorados"), así que las conexiones reales entre cuevas y el mapa superior no se veían.
- **Root cause:** (1) Orden de `_draw`: primero `_edges`, luego miniaturas — las líneas quedaban tapadas. (2) `_ExportMapAdjacency` (Exportador) clasifica los `TileExit` y DESCARTA los que no son cruces de borde (banda `ADJACENCY_BORDER_DIST`). (3) El mapa del mundo solo colocaba mapas del grafo geográfico (`MapNeighbors`); 22 mapas que solo existen vía teletransporte (17, 45, 48, 49, 66, 76, 139, 159, 166, 170, 179, 199, 200, 269, 270, 271, 274, 275, 281, 286, 299, 310) quedaban fuera.
- **Fix:** En `_draw`, dibujar primero las miniaturas, luego las uniones geográficas, luego los teletransportes (magenta con flecha `_draw_arrow` hacia el destino, bidireccional = línea sin flecha), y encima bordes/ids. `_build_layout` amplía el universo con `_get_transition_map_ids()` (origen+destino del seed `map_transitions.json`) para incluir los mapas de mazmorras. `_build_teleport_links` combina el seed del export (`res://Assets/Init/map_transitions.json`) con la lectura en TIEMPO REAL de `GameAssets.GetMapInf(map_id)` (los `.inf` del servidor), excluyendo los pares geográficos (`_geo_pairs`) para no duplicar líneas. `game_assets.GetMapInf` ahora cachea resultados (`_map_inf_cache`) porque se lee repetidamente. El Exportador añade `_ExportMapTransitions()` que vuelca TODOS los `TileExit` dirigidos (`{"from": [to,...]}`) en `map_transitions.json`.
- **Rule:** Distinguir adyacencia geográfica (afecta la caché 3×3 y el layout) de teletransportes (solo informativos para el mapa del mundo); NO mezclarlos en `MapNeighbors`. La fuente más fiel de teletransportes son los `.inf` leídos en tiempo real (sin heurísticas de clasificación), con el seed del export como respaldo. Las líneas que conectan mapas deben dibujarse POR ENCIMA de las miniaturas. Verificación runtime: 212 mapas colocados, 60 teletransportes (antes 21), 22 mapas de mazmorra incluidos.

### 2026-08-10 — Mapa del mundo: layout estrella + clasificar paso de mapa vs teletransporte por geometría de los .inf
- **Context:** Mapa del mundo (`ui/hub/world_map_view.gd`).
- **Problem:** (1) Los mapas sin paso de mapa se apilaban uno debajo del otro (una columna de 63 celdas de alto) y quedaba ilegible. (2) El BFS colocaba a DOS mapas distintos en la MISMA celda (24-30 solapamientos) porque el grafo geográfico tiene offsets inconsistentes (ciclos contradictorios). (3) Había que distinguir visualmente paso de mapa (frontera caminable) de teletransporte.
- **Root cause:** El layout "componentes desconectados debajo" acumulaba las mazmorras en vertical. El BFS con `DIR_OFFSET` unitario produce posiciones no únicas en grafos cíclicos inconsistentes (`_grid.has(nid)` solo evita re-colocar el MISMO mapa, no que otro mapa ocupe la misma celda). Las líneas geográficas se dibujaban y los teletransportes usaban un estilo no diferenciado.
- **Fix:** Clasificación por geometría de los `.inf` por par (mapa, destino): `_passage_direction` devuelve "N/S/E/W" si >=3 exits forman una línea sobre un borde (umbral `max(3, ceil(n/2))`, banda 16) → es PASO de mapa (se agrega a `_geo_neighbors`, queda lado a lado, sin línea); si no → TELETRANSPORTE (línea de puntos celeste `draw_dashed_line` con flecha `_draw_dotted_arrow`). El layout: BFS con `_find_free_cell` (búsqueda en anillos concéntricos) para que cada mapa caiga en celda única, y `_place_disconnected_ring` reparte los mapas sin paso en un anillo alrededor del clúster (estrella), espirando hacia afuera si la celda está ocupada. Se eliminaron las líneas de uniones geográficas (la adyacencia se ve por proximidad).
- **Rule:** Para layout de grafos con offsets no confiables, BFS con celda-única garantizada (`_find_free_cell`), nunca asumir posiciones únicas. Clasificar un par como paso de mapa por su geometría real en el `.inf` (línea sobre borde) y no solo por el grafo exportado. Verificación runtime: 0 solapamientos, 212 mapas, 51 teletransportes, bounding box compacto y balanceado.
