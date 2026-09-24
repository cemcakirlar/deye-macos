# Deye macOS

Deye solar inverter ve ev enerji depolama sistemleri için modern, hafif ve yerel (native) macOS takip uygulaması.

DeyeCloud Open API (EU veri merkezi) ile entegre çalışır; anlık üretim, tüketim, şebeke ve batarya metriklerini hem modern bir macOS masaüstü penceresinde hem de menü çubuğunda (Menu Bar) anlık olarak gösterir.

---

## Özellikler

- **Menü Çubuğu (Menu Bar) Takibi:**
  - macOS üst menü çubuğunda anlık güneş üretimi ve batarya doluluk oranı: `☀️ 2.4 kW · 🔋 %85`
  - Farklı görünüm modları: *Güneş ve Batarya*, *Sadece Güneş*, *Tam Özet*, *Sadece İkon*.
  - Menü simgesine tıklandığında açılan hızlı ve zarif popover kontrol paneli.
- **Tam Ekran / Bağımsız Masaüstü Penceresi (Dual Mode):**
  - İster menü çubuğundan kompakt takip edin, ister bağımsız bir pencerede büyük ve detaylı dashboard olarak açın.
  - Canlı enerji akış diyagramı (Güneş PV -> İnvertör -> Şebeke / Ev / Batarya yön okları ve anlık güçler).
- **Anlık Enerji Akışı:**
  - Güneş üretimi (PV - W / kW)
  - Batarya doluluk oranı (SOC %) ve dinamik durum çubuğu
  - Batarya şarj / deşarj gücü (W)
  - Ev tüketimi (W)
  - Şebeke alış / satış gücü (W)
- **Güvenlik (Security-first):**
  - Hassas veriler (App Secret, hesap şifresi, API erişim token'ı) cihazın korumalı uygulama alanında (sandbox storage - Android DataStore eşdeğeri) saklanır; harici şifre istemi oluşturmaz.
  - Şifreler DeyeCloud API protokolüne uygun olarak cihazda SHA-256 hex formatına dönüştürülür.
  - App Sandbox kuralı ile yalnızca giden ağ bağlantısına izin verilir (`com.apple.security.network.client`).
- **Çoklu İstasyon / Santral Desteği:**
  - Hesaba bağlı birden fazla santral varsa otomatik tespit edilir ve kullanıcıya seçim imkanı sunulur (`StationPickerView`).
  - Tek santral varsa otomatik olarak bağlanılır.
- **Otomatik & Manuel Yenileme:**
  - 1 dk, 3 dk, 5 dk, 10 dk, 15 dk veya 30 dk periyotlarla arka planda otomatik yenileme.
  - Tek tıkla anında veri yenileme butonu.
  - Bayat veri (stale - 15 dakikadan eski veri) uyarısı ve son güncelleme zamanı göstergesi.

---

## Teknoloji Yığını

| Bileşen | Teknoloji |
|---|---|
| **Dil** | Swift 6 (Strict Concurrency Safe) |
| **Arayüz (UI)** | SwiftUI (macOS 14.0+) |
| **Bileşenler** | MenuBarExtra (.window), WindowGroup, SF Symbols |
| **Ağ & İstemci** | URLSession (async/await), Codable JSON |
| **Şifreleme & Hash** | CryptoKit (SHA-256), Security.framework (Keychain Services) |
| **Derleme Araçları** | Xcode Projesi (`DeyeMacOS.xcodeproj`) & Swift Package Manager (`Package.swift`) |

---

## Proje Yapısı

```
deye-macos/
├── scripts/
│   ├── build.sh                 # Debug/Release derleme betiği
│   ├── run.sh                   # Derleme ve başlatma betiği
│   ├── stop.sh                  # Çalışan uygulamayı sonlandırma betiği
│   ├── install.sh               # /Applications dizinine kurma betiği
│   └── logs.sh                  # Canlı sistem loglarını dinleme betiği
├── Makefile                     # make run / stop / install kısayolları
├── DeyeMacOS.xcodeproj/         # Standart Xcode proje dosyası
│   └── project.pbxproj
├── DeyeMacOS/
│   ├── App/
│   │   ├── DeyeMacOSApp.swift   # App lifecycle, Window & MenuBarExtra
│   │   └── AppState.swift       # ObservableObject, durum ve otomatik yenileme yönetimi
│   ├── Models/
│   │   ├── DeyeModels.swift     # API DTO modelleri, Credentials, MenuBarDisplayMode
│   │   └── StationSnapshot.swift# Normalize edilmiş anlık enerji modeli
│   ├── Services/
│   │   ├── DeyeAPI.swift        # URLSession async/await istemcisi (401 auto-retry)
│   │   ├── CredentialStore.swift# Güvenli yerel veri saklama (Android DataStore eşdeğeri)
│   │   ├── CryptoHelper.swift   # CryptoKit SHA-256 hex
│   │   └── Formatters.swift     # Güç (W/kW), yüzde ve zaman biçimlendiricileri
│   ├── Views/
│   │   ├── MainDashboardView.swift  # Büyük pencere dashboard arayüzü
│   │   ├── MenuBarLabelView.swift   # Menü çubuğundaki canlı etiket (☀️/🔋)
│   │   ├── MenuBarPopoverView.swift # Menü çubuğuna tıklandığında açılan popover
│   │   ├── LoginView.swift          # İlk giriş ekranı
│   │   ├── StationPickerView.swift  # Çoklu santral seçim ekranı
│   │   ├── SettingsView.swift       # Ayarlar (Cmd + ,)
│   │   └── Components/
│   │       ├── EnergyCard.swift     # Enerji kartları bileşeni
│   │       ├── BatterySOCView.swift # Batarya doluluk oranı çubuğu
│   │       └── PowerFlowDiagram.swift # Canlı enerji akış diyagramı
│   └── Resources/
│       ├── Info.plist               # Uygulama meta bilgileri
│       ├── DeyeMacOS.entitlements   # App Sandbox & Network Client izinleri
│       └── Assets.xcassets/         # Uygulama ikonları ve tema renkleri
├── Package.swift                # Swift Package Manager desteği
└── README.md
```

---

## Derleme, Çalıştırma ve Kurulum

Xcode arayüzüne bağımlı kalmadan, doğrudan bu IDE / terminal içerisinden projenizi yönetebilirsiniz:

### 1. Terminal / IDE Kısayolları (Make)

```bash
# Debug derleyip uygulamayı arka planda başlatır (Varsayılan):
make run

# Terminal ön planında başlatıp canlı logları doğrudan görmek için:
make run-fg

# Çalışan Deye Solar Monitor uygulamasını durdurur:
make stop

# Sadece Debug derlemesi yapar:
make build

# Sadece Release (Prod) derlemesi yapar:
make release

# Canlı sistem loglarını dinler:
make logs

# Derleme önbelleğini temizler:
make clean
```

### 2. Kendi Makinenize Kalıcı Kurulum (Prod / Release)

Xcode veya terminal açmaya gerek kalmadan uygulamayı macOS'un kendi uygulamaları (`/Applications`) arasına kurup normal bir Mac uygulaması gibi kullanmak için:

```bash
make install
# veya: ./scripts/install.sh --release
```

Bu komut:
1. Uygulamayı en yüksek performanslı **Release (Prod)** modunda derler.
2. Yerel macOS ad-hoc kod imzalamasını yapar ve Gatekeeper karantinasını temizler.
3. Uygulamayı **`/Applications/Deye Solar Monitor.app`** dizinine kurar.
4. macOS LaunchServices'e kaydeder; böylece **Spotlight (Cmd + Space)** ve **Launchpad** üzerinden hemen bulunabilir.
5. Uygulamayı başlatır.

> **İpucu:** Mac açıldığında otomatik başlamasını isterseniz: *Sistem Ayarları -> Genel -> Giriş Öğeleri* menüsünden `Deye Solar Monitor` uygulamasını ekleyebilirsiniz.

---

## İlk Giriş & Yapılandırma

Uygulamayı ilk açtığınızda sizi giriş ekranı karşılar:

1. **App ID:** DeyeCloud Developer Portalı'ndan aldığınız App ID.
2. **App Secret:** DeyeCloud Developer Portalı'ndan aldığınız App Secret.
3. **E-posta / Kullanıcı Adı:** Deye mobil/web uygulamasında kullandığınız hesap.
4. **Şifre:** Deye hesap şifreniz.

Giriş yapıldıktan sonra bilgiler uygulamanın korumalı yerel alanına (`UserDefaults` - Android DataStore eşdeğeri) kaydedilir ve sonraki açılışlarda otomatik olarak oturum açılır. Gereksiz sistem şifresi istemi (Keychain prompt) oluşturmaz.

---

## Lisans

Kişisel kullanım projesidir.
