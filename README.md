# Cek Suhu Laptop (Windows)

Aplikasi terminal sederhana untuk menampilkan suhu laptop dari Windows. Cocok sebagai proyek GitHub pertama: kecil, mudah dibaca, dan tidak membutuhkan instalasi Python atau Node.js.

## Batasan yang perlu diketahui

Windows **tidak menyediakan satu perintah standar** untuk membaca suhu CPU di semua laptop. Aplikasi ini mencoba dua jalur:

1. **WMI/ACPI** (`MSAcpi_ThermalZoneTemperature`) — bawaan Windows, tanpa install apa pun. Namun tidak semua BIOS/DRIVER mengeksposnya, hasilnya bisa berupa zona termal motherboard (bukan suhu inti CPU), dan nilainya kadang statis. Pembacaan ini juga sering memerlukan PowerShell yang dijalankan sebagai Administrator.
2. **LibreHardwareMonitor** — opsional, lebih akurat untuk suhu paket CPU, tetapi perlu file `LibreHardwareMonitorLib.dll` yang diunduh sendiri.

Aplikasi ini **hanya untuk informasi**, bukan mekanisme perlindungan hardware. Jangan dipakai sebagai pemicu shutdown otomatis.

## Prasyarat

- Windows 10 atau Windows 11
- Windows PowerShell 5.1 (sudah bawaan) atau PowerShell 7
- Opsional: `LibreHardwareMonitorLib.dll` dari [halaman rilis LibreHardwareMonitor](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases)

## Cara menjalankan

Buka PowerShell di folder proyek ini, lalu jalankan:

```powershell
powershell -ExecutionPolicy Bypass -File .\cek-suhu.ps1
```

Gunakan mode simulasi untuk mencoba tampilan tanpa sensor sungguhan:

```powershell
powershell -ExecutionPolicy Bypass -File .\cek-suhu.ps1 -Simulasi
```

Gunakan DLL LibreHardwareMonitor jika WMI tidak menghasilkan data:

```powershell
powershell -ExecutionPolicy Bypass -File .\cek-suhu.ps1 -DllPath "C:\path\ke\LibreHardwareMonitorLib.dll"
```

Pantau terus-menerus setiap 5 detik, maksimal 10 kali bacaan:

```powershell
powershell -ExecutionPolicy Bypass -File .\cek-suhu.ps1 -Interval 5 -Count 10
```

Ubah batas status (default 80 °C):

```powershell
powershell -ExecutionPolicy Bypass -File .\cek-suhu.ps1 -Ambang 85
```

Status yang ditampilkan:

- `NORMAL` — di bawah ambang
- `WASPADA` — mencapai ambang
- `PANAS` — ambang + 10 °C

## Cara menjalankan pengujian

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Uji-CekSuhu.ps1
```

Pengujian ini sengaja tidak membaca perangkat keras, supaya hasilnya selalu bisa diulang.

## Struktur folder

```text
cek-suhu/
├── cek-suhu.ps1              # pintu masuk / command-line
├── CekSuhu.psm1              # logika baca dan konversi suhu
├── tests/
│   └── Uji-CekSuhu.ps1       # pengujian tanpa Pester
├── .gitignore                # mencegah DLL ikut ter-commit
└── README.md
```

## Cara upload ke GitHub sebagai proyek pertama

1. Buat repository baru di https://github.com/new. Beri nama misalnya `cek-suhu-windows`.
2. **Jangan** centang "Add a README file" / `.gitignore` / license, karena folder ini sudah memilikinya.
3. Di PowerShell, dari folder `cek-suhu`, jalankan:

```powershell
git init
git config user.name "RiBryanz"
git config user.email "email-aktif-kamu@example.com"
git add .
git commit -m "commit awal: aplikasi cek suhu laptop Windows"
git branch -M main
git remote add origin https://github.com/RiBryanz/cek-suhu-windows.git
git push -u origin main
```

Ganti alamat email dan nama repository dengan punyamu.

Jika keduanya sudah ada atau muncul pesan `remote origin already exists`, gunakan:

```powershell
git remote set-url origin https://github.com/RiBryanz/cek-suhu-windows.git
```

## Troubleshooting

| Masalah | Penyebab umum | Solusi |
| --- | --- | --- |
| `Tidak ada pembacaan suhu yang valid` | BIOS tidak mengekspos thermal zone | Gunakan opsi `-DllPath` |
| Pesan `Access denied` dari WMI | PowerShell biasa tidak cukup | Buka PowerShell dengan **Run as Administrator** |
| Program diblokir execution policy | Setting default Windows | Pakai `powershell -ExecutionPolicy Bypass -File ...` |
| Angka suhu tidak pernah berubah | Yang terbaca zona termal firmware, bukan CPU | Pakai LibreHardwareMonitor untuk perbandingan |
| `Gagal memuat ...dll` | File masih diblokir Windows | Klik kanan DLL → Properties → centang Unblock |

## Referensi

- [Microsoft WMI class `MSAcpi_ThermalZoneTemperature` dan konversi persepuluh kelvin](https://learn.microsoft.com/en-us/windows/win32/wmi/sw-class-properties)
- [Contoh penggunaan `LibreHardwareMonitorLib.dll` dari PowerShell](https://stackoverflow.com/questions/39738494/get-cpu-temperature-in-cmd-power-shell/77143593#77143593)
- [Penjelasan kenapa pembacaan ACPI bisa berbeda dari suhu inti CPU](https://www.windows-faq.com/2026/07/24/how-to-check-cpu-temperature-in-windows-11-and-10/)
