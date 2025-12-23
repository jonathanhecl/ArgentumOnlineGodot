# Plan: Communication with the 0.13.3 AO Libre Server

## Phase 1: Core Networking Foundation
This phase establishes the raw TCP connection and the basic tools for reading/writing the specific data types used by the AO protocol.

- [ ] Task: Create Networking Unit Tests Structure
    - **Goal**: Set up a test file to verify packet encoding/decoding logic.
    - **File**: `res://Tests/Unit/test_networking.gd`
    - **Description**: Create a test script using GDUnit4 or Godot's built-in testing to validate byte-level operations.

- [ ] Task: Implement `StreamPeerTCP` Wrapper in `ClientInterface`
    - **Goal**: Manage the raw connection state.
    - **File**: `res://engine/autoload/client_interface.gd`
    - **Description**: Implement `connect_to_server(host, port)`, `disconnect()`, and a `_process` loop to poll the connection status. Emit signals `connection_established`, `connection_lost`, `data_received`.

- [ ] Task: Implement Data Reading/Writing Utilities
    - **Goal**: Handle AO-specific data types (VB6 String compatibility, Little Endian integers).
    - **File**: `res://common/utils.gd` (or a new `PacketUtils` class)
    - **Description**: Add functions to read/write 16-bit integers, 32-bit integers, and length-prefixed strings. Ensure compatibility with the `StreamPeer` interface.

- [ ] Task: Conductor - User Manual Verification 'Core Networking Foundation' (Protocol in workflow.md)

## Phase 2: Handshake and Protocol Basics
This phase implements the specific message structure for the initial server communication.

- [ ] Task: Define Protocol Constants (0.13.3)
    - **Goal**: specific OpCodes for the version of the protocol.
    - **File**: `res://engine/autoload/consts.gd` (or `res://engine/enums/packet_headers.gd`)
    - **Description**: Add constants for `ClientPacketID` (e.g., LoginExistingChar, LoginNewChar) and `ServerPacketID` (e.g., Logged, Error).

- [ ] Task: Implement Handshake Logic
    - **Goal**: Send the initial version check/handshake packet.
    - **File**: `res://engine/autoload/protocol_write_to_server.gd`
    - **Description**: Create a function `write_login_existing_char(username, password)` that constructs the byte packet according to the 0.13.3 spec.

- [ ] Task: Implement Packet Parsing Loop
    - **Goal**: Continuously read incoming data and split it into valid packets.
    - **File**: `res://engine/autoload/protocol_handler.gd`
    - **Description**: Implement a buffer to accumulate incoming bytes. Process the buffer to extract full packets based on length headers (if applicable) or fixed sizes.

- [ ] Task: Conductor - User Manual Verification 'Handshake and Protocol Basics' (Protocol in workflow.md)

## Phase 3: Login Verification
This phase tests the full flow by attempting to log in.

- [ ] Task: Handle Server Responses (Logged / Error)
    - **Goal**: Decode the server's reply to the login attempt.
    - **File**: `res://engine/autoload/protocol_handler.gd`
    - **Description**: Implement handlers for `Logged` (Success) and `Error` (Failure) packets. Emit signals to the UI.

- [ ] Task: Integration Test - Server Connection
    - **Goal**: Verify against a live server or mock.
    - **File**: `res://Tests/Integration/test_server_login.gd`
    - **Description**: Script a test that connects to `localhost` (or defined IP), sends a dummy login, and asserts that a response (even an error) is received.

- [ ] Task: Conductor - User Manual Verification 'Login Verification' (Protocol in workflow.md)
