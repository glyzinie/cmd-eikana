//
//  toggleLaunchAtStartup.swift
//  cmd-eikana
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//  Copyright (c) 2025 Dominion525
//  Copyright (c) 2026 Wis
//

// ログイン項目に追加、またはそこから削除するための関数

import Cocoa
import ServiceManagement

@MainActor private let loginItemService = SMAppService.loginItem(
  identifier: "net.cmd-eikana-helper")

/// バージョンアップ時に自動起動設定を再登録すべきか判定する
/// - Parameters:
///   - lastVersion: 前回起動時のバージョン（初回起動時はnil）
///   - currentVersion: 現在のバージョン
///   - launchAtStartupEnabled: 自動起動設定がオンか
/// - Returns: 再登録すべきならtrue
func shouldReregisterLaunchAtStartup(
  lastVersion: String?,
  currentVersion: String?,
  launchAtStartupEnabled: Bool
) -> Bool {
  guard lastVersion != currentVersion else { return false }
  return launchAtStartupEnabled
}

@MainActor func setLaunchAtStartup(_ enabled: Bool) {
  do {
    if enabled {
      guard loginItemService.status != .enabled && loginItemService.status != .requiresApproval
      else {
        print("Login item is already registered: \(loginItemService.status)")
        return
      }
      try loginItemService.register()
      print("Successfully registered login item.")
    } else {
      guard loginItemService.status == .enabled || loginItemService.status == .requiresApproval
      else {
        print("Login item is already unregistered.")
        return
      }
      try loginItemService.unregister()
      print("Successfully unregistered login item.")
    }
  } catch {
    print("Failed to update login item: \(error)")
  }
}
