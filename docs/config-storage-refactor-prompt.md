# ⚙️ Deye macOS — Ayar Deposunu `config.json` (`AppConfig`) Mimarisine Yükseltme Rehberi & Prompt'u

Bu doküman, `Deye Solar Monitor for macOS` (`deye-macos`) projesinde dağınık `UserDefaults` string anahtarları ile yönetilen ayar deposunu, `router-check-macos` projesinde uygulanan modern, tip güvenli ve merkezi **`config.json` (`AppConfig`)** mimarisine yükseltmek için hazırlanmış teknik analiz ve hazır AI Agent Prompt'unu içerir.

---

## 📌 Neden `UserDefaults` Yerine `config.json` (`AppConfig`)?

Mevcut `deye-macos` uygulamasında 12'den fazla ayar `userDefaults.set(...)` / `userDefaults.string(...)` gibi dağınık string anahtarlarla saklanmaktadır. Hatta `selectedDataCenter` gibi karmaşık modeller UserDefaults içerisine JSON Data blob'u olarak gömülmektedir.

### `config.json` Mimarisine Geçişin Sağlayacağı Kazanımlar:
1. **Tip Güvenliği (Compile-Time Type Safety):** Tüm konfigürasyon tek bir `struct AppConfig: Codable` çatısı altında toplanır. String anahtar yazım hataları (`deye_grid_power_threshold_w` vb.) tamamen ortadan kalkar.
2. **Tek Doğruluk Kaynağı (Single Source of Truth):** Ayarların varsayılan değerleri, minimum/maksimum sınırları ve doğrulamaları tek bir yerde (`AppConfig.swift`) tanımlanır.
3. **İnsan Tarafından Okunabilir ve Düzenlenebilir (Developer-Friendly):** İleri düzey kullanıcılar veya geliştiriciler `~/Library/Application Support/DeyeSolarMonitor/config.json` dosyasını Terminal veya VS Code üzerinden kolayca açıp inceleyebilir ve düzenleyebilir (`.prettyPrinted`, `.sortedKeys`).
4. **Veri Bütünlüğü (Atomic Writes):** `data.write(to: url, options: .atomic)` ile olası sistem kapanmalarında dosya bozulmaları önlenir.
5. **Geriye Dönük Uyumluluk (Seamless Migration):** Eski kullanıcıların ayarlarını kaybetmemesi için ilk açılışta `UserDefaults`'taki mevcut anahtarlar okunarak otomatik olarak `config.json`'a aktarılır.

> ⚠️ **Güvenlik Notu:** `appSecret`, `password` ve `accessToken` gibi hassas kimlik bilgileri `config.json` içine açık metin yazılmaz; mevcut `CredentialStore` (Keychain / korumalı depolama) içinde kalmaya devam eder.

---

## 🤖 Kopyalayıp Kullanabileceğiniz AI Agent / Geliştirici Prompt'u

Aşağıdaki prompt'u `deye-macos` projesinde çalışırken doğrudan AI asistanınıza iletebilirsiniz:

```markdown
### Görev: Deye macOS Ayar Deposunu UserDefaults'tan Type-Safe config.json (AppConfig) Mimarisine Yükseltme

Deye Solar Monitor (`deye-macos`) uygulamasındaki ayar deposunu, `router-check-macos` standartlarında merkezi bir `config.json` (`AppConfig`) mimarisine refactor etmeni istiyorum.

#### 1. Yeni Model: `DeyeMacOS/Models/AppConfig.swift`
Aşağıdaki yapıya sahip `public struct AppConfig: Codable, Sendable, Equatable` modelini oluştur:
- **Alanlar:**
  - `public var appId: String = ""`
  - `public var emailOrUsername: String = ""`
  - `public var selectedStationId: String? = nil`
  - `public var selectedDataCenter: DeyeDataCenter = .europe`
  - `public var refreshInterval: TimeInterval = 30` (varsayılan 30 saniye)
  - `public var menuBarDisplayMode: MenuBarDisplayMode = .flow`
  - `public var showMainWindowOnLaunch: Bool = false`
  - `public var gridImportThresholdW: Double = 50.0`
  - `public var gridExportThresholdW: Double = 50.0`
  - `public var batteryChargeThresholdW: Double = 50.0`
  - `public var batteryDischargeThresholdW: Double = 50.0`
- **Depolama Yolu (`configURL`):**
  - `~/Library/Application Support/DeyeSolarMonitor/config.json` dizinini otomatik kontrol edip oluşturan statik bir `configURL` tanımla.
- **Yükleme ve Geriye Dönük Uyumluluk (`load()`):**
  - Eğer `config.json` dosyası mevcutsa JSONDecoder ile çözüp döndür.
  - Eğer `config.json` dosyası henüz YOKSA (eski kullanıcı veya ilk kurulum):
    - `UserDefaults` üzerindeki mevcut legacy anahtarları (`deye_refresh_interval`, `deye_selected_datacenter`, `deye_grid_import_threshold_w`, `deye_show_main_window_on_launch` vb.) oku.
    - Bulunan değerlerle bir `AppConfig` oluştur ve `save()` çağırarak `config.json`'a ilk yazmayı yap.
- **Kaydetme (`save()`):**
  - JSONEncoder ile `[.prettyPrinted, .sortedKeys]` formatında atomik olarak (`.atomic`) `configURL`'e yaz.

#### 2. `DeyeMacOS/App/AppState.swift` Refactoring
- Dağınık `private enum Keys` içindeki konfigürasyon anahtarlarını temizle (sadece cache/snapshot anahtarları gerekirse kalabilir).
- `AppState` içinde merkezi ayar nesnesi tanımla:
  `@Published public var config: AppConfig`
- `loadStoredConfiguration()` metodunu güncelle:
  - `self.config = AppConfig.load()` çağır.
  - `DeyeAPI.shared.setDataCenter(config.selectedDataCenter)`'ı ayarla.
- Mevcut setter metodlarını `config` üzerinden güncelleyecek ve `config.save()` çağıracak şekilde sadeleştir:
  - `setRefreshInterval(_ interval: TimeInterval)` -> `config.refreshInterval = interval; config.save()`
  - `setMenuBarDisplayMode(_ mode: MenuBarDisplayMode)` -> `config.menuBarDisplayMode = mode; config.save()`
  - `setGridImportThreshold`, `setGridExportThreshold`, `setBatteryChargeThreshold`, `setBatteryDischargeThreshold` -> `config` değerlerini güncelle ve `config.save()`
  - `setShowMainWindowOnLaunch(_ value: Bool)` -> `config.showMainWindowOnLaunch = value; config.save()`
  - `setSelectedDataCenter(_ center: DeyeDataCenter)` -> `config.selectedDataCenter = center; config.save()`
- UI uyumluluğu için mevcut `@Published` property'leri ya `config`'in computed getter/setter'ları yap ya da `config` değiştikçe senkronize tut.

#### 3. İlgili Görünümlerin Kontrolü (`SettingsView.swift`, `LoginView.swift`)
- `SettingsView.swift` içindeki threshold ve data center picker bağlamalarının (binding) `appState.config` üzerinden kesintisiz çalıştığından emin ol.
- Giriş yapıldığında (`saveCredentials`) `appId` ve `emailOrUsername` alanlarının `appState.config` içine kaydedilip `config.save()` yapıldığını doğrula.

#### 4. Doğrulama ve Test
- `make clean && make build` çalıştırarak derleme hatalarını gider.
- Uygulamayı çalıştır (`make run`), Ayarlar'dan birkaç eşik değeri değiştir ve `~/Library/Application Support/DeyeSolarMonitor/config.json` dosyasının düzgün JSON formatında güncellendiğini doğrula:
  ```bash
  cat ~/Library/Application\ Support/DeyeSolarMonitor/config.json
  ```
- Uygulamayı yeniden başlatıp ayarların eksiksiz korunduğunu test et.
```

---

## 📂 Değişecek Dosyalar Özeti

| Dosya | Yapılacak İşlem |
| :--- | :--- |
| `DeyeMacOS/Models/AppConfig.swift` | **Yeni dosya:** `Codable` konfigürasyon modeli, dosya yönetimi ve `UserDefaults` migration mantığı |
| `DeyeMacOS/App/AppState.swift` | `UserDefaults` string anahtarları yerine `AppConfig`'i tek doğruluk kaynağı yapma |
| `DeyeMacOS/Views/SettingsView.swift` | Ayar ekranı kontrollerinin `appState.config` ile entegrasyonu |
| `DeyeMacOS/Views/LoginView.swift` | Hesap bilgilerinin `config` modeline entegrasyonu |
