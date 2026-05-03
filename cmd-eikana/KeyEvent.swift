//
//  KeyEvent.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

@preconcurrency import Cocoa
@preconcurrency import CoreGraphics
@preconcurrency import ApplicationServices

@MainActor var activeAppsList: [AppData] = []
@MainActor var exclusionAppsList: [AppData] = []

@MainActor var exclusionAppsDict: [String: String] = [:]

@MainActor
class KeyEvent: NSObject {
  var keyCode: CGKeyCode?
  var isExclusionApp = false
  let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String

  override init() {
    super.init()
  }

  func start() {
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(KeyEvent.setActiveApp(_:)),
      name: NSWorkspace.didActivateApplicationNotification,
      object: nil)

    // Input Monitoring権限のチェック (macOS 10.15+)
    if #available(macOS 10.15, *) {
      if !CGPreflightListenEventAccess() {
        CGRequestListenEventAccess()
      }
    }

    // Accessibility権限のチェック
    let options: CFDictionary = ["AXTrustedCheckOptionPrompt": true] as NSDictionary

    if !AXIsProcessTrustedWithOptions(options) {
      // アクセシビリティに設定されていない場合、設定されるまでループで待つ
      Timer.scheduledTimer(
        timeInterval: 1.0,
        target: self,
        selector: #selector(KeyEvent.watchAXIsProcess(_:)),
        userInfo: nil,
        repeats: true)
    } else {
      self.watch()
    }
  }

  @objc func watchAXIsProcess(_ timer: Timer) {
    // macOS 10.15+ではInput Monitoring権限も確認
    if #available(macOS 10.15, *) {
      if AXIsProcessTrusted() && CGPreflightListenEventAccess() {
        timer.invalidate()
        self.watch()
      }
    } else {
      if AXIsProcessTrusted() {
        timer.invalidate()
        self.watch()
      }
    }
  }

  @objc func setActiveApp(_ notification: NSNotification) {
    let app = notification.userInfo!["NSWorkspaceApplicationKey"] as! NSRunningApplication

    if let name = app.localizedName, let id = app.bundleIdentifier {
      isExclusionApp = exclusionAppsDict[id] != nil

      if id != bundleId && !isExclusionApp {
        activeAppsList = activeAppsList.filter { $0.id != id }
        activeAppsList.insert(AppData(name: name, id: id), at: 0)

        if activeAppsList.count > 10 {
          activeAppsList.removeLast()
        }
      }
    }
  }

  func watch() {
    // マウスのドラッグバグ回避のため、NSEventとCGEventを併用
    // CGEventのみでやる方法を捜索中
    let nsEventMaskList: NSEvent.EventTypeMask = [
      .leftMouseDown,
      .leftMouseUp,
      .rightMouseDown,
      .rightMouseUp,
      .otherMouseDown,
      .otherMouseUp,
      .scrollWheel,
    ]

    NSEvent.addGlobalMonitorForEvents(matching: nsEventMaskList) { _ in
      self.keyCode = nil
    }

    NSEvent.addLocalMonitorForEvents(matching: nsEventMaskList) { (event: NSEvent) -> NSEvent? in
      self.keyCode = nil
      return event
    }

    let eventMaskList = [
      CGEventType.keyDown.rawValue,
      CGEventType.keyUp.rawValue,
      CGEventType.flagsChanged.rawValue,
      //            CGEventType.leftMouseDown.rawValue,
      //            CGEventType.leftMouseUp.rawValue,
      //            CGEventType.rightMouseDown.rawValue,
      //            CGEventType.rightMouseUp.rawValue,
      //            CGEventType.otherMouseDown.rawValue,
      //            CGEventType.otherMouseUp.rawValue,
      //            CGEventType.scrollWheel.rawValue,
      UInt32(NX_SYSDEFINED),  // Media key Event
    ]
    var eventMask: UInt32 = 0

    for mask in eventMaskList {
      eventMask |= (1 << mask)
    }

    let observer = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: {
          (
            proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
            refcon: UnsafeMutableRawPointer?
          ) -> Unmanaged<CGEvent>? in
          if let observer = refcon {
            let mySelf = Unmanaged<KeyEvent>.fromOpaque(observer).takeUnretainedValue()
            return MainActor.assumeIsolated {
              mySelf.eventCallback(proxy: proxy, type: type, event: event)
            }
          }
          return Unmanaged.passUnretained(event)
        },
        userInfo: observer
      )
    else {
      print("failed to create event tap")
      exit(1)
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
  }

  func eventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<
    CGEvent
  >? {
    if isExclusionApp {
      return Unmanaged.passUnretained(event)
    }

    if let mediaKeyEvent = MediaKeyEvent(event) {
      return mediaKeyEvent.keyDown ? mediaKeyDown(mediaKeyEvent) : mediaKeyUp(mediaKeyEvent)
    }

    switch type {
    case CGEventType.flagsChanged:
      let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

      if modifierMasks[keyCode] == nil {
        return Unmanaged.passUnretained(event)
      }
      return event.flags.rawValue & modifierMasks[keyCode]!.rawValue != 0
        ? modifierKeyDown(event) : modifierKeyUp(event)

    case CGEventType.keyDown:
      return keyDown(event)

    case CGEventType.keyUp:
      return keyUp(event)

    default:
      self.keyCode = nil

      return Unmanaged.passUnretained(event)
    }
  }

  func keyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    #if DEBUG
      // print("keyCode: \(KeyboardShortcut(event).keyCode)")
      print(KeyboardShortcut(event).toString())
    #endif

    self.keyCode = nil

    if let keyTextField = activeKeyTextField {
      keyTextField.shortcut = KeyboardShortcut(event)
      keyTextField.stringValue = keyTextField.shortcut!.toString()

      return nil
    }

    let conversion = convertEvent(event)
    if conversion.matched {
      return conversion.event.map { Unmanaged.passUnretained($0) }
    }

    return Unmanaged.passUnretained(event)
  }

  func keyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    self.keyCode = nil

    let conversion = convertEvent(event)
    if conversion.matched {
      return conversion.event.map { Unmanaged.passUnretained($0) }
    }

    return Unmanaged.passUnretained(event)
  }

  func modifierKeyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    #if DEBUG
      print(KeyboardShortcut(event).toString())
    #endif

    self.keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

    if let keyTextField = activeKeyTextField, keyTextField.isAllowModifierOnly {
      let shortcut = KeyboardShortcut(event)

      keyTextField.shortcut = shortcut
      keyTextField.stringValue = shortcut.toString()
    }

    return Unmanaged.passUnretained(event)
  }

  func modifierKeyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    if activeKeyTextField != nil {
      self.keyCode = nil
    } else if self.keyCode == CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)) {
      if let convertedEvent = convertEvent(event).event {
        KeyboardShortcut(convertedEvent).postEvent()
      }
    }

    self.keyCode = nil

    return Unmanaged.passUnretained(event)
  }

  func mediaKeyDown(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
    #if DEBUG
      print(
        KeyboardShortcut(
          keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode), flags: mediaKeyEvent.flags
        ).toString())
    #endif

    self.keyCode = nil

    if let keyTextField = activeKeyTextField {
      if keyTextField.isAllowModifierOnly {
        keyTextField.shortcut = KeyboardShortcut(
          keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode),
          flags: mediaKeyEvent.flags)
        keyTextField.stringValue = keyTextField.shortcut!.toString()
      }

      return nil
    }

    let mediaKeyCode = CGKeyCode(1000 + mediaKeyEvent.keyCode)
    let conversion = convertEvent(
      mediaKeyEvent.event, keyCode: mediaKeyCode, mediaKeyEvent: mediaKeyEvent)
    if conversion.matched {
      if let event = conversion.event {
        print(KeyboardShortcut(event).toString())

        print(event.type == CGEventType.keyDown)
        event.post(tap: CGEventTapLocation.cghidEventTap)
      }
      return nil
    }

    return Unmanaged.passUnretained(mediaKeyEvent.event)
  }

  func mediaKeyUp(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
    return Unmanaged.passUnretained(mediaKeyEvent.event)
  }

  func convertEvent(
    _ event: CGEvent,
    keyCode: CGKeyCode? = nil,
    mediaKeyEvent: MediaKeyEvent? = nil
  ) -> (matched: Bool, event: CGEvent?) {
    var event = event

    if event.type.rawValue == UInt32(NX_SYSDEFINED) {
      guard let mediaKeyEvent = mediaKeyEvent ?? MediaKeyEvent(event) else {
        return (false, nil)
      }
      let flags = mediaKeyEvent.flags
      event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
      event.flags = flags
    }

    let shortcht = KeyboardShortcut(event)

    func convertedEvent(_ mappings: KeyMapping) -> CGEvent? {
      if mappings.output.keyCode == 999 {
        // 999 is Disable
        return nil
      }

      event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mappings.output.keyCode))
      event.flags = CGEventFlags(
        rawValue: (event.flags.rawValue & ~mappings.input.flags.rawValue)
          | mappings.output.flags.rawValue
      )

      return event
    }

    if let mappingList = shortcutList[keyCode ?? shortcht.keyCode] {
      for mappings in mappingList where shortcht.isCover(mappings.input) {
        return (true, convertedEvent(mappings))
      }
    }
    return (false, nil)
  }
}

let modifierMasks: [CGKeyCode: CGEventFlags] = [
  54: CGEventFlags.maskCommand,
  55: CGEventFlags.maskCommand,
  56: CGEventFlags.maskShift,
  60: CGEventFlags.maskShift,
  59: CGEventFlags.maskControl,
  62: CGEventFlags.maskControl,
  58: CGEventFlags.maskAlternate,
  61: CGEventFlags.maskAlternate,
  63: CGEventFlags.maskSecondaryFn,
  57: CGEventFlags.maskAlphaShift,
]
