# Singlemon

Singlemon is a macOS menu bar app that keeps your mouse cursor locked to the main display. It is meant for multi-monitor setups where you want your primary screen to be mouse-only, while keeping a side monitor available for mouse-free apps like a terminal.

## What it does

- Installs a global mouse event tap and clamps the cursor to the main display bounds.
- Warps the cursor back to the main display if you launch it while the mouse is on another screen.
- Runs as a lightweight menu bar toggle with automatic launch at login.

## Requirements

- macOS (uses Accessibility permissions for mouse control).
- Accessibility access granted to Singlemon in System Settings.

## Usage

1. Launch the app.
2. When prompted, grant Accessibility access in Privacy & Security.
3. Use the menu bar item to turn the mouse wall on or off.

When the wall is enabled, your mouse will stay on the main monitor, leaving side monitors free for keyboard-only apps.
