# ADR-02: Architecture

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

MVVM: View → ViewModel → Repository → Service (Flutter's official "app architecture" guide shape) + DebugDrive bridge

## Rationale

Matches the diagram; every user action is a ViewModel command callable from tests and agents

## Revisit when

No trigger defined.
