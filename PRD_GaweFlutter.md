# 📱 GaweFlutter — Aplikasi Android Native untuk Karyawan
## Product Requirements Document (PRD), Tahapan, dan Todo List

---

## 📋 RINGKASAN PRODUK

**Nama Produk:** GaweFlutter  
**Platform:** Android Native (Flutter)  
**Target Pengguna:** Karyawan (Employee) — bukan HRD/Admin  
**Backend:** API dari `presensigpsv2` (Laravel) menggunakan REST API  
**Tujuan:** Memberikan pengalaman mobile yang lebih native dan performa tinggi kepada karyawan untuk melakukan presensi GPS, melihat slip gaji, mengajukan izin, dan aktivitas harian lainnya.

---

## 🎯 TUJUAN BISNIS

1. Meningkatkan pengalaman pengguna karyawan yang selama ini menggunakan web mobile (tidak optimal di smartphone).
2. Menyediakan fitur presensi GPS Geofencing yang lebih akurat dan real-time menggunakan native Android.
3. Memberikan notifikasi push yang lebih reliable.
4. Mendukung mode offline dasar (menyimpan data presensi sementara jika tidak ada koneksi).
5. Mengintegrasikan fitur keamanan Device Lock agar 1 akun hanya bisa digunakan di 1 perangkat.

---

## 👤 TARGET PENGGUNA (USER PERSONA)

**Ahmad — Karyawan Lapangan**
- Usia: 25–40 tahun
- Aktivitas: Absen masuk/pulang, cek jadwal, ajukan izin, lihat slip gaji
- Kebutuhan: Aplikasi ringan, mudah digunakan, bisa dipakai saat sinyal lemah

**Siti — Karyawan Kantor**
- Usia: 22–35 tahun
- Aktivitas: Presensi, lihat riwayat absen, pengajuan cuti, lihat reimbursement
- Kebutuhan: Tampilan informasi yang jelas dan akses ke riwayat data

---

## 🔑 FITUR UTAMA (MVP — Minimum Viable Product)

### 1. Autentikasi
- [ ] Login dengan username & password
- [ ] Penguncian Device (Device Binding) — 1 akun = 1 perangkat
- [ ] Auto-login (simpan token di secure storage)
- [ ] Logout

### 2. Dashboard
- [ ] Tampilkan nama, foto, dan jabatan karyawan
- [ ] Status presensi hari ini (sudah masuk/belum, sudah pulang/belum)
- [ ] Ringkasan informasi bulan ini (total hadir, izin, sakit, alpa)
- [ ] Shortcut menu ke fitur utama

### 3. Presensi GPS
- [ ] Absen Masuk dengan GPS Geofencing (validasi radius lokasi)
- [ ] Absen Pulang dengan GPS Geofencing
- [ ] Foto selfie saat absen masuk dan pulang
- [ ] Tampilkan jam kerja hari ini
- [ ] Riwayat presensi per bulan
- [ ] Tampilkan status presensi (Tepat waktu, Terlambat, Tidak Hadir, dll)

### 4. Pengajuan Izin
- [ ] Ajukan Izin Tidak Masuk (dengan alasan)
- [ ] Ajukan Izin Sakit (dengan upload surat dokter)
- [ ] Ajukan Cuti (dengan pilih tanggal dan alasan)
- [ ] Riwayat pengajuan izin
- [ ] Status pengajuan (Pending, Disetujui, Ditolak)

### 5. Slip Gaji
- [ ] Lihat slip gaji per bulan
- [ ] Detail komponen gaji (tunjangan, potongan, dll)
- [ ] Download slip gaji (PDF)

### 6. Profil Karyawan
- [ ] Lihat data profil pribadi
- [ ] Ubah password
- [ ] Foto profil

### 7. Notifikasi
- [ ] Push notification untuk status pengajuan izin (disetujui/ditolak)
- [ ] Reminder presensi masuk/pulang
- [ ] Pengumuman dari perusahaan

---

## 🗓️ FITUR LANJUTAN (Post-MVP)

- [ ] Pengajuan Lembur
- [ ] Pengajuan Reimbursement + upload foto nota
- [ ] Lihat status pinjaman karyawan (cicilan, sisa)
- [ ] Lihat KPI (Key Performance Indicator)
- [ ] Absen Istirahat
- [ ] Kunjungan / Customer Visit (untuk sales lapangan)
- [ ] Aktivitas Harian Karyawan
- [ ] Chat/Pesan internal (jika ada)
- [ ] QR Code Presensi (sebagai alternatif GPS)

---

## 🔗 INTEGRASI API BACKEND

Backend menggunakan `presensigpsv2` (Laravel). Flutter akan berkomunikasi melalui REST API menggunakan token autentikasi (Laravel Sanctum).

### Endpoint yang Dibutuhkan (Perlu Dibuat di Backend):
```
POST   /api/mobile/login
POST   /api/mobile/logout
GET    /api/mobile/profile
GET    /api/mobile/dashboard
POST   /api/mobile/presensi/masuk
POST   /api/mobile/presensi/pulang
GET    /api/mobile/presensi/riwayat
GET    /api/mobile/izin/list
POST   /api/mobile/izin/create
GET    /api/mobile/izin/riwayat
GET    /api/mobile/cuti/list
POST   /api/mobile/cuti/create
GET    /api/mobile/slipgaji
GET    /api/mobile/slipgaji/{id}
GET    /api/mobile/pengumuman
```

---

## 🏗️ ARSITEKTUR APLIKASI

```
gaweflutter/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── routes/         # Routing (GoRouter)
│   │   └── themes/         # Tema warna dan tipografi
│   ├── core/
│   │   ├── network/        # Dio HTTP client, interceptors
│   │   ├── storage/        # Secure storage (token, device_id)
│   │   ├── constants/      # Konstanta URL, warna, dll
│   │   └── utils/          # Helper functions
│   ├── data/
│   │   ├── models/         # Model data (JSON serializable)
│   │   ├── repositories/   # Data repository layer
│   │   └── datasources/    # Remote & local data sources
│   ├── features/
│   │   ├── auth/           # Login, logout
│   │   ├── dashboard/      # Halaman utama
│   │   ├── presensi/       # Presensi GPS
│   │   ├── izin/           # Izin & Cuti
│   │   ├── slipgaji/       # Slip Gaji
│   │   ├── profil/         # Profil karyawan
│   │   └── notifikasi/     # Push notification
│   └── shared/
│       ├── widgets/        # Widget yang dipakai berulang
│       └── services/       # Service GPS, kamera, dll
├── assets/
│   ├── images/
│   └── fonts/
├── pubspec.yaml
└── README.md
```

**State Management:** Riverpod / BLoC  
**HTTP Client:** Dio  
**Navigasi:** GoRouter  
**Local Storage:** Flutter Secure Storage + Hive  
**GPS:** Geolocator + Google Maps  
**Kamera:** Camera / Image Picker  
**Push Notification:** Firebase Cloud Messaging (FCM)  
**PDF:** pdf / printing package

---

## 📦 TAHAPAN PENGEMBANGAN

### 🔷 Tahap 0: Persiapan & Setup (Estimasi: 1 minggu)
- Setup project Flutter (Android)
- Setup struktur folder Clean Architecture
- Konfigurasi dependencies (pubspec.yaml)
- Setup Firebase (FCM untuk push notification)
- Setup environment (dev/staging/production)
- Buat koneksi ke API backend (base URL, interceptor token)

### 🔷 Tahap 1: Autentikasi & Device Lock (Estimasi: 1 minggu)
- Halaman login (UI + logic)
- Integrasi API login (Sanctum token)
- Simpan token di Secure Storage
- Generate dan simpan Device ID unik
- Implementasi Device Lock (satu akun = satu perangkat)
- Auto-login jika token masih valid
- Halaman logout

### 🔷 Tahap 2: Dashboard & Profil (Estimasi: 1 minggu)
- Halaman dashboard
- Komponen status presensi hari ini
- Ringkasan statistik bulan ini
- Menu navigasi bawah (Bottom Navigation Bar)
- Halaman profil karyawan
- Fitur ganti password

### 🔷 Tahap 3: Presensi GPS (Estimasi: 2 minggu)
- Integrasi GPS/Location Service
- Implementasi Geofencing (validasi radius)
- Tampil peta lokasi absen
- Tombol Absen Masuk + foto selfie
- Tombol Absen Pulang + foto selfie
- Riwayat presensi per bulan
- Kalender absensi visual

### 🔷 Tahap 4: Pengajuan Izin & Cuti (Estimasi: 1.5 minggu)
- Form pengajuan izin tidak masuk
- Form pengajuan izin sakit (+ upload surat)
- Form pengajuan cuti (pilih tanggal, alasan)
- Riwayat pengajuan dengan status
- Detail pengajuan

### 🔷 Tahap 5: Slip Gaji (Estimasi: 1 minggu)
- List slip gaji per bulan/tahun
- Halaman detail slip gaji (breakdown komponen)
- Fitur download/share PDF slip gaji

### 🔷 Tahap 6: Notifikasi Push (Estimasi: 1 minggu)
- Setup FCM di Flutter
- Terima notifikasi saat status izin diupdate
- Terima pengumuman perusahaan
- List riwayat notifikasi di app

### 🔷 Tahap 7: Testing & Optimasi (Estimasi: 1 minggu)
- Unit testing
- Widget testing
- Integration testing
- Optimasi performa (lazy loading, caching)
- Bug fixing

### 🔷 Tahap 8: Deployment (Estimasi: 0.5 minggu)
- Build APK release
- Signing APK
- Distribusi via Google Play Store / Firebase App Distribution

---

## ✅ TODO LIST LENGKAP

### 📁 SETUP PROJECT
- [x] Buat project Flutter baru (`flutter create gaweflutter`)
- [x] Setup struktur folder Clean Architecture
- [x] Tambahkan semua dependencies di `pubspec.yaml`
- [x] Konfigurasi `AndroidManifest.xml` (permission GPS, kamera, internet)
- [ ] Setup Firebase project & unduh `google-services.json` (Membutuhkan konfigurasi manual oleh user di Firebase Console)
- [x] Setup GoRouter untuk navigasi
- [x] Buat file konstanta (base URL, warna, string)
- [x] Setup Dio dengan base options dan token interceptor
- [x] Setup Secure Storage untuk token dan device ID
### 🔐 AUTENTIKASI
- [x] Buat model `UserModel` (dari response API login)
- [x] Buat `AuthRepository` dan `AuthRemoteDataSource`
- [x] Buat `LoginScreen` (UI: input username, password, tombol login)
- [x] Implementasi logic login (panggil API, simpan token)
- [ ] Generate UUID device ID saat pertama kali install
- [ ] Kirim device ID saat login, validasi di backend
- [ ] Tampilkan error jika device tidak sesuai (device lock)
- [x] Implementasi auto-login (cek token di startup)
- [x] Implementasi logout (hapus token, kembali ke login)
- [x] *(Backend)* Buat endpoint `POST /api/mobile/login` (dengan validasi device ID dilewati sementara)
- [ ] *(Backend)* Tambahkan kolom `device_id` & `fcm_token` di tabel `users`

### 🏠 DASHBOARD
- [x] Buat `DashboardScreen` (layout dengan Bottom Nav Bar)
- [x] Widget status presensi hari ini (jam masuk, jam pulang)
- [x] Widget statistik bulan ini (hadir, izin, sakit, alpa)
- [x] Widget shortcut menu (Presensi, Izin, Slip Gaji, dll)
- [x] Widget pengumuman terbaru
- [x] *(Backend)* Buat endpoint `GET /api/mobile/dashboard`

### 👤 PROFIL
- [x] Buat `ProfilScreen` dengan data karyawan
- [x] Tampilkan: nama, NIK, jabatan, departemen, cabang, foto
- [x] Form ganti password
- [x] Upload/ganti foto profil
- [x] *(Backend)* Buat endpoint `GET /api/mobile/profile`
- [x] *(Backend)* Buat endpoint `PUT /api/mobile/profile/password`

### 📍 PRESENSI GPS
- [x] Tambahkan permission GPS di manifest
- [x] Implementasi service GPS (dapatkan koordinat saat ini)
- [x] Implementasi validasi Geofencing (cek apakah dalam radius lokasi)
- [x] Tampilkan peta kecil dengan posisi karyawan & titik kantor
- [x] Buat tombol "Absen Masuk" (aktif hanya jika dalam radius)
- [x] Integrasi kamera untuk foto selfie (absen masuk)
- [x] Buat tombol "Absen Pulang"
- [x] Integrasi kamera untuk foto selfie (absen pulang)
- [x] Tampilkan konfirmasi setelah berhasil absen
- [x] Buat `RiwayatPresensiScreen` (list per bulan)
- [x] Buat kalender absensi visual (warna merah/hijau/kuning per hari)
- [x] *(Backend)* Buat endpoint `POST /api/mobile/presensi/masuk`
- [x] *(Backend)* Buat endpoint `POST /api/mobile/presensi/pulang`
- [x] *(Backend)* Buat endpoint `GET /api/mobile/presensi/riwayat?bulan=&tahun=`

### 📝 PENGAJUAN IZIN & CUTI
- [ ] Buat `IzinScreen` (list pengajuan izin saya)
- [ ] Form pengajuan izin tidak masuk (tanggal, alasan)
- [ ] Form pengajuan izin sakit (tanggal, alasan, upload surat)
- [ ] Form pengajuan cuti (dari-sampai tanggal, alasan, sisa saldo cuti)
- [ ] Tampilkan status pengajuan (Pending / Disetujui / Ditolak)
- [ ] Detail pengajuan (termasuk catatan penolakan jika ada)
- [ ] *(Backend)* Buat endpoint `GET /api/mobile/izin`
- [ ] *(Backend)* Buat endpoint `POST /api/mobile/izin` (izin absen)
- [ ] *(Backend)* Buat endpoint `POST /api/mobile/izinsakit`
- [ ] *(Backend)* Buat endpoint `GET /api/mobile/cuti` (saldo cuti)
- [ ] *(Backend)* Buat endpoint `POST /api/mobile/cuti`

### 💰 SLIP GAJI
- [ ] Buat `SlipGajiScreen` (pilih bulan/tahun)
- [ ] Buat halaman detail slip gaji
- [ ] Tampilkan: gaji pokok, tunjangan, potongan, total bersih
- [ ] Fitur download/share slip dalam format PDF
- [ ] *(Backend)* Buat endpoint `GET /api/mobile/slipgaji`
- [ ] *(Backend)* Buat endpoint `GET /api/mobile/slipgaji/{id}`
- [ ] *(Backend)* Buat endpoint `GET /api/mobile/slipgaji/{id}/download`

### 🔔 NOTIFIKASI
- [ ] Setup FCM di aplikasi Flutter
- [ ] Simpan FCM token setelah login ke backend
- [ ] Handle notifikasi saat app di foreground
- [ ] Handle notifikasi saat app di background/killed
- [ ] Buat `NotifikasiScreen` (riwayat notifikasi)
- [ ] *(Backend)* Simpan FCM token per user di database
- [ ] *(Backend)* Kirim push notification saat status izin berubah
- [ ] *(Backend)* Kirim push notification saat ada pengumuman baru

### 🧪 TESTING
- [ ] Unit test untuk semua repository
- [ ] Unit test untuk semua use cases
- [ ] Widget test untuk halaman login
- [ ] Widget test untuk dashboard
- [ ] Integration test alur login → absen → logout

### 🚀 DEPLOYMENT
- [ ] Buat keystore untuk signing APK
- [ ] Konfigurasi `build.gradle` untuk release
- [ ] Build APK release (`flutter build apk --release`)
- [ ] Test di minimal 3 device Android berbeda
- [ ] Upload ke Firebase App Distribution untuk internal testing
- [ ] *(Opsional)* Publish ke Google Play Store

---

## 📌 CATATAN PENTING

### API Backend (presensigpsv2) yang Perlu Dipersiapkan:
Sebelum Flutter bisa berjalan penuh, perlu dibuat endpoint API khusus mobile di Laravel:
1. Install atau gunakan Laravel Sanctum (sudah ada) untuk autentikasi token
2. Buat Controller baru `Api/MobileController.php`
3. Semua endpoint mobile diawali `/api/mobile/`
4. Pastikan CORS dikonfigurasi untuk menerima request dari app Android

### Keamanan:
- Semua komunikasi harus menggunakan HTTPS
- Token disimpan di Flutter Secure Storage (bukan SharedPreferences biasa)
- Device ID di-generate sekali saat install dan tidak bisa diubah user
- Foto selfie presensi disimpan dengan timestamp sebagai metadata

### Versi Android Minimum:
- **minSdkVersion:** 21 (Android 5.0 Lollipop)
- **targetSdkVersion:** 34 (Android 14)

---

*Dokumen dibuat: 11 Juni 2026*  
*Status: Draft — Belum dieksekusi*
