# ABank

[English](README.md) · [中文](README.zh-CN.md)

A frontend-only iOS learning project that recreates a banking-style app UI from scratch—modular architecture, a shared design system, and maintainable page structure—powered entirely by mock data.

> **Learning project only. Not a real banking app.** No live services, network calls, or sensitive data persistence.

---

## Contents

- [Purpose](#purpose)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Naming Conventions](#naming-conventions)
- [Roadmap](#roadmap)
- [Contributing & Disclaimer](#contributing--disclaimer)

---

## Purpose

| Aspect | Detail |
|--------|--------|
| Scope | UI / interaction layer only—no real networking, payments, or risk control |
| Data | In-memory models driven by `MockDataProvider` and local Stores |
| Goals | Readable, extensible code for practicing architecture, modularity, layout, and naming |

Good for practicing:

- Feature-based module splits and navigation flows
- A unified design system (color / typography / spacing / corner radius)
- Complex banking-style layouts with SnapKit (code-only Auto Layout)
- Multi-screen flows and local state refresh with mock data

---

## Tech Stack

| Item | Choice |
|------|--------|
| Language | Swift 5 |
| Platform | iOS 15.6+ |
| UI | UIKit · programmatic layout |
| Layout | [SnapKit](https://github.com/SnapKit/SnapKit) `~> 5.6` |
| Dependencies | CocoaPods |
| Entry point | `ABank.xcworkspace` (do not open `.xcodeproj` directly) |

---

## Features

### Main Tab Bar

| Tab | Module | Status |
|-----|--------|--------|
| Home | `Features/Home` | Done |
| Wealth | `Features/Finance` | Done |
| Life | `Features/Life` | Done |
| News | `Features/News` | Done |
| Mine | `Features/Mine` | Core flows done |

Secondary screens such as **Transfer** (`Features/Transfer`) and **My Account** (`Features/MyAccount`) are reachable from Home and related entry points.

### Module Overview

<details>
<summary><strong>Home</strong></summary>

Account overview, search bar, notice ticker, shortcuts, grid menu, hot activities, wealth picks, branch services, consumer-protection content, and more.

</details>

<details>
<summary><strong>Wealth (Finance)</strong></summary>

Login prompt card, function grid, hotspots, featured products, steady-growth section, income-first picks, popular deposits, bond index, spare-money zone, and learning content.

</details>

<details>
<summary><strong>Life</strong></summary>

Search, banners, life-service grid, colorful campaigns, and masonry-style content.

</details>

<details>
<summary><strong>News</strong></summary>

Recommend / Follow tabs, search, feed list, topics, and banners.

</details>

<details>
<summary><strong>Mine</strong></summary>

Personal hub with the following submodules:

| Submodule | Path | Capabilities |
|-----------|------|----------------|
| Customer Info | `CustomerInfo` | Profile view/edit, mobile change, tax-identity declaration (local Store) |
| Assets & Liabilities | `AssetLiability` | Summary cards, category lists, tips and announcements |
| Income & Expense | `IncomeExpense` | List, detail, date / account / category filters and pickers |
| My Loans | `MyLoan` | Overview, contracts, details, due / repayment / prepayment, usage records |
| Finance Ledger | `FinanceLedger` | `FinanceLedgerStore` aggregates assets/liabilities and monthly flows |

</details>

<details>
<summary><strong>Transfer · My Account</strong></summary>

- **Transfer**: Notice banner, primary action card, function grid, recent payees (page-level UI; full transfer flow can be extended)
- **My Account**: Debit card display, credit-card promo, open-account entry; debit card detail and account transaction query with filters

</details>

---

## Project Structure

```text
ABank/
├── Core/
│   ├── Base/BaseViewController.swift   # Nav / Loading / Toast base
│   └── MainTabBarController.swift      # Five-tab shell
├── Features/
│   ├── Home/
│   ├── Finance/                        # Wealth
│   ├── Life/
│   ├── News/
│   ├── Mine/                           # Includes customer info, A&L, etc.
│   ├── Transfer/
│   └── MyAccount/
├── Shared/
│   ├── DesignSystem/                   # Color / Font / Spacing / CornerRadius
│   └── Utilities/                      # UIView, String helpers
├── Data/
│   └── MockDataProvider.swift          # Mock data entry point
└── Assets.xcassets/
```

Feature modules are typically organized as `ViewController` + `Views/` + `Models/`. Larger domains such as `Mine` split further by business subdirectory.

---

## Architecture

```text
┌─────────────────────────────────────────┐
│           Features (by domain)          │
│   ViewController  →  Views  →  Models   │
└──────────────────┬──────────────────────┘
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
  Core/Base    Shared/DS     Data / Store
  base UX      design tokens  mocks & local state
```

- **Layers**: `ViewController` + custom `View` + `Models` + `MockDataProvider` / `*Store`
- **Design system**: Agriculture Bank–inspired green palette; shared colors, fonts, spacing, and radii (`abank*` prefix)
- **Navigation**: each tab wraps a `UINavigationController`; child screens are pushed
- **State**: customer info and finance ledger use local Stores and refresh on `viewWillAppear`

---

## Getting Started

### Requirements

- macOS + Xcode (iOS 15.6 SDK or later)
- [CocoaPods](https://cocoapods.org/)

### Install & Run

```bash
cd /path/to/ABank
export LANG=en_US.UTF-8   # optional, if pod encoding issues occur
pod install
open ABank.xcworkspace
```

Pick a simulator or device in Xcode and press `Cmd + R`. All data is local—no network required.

> Failed `pod install` runs are usually network-related; retry or configure a proxy.

---

## Naming Conventions

| Kind | Convention | Example |
|------|------------|---------|
| Types | `PascalCase` | `MineViewController` |
| Variables / properties | `camelCase` | `pageData` |
| Views | `View` / `Cell` / `Header` suffix | `MineProfileHeaderView` |
| Controllers | `ViewController` suffix | `LoanDetailViewController` |
| Stores | `SomethingStore` | `CustomerInfoStore` |
| Design tokens | `abank*` prefix | `.abankPrimary` |

Keep models under each feature’s `Models/` folder by domain.

---

## Roadmap

### Done

- [x] Project skeleton, CocoaPods, SnapKit, design system, base view controller
- [x] TabBar: Home / Wealth / Life / News / Mine
- [x] Full UI for Home, Wealth, Life, and News
- [x] Mine: profile, customer info, assets & liabilities, income & expense, my loans
- [x] Transfer page and My Account (debit detail, account query)
- [x] Finance ledger Store and mock-driven screens

### Planned

- [ ] Complete transfer flow (confirm, result screens, etc.)
- [ ] Login / registration onboarding
- [ ] Dark mode, localization, accessibility
- [ ] Richer empty / error mock scenarios
- [ ] Motion and micro-interaction polish

---

## Contributing & Disclaimer

Issues and PRs that improve structure and UI quality are welcome. The goal is to get the interface right and keep the architecture clean.

**Disclaimer**: For learning and discussion only. All UI and data are simulated. This project does not provide financial services and is not affiliated with any real bank.
