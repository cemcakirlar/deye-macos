# 🪟 Deye macOS — Pencere Yönetimi ve Başlangıç Görünürlüğü İyileştirme Rehberi & Prompt'u

Bu doküman, `Deye Solar Monitor for macOS` (`deye-macos`) uygulamasındaki pencere yönetimini, `router-check-macos` projesinde uygulanan modern **`WindowAccessor` + `WindowManager` + `NSWindowDelegate` (`orderOut`)** mimarisine yükseltmek için hazırlanmış teknik analiz ve hazır AI Agent Prompt'unu içerir.

---

## 📌 Mevcut Durum Analizi ve Yaşanan Problemler

Mevcut `deye-macos` uygulamasında ana pencerenin açılışta gizlenmesi ve yönetimi şu şekilde çalışmaktadır:
1. **Global Arama ve Yarış Durumu (Race Condition):** `AppDelegate.applicationDidFinishLaunching` ve `MainDashboardView.onAppear` içinde `NSApplication.shared.windows` dizisi üzerinde döngü kurularak başlık (`"Deye Solar"`) veya kimlik (`"main"`) ile pencere aranıp `window.close()` çağrılmaktadır.
2. **Ekranda Yanıp Sönme (Flicker / Pop-in):** SwiftUI pencereyi çizmeye başladığında `AppDelegate` henüz pencereyi bulamamış olabilir veya `onAppear` çalışana kadar pencere ekranda yarım saniye görünüp kaybolabilir.
3. **Pencereyi Yok Etme (`close`) vs Gizleme (`orderOut`):** `window.close()` pencereyi ve altındaki SwiftUI hiyerarşisini bellekten yok eder. Menü çubuğundan tekrar "Aç" dendiğinde SwiftUI'ın `openWindow(id: "main")` ile her şeyi sıfırdan oluşturması gerekir (durum kaybı ve render gecikmesi).
4. **Kırmızı Kapatma Butonu (X):** Kullanıcı pencere üzerindeki kırmızı (X) butonuna bastığında pencere yok edilir; arkada çalışmaya devam eden bir menü çubuğu uygulaması için beklenen davranış pencerenin yok edilmesi değil, yalnızca ekrandan gizlenmesidir.

---

## 🎯 Hedef Mimari (`router-check-macos` Standardı)

1. **`WindowAccessor` (`NSViewRepresentable`):** SwiftUI hiyerarşisindeki gerçek `NSView`'ın `viewDidMoveToWindow` delegesini dinleyerek ilgili `NSWindow` örneğini ekrana çizilmeden hemen önce yakalar.
2. **`WindowManager` Servisi:**
   - Yakalanan pencere referansını `weak var mainWindow: NSWindow?` olarak tutar.
   - `NSWindowDelegate` uygulayarak `windowShouldClose` olayında `return false` dönüp `window.orderOut(nil)` çağırır (X butonuna basıldığında pencere yok edilmez, gizlenir).
   - Başlangıçta gizli başlama tercihi (`showMainWindowOnLaunch == false`) aktifse, pencere ilk yakalandığı an `orderOut(nil)` ile titreşimsiz gizlenir.
   - Menü çubuğundan açma istendiğinde `makeKeyAndOrderFront` ve `activate(ignoringOtherApps: true)` ile **sıfır gecikmeyle** ekrana getirilir.

---

## 🤖 Kopyalayıp Kullanabileceğiniz AI Agent / Geliştirici Prompt'u

Aşağıdaki prompt'u `deye-macos` projesinde çalışırken doğrudan AI asistanınıza iletebilirsiniz:

```markdown
### Görev: Deye macOS Pencere Yönetimi ve Başlangıç Görünürlüğünü WindowManager Mimarisine Yükseltme

Deye Solar Monitor (`deye-macos`) uygulamasındaki pencere yönetimini, modern AppKit + SwiftUI `WindowManager` ve `WindowAccessor` mimarisine refactor etmeni istiyorum.

#### 1. Yeni Servis: `DeyeMacOS/Services/WindowManager.swift`
Aşağıdaki yeteneklere sahip `@MainActor public final class WindowManager: NSObject, NSWindowDelegate, @unchecked Sendable` sınıfı oluştur:
- `public static let shared = WindowManager()` singleton.
- `public weak var mainWindow: NSWindow?` ve `public weak var appState: AppState?`.
- `public var isTerminating: Bool = false`.
- `private var hasAppliedStartupVisibility: Bool = false`.
- `public func register(window: NSWindow, appState: AppState)` fonksiyonu:
  - `mainWindow` ve `appState` referanslarını kaydet.
  - `window.delegate = self` ve `window.isReleasedWhenClosed = false` ayarla.
  - Eğer `!hasAppliedStartupVisibility`:
    - `hasAppliedStartupVisibility = true` yap.
    - `appState.showMainWindowOnLaunch == false` ise `window.orderOut(nil)` çağırarak pencereyi ekranda titreşmeden anında gizle.
- `public func showMainWindow()` fonksiyonu:
  - Eğer `mainWindow` varsa: minimize edilmişse `deminiaturize`, ardından `makeKeyAndOrderFront(nil)` ve `orderFrontRegardless()`.
  - Yoksa `NSApp.windows` üzerinde fallback yap.
  - `NSApplication.shared.activate(ignoringOtherApps: true)` çağır.
- `public func hideMainWindow()` fonksiyonu: `mainWindow?.orderOut(nil)`.
- `public func toggleMainWindow()` fonksiyonu.
- `NSWindowDelegate` uygulaması:
  - `windowShouldClose(_ sender: NSWindow) -> Bool`: Eğer `isTerminating` ise `true` dön. Değilse `sender.orderOut(nil)` çağırıp `return false` dön (kırmızı X butonu pencereyi yok etmek yerine gizlesin).
  - `windowDidMiniaturize`, `windowDidDeminiaturize`, `windowDidBecomeKey` olaylarını dinle.
- Dosyanın altına `public struct WindowAccessor: NSViewRepresentable` ve `WindowObserverView: NSView` ekleyerek `viewDidMoveToWindow` üzerinden `NSWindow` referansını yakala.

#### 2. `DeyeMacOS/Views/MainDashboardView.swift` Güncellemesi
- `onAppear { AppDelegate.handleInitialWindowVisibility() }` kodunu kaldır.
- `MainDashboardView` kök görünümünün arka planına şu modifier'ı ekle:
  ```swift
  .background(
      WindowAccessor { window in
          WindowManager.shared.register(window: window, appState: appState)
      }
  )
  ```

#### 3. `DeyeMacOS/Views/MenuBarPopoverView.swift` Güncellemesi
- `private func openMainWindow()` içindeki döngülü `NSApp.windows` kodunu ve `openWindow(id: "main")` karmaşasını kaldır.
- Doğrudan `WindowManager.shared.showMainWindow()` çağır.

#### 4. `DeyeMacOS/App/DeyeMacOSApp.swift` Güncellemesi
- `AppDelegate` içindeki eski `handleInitialWindowVisibility()` statik metodunu ve `hasHandledAppLaunch` mantığını temizle.
- `applicationShouldHandleReopen` içine `WindowManager.shared.showMainWindow(); return true` ekle (Dock ikonuna tıklandığında pencere açılsın).
- `applicationShouldTerminate` içine `WindowManager.shared.isTerminating = true` ekle.

#### 5. Doğrulama
- `make clean && make build` çalıştırarak hatasız derlendiğini doğrula.
- `showMainWindowOnLaunch` ayarı kapalıyken uygulama başlatıldığında pencerenin ekranda hiç görünmeden sessizce menü çubuğuna yerleştiğini kontrol et.
- Pencere açıkken kırmızı (X) butonuna basıldığında uygulamanın kapanmadığını, sadece gizlendiğini ve menü çubuğundan tekrar tıklandığında anında belirdiğini doğrula.
```

---

## 📂 Değişecek Dosyalar Özeti

| Dosya | Yapılacak İşlem |
| :--- | :--- |
| `DeyeMacOS/Services/WindowManager.swift` | **Yeni dosya:** `WindowManager` ve `WindowAccessor` bileşenleri |
| `DeyeMacOS/App/DeyeMacOSApp.swift` | `AppDelegate` içindeki arama döngülerini ve geçici çözümleri temizleme |
| `DeyeMacOS/Views/MainDashboardView.swift` | `WindowAccessor` modifier'ı ekleme ve `onAppear` temizliği |
| `DeyeMacOS/Views/MenuBarPopoverView.swift` | `openMainWindow()` metodunu `WindowManager.shared.showMainWindow()`'a bağlama |
