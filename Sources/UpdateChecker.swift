import AppKit
import Foundation

/// GitHub version notices only: never downloads or executes an update.
final class UpdateChecker {
    static let shared = UpdateChecker()
    static let repository = "andyforfun168/KuroCatAndy"
    static let releasesURL = URL(string: "https://github.com/\(repository)/releases/latest")!
    private let defaults = UserDefaults.standard
    private var checking = false
    private var timer: Timer?
    var automatic: Bool {
        get { defaults.object(forKey: "KuroCat.Update.Automatic") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "KuroCat.Update.Automatic") }
    }
    static func version(_ text: String) -> [Int]? {
        let raw = text.hasPrefix("v") ? String(text.dropFirst()) : text
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        var values: [Int] = []
        for p in parts {
            guard !p.isEmpty, p.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }),
                  let value = Int(p), value <= 1_000_000 else { return nil }
            values.append(value)
        }
        return values
    }
    static func newer(_ remote: String, than current: String) -> Bool {
        guard let r = version(remote), let c = version(current) else { return false }
        return c.lexicographicallyPrecedes(r)
    }
    static func stableTag(_ data: Data) -> String? {
        guard data.count <= 262144,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["draft"] as? Bool == false, json["prerelease"] as? Bool == false,
              let tag = json["tag_name"] as? String, version(tag) != nil else { return nil }
        return tag
    }
    func start() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.check(manual: false) }
        timer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { _ in self.check(manual: false) }
    }
    func check(manual: Bool) {
        guard !checking else { return }
        if !manual {
            guard automatic else { return }
            let last = defaults.double(forKey: "KuroCat.Update.LastCheck")
            guard Date().timeIntervalSince1970 - last >= 24 * 3600 else { return }
        }
        checking = true
        defaults.set(Date().timeIntervalSince1970, forKey: "KuroCat.Update.LastCheck")
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3.5"
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repository)/releases/latest")!)
        request.setValue("KuroCat/\(current)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = 15
        config.httpShouldSetCookies = false
        let session = URLSession(configuration: config)
        session.dataTask(with: request) { data, response, error in
            let tag: String?
            if error == nil, (response as? HTTPURLResponse)?.statusCode == 200, let data {
                tag = Self.stableTag(data)
            } else { tag = nil }
            DispatchQueue.main.async {
                self.checking = false
                if !manual && !self.automatic { return }
                guard let tag else {
                    if manual { self.show(title: "暂时无法检查更新", message: "请稍后重试，或打开 GitHub Release 查看。", download: true) }
                    return
                }
                if Self.newer(tag, than: current) {
                    if !manual && self.defaults.string(forKey: "KuroCat.Update.NotifiedTag") == tag { return }
                    self.defaults.set(tag, forKey: "KuroCat.Update.NotifiedTag")
                    self.show(title: "KuroCat 有新版本 \(tag)", message: "当前版本 \(current)。请先退出旧版，再下载并替换应用；原有设置会保留。", download: true)
                } else if manual {
                    self.show(title: "未发现更新", message: "当前版本 \(current)。", download: false)
                }
            }
            session.finishTasksAndInvalidate()
        }.resume()
    }
    private func show(title: String, message: String, download: Bool) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        if download { alert.addButton(withTitle: "打开下载页面") }
        alert.addButton(withTitle: download ? "稍后" : "好")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn && download { NSWorkspace.shared.open(Self.releasesURL) }
    }
}
