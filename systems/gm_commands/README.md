# Sistema de Comandos GM - Argentum Online Godot

## Descripción

Sistema completo de comandos de Game Master (GM) portado desde el cliente original de Visual Basic a Godot 4.4. Incluye más de 80 comandos organizados por categorías con interfaz gráfica intuitiva.

## Características

- **Sistema Modular**: Comandos organizados por categorías para fácil mantenimiento
- **Interfaz Gráfica**: Panel GM con pestañas categorizadas y ejecución visual
- **Validación de Parámetros**: Verificación automática de argumentos y permisos
- **Historial de Comandos**: Registro de comandos ejecutados con navegación
- **Ventanas de Información**: Visualización detallada de datos de jugadores
- **Autocompletado**: Sugerencias de comandos mientras escribes
- **Atajos de Teclado**: Acceso rápido a funciones principales

## Estructura del Sistema

```
systems/gm_commands/
├── GMCommandSystem.gd      # Sistema principal de comandos
├── README.md              # Esta documentación
└── test_gm_commands.gd    # Script de pruebas

systems/network/
└── GameProtocol.gd        # Protocolo de comunicación con servidor

ui/gm/
├── gm_panel.gd           # Panel principal GM
├── gm_panel.tscn         # Escena del panel GM
├── player_info_window.gd # Ventana de información de jugadores
└── player_info_window.tscn # Escena de información

autoload/
└── Global.gd             # Autoload global con integración
```

## Categorías de Comandos

### 1. Mensajería (10 comandos)
- `/gmsg` - Mensaje GM global
- `/rmsg` - Mensaje del servidor
- `/mapmsg` - Mensaje al mapa actual
- `/realmsg` - Mensaje al Ejército Real
- `/caosmsg` - Mensaje a la Legión Oscura
- `/ciumsg` - Mensaje a ciudadanos
- `/crimsg` - Mensaje a criminales
- `/smsg` - Mensaje del sistema
- `/talkas` - Hablar como NPC

### 2. Teletransporte y Movimiento (5 comandos)
- `/telep` - Teletransportar jugador
- `/teleploc` - Teletransportarse al objetivo
- `/ira` - Ir hacia un personaje
- `/ircerca` - Ir cerca de un personaje
- `/sum` - Invocar personaje

### 3. Información de Jugadores (9 comandos)
- `/info` - Información del personaje
- `/stat` - Estadísticas del personaje
- `/bal` - Oro del personaje
- `/inv` - Inventario del personaje
- `/bov` - Bóveda del personaje
- `/skills` - Habilidades del personaje
- `/donde` - Ubicación del personaje
- `/lastip` - Última IP del personaje
- `/lastemail` - Último email del personaje

### 4. Castigos y Moderación (11 comandos)
- `/carcel` - Encarcelar jugador
- `/ban` - Banear personaje
- `/unban` - Desbanear personaje
- `/banip` - Banear IP
- `/unbanip` - Desbanear IP
- `/echar` - Expulsar jugador
- `/ejecutar` - Ejecutar jugador
- `/advertencia` - Advertir usuario
- `/silenciar` - Silenciar jugador
- `/estupido` - Hacer estúpido
- `/noestupido` - Quitar estúpido

### 5. Modificación de Personajes (6 comandos)
- `/mod` - Modificar personaje
- `/revivir` - Revivir personaje
- `/perdon` - Perdonar personaje
- `/conden` - Convertir en criminal
- `/rajar` - Resetear facciones
- `/rajarclan` - Expulsar de clan

### 6. Control del Servidor (8 comandos)
- `/show` - Mostrar listas
- `/panelgm` - Abrir panel GM
- `/onlinegm` - GMs online
- `/onlinemap` - Jugadores en mapa
- `/onlinereal` - Ejército Real online
- `/onlinecaos` - Legión Oscura online
- `/habilitar` - Alternar servidor abierto
- `/apagar` - Apagar servidor

### 7. Manipulación del Mundo (9 comandos)
- `/ci` - Crear objeto
- `/dest` - Destruir objetos
- `/acc` - Crear NPC
- `/racc` - Crear NPC con respawn
- `/rmata` - Matar NPC
- `/mata` - Matar NPC sin respawn
- `/masskill` - Matar NPCs cercanos
- `/limpiar` - Limpiar mundo
- `/resetinv` - Resetear inventario NPC

### 8. Audio/Visual (5 comandos)
- `/forcemidi` - Forzar MIDI a todos
- `/forcewav` - Forzar WAV a todos
- `/forcemidimap` - Forzar MIDI al mapa
- `/forcewavmap` - Forzar WAV al mapa
- `/lluvia` - Alternar lluvia

### 9. Gestión de Facciones (5 comandos)
- `/aceptconse` - Aceptar consejero real
- `/aceptconsecaos` - Aceptar consejero caos
- `/kickconse` - Expulsar consejero
- `/nocaos` - Expulsar de Legión Oscura
- `/noreal` - Expulsar de Ejército Real

### 10. Administrativo (12 comandos)
- `/invisible` - Alternar invisibilidad
- `/trabajando` - Alternar trabajando
- `/ocultando` - Alternar ocultando
- `/showname` - Mostrar nombre
- `/hora` - Mostrar hora del servidor
- `/rem` - Agregar comentario
- `/nene` - Criaturas en mapa
- `/piso` - Objetos en el suelo
- `/bloq` - Alternar tile bloqueado
- `/trigger` - Configurar trigger
- `/centinelaactivado` - Alternar centinela
- `/slot` - Verificar slot

## Uso del Sistema

### Inicialización

El sistema se inicializa automáticamente a través del autoload `Global.gd`:

```gdscript
# El sistema está disponible globalmente
Global.set_gm_status(true, 2)  # Activar GM nivel 2
Global.toggle_gm_panel()       # Mostrar panel GM
```

### Ejecución de Comandos

#### Desde el Panel GM
1. Abrir panel con `Ctrl+F1` o `Global.toggle_gm_panel()`
2. Navegar por las pestañas de categorías
3. Hacer clic en "Ejecutar" para comandos sin parámetros
4. Usar diálogos de parámetros para comandos complejos

#### Desde Código
```gdscript
# Ejecutar comando directamente
Global.execute_gm_command("/gmsg Hola aventureros!")

# Comandos específicos
Global.go_to_player("NombreJugador")
Global.summon_player("NombreJugador")
Global.show_player_info("NombreJugador")
```

#### Desde Input de Comando
```gdscript
# En el panel GM, escribir directamente:
/gmsg Este es un mensaje GM
/telep Jugador 1 50 50
/info NombreJugador
```

### Validación y Permisos

El sistema incluye validación automática:

- **Permisos GM**: Verificación de estado GM antes de ejecutar
- **Comandos Admin**: Comandos marcados como admin_only requieren nivel 3+
- **Parámetros**: Validación de argumentos requeridos y opcionales
- **Formato**: Verificación de tipos de datos (enteros, bytes, etc.)

### Ventanas de Información

Para comandos de información (`/info`, `/stat`, `/inv`, etc.), se abren ventanas especializadas:

```gdscript
# Mostrar información específica
player_info_window.show_char_info("NombreJugador")
player_info_window.show_char_stats("NombreJugador")
player_info_window.show_char_inventory("NombreJugador")
```

## Atajos de Teclado

### Globales (solo para GMs)
- `Ctrl+F1`: Alternar panel GM
- `Ctrl+Shift+F2`: Alternar invisibilidad
- `Ctrl+Shift+F3`: Mostrar GMs online

### En el Panel GM
- `Ctrl+Enter`: Ejecutar comando
- `Ctrl+L`: Limpiar salida
- `Ctrl+H`: Mostrar historial

## Extensión del Sistema

### Agregar Nuevos Comandos

1. **Registrar el comando** en `GMCommandSystem._register_all_commands()`:
```gdscript
_register_command("NUEVO", CommandCategory.MESSAGING, "Descripción", "/nuevo PARAM", ["param"])
```

2. **Implementar la lógica** en `GMCommandSystem._execute_specific_command()`:
```gdscript
"NUEVO":
    return _execute_nuevo(arguments)
```

3. **Crear función específica**:
```gdscript
func _execute_nuevo(arguments: String) -> String:
    # Lógica del comando
    GameProtocol.WriteNuevoComando(arguments)
    return "Comando nuevo ejecutado"
```

4. **Agregar protocolo** en `GameProtocol.gd`:
```gdscript
func WriteNuevoComando(data: String):
    _send_message(MessageType.NUEVO_COMANDO, {"data": data})
```

### Personalizar Interfaz

El panel GM es completamente personalizable:

- **Colores**: Modificar temas en `gm_panel.gd`
- **Diseño**: Editar `gm_panel.tscn`
- **Categorías**: Agregar nuevas pestañas en `_setup_command_categories()`

## Notas de Implementación

### Comandos con Implementación Pendiente

Algunos comandos requieren integración adicional con el servidor:

- **Comandos de Red**: Requieren conexión TCP/UDP activa
- **Comandos de Base de Datos**: Necesitan acceso a datos del servidor
- **Comandos de Archivos**: Requieren acceso al sistema de archivos del servidor

### Simulación para Testing

El sistema incluye simulación de respuestas del servidor para testing:

```gdscript
# En GameProtocol._simulate_server_response()
# Se generan respuestas ficticias para probar la UI
```

### Compatibilidad

- **Godot 4.4+**: Utiliza características específicas de Godot 4
- **GDScript**: Código nativo, sin dependencias externas
- **Multiplataforma**: Compatible con Windows, Linux, macOS

## Solución de Problemas

### Comandos No Funcionan
1. Verificar estado GM: `Global.is_gm`
2. Verificar permisos: `Global.gm_level`
3. Revisar sintaxis del comando
4. Verificar conexión de red (para comandos reales)

### Panel No Aparece
1. Verificar autoload Global.gd está configurado
2. Verificar escenas están en las rutas correctas
3. Revisar errores en consola de Godot

### Errores de Protocolo
1. Verificar GameProtocol está inicializado
2. Revisar conexión con servidor
3. Verificar formato de mensajes

## Futuras Mejoras

- [ ] Integración con sistema de red real
- [ ] Comandos de batch/script
- [ ] Filtros y búsqueda en el panel
- [ ] Exportar/importar configuraciones
- [ ] Logs persistentes de comandos
- [ ] Notificaciones push para eventos
- [ ] Integración con sistema de permisos granular
- [ ] API REST para comandos remotos

## Créditos

Sistema desarrollado para Argentum Online Godot, basado en el protocolo original de Visual Basic. Implementación optimizada para Godot 4.4 con patrones modernos de GDScript.
