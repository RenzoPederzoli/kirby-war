# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 game (GL Compatibility renderer). The game uses a 320x180 pixel art viewport with stretch mode.

## Code Generation & Documentation

When generating code, providing setup/configuration steps, or referencing library APIs, automatically use Context7 MCP tools to fetch up-to-date documentation. Resolve library IDs and retrieve docs without requiring explicit user requests.

## Design Reference

When implementing larger features or architectural decisions, consult the Game Programming Patterns book:
- Main contents: https://gameprogrammingpatterns.com/contents.html
- Use WebFetch to retrieve specific chapters when designing systems like:
  - State machines (State pattern)
  - Object pooling (Object Pool pattern)
  - Event systems (Observer pattern)
  - Component architecture (Component pattern)
