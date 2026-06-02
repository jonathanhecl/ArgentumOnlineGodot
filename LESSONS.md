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
