---
name: fix-desync-godot
description: Fix de desincronización de paquetes (VB6 parity)
---
# Objetivo
Detectar y corregir desincronizaciones de stream en el cliente Godot, comparando consumo exacto de paquetes con VB6.

# Pasos
1) Reproducir el bug con logging activo
   - Activar `ProtocolHandler.packet_debug_enabled = true`.
   - Registrar `packet_id`, `pos` y `size`.

2) Identificar paquete que rompe el stream
   - Buscar `packet_id=0` o saltos de posición.
   - Anotar secuencia de paquetes antes del desync.

3) Comparar con VB6
   - Abrir [d:\ao-cliente\CODIGO\Red\Protocol.bas](cci:7://file:///d:/ao-cliente/CODIGO/Red/Protocol.bas:0:0-0:0).
   - Buscar `Handle<PacketName>` y anotar orden/tipos de lectura:
     - `ReadByte` (int8), `ReadInteger` (int16), `ReadLong` (int32), etc.

4) Implementar parser en Godot
   - Crear `network/commands/<PacketName>.gd`
   - Usar `get_u8`, `get_16`, `get_32` según VB6.
   - Mantener nombres de variables en inglés.

5) Conectar en [protocol_handler.gd](cci:7://file:///d:/ArgentumOnlineGodot/engine/autoload/protocol_handler.gd:0:0-0:0)
   - Agregar `Enums.ServerPacketID.<PacketName>` y consumir el parser.
   - Si no hay efecto visual, igual consumir para no desync.

6) Validar con simulador
   - Crear test en [Tests/test_protocol_packet_simulator.gd](cci:7://file:///d:/ArgentumOnlineGodot/Tests/test_protocol_packet_simulator.gd:0:0-0:0)
   - Construir `PackedByteArray` con secuencia real.
   - Verificar `pos == size`.

7) Validación in-game
   - Repetir ataque/acción.
   - Confirmar ausencia de `packet_id=0`.

# Checklist final
- [ ] Parser consume exactamente el payload VB6
- [ ] Stream termina en `size`
- [ ] No aparece `packet_id=0`
- [ ] Logs desactivables