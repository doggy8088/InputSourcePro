<p align="center">
    <a href="https://inputsource.pro" target="_blank">
        <img height="200" src="https://inputsource.pro/img/app-icon.png" alt="Input Source Pro Logo">
    </a>
</p>

<h1 align="center">Input Source Pro</h1>

<p align="center">輕鬆切換與追蹤輸入法</p>

<p align="center">
    <a href="https://inputsource.pro" target="_blank">官方網站</a> ·
    <a href="https://inputsource.pro/changelog" target="_blank">版本紀錄</a> ·
    <a href="https://github.com/runjuu/InputSourcePro/discussions">討論區</a>
</p>

> Input Source Pro 是一套免費且開源的 macOS 小工具，專為常需在多種輸入法間切換的多語系使用者設計。它會依據目前啟用的應用程式，甚至你正在瀏覽的網站，自動切換輸入法，明顯提升工作效率與打字體驗。

<table>
    <tr>
        <td>
            <a href="https://inputsource.pro">
                <img src="./imgs/switch-keyboard-base-on-app.gif"  alt="Switch Keyboard Based on App" width="100%">
            </a>
        </td>
        <td>
            <a href="https://inputsource.pro">
                <img src="./imgs/switch-keyboard-base-on-browser.gif"  alt="Switch Keyboard Based on Browser" width="100%">
            </a>
        </td>
    </tr>
</table>

<hr />

<p align="center">
  <a href="https://refine.sh?utm_source=github&utm_medium=readme&utm_campaign=inputsourcepro">
    <img src="https://refine.sh/banner.png" width="800" />
  </a>
</p>

<p align="center">
    Meet my new app: <a href="https://refine.sh/" target="_blank">Refine</a>, a local Grammarly alternative that runs 100% offline 🤩
</p>

<hr />

## 功能

### 🥷 自動情境感知切換
- 可為每個應用程式
  設定預設輸入法。
- 使用瀏覽器時，可依網站設定輸入法（Safari、Chrome、Arc、Edge、Vivaldi、Opera、Brave、Firefox、Zen、Dia 及更多）。
- 在應用程式／網站之間切換時，自動完成輸入法切換。

### 🐈‍⬛ 優雅的輸入法指示器
- 以簡潔畫面指示目前使用中的輸入法。
- 可自訂，且設計上不會干擾操作。

### ✍️ 應用程式專用標點模式
為特定應用程式啟用「強制英文標點」，可讓跨語系輸入時標點符號保持一致。
- 即使目前輸入法預設輸出的是本地化或全形符號，也會自動輸入標準符號（`\` ` ~ - _ $ ^ , . ; ' " [ ]`）。
- 僅針對需要的應用程式啟用，例如程式碼編輯器或終端機。

### 🎛️ 應用程式專用功能鍵模式
依應用程式自動切換 macOS 功能鍵模式。
- 可指定某個應用程式使用 F1 ~ F12 的行為：
    - 標準功能鍵：行為為標準 F1 ~ F12 按鍵，適合 IDE（例如 VSCode）與遊戲。
    - 媒體鍵：改由按鍵上標示的媒體功能（如亮度、音量、播放）運作，適合日常一般使用。
- 若某個應用程式未設定覆蓋規則，會回退到系統全域預設。

### ⌨️ 自訂快捷鍵
透過以下方式切換輸入法：
- 鍵盤快捷鍵：使用一般組合鍵。
- 修飾鍵快捷鍵：使用單一或組合修飾鍵（例如 Shift、Command、Shift + Command），可設定單次按壓或連點兩下。

### 😎 其他功能

<a href="https://inputsource.pro">
    <img width="892" alt="image" src="https://github.com/user-attachments/assets/351e2ac9-27d8-402e-8739-21c3f604a3c1" />
</a>


## 安裝方式

### 使用 Homebrew

```bash
brew install --cask input-source-pro
```

### 手動下載
請至 [版本頁面](https://inputsource.pro/changelog) 下載最新版本。

## 贊助

本專案由所有支持我工作的贊助者共同成就：

<p align="center">
  <a href="https://github.com/sponsors/runjuu">
    <img src="https://github.com/runjuu/runjuu/raw/refs/heads/main/sponsorkit/sponsors.svg" alt="Logos from Sponsors" />
  </a>
</p>

## 貢獻方式

非常歡迎各類參與。無論是回報問題、提出功能建議，或是直接提交程式碼，都會對專案有實質幫助。

* 想了解詳細貢獻流程、專案設定與程式碼規範，請先閱讀 [Contributing Guidelines](CONTRIBUTING.md)。
* 問題回報：請先到 [GitHub Issues](https://github.com/runjuu/InputSourcePro/issues) 提交並先行查看既有問題。
* 功能提案與提問：有新的功能想法、問題或一般討論，請前往 [GitHub Discussions](https://github.com/runjuu/InputSourcePro/discussions)。
* 行為準則：本專案遵循 [Code of Conduct](CODE_OF_CONDUCT.md)，參與討論與提交前請先閱讀並遵守。

## 從原始碼建置
請先克隆本專案並使用最新版 Xcode 進行編譯：

```bash
git clone git@github.com:runjuu/InputSourcePro.git
```

完成後以 Xcode 開啟專案並執行 Build。🍻

## 星標紀錄

<a href="https://www.star-history.com/#runjuu/InputSourcePro&type=date&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=runjuu/InputSourcePro&type=date&theme=dark&legend=bottom-right" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=runjuu/InputSourcePro&type=date&legend=bottom-right" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=runjuu/InputSourcePro&type=date&legend=bottom-right" />
 </picture>
</a>

## 授權條款
Input Source Pro 使用 [GPL-3.0 License](LICENSE) 授權。 
EOF && git add README.md && git status --short