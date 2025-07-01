# Comandos de Argentum Online Godot

## Tabla de Contenidos
- [Comandos de Usuario](#comandos-de-usuario)
  - [Básicos](#básicos)
  - [Bóveda y Comercio](#bóveda-y-comercio)
  - [Mascotas](#mascotas)
  - [Entrenamiento y Descanso](#entrenamiento-y-descanso)
  - [Información](#información)
  - [Grupo (Party)](#grupo-party)
  - [Clan](#clan)
  - [Mensajes](#mensajes)
  - [Varios](#varios)
- [Comandos de Game Master](#comandos-de-game-master)
  - [Mensajería](#mensajería)
  - [Teletransporte y Movimiento](#teletransporte-y-movimiento)
  - [Información de Jugadores](#información-de-jugadores)
  - [Moderación y Castigos](#moderación-y-castigos)
  - [Modificación de Personajes](#modificación-de-personajes)
  - [Control del Servidor](#control-del-servidor)
  - [Manipulación del Mundo](#manipulación-del-mundo)
  - [Audio y Visual](#audio-y-visual)
  - [Gestión de Facción](#gestión-de-facción)
  - [Administrativos](#administrativos)

---

## Comandos de Usuario

### Básicos
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/salir` | Cierra el juego | `/salir` | ❌ |
| `/est` | Muestra estadísticas del personaje | `/est` | ❌ |
| `/invisible` | Alterna visibilidad del personaje | `/invisible` | ✅ |
| `/meditar` | Recupera maná | `/meditar` | ✅ |
| `/resucitar` | Revive al personaje | `/resucitar` | ❌ |
| `/desc` | Cambia la descripción | `/desc [texto]` | ✅ |
| `/ping` | Verifica latencia | `/ping` | ❌ |

### Bóveda y Comercio
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/boveda` | Abre la bóveda | `/boveda` | ✅ |
| `/depositar` | Deposita oro | `/depositar [cantidad]` | ✅ |
| `/retirar` | Retira oro | `/retirar [cantidad]` | ✅ |
| `/balance` | Consulta saldo | `/balance` | ✅ |
| `/comerciar` | Inicia comercio | `/comerciar` | ✅ |
| `/apostar` | Realiza apuesta | `/apostar [cantidad]` | ✅ |

### Mascotas
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/quieto` | Mascota se queda | `/quieto` | ✅ |
| `/acompañar` | Mascota te sigue | `/acompañar` | ✅ |
| `/liberar` | Libera mascota | `/liberar` | ✅ |

### Entrenamiento y Descanso
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/entrenar` | Muestra entrenadores | `/entrenar` | ✅ |
| `/descansar` | Recupera vida | `/descansar` | ✅ |

### Información
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/consulta` | Información de consulta | `/consulta` | ❌ |
| `/ayuda` | Ayuda del juego | `/ayuda` | ❌ |
| `/enlistar` | Lista de comandos | `/enlistar` | ❌ |
| `/informacion` | Información del juego | `/informacion` | ❌ |
| `/recompensa` | Recompensas | `/recompensa` | ❌ |
| `/motd` | Mensaje del día | `/motd` | ❌ |
| `/uptime` | Tiempo activo | `/uptime` | ❌ |
| `/online` | Jugadores conectados | `/online` | ❌ |

### Grupo (Party)
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/salirparty` | Abandona grupo | `/salirparty` | ❌ |
| `/crearparty` | Crea grupo | `/crearparty` | ✅ |
| `/party` | Une a grupo | `/party` | ✅ |
| `/compartirnpc` | Comparte NPC | `/compartirnpc` | ✅ |
| `/nocompartirnpc` | Deja de compartir | `/nocompartirnpc` | ✅ |
| `/echarparty` | Expulsa del grupo | `/echarparty [nick]` | ❌ |
| `/partylider` | Transfiere liderazgo | `/partylider [nick]` | ❌ |
| `/acceptparty` | Acepta miembro | `/acceptparty [nick]` | ❌ |
| `/pmsg` | Mensaje al grupo | `/pmsg [mensaje]` | ❌ |
| `/onlineparty` | Miembros conectados | `/onlineparty` | ❌ |

### Clan
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/salirclan` | Abandona clan | `/salirclan` | ❌ |
| `/cmsg` | Mensaje al clan | `/cmsg [mensaje]` | ❌ |
| `/voto` | Vota por miembro | `/voto [nick]` | ❌ |
| `/penas` | Muestra penas | `/penas [nick]` | ❌ |
| `/fundarclan` | Crea clan | `/fundarclan` | ✅ |
| `/onlineclan` | Miembros conectados | `/onlineclan` | ❌ |
| `/bmsg` | Mensaje al consejo | `/bmsg [mensaje]` | ❌ |

### Mensajes
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/encuesta` | Participa en encuesta | `/encuesta [opción]` | ❌ |
| `/centinela` | Reporta centinela | `/centinela [código]` | ❌ |
| `/denunciar` | Realiza denuncia | `/denunciar [texto]` | ❌ |
| `/_bug` | Reporta error | `/_bug [descripción]` | ❌ |

### Varios
| Comando | Descripción | Uso | Requiere estar vivo |
|---------|-------------|-----|-------------------|
| `/contraseña` | Cambia contraseña | `/contraseña` | ❌ |
| `/retirarfaccion` | Abandona facción | `/retirarfaccion` | ✅ |
| `/rol` | Pregunta al MR | `/rol [pregunta]` | ❌ |
| `/gm` | Solicita GM | `/gm` | ❌ |

---

## Comandos de Game Master

### Mensajería
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/gmsg` | Mensaje GM | `/gmsg [mensaje]` | ❌ |
| `/rmsg` | Mensaje servidor | `/rmsg [mensaje]` | ❌ |
| `/mapmsg` | Mensaje al mapa | `/mapmsg [mensaje]` | ❌ |
| `/realmsg` | A Ejército Real | `/realmsg [mensaje]` | ❌ |
| `/caosmsg` | A Legión Oscura | `/caosmsg [mensaje]` | ❌ |
| `/ciumsg` | A ciudadanos | `/ciumsg [mensaje]` | ❌ |
| `/crimsg` | A criminales | `/crimsg [mensaje]` | ❌ |
| `/smsg` | Mensaje sistema | `/smsg [mensaje]` | ❌ |
| `/talkas` | Habla como NPC | `/talkas [mensaje]` | ❌ |

### Teletransporte y Movimiento
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/telep` | Teletransporta | `/telep [nick] [mapa] [x] [y]` | ❌ |
| `/teleploc` | Va a ubicación | `/teleploc [x] [y]` | ❌ |
| `/ira` | Va a jugador | `/ira [nick]` | ❌ |
| `/ircerca` | Va cerca de jugador | `/ircerca [nick]` | ❌ |
| `/sum` | Invoca jugador | `/sum [nick]` | ❌ |

### Información de Jugadores
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/info` | Info personaje | `/info [nick]` | ❌ |
| `/stat` | Estadísticas | `/stat [nick]` | ❌ |
| `/bal` | Oro personaje | `/bal [nick]` | ❌ |
| `/inv` | Inventario | `/inv [nick]` | ❌ |
| `/bov` | Bóveda | `/bov [nick]` | ❌ |
| `/skills` | Habilidades | `/skills [nick]` | ❌ |
| `/donde` | Ubicación | `/donde [nick]` | ❌ |
| `/lastip` | Última IP | `/lastip [nick]` | ❌ |
| `/lastemail` | Último email | `/lastemail [nick]` | ❌ |

### Moderación y Castigos
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/carcel` | Encarcela | `/carcel [nick]@[motivo]@[tiempo]` | ❌ |
| `/ban` | Banea personaje | `/ban [nick]@[motivo]` | ❌ |
| `/unban` | Desbanea | `/unban [nick]` | ❌ |
| `/banip` | Banea IP | `/banip [ip/nick] [motivo]` | ❌ |
| `/unbanip` | Desbanea IP | `/unbanip [ip]` | ❌ |
| `/echar` | Expulsa | `/echar [nick]` | ❌ |
| `/ejecutar` | Mata jugador | `/ejecutar [nick]` | ❌ |
| `/advertencia` | Advertencia | `/advertencia [nick]@[motivo]` | ❌ |
| `/silenciar` | Silencia | `/silenciar [nick]` | ❌ |
| `/estupido` | Hace estúpido | `/estupido [nick]` | ❌ |
| `/noestupido` | Quita estúpido | `/noestupido [nick]` | ❌ |

### Modificación de Personajes
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/mod` | Modifica atributo | `/mod [nick] [atributo] [valor] [extra]` | ❌ |
| `/revivir` | Revive | `/revivir [nick]` | ❌ |
| `/perdon` | Perdona | `/perdon [nick]` | ❌ |
| `/conden` | Hace criminal | `/conden [nick]` | ❌ |
| `/rajar` | Resetea facciones | `/rajar [nick]` | ❌ |
| `/rajarclan` | Expulsa de clan | `/rajarclan [nick]` | ❌ |

### Control del Servidor
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/show` | Muestra listas | `/show [tipo]` | ❌ |
| `/panelgm` | Abre panel GM | `/panelgm` | ❌ |
| `/onlinegm` | GMs online | `/onlinegm` | ❌ |
| `/onlinemap` | Jugadores en mapa | `/onlinemap [mapa]` | ❌ |
| `/onlinereal` | Ejército Real | `/onlinereal` | ❌ |
| `/onlinecaos` | Legión Oscura | `/onlinecaos` | ❌ |
| `/habilitar` | Alterna servidor | `/habilitar` | ✅ |
| `/apagar` | Apaga servidor | `/apagar` | ✅ |

### Manipulación del Mundo
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/ci` | Crea objeto | `/ci [objeto]` | ❌ |
| `/dest` | Destruye objetos | `/dest` | ❌ |
| `/acc` | Crea NPC | `/acc [npc]` | ❌ |
| `/racc` | Crea NPC con respawn | `/racc [npc]` | ❌ |
| `/rmata` | Mata NPC | `/rmata` | ❌ |
| `/mata` | Mata sin respawn | `/mata` | ❌ |
| `/masskill` | Mata NPCs cercanos | `/masskill` | ❌ |
| `/limpiar` | Limpia mundo | `/limpiar` | ❌ |
| `/resetinv` | Resetea inventario NPC | `/resetinv` | ❌ |

### Audio y Visual
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/forcemidi` | Forza MIDI global | `/forcemidi [midi]` | ❌ |
| `/forcewav` | Forza WAV global | `/forcewav [wav]` | ❌ |
| `/forcemidimap` | Forza MIDI en mapa | `/forcemidimap [midi] [mapa]` | ❌ |
| `/forcewavmap` | Forza WAV en mapa | `/forcewavmap [wav] [mapa] [x] [y]` | ❌ |
| `/lluvia` | Alterna lluvia | `/lluvia` | ❌ |

### Gestión de Facción
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/aceptconse` | Acepta consejero real | `/aceptconse [nick]` | ❌ |
| `/aceptconsecaos` | Acepta consejero caos | `/aceptconsecaos [nick]` | ❌ |
| `/kickconse` | Expulsa consejero | `/kickconse [nick]` | ❌ |
| `/nocaos` | Expulsa de Legión | `/nocaos [nick]` | ❌ |
| `/noreal` | Expulsa de Ejército | `/noreal [nick]` | ❌ |

### Administrativos
| Comando | Descripción | Uso | Requiere Admin |
|---------|-------------|-----|--------------|
| `/invisible` | Alterna invisibilidad | `/invisible` | ❌ |
| `/trabajando` | Alterna estado trabajando | `/trabajando` | ❌ |
| `/ocultando` | Alterna estado oculto | `/ocultando` | ❌ |
| `/showname` | Muestra nombre | `/showname` | ❌ |
| `/hora` | Hora del servidor | `/hora` | ❌ |
| `/rem` | Agrega comentario | `/rem [comentario]` | ❌ |
| `/nene` | Criaturas en mapa | `/nene [mapa]` | ❌ |
| `/piso` | Objetos en suelo | `/piso` | ❌ |
| `/bloq` | Alterna bloqueo de tile | `/bloq` | ❌ |
| `/trigger` | Configura trigger | `/trigger [numero]` | ❌ |
| `/centinelaactivado` | Alterna centinela | `/centinelaactivado` | ❌ |
| `/slot` | Verifica slot | `/slot [nick]@[slot]` | ❌ |

---

## Notas
- ✅ = Requiere que el personaje esté vivo
- ❌ = No requiere que el personaje esté vivo
- Los comandos marcados con "Requiere Admin" solo pueden ser usados por administradores
- Los parámetros entre corchetes `[]` son opcionales
- Los parámetros separados por `@` deben incluirse en un solo argumento
