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
  ABank/Features/Mine/FinanceLedger/LedgerInsights.swift
  ABank/Core/Routing/AppRoute.swift
  ABank/Features/AllFeatures/Models/FeatureCatalog.swift
  ABank/Features/AllFeatures/Models/FeatureSearch.swift
  ABank/Features/AllFeatures/FeaturePreferencesStore.swift
  ABank/Features/Security/Models/SecuritySettings.swift
  ABank/Features/Security/SecuritySettingsStore.swift
  ABank/Features/BranchService/Models/BranchModels.swift
  ABank/Features/BranchService/Models/BranchCatalog.swift
  ABank/Features/BranchService/Models/BranchSchedule.swift
  ABank/Features/BranchService/CitySelectionStore.swift
  ABank/Features/BranchService/BranchServiceStore.swift
  ABank/Features/BranchService/Models/BranchCardSummary.swift
  ABank/Features/Benefits/Models/BenefitsModels.swift
  ABank/Features/Benefits/Models/BenefitsCatalog.swift
  ABank/Features/Benefits/Models/BenefitsRules.swift
  ABank/Features/Benefits/BenefitsStore.swift
  ABank/Features/Benefits/Models/BenefitsCardSummary.swift
  ABank/Features/WealthProduct/Models/WealthProductModels.swift
  ABank/Features/WealthProduct/Models/WealthProductCatalog.swift
  ABank/Features/WealthProduct/Models/WealthRules.swift
  ABank/Features/WealthProduct/Models/RiskAssessmentModels.swift
  ABank/Features/WealthProduct/RiskAssessmentStore.swift
  ABank/Features/Mine/FinanceLedger/FinanceLedgerStore+Wealth.swift
)
for check in banking transfer insights feature security branch benefits wealth; do
  if [[ $check == feature ]]; then
    check_file=scripts/check_feature_catalog.swift
  elif [[ $check == security ]]; then
    check_file=scripts/check_security_settings.swift
  elif [[ $check == branch ]]; then
    check_file=scripts/check_branch_services.swift
  elif [[ $check == benefits ]]; then
    check_file=scripts/check_benefits.swift
  elif [[ $check == wealth ]]; then
    check_file=scripts/check_wealth.swift
  else
    check_file="scripts/check_${check}_data.swift"
  fi
  task_binary="${TMPDIR:-/private/tmp}/abank-${check}-data-checks"
  xcrun swiftc -module-cache-path /private/tmp/abank-banking-module-cache \
    -swift-version 5 -default-isolation MainActor -parse-as-library \
    "${sources[@]}" "$check_file" -o "$task_binary"
  "$task_binary"
done
