//
//  checkUpdate.swift
//  cmd-eikana
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

// MARK: - ReleaseInfo

struct ReleaseInfo {
  let version: String
  let description: String
  let releaseUrl: String
}

private struct GitHubReleaseResponse: Decodable {
  let tagName: String?
  let name: String?
  let htmlUrl: String?

  enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case name
    case htmlUrl = "html_url"
  }
}

// MARK: - JSON Parsing

func parseReleaseJSON(_ data: Data) -> ReleaseInfo? {
  do {
    let release = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)

    guard let tagName = release.tagName else {
      return nil
    }

    // tag_name から "v" プレフィックスを除去してバージョン番号を取得
    let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

    // versionが空の場合はnil
    if version.isEmpty {
      return nil
    }

    // リリース名を説明として使用
    let description = release.name ?? ""

    // リリースページのURL
    let releaseUrl =
      release.htmlUrl ?? "https://github.com/glyzinie/cmd-eikana/releases"

    return ReleaseInfo(version: version, description: description, releaseUrl: releaseUrl)
  } catch {
    return nil
  }
}

// MARK: - Check Update

func makeLatestReleaseRequest() -> URLRequest {
  let url = URL(string: "https://api.github.com/repos/glyzinie/cmd-eikana/releases/latest")!
  var request = URLRequest(url: url)
  request.timeoutInterval = 10
  request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
  request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
  request.setValue("cmd-eikana", forHTTPHeaderField: "User-Agent")
  return request
}

func fetchLatestRelease() async throws -> ReleaseInfo {
  let (data, response) = try await URLSession.shared.data(for: makeLatestReleaseRequest())

  guard let httpResponse = response as? HTTPURLResponse,
    (200..<300).contains(httpResponse.statusCode),
    let releaseInfo = parseReleaseJSON(data)
  else {
    throw URLError(.badServerResponse)
  }

  return releaseInfo
}

func checkUpdate(_ callback: (@MainActor @Sendable (_ isNewVer: Bool?) -> Void)? = nil) {
  Task {
    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

    do {
      let releaseInfo = try await fetchLatestRelease()
      let isAbleUpdate = compareVersions(releaseInfo.version, currentVersion)

      if isAbleUpdate {
        await MainActor.run {
          showUpdateAlert(releaseInfo)
        }
      }

      await MainActor.run {
        callback?(isAbleUpdate)
      }
    } catch {
      await MainActor.run {
        callback?(nil)
      }
    }
  }
}

@MainActor
func showUpdateAlert(_ releaseInfo: ReleaseInfo) {
  let alert = NSAlert()
  alert.messageText = "cmd-eikana ver.\(releaseInfo.version) が利用可能です"
  alert.informativeText = releaseInfo.description
  alert.addButton(withTitle: "Download")
  alert.addButton(withTitle: "Cancel")
  let ret = alert.runModal()

  if ret == NSApplication.ModalResponse.alertFirstButtonReturn {
    if let url = URL(string: releaseInfo.releaseUrl) {
      NSWorkspace.shared.open(url)
    }
  }
}

// セマンティックバージョニングで比較 (new > current なら true)
func compareVersions(_ newVersion: String, _ currentVersion: String) -> Bool {
  let newParts = newVersion.split(separator: ".").compactMap { Int($0) }
  let currentParts = currentVersion.split(separator: ".").compactMap { Int($0) }

  let maxLength = max(newParts.count, currentParts.count)
  let paddedNew = newParts + Array(repeating: 0, count: maxLength - newParts.count)
  let paddedCurrent = currentParts + Array(repeating: 0, count: maxLength - currentParts.count)

  for (newPart, currentPart) in zip(paddedNew, paddedCurrent) {
    if newPart > currentPart {
      return true
    } else if newPart < currentPart {
      return false
    }
  }

  return false  // 同じバージョン
}
