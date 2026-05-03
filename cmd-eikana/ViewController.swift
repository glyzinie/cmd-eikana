//
//  ViewController.swift
//  cmd-eikana
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//  Copyright (c) 2025 Dominion525
//  Copyright (c) 2026 Wis
//

import Cocoa

@objc(ViewController)
class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  let userDefaults = UserDefaults.standard

  @IBOutlet weak var showIcon: NSButton!
  @IBOutlet weak var lunchAtStartup: NSButton!
  @IBOutlet weak var checkUpdateAtlaunch: NSButton!
  @IBOutlet weak var updateButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

    let showIconState = userDefaults.object(forKey: "showIcon") as? Int ?? 1
    showIcon.state = NSControl.StateValue(rawValue: showIconState)

    lunchAtStartup.state = NSControl.StateValue(
      rawValue: userDefaults.integer(forKey: "lunchAtStartup"))

    // GitHub Releases API対応済み
    checkUpdateAtlaunch.state = NSControl.StateValue(
      rawValue: userDefaults.integer(forKey: "checkUpdateAtlaunch") == 0 ? 0 : 1)
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }

  @IBAction func clickShowIcon(_ sender: AnyObject) {
    statusItem.isVisible = (showIcon.state == NSControl.StateValue.on)
    userDefaults.set(showIcon.state, forKey: "showIcon")
  }
  @IBAction func clickLunchAtStartup(_ sender: AnyObject) {
    setLaunchAtStartup(lunchAtStartup.state == NSControl.StateValue.on)
    userDefaults.set(lunchAtStartup.state, forKey: "lunchAtStartup")
  }
  @IBAction func clickCheckUpdateAtlaunch(_ sender: AnyObject) {
    userDefaults.set(checkUpdateAtlaunch.state, forKey: "checkUpdateAtlaunch")
  }
  @IBAction func test(_ sender: Any) {

  }

  @IBAction func checkUpdateButton(_ sender: AnyObject) {
    updateButton.isEnabled = false
    checkUpdate({ (isNewVer: Bool?) in
      self.updateButton.isEnabled = true
      if isNewVer == nil {
        let alert = NSAlert()

        alert.messageText = NSLocalizedString(
          "update.check.failed.message", comment: "Update check failure alert title")
        alert.informativeText = NSLocalizedString(
          "update.check.failed.informative", comment: "Update check failure alert body")

        alert.runModal()
      } else if isNewVer == false {
        let alert = NSAlert()

        alert.messageText = NSLocalizedString(
          "update.check.latest.message", comment: "Already latest version alert title")
        let version =
          Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        alert.informativeText = "ver.\(version)"

        alert.runModal()
      }
    })
  }
}
