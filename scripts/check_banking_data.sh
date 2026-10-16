#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
sources=(
  ABank/Shared/Utilities/BankingDateContext.swift
  ABank/Features/Transfer/Models/TransferSimulationModels.swift
  ABank/Features/Mine/Models/FinanceLedgerModels.swift
  ABank/Features/Mine/Models/MineModels.swift
  ABank/Features/Mine/Models/AssetLiabilityModels.swift
  ABank/Features/MyAccount/Models/MyAccountModels.swift
  ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift
)
for check in banking transfer; do
  task_binary="${TMPDIR:-/private/tmp}/abank-${check}-data-checks"
  xcrun swiftc -module-cache-path /private/tmp/abank-banking-module-cache \
    -swift-version 5 -default-isolation MainActor -parse-as-library \
    "${sources[@]}" "scripts/check_${check}_data.swift" -o "$task_binary"
  "$task_binary"
done
