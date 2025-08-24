# chatgpt_docs/12_PERF_A11Y_BUDGETS.md
# Vector — Performance & Accessibility Budgets (Authoritative)

Goal: **fast, smooth, readable**. This file sets hard budgets for runtime, memory, and accessibility.
All features must meet these numbers on **iPhone 12 / iOS 17** or better (unless stated).

---

## 1) Performance Budgets (User-Visible)

| Surface / Action                               | Budget (P50 / P95)                 | Notes / Measurement |
|---|---|---|
| **Cold launch → first interactive frame**      | ≤ **700 ms** / **1100 ms**         | Disable debug logs; measure with Instruments “App Launch”. |
| **Route switch (Splash→Intro→Vault)**          | ≤ **180 ms** / **250 ms**           | Transition = `.easeInOut(0.18)`, avoid layout thrash. |
| **Vault list scroll (100 tokens)**             | ≤ **4 ms** avg frame, no jank       | Avoid expensive modifiers in rows; render async images off-main if added. |
| **Code tick (per 1s update)**                  | ≤ **1.5 ms** on main                | Diff-only updates; no full-list refresh. |
| **QR scanner start**                           | ≤ **350 ms** camera warmup          | Preconfigure session off-main; show lightweight overlay. |
| **Backup export (500 tokens)**                 | ≤ **1.2 s** end-to-end              | PBKDF2 150k iters; streaming JSON encode. |
| **Backup import (500 tokens)**                 | ≤ **1.5 s**                         | Streaming decode; validate incrementally. |
| **Widget timeline load**                       | ≤ **20 ms** provider                | Precompute in app; share via App Group file snapshot. |
| **Watch app reachability & render**            | ≤ **300 ms**                        | Send precomputed payloads. |

**Power budget:** No tight loops on main; background crypto on utility QoS.

---

## 2) Memory Budgets

- **Steady-state app:** ≤ **90 MB** resident on Vault with 100 tokens.
- **Peak while backup/export:** ≤ **150 MB** (then return to ≤ 90 MB).
- **Widget/Watch extensions:** ≤ **20 MB** working set.
- **No image caching** unless we add brand icons (then cap ≤ 10 MB with LRU).

---

## 3) I/O & Storage

- **Keychain-only** for secrets (synchronizable).  
- **Backups**: single JSON envelope (AES-GCM) typically **< 200 KB** for 100 tokens.  
- **Disk writes:** coalesce settings writes; no log spam.  
- **Clipboard auto-clear:** timer ≤ **20 s**, cancels on app background.

---

## 4) Accessibility Budgets (WCAG & HIG)

**Targets**
- **Contrast:** Body text WCAG **AA ≥ 4.5:1**; icons/secondary ≥ 3:1.  
- **Dynamic Type:** Support **XS–XXXL** without truncation of critical info or clipped layouts.  
- **Tap targets:** **≥ 44×44 pt** for all interactive elements.
- **VoiceOver:** Every token row reads:  
  “_GitHub, you@example.com. Code **123 456**. **12 seconds** remaining. Button: Copy code_”.
- **Reduce Motion:** Disable non-essential animations; keep **≤ 120 ms** on essentials.
- **Reduce Transparency:** Avoid frosted backgrounds; fall back to solid surfaces.
- **Localization expansion:** Allow **30%** string growth; no hard-coded widths.

---

## 5) Profiling & Verification Playbook

### A. Instruments Recipes
- **App Launch:** _Time Profiler_ + _Animation Hitches_. Check cold start budget.
- **Scrolling Vault:** _Core Animation_ “FPS” + _Time Profiler_. Look for hot modifiers.
- **Crypto/Backup:** _CPU Profiler_ with signposts around PBKDF2/AES.
- **Memory:** _Allocations_ → take heap snapshots before/after backup.

### B. In-App Signposts (use for local runs)
```swift
import os.signpost

let perfLog = OSLog(subsystem: "app.vector", category: .pointsOfInterest)
os_signpost(.begin, log: perfLog, name: "Backup Export")
/* … work … */
os_signpost(.end,   log: perfLog, name: "Backup Export")

C. Frame-Time Probe (debug-only)

#if DEBUG
import QuartzCore
final class FrameProbe: ObservableObject {
    private var display: CADisplayLink?
    private var last: CFTimeInterval = 0
    func start() {
        display = CADisplayLink(target: self, selector: #selector(tick))
        display?.add(to: .main, forMode: .common)
    }
    func stop() { display?.invalidate(); display = nil }
    @objc private func tick(_ link: CADisplayLink) {
        let dt = last == 0 ? 0 : (link.timestamp - last)
        last = link.timestamp
        if dt > (1.0/50.0) { print("⚠️ Frame over 20ms: \(Int(dt*1000))ms") }
    }
}
#endif


⸻

6) Accessibility Implementation Snippets

A. Dynamic Type & Text Scaling

Text("Vector Pro")
  .font(.title2)                   // use semantic fonts
  .minimumScaleFactor(0.85)        // last resort
  .lineLimit(2)

B. VoiceOver Labels & Values

TimeRing(progress: progress)
  .accessibilityLabel("Time remaining")
  .accessibilityValue("\(secondsRemaining) seconds")
  .accessibilityTraits(.updatesFrequently)

Button(role: .none) { onCopy() } label: {
  Image(systemName: "doc.on.doc")
}
.accessibilityLabel("Copy code")

C. Reduced Motion / Transparency

let anim = UIAccessibility.isReduceMotionEnabled ? nil : Animation.easeInOut(duration: 0.12)
withAnimation(anim) { /* state change */ }

View()
.background(
  UIAccessibility.isReduceTransparencyEnabled
  ? Color.black.opacity(0.2)
  : .ultraThinMaterial
)

D. Minimum Tap Target

.contentShape(Rectangle())
.frame(minWidth: 44, minHeight: 44)


⸻

7) Acceptance Checklists

A. Performance (per screen)
    •    Launch ≤ 700/1100 ms on iPhone 12 (P50/P95)
    •    Route switch ≤ 180/250 ms
    •    Scroll 100 tokens at 60 FPS (≤ 4 ms avg frame)
    •    Code tick ≤ 1.5 ms main
    •    Backup export ≤ 1.2 s (500 tokens)
    •    Import ≤ 1.5 s (500 tokens)
    •    No layout jumps on Dynamic Type XXL
    •    Memory steady ≤ 90 MB; peak ≤ 150 MB

B. Accessibility
    •    Contrast AA on all text; links distinguishable without color alone
    •    VoiceOver order logical (title → value → actions)
    •    All interactive items ≥ 44×44 pt
    •    Reduce Motion honored (no parallax/large scale pops)
    •    Reduce Transparency honored (solid fallbacks)
    •    Localization passes German/Arabic pseudo with 30% expansion
    •    Token row VO reads issuer, account, code, time remaining, actions

⸻

8) “Red Flags” to Eliminate
    •    ❌ Heavy view modifiers inside List rows (.shadow, .blur, multiple .overlay)
    •    ❌ Recalculating TOTP for every row on every tick → compute once, publish
    •    ❌ Long-running work on main (PBKDF2/AES/IO)
    •    ❌ Animations > 250 ms or springy bounces on core flows
    •    ❌ Images without fixed sizes (causes layout thrash)
    •    ❌ Custom fonts for code digits (monospaced SF Symbols recommended)

⸻

9) Team Playbook
    1.    Before code review: run Instruments with a 60-second scroll/click script; attach PNG screens from Accessibility Inspector.
    2.    Add a perf note in PR: launch time delta, frame stats, memory delta.
    3.    Guard rails in code: #if DEBUG frame probe toggle in Vault to catch jank early.
    4.    Fail the PR if any critical checklist box is unchecked.

⸻

10) QA Matrix (what to test every release)
    •    iPhone 12 / 15 Pro, iOS 17–18
    •    Text sizes: XS, L, XXL, XXXL
    •    Settings: Reduce Motion on/off; Reduce Transparency on/off
    •    Languages: en-US, de-DE (expansion), ar (RTL smoke)
    •    Screen recording ON → Vault blurs; widgets remain tap-to-reveal
    •    Backup with 500 tokens on device thermal state “Nominal” and “Fair”

⸻

11) Roadmap Enhancements
    •    Precompute and cache next code + expiry per token; publish with Combine timer.
    •    Incremental “diff” updates for visible cells only (identity via token ID).
    •    Optional Argon2id (if added via vetted library) with tunable memory/time.
    •    UITests that assert AX labels verbatim for top flows.

⸻

TL;DR
    •    Speed: < 0.7s launch, < 0.18s route switches, 60 FPS list, ≤ 1.2s 500-token backup.
    •    Memory: < 90 MB steady, < 150 MB peak.
    •    A11y: AA contrast, Dynamic Type to XXXL, VO complete, reduced motion honored.
    •    Ship only when green on this page.


