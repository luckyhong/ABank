# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This repository currently contains only a `README.md` — there is no Xcode project, source code, dependency manifest, or build tooling yet. There are no build/lint/test commands to document because none exist in the repo. Do not assume a project layout (e.g. `.xcodeproj`, `Package.swift`, `Podfile`, folder structure) is present until it has actually been added — check the working tree before relying on anything described below.

## Project purpose (from README.md)

ABank is a learning-only iOS project: a **frontend-UI-layer-only** implementation of a bank app, built to practice going from zero to a working UI/interaction structure. It does not implement real banking functionality — all data is intended to be fake/mocked. The stated goal is to build iOS development skill in:

- App architecture
- Modularization
- UI layout
- Naming conventions

## Working in this repo

- When the project is scaffolded (Xcode project/workspace, Swift Package, etc. added), update this file with real build/run/test commands (e.g. `xcodebuild` invocations, scheme names, how to run a single test) and the actual module/architecture layout.
- Since this is explicitly a UI-only learning project with fake data, do not add real networking, persistence of sensitive data, or backend integration — that would be out of scope for the stated goal.
