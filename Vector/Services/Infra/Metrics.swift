//
//  Metrics.swift
//  Vector
//
//  Created by Vector Build System on 8/23/25.
//  File: Services/Infra/Metrics.swift
//

import Foundation

/// All events we care about (local-only; no third-party).
public enum AppEvent: String, Codable, CaseIterable, Sendable {
    case account_added
    case sync_enabled
    case paywall_shown
    case pro_purchased
    case backup_exported
}

/// Minimal interface so we can swap implementations if needed.
public protocol Metrics: Sendable {
    func log(_ event: AppEvent, _ props: [String:String]?)
    func log(_ event: AppEvent)
}

/// Privacy-preserving, local-only metrics.
/// - Writes newline-delimited JSON to Documents/metrics.ndjson
/// - Also prints in DEBUG for quick dev feedback.
public final class LocalMetrics: Metrics {
    private let queue = DispatchQueue(label: "app.vector.metrics", qos: .utility)

    public init() {}

    public func log(_ event: AppEvent, _ props: [String:String]? = nil) {
        let payload = Self.makeRecord(event: event, props: props)
        #if DEBUG
        print("📊 \(payload)")
        #endif
        queue.async { [url = Self.fileURL()] in
            do {
                let data = (payload + "\n").data(using: .utf8)!
                if FileManager.default.fileExists(atPath: url.path) {
                    let handle = try FileHandle(forWritingTo: url)
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                } else {
                    try data.write(to: url, options: .atomic)
                }
            } catch {
                #if DEBUG
                print("⚠️ Metrics write failed:", error.localizedDescription)
                #endif
            }
        }
    }

    public func log(_ event: AppEvent) { log(event, nil) }

    // MARK: - Helpers

    private static func makeRecord(event: AppEvent, props: [String:String]?) -> String {
        let ts = ISO8601DateFormatter().string(from: Date())
        var dict: [String: Any] = ["ts": ts, "event": event.rawValue]
        if let props { for (k, v) in props { dict[k] = v } }
        if let json = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let line = String(data: json, encoding: .utf8) {
            return line
        }
        return #"{"ts":"\#(ts)","event":"\#(event.rawValue)"}"#
    }

    private static func fileURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("metrics.ndjson")
    }
}
