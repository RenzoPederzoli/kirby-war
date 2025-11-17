# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 game (GL Compatibility renderer). The game uses a 320x180 pixel art viewport with stretch mode.

## Code Generation & Documentation

When generating code, providing setup/configuration steps, or referencing library APIs, automatically use Context7 MCP tools to fetch up-to-date documentation. Resolve library IDs when nedded and retrieve docs without requiring explicit user requests. 

Library ID for Godot 4.4 documentation: /websites/godotengine_en_4_4
Library ID for Game Programming Patterns book: /websites/gameprogrammingpatterns

## Design Reference

When implementing larger features or architectural decisions, consult the Game Programming Patterns book:
- Main contents: Using Context7 MCP with library ID of /websites/gameprogrammingpatterns
