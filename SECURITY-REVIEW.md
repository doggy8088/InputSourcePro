# 安全審查報告 — InputSourcePro

**日期：** 2026-06-20
**範圍：** 整個 InputSourcePro macOS 應用程式碼庫（約 140 個 Swift 檔案）
**模式：** 唯讀審查 — 未修改任何程式碼。

## 摘要

本次審查的程式碼庫中未發現安全漏洞。

審查涵蓋 entitlements、Info.plist、持久層（CoreData + JSON 備份）、shell/AppleScript 執行路徑、網路呼叫、輔助使用/CGEvent 使用方式、URL 處理、檔案 I/O、`NSPredicate` 構造、`UserDefaults`、分散式通知與剪貼簿操作。

## 發現結果

| # | 嚴重性 | 檔案 | 行號 | 漏洞 | 信心度 |
|---|--------|------|------|------|--------|

**未發現安全漏洞。**

## 已驗證為安全的項目

下列項目在審查過程中已明確驗證為安全：

- **`runCommand`**（`Utilities/AppKit/NSString.swift`）— 在設計上屬於注入匯流點（`/bin/bash -c <原始字串>` 與未完整跳脫的 `osascript do shell script ... with administrator privileges`）。其唯一呼叫者（`CursorLagFixView.swift`）傳入的全是硬編碼指令範本，其中 `Bool` 內插只會產生 `"YES"`/`"NO"`。無使用者可控資料流入該匯流點，故目前無可利用路徑。
- **`NSPredicate`** — 所有使用處（`PreferencesVM+AppCustomization.swift:109,124`）皆採用參數化 `%@` 綁定。
- **設定備份匯入**（`SettingsBackup.swift`）— 使用 `JSONDecoder`（預設安全）於使用者選取的檔案，並帶有 `schemaVersion` 檢查；無程式碼執行或封存反序列化。
- **網路呼叫** — `AppDelegate.sendLaunchPing`、`FeedbackVM.sendFeedback`、`GeneralSettingsView.RefinePromotionCard` 皆透過 Alamofire/URLSession 走 HTTPS。ATS 保留安全預設值（無 `NSAppTransportSecurity` 覆寫）。
- **Sparkle 更新摘要**（`SUFeedURL`）— HTTPS，並已設定 EdDSA 公鑰（`SUPublicEDKey`）用於簽章驗證。
- **`NSAppleScriptEnabled`**（Info.plist）— 實際上為無作用；bundle 中無 `.sdef` 腳本定義檔存在。
- **CoreData URL 欄位**（`AppRule.url`）— 僅作為路徑讀回供 `NSWorkspace.icon(forFile:)` 使用，從未開啟/執行。
- **無自訂 URL scheme** — `CFBundleURLTypes` 不存在，故無外部 URL 進入攻擊面。
- **`CodableUserDefault`** — 使用 `JSONEncoder`/`JSONDecoder`，非舊版 `NSKeyedUnarchiver`。
- **加密輔助函式**（`Data+MD5.swift`、`Data+SHA256.swift`）— 僅用於非安全用途（圖示快取鍵／bundle-id 回退雜湊）。
- **日誌**（`ISPLogger`）— 僅在 DEBUG 模式，僅輸出診斷狀態，無憑證/PII。
- **分散式通知觀察器** — 僅訂閱已知系統通知（`screenIsLocked`、`kTISNotifySelectedKeyboardInputSourceChanged` 等）；不信任任何使用者可控的承載資料。