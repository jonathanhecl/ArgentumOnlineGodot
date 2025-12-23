# Tech Stack - Argentum Online Godot

## Core Engine
- **Godot Engine 4.5:** Using the GL Compatibility renderer for broad hardware support.

## Programming Language
- **GDScript:** The primary language for game logic, UI, and networking.

## Architecture
- **Scene-based Hierarchy:** Standard Godot pattern for organizing game objects and UI.
- **Autoload Singletons:** Centralized management for persistent systems:
    - `GameAssets`: Asset management and loading.
    - `ClientInterface`: Networking and server communication.
    - `GameProtocol` & `ProtocolHandler`: Implementation of the AO 0.13.3 binary protocol.
    - `Global`: Global state management.
    - `HotkeyConfig`: User-defined input handling.

## Assets & Resources
- **Original AO Assets:** Direct use or conversion of original Gfx, Sfx, and Init data files.
- **Godot Resources:** Use of `.tscn` and `.gd` files for scene and script management.
