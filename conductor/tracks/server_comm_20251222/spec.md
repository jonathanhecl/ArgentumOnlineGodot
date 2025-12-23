# Specification: Communication with the 0.13.3 AO Libre Server

## 1. Overview
This track focuses on establishing a stable network connection between the Godot client and the Argentum Online 0.13.3 server (AO Libre). It involves implementing the TCP socket connection, handling the binary protocol for the initial handshake, and successfully processing login/error messages.

## 2. Goals
- Establish a TCP connection to the server.
- Implement the basic binary reader/writer compatible with Visual Basic 6 strings/integers.
- Successfully perform the client-server handshake.
- Send a login packet and receive a response (OK or Error).
- Handle disconnection gracefully.

## 3. Technical Requirements
- **Protocol:** AO 0.13.3 Binary Protocol.
- **Transport:** TCP/IP.
- **Godot Classes:** `StreamPeerTCP`.
- **Data Types:** 
    - 2-byte Integer (Little Endian).
    - Long (4 bytes).
    - ASCII Strings (prefixed with 2-byte length).
    - Byte arrays.

## 4. Key Components
- **ClientInterface (Autoload):** Manages the `StreamPeerTCP` connection.
- **GameProtocol (Autoload):** Encodes outgoing packets.
- **ProtocolHandler (Autoload):** Decodes incoming packets.
