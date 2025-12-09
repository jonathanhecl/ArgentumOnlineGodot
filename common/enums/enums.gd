extends RefCounted
class_name Enums

enum Class{ 
	None,
	Mage = 1,
	Cleric,
	Warrior,
	Assassin,
	Thief,
	Bard,
	Druid,
	Bandit,
	Paladin,
	Hunter,
	Worker,
	Pirat
}

enum Race{ 
	None,
	Human = 1,
	Elf,
	Drow,
	Gnome,
	Dwarf
}

enum Home{
	None = 0,
	Ullathorpe = 1,
	Nix,
	Banderbill,
	Lindos,
	Arghal,
	Arkhein,
	LastCity
};

enum TileState {
	None = 0,
	Blocked = 1 << 0, 
	Roof = 1 << 1,
	Water = 1 << 2,
} 

enum Heading{
	None,
	North,
	East,
	South,
	West,
}

enum Skill{
	None = 0,
	Magia = 1,
	Robar = 2,
	Tacticas = 3,
	Armas = 4,
	Meditar = 5,
	Apunalar = 6,
	Ocultarse = 7,
	Supervivencia = 8,
	Talar = 9,
	Comerciar = 10,
	Defensa = 11,
	Pesca = 12,
	Mineria = 13,
	Carpinteria = 14,
	Herreria = 15,
	Liderazgo = 16,
	Domar = 17,
	Proyectiles = 18,
	Wrestling = 19,
	Navegacion = 20,
}

enum eMoveType {
	Inventory = 1,
	Bank
}

enum eOBJType {
	eOBJType_Null = 0,
	eOBJType_otUseOnce = 1,
	eOBJType_otWeapon = 2,
	eOBJType_otArmadura = 3,
	eOBJType_otArboles = 4,
	eOBJType_otGuita = 5,
	eOBJType_otPuertas = 6,
	eOBJType_otContenedores = 7,
	eOBJType_otCarteles = 8,
	eOBJType_otLlaves = 9,
	eOBJType_otForos = 10,
	eOBJType_otPociones = 11,
	eOBJType_otBebidas = 13,
	eOBJType_otLena = 14,
	eOBJType_otFogata = 15,
	eOBJType_otESCUDO = 16,
	eOBJType_otCASCO = 17,
	eOBJType_otAnillo = 18,
	eOBJType_otTeleport = 19,
	eOBJType_otYacimiento = 22,
	eOBJType_otMinerales = 23,
	eOBJType_otPergaminos = 24,
	eOBJType_otInstrumentos = 26,
	eOBJType_otYunque = 27,
	eOBJType_otFragua = 28,
	eOBJType_otBarcos = 31,
	eOBJType_otFlechas = 32,
	eOBJType_otBotellaVacia = 33,
	eOBJType_otBotellaLlena = 34,
	
	#No se usa 
	eOBJType_otManchas = 35,
	eOBJType_otArbolElfico = 36,
	eOBJType_otMochilas = 37,
	eOBJType_otYacimientoPez = 38,
	eOBJType_otCualquiera = 1000
}

enum Messages {
	DontSeeAnything,
	NPCSwing,
	NPCKillUser,
	BlockedWithShieldUser,
	BlockedWithShieldother,
	UserSwing,
	SafeModeOn,
	SafeModeOff,
	ResuscitationSafeOff,
	ResuscitationSafeOn,
	NobilityLost,
	CantUseWhileMeditating,
	NPCHitUser,
	UserHitNPC,
	UserAttackedSwing,
	UserHittedByUser,
	UserHittedUser,
	WorkRequestTarget,
	HaveKilledUser,
	UserKill,
	EarnExp,
	Home,
	CancelHome,
	FinishHome
};
	
enum FontTypeNames {
	FontType_Talk,
	FontType_Fight,
	FontType_Warning,
	FontType_Info,
	FontType_InfoBold,
	FontType_Ejecucion,
	FontType_Party,
	FontType_Veneno,
	FontType_Guild,
	FontType_Server,
	FontType_GuildMsg,
	FontType_Consejo,
	FontType_ConsejoCaos,
	FontType_ConsejoVesA,
	FontType_ConsejoCaosVesA,
	FontType_Centinela,
	FontType_GMMsg,
	FontType_GM,
	FontType_Citizen,
	FontType_Conse,
	FontType_Dios
}

enum PlayerType {
	None = 0,
	User = 1 << 0,         # 1
	Consejero = 1 << 1,    # 2
	SemiDios = 1 << 2,     # 4
	Dios = 1 << 3,         # 8
	Admin = 1 << 4,        # 16
	RoleMaster = 1 << 5,   # 32
	ChaosCouncil = 1 << 6, # 64
	RoyalCouncil = 1 << 7  # 128
}

enum NickColor {
	None = 0,
	IeCriminal = 1 << 0,  # 1
	IeCiudadano = 1 << 1, # 2
	IeAtacable = 1 << 2   # 4
}

# ServerPacketID: Is the protocol from the server to the client
enum ServerPacketID {
	Logged = 1,                 # LOGGED
	RemoveDialogs = 2,           # QTDL
	RemoveCharDialog = 3,        # QDL
	NavigateToggle = 4,          # NAVEG
	Disconnect = 5,              # FINOK
	CommerceEnd = 6,             # FINCOMOK
	BankEnd = 7,                 # FINBANOK
	CommerceInit = 8,            # INITCOM
	BankInit = 9,                # INITBANCO
	UserCommerceInit = 10,       # INITCOMUSU
	UserCommerceEnd = 11,        # FINCOMUSUOK
	UserOfferConfirm = 12,
	CommerceChat = 13,
	UpdateSta = 14,               # ASS
	UpdateMana = 15,             # ASM
	UpdateHP = 16,                # ASH
	UpdateGold = 17,              # ASG
	UpdateBankGold = 18,
	UpdateExp = 19,               # ASE
	ChangeMap = 20,               # CM
	PosUpdate = 21,              # PU
	ChatOverHead = 22,            # ||
	ConsoleMsg = 23,              # || - Beware!! its the same as above, but it was properly splitted
	GuildChat = 24,               # |+
	ShowMessageBox = 25,           # !!
	UserIndexInServer = 26,       # IU
	UserCharIndexInServer = 27,   # IP
	CharacterCreate = 28,         # CC
	CharacterRemove = 29,         # BP
	CharacterChangeNick = 30,
	CharacterMove = 31,           # MP, +, * and _ #
	ForceCharMove = 32,
	CharacterChange = 33,         # CP
	HeadingChange = 34,
	ObjectCreate = 35,            # HO
	ObjectDelete = 36,            # BO
	BlockPosition = 37,           # BQ
	PlayMp3 = 38,
	PlayMIDI = 39,               # TM
	PlayWave = 40,                # TW
	GuildList = 41,               # GL
	AreaChanged = 42,             # CA
	PauseToggle = 43,             # BKW
	RainToggle = 44,              # LLU
	CreateFX = 45,                # CFX
	UpdateUserStats = 46,         # EST
	ChangeInventorySlot = 47,     # CSI
	ChangeBankSlot = 48,          # SBO
	ChangeSpellSlot = 49,         # SHS
	Atributes = 50,               # ATR
	BlacksmithWeapons = 51,       # LAH
	BlacksmithArmors = 52,        # LAR
	InitCarpenting = 53,          # OBR
	RestOK = 54,                  # DOK
	ErrorMsg = 55,                # ERR
	Blind = 56,                   # CEGU
	Dumb = 57,                    # DUMB
	ShowSignal = 58,              # MCAR
	ChangeNPCInventorySlot = 59,  # NPCI
	UpdateHungerAndThirst = 60,   # EHYS
	Fame = 61,                    # FAMA
	MiniStats = 62,               # MEST
	LevelUp = 63,                 # SUNI
	AddForumMsg = 64,             # FMSG
	ShowForumForm = 65,           # MFOR
	SetInvisible = 66,            # NOVER
	DiceRoll = 67,                # DADOS
	MeditateToggle = 68,          # MEDOK
	BlindNoMore = 69,             # NSEGUE
	DumbNoMore = 70,              # NESTUP
	SendSkills = 71,              # SKILLS
	TrainerCreatureList = 72,     # LSTCRI
	GuildNews = 73,               # GUILDNE
	OfferDetails = 74,            # PEACEDE & ALLIEDE
	AlianceProposalsList = 75,    # ALLIEPR
	PeaceProposalsList = 76,      # PEACEPR
	CharacterInfo = 77,           # CHRINFO
	GuildLeaderInfo = 78,         # LEADERI
	GuildMemberInfo = 79,
	GuildDetails = 80,            # CLANDET
	ShowGuildFundationForm = 81,  # SHOWFUN
	ParalizeOK = 82,              # PARADOK
	ShowUserRequest = 83,         # PETICIO
	ChangeUserTradeSlot = 84,     # COMUSUINV
	SendNight = 85,               # NOC
	Pong = 86,
	UpdateTagAndStatus = 87,
	
	#GM =  messages
	SpawnList = 88,               # SPL
	ShowSOSForm = 89,             # MSOS
	ShowMOTDEditionForm = 90,     # ZMOTD
	ShowGMPanelForm = 91,         # ABPANEL
	UserNameList = 92,            # LISTUSU
	ShowDenounces = 93,
	RecordList = 94,
	RecordDetails = 95,
	
	ShowGuildAlign = 96,
	ShowPartyForm = 97,
	UpdateStrenghtAndDexterity = 98,
	UpdateStrenght = 99,
	UpdateDexterity = 100,
	AddSlots = 101,
	MultiMessage = 102,
	StopWorking = 103,
	CancelOfferItem = 104,
	PalabrasMagicas = 105,
	PlayAttackAnim = 106,
	FXtoMap = 107,
	AccountLogged = 108,         # CHOTS | Accounts
	SearchList = 109,
	QuestDetails = 110,
	QuestListSend = 111,
	CreateDamage = 112,          # CDMG
	UserInEvent = 113,
	RenderMsg = 114,
	DeletedChar = 115,
	EquitandoToggle = 116,
	EnviarDatosServer = 117,
	InitCraftman = 118,
	EnviarListDeAmigos = 119,
	SeeInProcess = 120,
	ShowProcess = 121,
	Proyectil = 122,
	PlayIsInChatMode = 123
}

# ClientPacketID: Is the protocol from the client to the server
enum ClientPacketID {
	ClientLoginExistingChar = 1, # OLOGIN
	ClientThrowDices = 2, # TIRDAD
	ClientLoginNewChar = 3, # NLOGIN
	ClientTalk = 4, # ;
	ClientYell = 5, # -
	ClientWhisper = 6, # \
	ClientWalk = 7, # M
	ClientRequestPositionUpdate = 8, # RPU
	ClientAttack = 9, # AT
	ClientPickUp = 10, # AG
	ClientSafeToggle = 11, # SEG & SEG (SEG's behaviour has to be coded in the client)
	ClientResuscitationSafeToggle = 12,
	ClientRequestGuildLeaderInfo = 13, # GLINFO
	ClientRequestAttributes = 14, # ATR
	ClientRequestFame = 15, # FAMA
	ClientRequestSkills = 16, # ESKI
	ClientRequestMiniStats = 17, # FEST
	ClientCommerceEnd = 18, # FINCOM
	ClientUserCommerceEnd = 19, # FINCOMUSU
	ClientUserCommerceConfirm = 20,
	ClientCommerceChat = 21,
	ClientBankEnd = 22, # FINBAN
	ClientUserCommerceOk = 23, # COMUSUOK
	ClientUserCommerceReject = 24, # COMUSUNO
	ClientDrop = 25, # TI
	ClientCastSpell = 26, # LH
	ClientLeftClick = 27, # LC
	ClientDoubleClick = 28, # RC
	ClientWork = 29, # UK
	ClientUseSpellMacro = 30, # UMH
	ClientUseItem = 31, # USA
	ClientCraftBlacksmith = 32, # CNS
	ClientCraftCarpenter = 33, # CNC
	ClientWorkLeftClick = 34, # WLC
	ClientCreateNewGuild = 35, # CIG
	ClientsadasdA = 36, # <<<<< Es un dummy
	ClientEquipItem = 37, # EQUI
	ClientChangeHeading = 38, # CHEA
	ClientModifySkills = 39, # SKSE
	ClientTrain = 40, # ENTR
	ClientCommerceBuy = 41, # COMP
	ClientBankExtractItem = 42, # RETI
	ClientCommerceSell = 43, # VEND
	ClientBankDeposit = 44, # DEPO
	ClientForumPost = 45, # DEMSG
	ClientMoveSpell = 46, # DESPHE
	ClientMoveBank = 47,
	ClientClanCodexUpdate = 48, # DESCOD
	ClientUserCommerceOffer = 49, # OFRECER
	ClientGuildAcceptPeace = 50, # ACEPPEAT
	ClientGuildRejectAlliance = 51, # RECPALIA
	ClientGuildRejectPeace = 52, # RECPPEAT
	ClientGuildAcceptAlliance = 53, # ACEPALIA
	ClientGuildOfferPeace = 54, # PEACEOFF
	ClientGuildOfferAlliance = 55, # ALLIEOFF
	ClientGuildAllianceDetails = 56, # ALLIEDET
	ClientGuildPeaceDetails = 57, # PEACEDET
	ClientGuildRequestJoinerInfo = 58, # ENVCOMEN
	ClientGuildAlliancePropList = 59, # ENVALPRO
	ClientGuildPeacePropList = 60, # ENVPROPP
	ClientGuildDeclareWar = 61, # DECGUERR
	ClientGuildNewWebsite = 62, # NEWWEBSI
	ClientGuildAcceptNewMember = 63, # ACEPTARI
	ClientGuildRejectNewMember = 64, # RECHAZAR
	ClientGuildKickMember = 65, # ECHARCLA
	ClientGuildUpdateNews = 66, # ACTGNEWS
	ClientGuildMemberInfo = 67, # 1HRINFO<
	ClientGuildOpenElections = 68, # ABREELEC
	ClientGuildRequestMembership = 69, # SOLICITUD
	ClientGuildRequestDetails = 70, # CLANDETAILS
	ClientOnline = 71, # ONLINE
	ClientQuit = 72, # SALIR
	ClientGuildLeave = 73, # SALIRCLAN
	ClientRequestAccountState = 74, # BALANCE
	ClientPetStand = 75, # QUIETO
	ClientPetFollow = 76, # ACOMPANAR
	ClientReleasePet = 77, # LIBERAR
	ClientTrainList = 78, # ENTRENAR
	ClientRest = 79, # DESCANSAR
	ClientMeditate = 80, # MEDITAR
	ClientResucitate = 81, # RESUCITAR
	ClientHeal = 82, # CURAR
	ClientHelp = 83, # AYUDA
	ClientRequestStats = 84, # EST
	ClientCommerceStart = 85, # COMERCIAR
	ClientBankStart = 86, # BOVEDA
	ClientEnlist = 87, # ENLISTAR
	ClientInformation = 88, # INFORMACION
	ClientReward = 89, # RECOMPENSA
	ClientRequestMOTD = 90, # MOTD
	ClientUpTime = 91, # UPTIME
	ClientPartyLeave = 92, # SALIRPARTY
	ClientPartyCreate = 93, # CREARPARTY
	ClientPartyJoin = 94, # PARTY
	ClientInquiry = 95, # ENCUESTA ( with no params )
	ClientGuildMessage = 96, # CMSG
	ClientPartyMessage = 97, # PMSG
	ClientGuildOnline = 98, # ONLINECLAN
	ClientPartyOnline = 99, # ONLINEPARTY
	ClientCouncilMessage = 100, # BMSG
	ClientRoleMasterRequest = 101, # ROL
	ClientGMRequest = 102, # GM
	ClientBugReport = 103, # _BUG
	ClientChangeDescription = 104, # DESC
	ClientGuildVote = 105, # VOTO
	ClientPunishments = 106, # PENAS
	ClientChangePassword = 107, # CONTRASENA
	ClientGamble = 108, # APOSTAR
	ClientInquiryVote = 109, # ENCUESTA ( with parameters )
	ClientLeaveFaction = 110, # RETIRAR ( with no arguments )
	ClientBankExtractGold = 111, # RETIRAR ( with arguments )
	ClientBankDepositGold = 112, # DEPOSITAR
	ClientDenounce = 113, # DENUNCIAR
	ClientGuildFundate = 114, # FUNDARCLAN
	ClientGuildFundation = 115,
	ClientPartyKick = 116, # ECHARPARTY
	ClientPartySetLeader = 117, # PARTYLIDER
	ClientPartyAcceptMember = 118, # ACCEPTPARTY
	ClientPing = 119, # PING
	ClientRequestPartyForm = 120,
	ClientItemUpgrade = 121,
	ClientGMCommands = 122,
	ClientInitCrafting = 123,
	ClientHome = 124,
	ClientShowGuildNews = 125,
	ClientShareNpc = 126, # COMPARTIR
	ClientStopSharingNpc = 127,
	ClientConsultation = 128,
	ClientMoveItem = 129,
	ClientLoginExistingAccount = 130, # CHOTS | Accounts
	ClientLoginNewAccount = 131, # CHOTS | Accounts
	ClientCentinelReport = 132, # CENTINELA
	ClientEcvc = 133,
	ClientAcvc = 134,
	ClientIrCvc = 135,
	ClientDragAndDropHechizos = 136, # HECHIZOS
	ClientQuest = 137, # QUEST
	ClientQuestAccept = 138,
	ClientQuestListRequest = 139,
	ClientQuestDetailsRequest = 140,
	ClientQuestAbandon = 141,
	ClientCambiarContrasena = 142,
	ClientFightSend = 143,
	ClientFightAccept = 144,
	ClientCloseGuild = 145, # CERRARCLAN
	ClientDiscord = 146, # DISCORD
	ClientDeleteChar = 147,
	ClientObtenerDatosServer = 148,
	ClientCraftsmanCreate = 149,
	ClientAddAmigos = 150,
	ClientDelAmigos = 151,
	ClientOnAmigos = 152,
	ClientMsgAmigos = 153,
	ClientLookProcess = 154,
	ClientSendProcessList = 155,
	ClientSendIfCharIsInChatMode = 156,
}

enum EGMCommands {
	GM_MESSAGE = 1,           # /GMSG
	SHOW_NAME,                # /SHOWNAME
	ONLINE_ROYAL_ARMY,        # /ONLINEREAL
	ONLINE_CHAOS_LEGION,      # /ONLINECAOS
	GO_NEARBY,                # /IRCERCA
	COMMENT,                  # /REM
	SERVER_TIME,              # /HORA
	WHERE,                    # /DONDE
	CREATURES_IN_MAP,         # /NENE
	WARP_ME_TO_TARGET,        # /TELEPLOC
	WARP_CHAR,                # /TELEP
	SILENCE,                  # /SILENCIAR
	SOS_SHOW_LIST,            # /SHOW SOS
	SOS_REMOVE,               # SOSDONE
	GO_TO_CHAR,               # /IRA
	INVISIBLE,                # /INVISIBLE
	GM_PANEL,                 # /PANELGM
	REQUEST_USER_LIST,        # LISTUSU
	WORKING,                  # /TRABAJANDO
	HIDING,                   # /OCULTANDO
	JAIL,                     # /CARCEL
	KILL_NPC,                 # /RMATA
	WARN_USER,                # /ADVERTENCIA
	EDIT_CHAR,                # /MOD
	REQUEST_CHAR_INFO,        # /INFO
	REQUEST_CHAR_STATS,       # /STAT
	REQUEST_CHAR_GOLD,        # /BAL
	REQUEST_CHAR_INVENTORY,   # /INV
	REQUEST_CHAR_BANK,        # /BOV
	REQUEST_CHAR_SKILLS,      # /SKILLS
	REVIVE_CHAR,              # /REVIVIR
	ONLINE_GM,                # /ONLINEGM
	ONLINE_MAP,               # /ONLINEMAP
	FORGIVE,                  # /PERDON
	KICK,                     # /ECHAR
	EXECUTE,                  # /EJECUTAR
	BAN_CHAR,                 # /BAN
	UNBAN_CHAR,               # /UNBAN
	NPC_FOLLOW,               # /SEGUIR
	SUMMON_CHAR,              # /SUM
	SPAWN_LIST_REQUEST,       # /CC
	SPAWN_CREATURE,           # SPA
	RESET_NPC_INVENTORY,      # /RESETINV
	CLEAN_WORLD,              # /LIMPIAR
	SERVER_MESSAGE,           # /RMSG
	NICK_TO_IP,               # /NICK2IP
	IP_TO_NICK,               # /IP2NICK
	GUILD_ONLINE_MEMBERS,     # /ONCLAN
	TELEPORT_CREATE,          # /CT
	TELEPORT_DESTROY,         # /DT
	RAIN_TOGGLE,              # /LLUVIA
	SET_CHAR_DESCRIPTION,     # /SETDESC
	FORCE_MIDI_TO_MAP,        # /FORCEMIDIMAP
	FORCE_WAVE_TO_MAP,        # /FORCEWAVMAP
	ROYAL_ARMY_MESSAGE,       # /REALMSG
	CHAOS_LEGION_MESSAGE,     # /CAOSMSG
	CITIZEN_MESSAGE,          # /CIUMSG
	CRIMINAL_MESSAGE,         # /CRIMSG
	TALK_AS_NPC,              # /TALKAS
	DESTROY_ALL_ITEMS_IN_AREA,# /MASSDEST
	ACCEPT_ROYAL_COUNCIL_MEMBER, # /ACEPTCONSE
	ACCEPT_CHAOS_COUNCIL_MEMBER, # /ACEPTCONSECAOS
	ITEMS_IN_THE_FLOOR,       # /PISO
	MAKE_DUMB,                # /ESTUPIDO
	MAKE_DUMB_NO_MORE,        # /NOESTUPIDO
	DUMP_IP_TABLES,           # /DUMPSECURITY
	COUNCIL_KICK,             # /KICKCONSE
	SET_TRIGGER,              # /TRIGGER
	ASK_TRIGGER,              # /TRIGGER with no args
	BANNED_IP_LIST,           # /BANIPLIST
	BANNED_IP_RELOAD,         # /BANIPRELOAD
	GUILD_MEMBER_LIST,        # /MIEMBROSCLAN
	GUILD_BAN,                # /BANCLAN
	BAN_IP,                   # /BANIP
	UNBAN_IP,                 # /UNBANIP
	CREATE_ITEM,              # /CI
	DESTROY_ITEMS,            # /DEST
	CHAOS_LEGION_KICK,        # /NOCAOS
	ROYAL_ARMY_KICK,          # /NOREAL
	FORCE_MIDI_ALL,           # /FORCEMIDI
	FORCE_WAVE_ALL,           # /FORCEWAV
	REMOVE_PUNISHMENT,        # /BORRARPENA
	TILE_BLOCKED_TOGGLE,      # /BLOQ
	KILL_NPC_NO_RESPAWN,      # /MATA
	KILL_ALL_NEARBY_NPCS,     # /MASSKILL
	LAST_IP,                  # /LASTIP
	CHANGE_MOTD,              # /MOTDCAMBIA
	SET_MOTD,                 # ZMOTD
	SYSTEM_MESSAGE,           # /SMSG
	CREATE_NPC,               # /ACC
	CREATE_NPC_WITH_RESPAWN,  # /RACC
	IMPERIAL_ARMOUR,          # /AI1 - 4
	CHAOS_ARMOUR,             # /AC1 - 4
	NAVIGATE_TOGGLE,          # /NAVE
	SERVER_OPEN_TO_USERS_TOGGLE, # /HABILITAR
	TURN_OFF_SERVER,          # /APAGAR
	TURN_CRIMINAL,            # /CONDEN
	RESET_FACTIONS,           # /RAJAR
	REMOVE_CHAR_FROM_GUILD,   # /RAJARCLAN
	REQUEST_CHAR_MAIL,        # /LASTEMAIL
	ALTER_PASSWORD,           # /APASS
	ALTER_MAIL,               # /AEMAIL
	ALTER_NAME,               # /ANAME
	TOGGLE_CENTINEL_ACTIVATED,# /CENTINELAACTIVADO
	DO_BACKUP,                # /DOBACKUP
	SHOW_GUILD_MESSAGES,      # /SHOWCMSG
	SAVE_MAP,                 # /GUARDAMAPA
	CLEAN_SOS,                # /BORRAR SOS
	SHOW_SERVER_FORM,         # /SHOW INT
	NIGHT,                    # /NOCHE
	KICK_ALL_CHARS,           # /ECHARTODOSPJS
	RELOAD_NPCS,              # /RELOADNPCS
	RELOAD_SERVER_INI,        # /RELOADSINI
	RELOAD_SPELLS,            # /RELOADHECHIZOS
	RELOAD_OBJECTS,           # /RELOADOBJ
	RESTART,                  # /REINICIAR
	RESET_AUTO_UPDATE,        # /AUTOUPDATE
	CHAT_COLOR,               # /CHATCOLOR
	IGNORED,                  # /IGNORADO
	CHECK_SLOT,               # /SLOT
	SET_INI_VAR,              # /SETINIVAR LLAVE CLAVE VALOR
	CREATE_PRETORIAN_CLAN,    # /CREARPRETORIANOS
	REMOVE_PRETORIAN_CLAN,    # /ELIMINARPRETORIANOS
	ENABLE_DENOUNCES,         # /DENUNCIAS
	SHOW_DENOUNCES_LIST,      # /SHOW DENUNCIAS
	MAP_MESSAGE,              # /MAPMSG
	SET_DIALOG,               # /SETDIALOG
	IMPERSONATE,              # /IMPERSONAR
	IMITATE,                  # /MIMETIZAR
	RECORD_ADD,
	RECORD_REMOVE,
	RECORD_ADD_OBS,
	RECORD_LIST_REQUEST,
	RECORD_DETAILS_REQUEST
}
