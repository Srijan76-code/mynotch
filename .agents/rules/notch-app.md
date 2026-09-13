---
trigger: always_on
---

# Project Rules — macOS Notch App

## Stack
- Target macOS 14+, Swift 6, SwiftUI with AppKit interop where needed.
- Distributed outside the App Store (Sparkle for updates).

## Libraries — use these, do not hand-roll
- Notch UI: DynamicNotchKit. Never hand-roll NSPanel positioning. See @/docs/DynamicNotchKit.md
- Global hotkeys: sindresorhus/KeyboardShortcuts. See @/docs/KeyboardShortcuts.md
- Persistence: sindresorhus/Defaults.
- Settings window: sindresorhus/Settings.
- Launch at login: sindresorhus/LaunchAtLogin-Modern.
- Animations: EmergeTools/Pow for expand/collapse transitions.
- SF Symbols: SFSafeSymbols (compile-checked).

## Conventions
- Prefer NSScreen.safeAreaInsets / auxiliaryTopLeftArea for notch geometry.
  Never use deprecated NSScreen APIs.
- New SwiftUI views: add `@ObserveInjection var inject` and `.enableInjection()`
  as the last body modifier (hot reload).
- Debug builds: com.apple.security.app-sandbox = false (required for InjectionIII).
  Re-enable sandbox for release.
- Use MenuBarExtra for any menu-bar item; control it via MenuBarExtraAccess.

## Behavior
- Before inventing an API, check the referenced @docs files.
- When a build fails, read the actual compiler error via XcodeBuildMCP and fix it.
- Keep notch window creation (AppKit) separate from hosted SwiftUI content.
