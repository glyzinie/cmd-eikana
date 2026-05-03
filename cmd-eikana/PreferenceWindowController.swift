//
//  PreferenceWindowController.swift
//  cmd-eikana
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//  Copyright (c) 2025 Dominion525
//  Copyright (c) 2026 Wis
//

import Cocoa

@objc(PreferenceWindowController)
class PreferenceWindowController: NSWindowController, NSWindowDelegate {
  static func getInstance() -> PreferenceWindowController {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let controller =
      storyboard.instantiateController(withIdentifier: "Preference") as! PreferenceWindowController

    controller.window?.title = "cmd-eikana"

    return controller
  }

  func showAndActivate(_ sender: AnyObject?) {
    self.showWindow(sender)
    self.window?.makeKeyAndOrderFront(sender)
    NSApp.activate(ignoringOtherApps: true)
  }
  override func mouseDown(with event: NSEvent) {
    activeKeyTextField?.blur()
  }
}
