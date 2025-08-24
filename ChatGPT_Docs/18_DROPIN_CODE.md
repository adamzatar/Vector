#(you dont have to copy any of the code in here just suggestions and tips or models but always make the files you put out as detailed and as senior-developer-level professional!)
# 18_DROPIN_CODE — Drop-in Swift Files

Copy these files into your Xcode project (use the suggested paths). They are self-contained and follow Vector’s policies (privacy-first, Apple-native, accessibility).

---

## 1) Services/Infra/Entitlements.swift

```swift
// File: Services/Infra/Entitlements.swift
import Foundation
import StoreKit

@MainActor
public final class Entitlements: ObservableObject {
    public static let shared = Entitlements()

    @Published public private(set) var isPro: Bool = false
    @Published public private(set) var products: [Product] = []

    private let productIDs = ["pro.monthly", "pro.lifetime", "tip.small", "tip.large"]
    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = listenForTransactions()
    }

    public func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            products = []
        }
        await refreshEntitlement()
    }

    public func product(id: String) -> Product? {
        products.first(where: { $0.id == id })
    }

    public func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    await refreshEntitlement()
                    return true
                }
                return false
            default:
                return false
            }
        } catch {
            return false
        }
    }

    public func restore() async {
        do { try await AppStore.sync() } catch { }
        await refreshEntitlement()
    }

    public func refreshEntitlement() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result {
                if t.productID == "pro.lifetime" || t.productType == .autoRenewable {
                    pro = true
                }
            }
        }
        isPro = pro
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let t) = update {
                    await t.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }
}


⸻

2) Services/Infra/Metrics.swift (local-only)

// File: Services/Infra/Metrics.swift
import Foundation

public enum MetricEvent: String, Codable {
    case account_added, sync_enabled, paywall_shown, pro_purchased, backup_exported
}

public struct Metrics {
    private static let filename = "metrics.json"

    public static func log(_ event: MetricEvent, context: [String:String] = [:]) {
        #if DEBUG
        print("📊 \(event.rawValue) \(context)")
        #endif
        var arr = (try? load()) ?? []
        var entry = context
        entry["ts"] = ISO8601DateFormatter().string(from: .init())
        entry["event"] = event.rawValue
        arr.append(entry)
        try? save(arr)
    }

    private static func url() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    private static func save(_ arr: [[String:String]]) throws {
        let data = try JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted])
        try data.write(to: url(), options: .atomic)
    }

    private static func load() throws -> [[String:String]] {
        let d = try Data(contentsOf: url())
        return (try JSONSerialization.jsonObject(with: d)) as? [[String:String]] ?? []
    }
}


⸻

3) Services/Crypto/TOTP.swift (RFC6238 + Base32)

// File: Services/Crypto/TOTP.swift
import Foundation
import CryptoKit

public enum HashAlgo: String, Codable, CaseIterable { case sha1, sha256, sha512 }

public struct TOTP: Codable, Equatable {
    public var secret: Data
    public var digits: Int
    public var period: Int
    public var algo: HashAlgo

    public init(secret: Data, digits: Int = 6, period: Int = 30, algo: HashAlgo = .sha1) {
        self.secret = secret; self.digits = digits; self.period = period; self.algo = algo
    }

    public func code(at date: Date = .init()) -> String {
        let counter = UInt64(floor(date.timeIntervalSince1970 / Double(period)))
        let hmac = Self.hmac(counter: counter, key: secret, algo: algo)
        let offset = Int(hmac.last! & 0x0f)
        let bin = (UInt32(hmac[offset] & 0x7f) << 24) |
                  (UInt32(hmac[offset+1]) << 16) |
                  (UInt32(hmac[offset+2]) << 8) |
                   UInt32(hmac[offset+3])
        let mod = Int(pow(10.0, Double(digits)))
        let otp = Int(bin) % mod
        return String(format: "%0*\(digits)d", digits, otp)
    }

    public func remainingSeconds(at date: Date = .init()) -> Int {
        let t = Int(date.timeIntervalSince1970)
        return period - (t % period)
    }

    private static func hmac(counter: UInt64, key: Data, algo: HashAlgo) -> [UInt8] {
        var msg = counter.bigEndian
        let body = withUnsafeBytes(of: &msg) { Data($0) }
        let skey = SymmetricKey(data: key)
        switch algo {
        case .sha1:   return Array(HMAC<Insecure.SHA1>.authenticationCode(for: body, using: skey))
        case .sha256: return Array(HMAC<SHA256>.authenticationCode(for: body, using: skey))
        case .sha512: return Array(HMAC<SHA512>.authenticationCode(for: body, using: skey))
        }
    }
}

// Base32 RFC4648 decode (padding optional)
public enum Base32 {
    private static let map: [Character: UInt8] = {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var m = [Character: UInt8]()
        for (i, c) in chars.enumerated() {
            m[c] = UInt8(i); m[Character(c.lowercased())] = UInt8(i)
        }
        return m
    }()

    public static func decode(_ s: String) -> Data? {
        var buffer: UInt32 = 0, bits: Int = 0
        var out = [UInt8]()
        for ch in s where ch != "=" {
            guard let val = map[ch] else { continue }
            buffer = (buffer << 5) | UInt32(val); bits += 5
            if bits >= 8 {
                bits -= 8
                out.append(UInt8((buffer >> UInt32(bits)) & 0xff))
            }
        }
        return Data(out)
    }
}


⸻

4) Services/Keychain/KeychainVault.swift (synchronizable)

// File: Services/Keychain/KeychainVault.swift
import Foundation
import Security

public enum KeychainError: Error { case unexpectedStatus(OSStatus), itemNotFound }

public struct KeychainVault {
    public static let service = "app.vector.vault"

    public static func save(key: String, data: Data) throws {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
            kSecValueData as String: data
        ]
        SecItemDelete(q as CFDictionary)
        let st = SecItemAdd(q as CFDictionary, nil)
        guard st == errSecSuccess else { throw KeychainError.unexpectedStatus(st) }
    }

    public static func load(key: String) throws -> Data {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let st = SecItemCopyMatching(q as CFDictionary, &item)
        guard st != errSecItemNotFound else { throw KeychainError.itemNotFound }
        guard st == errSecSuccess, let data = item as? Data else { throw KeychainError.unexpectedStatus(st) }
        return data
    }

    public static func delete(key: String) throws {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        let st = SecItemDelete(q as CFDictionary)
        guard st == errSecSuccess || st == errSecItemNotFound else { throw KeychainError.unexpectedStatus(st) }
    }
}


⸻

5) Services/ImportExport/BackupService.swift (PBKDF2 + AES-GCM)

// File: Services/ImportExport/BackupService.swift
import Foundation
import CryptoKit

public enum BackupError: Error { case crypto }

public struct BackupEnvelope: Codable, Equatable {
    public let salt: Data   // 16 bytes
    public let nonce: Data  // 12 bytes
    public let ciphertext: Data
    public let tag: Data
}

public struct BackupService {
    // PBKDF2-HMAC-SHA256 (iterations >= 150_000 recommended)
    static func pbkdf2(password: Data, salt: Data, iterations: Int, keyLength: Int) -> Data {
        precondition(iterations > 0 && keyLength > 0)
        let blockSize = 32 // SHA256
        let blocks = Int(ceil(Double(keyLength) / Double(blockSize)))
        var derived = Data(capacity: blocks * blockSize)

        for i in 1...blocks {
            var ctx = Data(); ctx.append(salt)
            var bi = UInt32(i).bigEndian
            ctx.append(Data(bytes: &bi, count: MemoryLayout<UInt32>.size))
            var u = HMAC<SHA256>.authenticationCode(for: ctx, using: SymmetricKey(data: password))
            var t = Data(u)
            if iterations > 1 {
                for _ in 2...iterations {
                    u = HMAC<SHA256>.authenticationCode(for: Data(u), using: SymmetricKey(data: password))
                    t = xor(t, Data(u))
                }
            }
            derived.append(t)
        }
        return derived.prefix(keyLength)
    }

    private static func xor(_ a: Data, _ b: Data) -> Data {
        var out = Data(count: min(a.count, b.count))
        out.withUnsafeMutableBytes { o in
            a.withUnsafeBytes { pa in b.withUnsafeBytes { pb in
                for i in 0..<out.count { o[i] = pa[i] ^ pb[i] }
            }}
        }
        return out
    }

    public static func exportJSON<T: Codable>(_ payload: T, passphrase: String) throws -> Data {
        let salt = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        let key  = pbkdf2(password: Data(passphrase.utf8), salt: salt, iterations: 150_000, keyLength: 32)
        let pt   = try JSONEncoder().encode(payload)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(pt, using: .init(data: key), nonce: nonce)
        let env = BackupEnvelope(salt: salt, nonce: Data(nonce), ciphertext: sealed.ciphertext, tag: sealed.tag)
        return try JSONEncoder().encode(env)
    }

    public static func importJSON<T: Codable>(_ type: T.Type, data: Data, passphrase: String) throws -> T {
        let env = try JSONDecoder().decode(BackupEnvelope.self, from: data)
        let key = pbkdf2(password: Data(passphrase.utf8), salt: env.salt, iterations: 150_000, keyLength: 32)
        let box = try AES.GCM.SealedBox(nonce: .init(data: env.nonce), ciphertext: env.ciphertext, tag: env.tag)
        let pt  = try AES.GCM.open(box, using: .init(data: key))
        return try JSONDecoder().decode(T.self, from: pt)
    }
}


⸻

6) Features/Paywall/Components/AppHeader.swift

// File: Features/Paywall/Components/AppHeader.swift
import SwiftUI

public struct AppHeader: View {
    public enum Size { case small, medium, large }
    let title: String?
    let subtitle: String?
    let size: Size

    public init(title: String? = "Vector", subtitle: String? = nil, size: Size = .medium) {
        self.title = title
        self.subtitle = subtitle
        self.size = size
    }

    public var body: some View {
        VStack(spacing: 8) {
            LogoMark(size: .medium)
                .shadow(radius: 8, y: 4)
                .padding(.top, size == .large ? 8 : 0)

            if let title {
                Text(title)
                    .font(size == .large ? Typography.titleL : Typography.titleM)
                    .accessibilityAddTraits(.isHeader)
            }
            if let subtitle {
                Text(subtitle)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}


⸻

7) Features/Paywall/Components/BenefitRow.swift

// File: Features/Paywall/Components/BenefitRow.swift
import SwiftUI

public struct BenefitRow: View {
    let system: String
    let title: String
    let subtitle: String
    public init(system: String, title: String, subtitle: String) {
        self.system = system; self.title = title; self.subtitle = subtitle
    }
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: system).imageScale(.large)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typography.body)
                Text(subtitle).font(Typography.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}


⸻

8) Features/Paywall/Components/PlanPicker.swift

// File: Features/Paywall/Components/PlanPicker.swift
import SwiftUI
import StoreKit

public enum ProPlan: Hashable { case monthly, lifetime }

public struct PlanPicker: View {
    @Binding var selected: ProPlan
    let monthlyPrice: String?
    let lifetimePrice: String?
    public init(selected: Binding<ProPlan>, monthlyPrice: String?, lifetimePrice: String?) {
        _selected = selected; self.monthlyPrice = monthlyPrice; self.lifetimePrice = lifetimePrice
    }
    public var body: some View {
        HStack(spacing: 12) {
            SelectCard(isSelected: selected == .monthly, title: "Monthly",
                       subtitle: monthlyPrice ?? "$0.99") { selected = .monthly }
            SelectCard(isSelected: selected == .lifetime, title: "Lifetime",
                       subtitle: lifetimePrice ?? "$14.99") { selected = .lifetime }
        }
        .accessibilityElement(children: .contain)
    }
}

public struct SelectCard: View {
    let isSelected: Bool
    let title: String
    let subtitle: String
    let onTap: () -> Void

    public init(isSelected: Bool, title: String, subtitle: String, onTap: @escaping () -> Void) {
        self.isSelected = isSelected; self.title = title; self.subtitle = subtitle; self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(title).font(Typography.body)
                Text(subtitle).font(Typography.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? BrandColor.surface : BrandColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : BrandColor.divider.opacity(0.6),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}


⸻

9) Features/Paywall/PaywallView.swift

// File: Features/Paywall/PaywallView.swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var ent: Entitlements
    @Environment(\.dismiss) private var dismiss

    enum Plan { case monthly, lifetime }
    @State private var selected: Plan = .monthly
    @State private var purchasing = false
    @State private var error: String?

    @State private var monthly: Product?
    @State private var lifetime: Product?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(title: "Vector Pro", subtitle: "Power features that stay private.", size: .large)

                VStack(alignment: .leading, spacing: 12) {
                    BenefitRow(system: "icloud", title: "iCloud Sync", subtitle: "Your codes on all devices")
                    BenefitRow(system: "lock.shield", title: "Encrypted Backups", subtitle: "Bring your codes anywhere")
                    BenefitRow(system: "applewatch", title: "Watch & Widgets", subtitle: "Faster 2FA at a glance")
                    BenefitRow(system: "square.grid.2x2", title: "Brand Icons & Bulk Import", subtitle: "Organize in seconds")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(BrandColor.surfaceSecondary))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(BrandColor.divider.opacity(0.6), lineWidth: 1))

                PlanPicker(selected: Binding(
                    get: { selected == .monthly ? .monthly : .lifetime },
                    set: { selected = ($0 == .monthly ? .monthly : .lifetime) }
                ), monthlyPrice: monthly?.displayPrice, lifetimePrice: lifetime?.displayPrice)

                PrimaryButton(purchasing ? "Purchasing…" : "Unlock Pro") {
                    Task { await buy() }
                }
                .disabled(purchasing || (selected == .monthly && monthly == nil) || (selected == .lifetime && lifetime == nil))

                Button("Restore Purchases") { Task { await ent.restore() } }
                    .buttonStyle(.bordered)

                Button("Maybe later") { dismiss() }
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)

                Text("No ads. No tracking. Cancel anytime.")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(BrandGradient.primary().ignoresSafeArea())
        .task {
            Metrics.log(.paywall_shown)
            await ent.loadProducts()
            monthly  = ent.product(id: "pro.monthly")
            lifetime = ent.product(id: "pro.lifetime")
        }
        .alert("Purchase Failed", isPresented: .constant(error != nil)) {
            Button("OK", role: .cancel) { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    private func buy() async {
        guard let product = (selected == .monthly ? monthly : lifetime) else { return }
        purchasing = true
        defer { purchasing = false }
        let ok = await ent.purchase(product)
        if ok {
            Metrics.log(.pro_purchased)
            dismiss()
        } else {
            error = "Purchase did not complete."
        }
    }
}


⸻

10) UI/Modifiers/PrivacySensitiveView.swift

// File: UI/Modifiers/PrivacySensitiveView.swift
import SwiftUI
import Combine

final class ScreenCaptureObserver: ObservableObject {
    @Published var isCaptured = UIScreen.main.isCaptured
    private var bag = Set<AnyCancellable>()
    init() {
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .map { _ in UIScreen.main.isCaptured }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isCaptured, on: self)
            .store(in: &bag)
    }
}

public struct PrivacySensitiveView<Content: View>: View {
    @StateObject private var capture = ScreenCaptureObserver()
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    public var body: some View {
        content()
            .privacySensitive()
            .overlay {
                if capture.isCaptured {
                    VisualEffectBlur()
                        .overlay(
                            Label("Hidden while recording", systemImage: "eye.slash")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        )
                        .transition(.opacity)
                }
            }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { }
}


⸻

11) Integration Snippets (Router / DI)

Paste where appropriate. These are snippets, not full files.

Presenting Paywall from any Pro gate (e.g., Settings toggles):

@State private var showPaywall = false
.environmentObject(Entitlements.shared) // at scene/root

// Gate:
let isPro = Entitlements.shared.isPro
if !isPro {
    showPaywall = true
    Metrics.log(.paywall_shown)
} else {
    // proceed with Pro action
}

// Sheet:
.sheet(isPresented: $showPaywall) { PaywallView().environmentObject(Entitlements.shared) }

Soft upsell after 2+ accounts on Settings entry:

.onAppear {
    if tokenCount >= 2 && !Entitlements.shared.isPro {
        // non-blocking suggestion; maybe show small banner that opens PaywallView
    }
}

Log metrics when enabling sync / exporting backup:

Metrics.log(.sync_enabled)
Metrics.log(.backup_exported, context: ["count":"\(tokens.count)"])


⸻

12) Notes
    •    All UI honors existing design tokens (BrandColor, BrandGradient, Typography, Spacing, PrimaryButton, SecondaryButton, LogoMark).
    •    Entitlements.shared is an ObservableObject; inject at the app root:

WindowGroup { AppRootView().environmentObject(Entitlements.shared) }


    •    StoreKit products must exist in App Store Connect with IDs:
pro.monthly, pro.lifetime, tip.small, tip.large.

EOF


