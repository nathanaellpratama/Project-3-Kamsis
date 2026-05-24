# Lab Keamanan Jaringan: 3-Container IDS/IPS & Secure Web App Lab

Project ini adalah laboratorium keamanan jaringan terintegrasi berbasis **Docker Compose** yang dirancang untuk disimulasikan di **Kali Linux VM**. Sistem ini terdiri dari 3 container utama yang mensimulasikan lingkungan nyata yang dilindungi oleh **Snort 3 IPS (Intrusion Prevention System)** dan **Access Control List (ACL) Firewall**, dengan target sebuah web application yang memiliki sistem keamanan berlapis (*Defense-in-Depth*).

---

## 📐 Arsitektur Jaringan & Topologi

Seluruh container terhubung pada custom network Docker bridge (`security_net` dengan subnet `10.10.10.0/24`) dengan alokasi IP statis sebagai berikut:

```
                      +---------------------------------------+
                      |       Docker Bridge Network           |
                      |           10.10.10.0/24               |
                      +------------------+--------------------+
                                         |
         +-------------------------------+-------------------------------+
         |                               |                               |
+--------+--------+              +-------+--------+              +-------+--------+
|  Container 3    |              |  Container 2    |              |  Container 1    |
|  User / Client  |              | Snort IDS/IPS   |              | Web Server + DB |
|  (Kali Linux)   |              |  + ACL Gateway  |              | (Flask+Nginx+PG)|
|   10.10.10.30   |              |   10.10.10.20   |              |   10.10.10.10   |
+--------+--------+              +-------+--------+              +--------+--------+
         |                               |                                |
         |   (HTTP/HTTPS Requests)       |   (Forwarded & Filtered)       |
         +----------------------------->[NFQ]----------------------------->|
         |                               |                                |
         |                               | (Direct SSH/Postgres Blocked)  |
         +----------------------------->[ACL]--X                          |
```

### Detail Alokasi Host

| Container | Hostname | IP Address | Peran / Deskripsi |
| :--- | :--- | :--- | :--- |
| **Container 1** | `secure-web` | `10.10.10.10` | **Web Target & DB**: Menjalankan Flask Application, database PostgreSQL (local), dan Nginx Reverse Proxy. |
| **Container 2** | `snort-ids-ips` | `10.10.10.20` | **Gateway / Sensor**: Menjalankan **Snort 3** (mode inline IPS dengan `NFQUEUE`), `iptables` rules, dan Access Control List (ACL). |
| **Container 3** | `user-client` | `10.10.10.30` | **User / Attacker**: Basis Kali Linux Rolling dengan tools lengkap (nmap, hping3, sqlmap, nikto, dll) untuk simulasi serangan. |

---

## 🔒 Fitur Pengamanan & Proteksi Lengkap

### 1. Container 1 (Web Target + Database PostgreSQL)
Aplikasi Web dirancang dengan prinsip **Defense-in-Depth** (Keamanan Berlapis) menggunakan teknologi Python (Flask) + PostgreSQL + Nginx:
*   **HTTPS (TLS 1.2 / 1.3)**: Di-handle di layer terdepan oleh **Nginx Reverse Proxy** dengan sertifikat SSL RSA 2048-bit *self-signed*. Seluruh traffic port 80 (HTTP) otomatis di-redirect ke port 443 (HTTPS).
*   **Password Hash & Salt**: Password user tidak disimpan dalam bentuk plain-text melainkan menggunakan hashing **PBKDF2-SHA256** dengan salt unik sepanjang 16 karakter (di-generate otomatis oleh `werkzeug.security`) untuk mencegah serangan *Rainbow Table* jika database bocor.
*   **SQL Injection (SQLi) Prevention**: 
    1.  Menggunakan **SQLAlchemy ORM** untuk seluruh query database. ORM secara otomatis menggunakan *parameterized queries* sehingga input user selalu diperlakukan sebagai data, bukan perintah SQL eksekusi.
    2.  *Defense-in-depth middleware*: Fungsi regex kustom memindai pola SQLi umum (seperti `UNION SELECT`, `OR 1=1`, `DROP TABLE`) di query string dan form POST, langsung mengembalikan HTTP 403 Forbidden sebelum diproses.
*   **XSS (Cross-Site Scripting) Prevention**:
    1.  Mesin template **Jinja2** mengaktifkan *auto-escaping* secara default untuk meminimalisir reflected/stored XSS pada browser.
    2.  Pustaka **Bleach** digunakan pada sisi server untuk membersihkan seluruh input dari tag HTML berbahaya (mengubah `<script>` menjadi entitas aman).
    3.  Implementasi header **Content-Security-Policy (CSP)** yang ketat via Nginx dan `Flask-Talisman` untuk membatasi eksekusi inline script tak dikenal.
*   **Buffer Overflow Protection**:
    1.  Batasan ukuran request maksimum (`client_max_body_size 1M`) pada Nginx dan `MAX_CONTENT_LENGTH` pada Flask.
    2.  Batasan buffer request header dan body pada Nginx untuk mencegah exploitasi memori server.
    3.  Validasi panjang karakter strict pada model database (contoh: Username maks 50, Email maks 120, Bio maks 500) baik secara client-side (`maxlength` HTML) maupun server-side.
    4.  Pembersihan *null byte* (`\x00`) pada input middleware untuk mencegah pemotongan string memori C-style.

### 2. Container 2 (Snort 3 + ACL Firewall)
Container ini bertindak sebagai Security Gateway di mana semua traffic dari Client/User harus melewati proses inspeksi Snort 3 dan ACL Firewall sebelum bisa sampai ke Web Server:
*   **Inline IPS Mode (Blocking)**: Menggunakan driver **DAQ (Data Acquisition) NFQUEUE** (`nfq`) terintegrasi dengan `iptables`. Jika traffic terindikasi aman, Snort mengizinkannya lewat (`ACCEPT`). Jika terindikasi serangan (sesuai rule dengan action `drop` atau `reject`), paket langsung di-**DROP** di network level secara real-time.
*   **Local Rules**: Rule kustom buatan sendiri (disimpan di `/etc/snort/rules/local.rules`) untuk mendeteksi:
    *   *SQL Injection*: Pola `UNION SELECT`, `OR 1=1`, `DROP TABLE`, `INSERT INTO`, `DELETE FROM`, dan identifikasi tool `sqlmap`.
    *   *XSS*: Pola tag `<script>`, `onerror=`, `onload=`, `eval()`, `document.cookie`.
    *   *Port Scanning*: Mendeteksi scanning tipe SYN, FIN, XMAS, NULL dari `nmap` dan deteksi tool `nikto`.
    *   *DoS / DDoS*: Deteksi SYN flood (threshold 100 pkt/10s), HTTP flood (50 req/5s), dan ICMP flood.
    *   *Buffer Overflow*: Deteksi URL string panjang (>2048 chars) dan POST body raksasa.
*   **Community Rules**: Snort community ruleset siap pakai untuk deteksi Trojan, malware outbound, generic shellcode (seperti NOP sled), dan eksploitasi server umum.
*   **Access Control List (ACL)**: Konfigurasi firewall packet-filtering (`/opt/acl/acl-rules.sh`) menggunakan `iptables`:
    *   Hanya mengizinkan traffic port **443 (HTTPS)** dan **80 (HTTP)** dari User ke Web.
    *   Memblokir langsung akses database PostgreSQL (**port 5432**) dari luar.
    *   Memblokir akses **SSH (port 22)** ke Web Server.
    *   Membatasi kecepatan koneksi baru (rate limiting syn flood) maksimal 25 koneksi/detik per source IP.

### 3. Container 3 (User / Attacker Client)
Container berbasis **Kali Linux** yang dilengkapi dengan berbagai alat uji penetrasi:
*   **Tools Tersedia**: `nmap`, `hping3`, `sqlmap`, `nikto`, `curl`, `hydra`, `dirb`, dll.
*   **Uji Otomatis**: Dilengkapi dengan script bash interaktif `/opt/tools/attacker-toolkit.sh` untuk mensimulasikan berbagai serangan dalam satu menu.

---

## 📁 Struktur File Project VS Code

Struktur direktori project dirancang rapi agar mudah dibuka dan didebug menggunakan VS Code sebelum dideploy ke Kali Linux:

```
Project 3/
├── docker-compose.yml              # Konfigurasi orchestrasi multikontainer
├── .env                            # Variabel rahasia (DB pass, Flask key)
├── .gitignore                      # Mengabaikan log, cert, dan folder cache
├── README.md                       # Dokumentasi project (File ini)
│
├── container1-web/                 # LAYER WEB & DB TARGET
│   ├── Dockerfile                  # Build multi-service (Python + Postgres + Nginx)
│   ├── requirements.txt            # Library Python (Flask, Talisman, Bleach)
│   ├── entrypoint.sh               # Script inisialisasi awal cluster Postgres
│   ├── supervisord.conf            # Konfigurasi Supervisor (Nginx + Flask + DB)
│   ├── certs/
│   │   └── generate-certs.sh       # Auto-generator SSL certificate self-signed
│   ├── init-db/
│   │   └── init.sql                # Skema DB, user, privileges (Least Privilege)
│   ├── nginx/
│   │   └── nginx.conf              # Config HTTPS, buffer limit, rate limit
│   └── app/
│       ├── __init__.py             # Inisialisasi Flask, Talisman, CSRF, Limiter
│       ├── config.py               # Batasan input (Buffer Overflow Protection)
│       ├── models.py               # Definisi tabel DB & PBKDF2 Hashing
│       ├── auth.py                 # Fitur login/register & brute-force lock (5x)
│       ├── routes.py               # Routing, searching, message posting (safe ORM)
│       ├── security.py             # Middleware deteksi SQLi & XSS sanitization (Bleach)
│       ├── static/
│       │   ├── css/style.css       # Styling dark premium UI
│       │   └── js/app.js           # Client-side input length checking
│       └── templates/              # File HTML dengan Auto-escaping
│           ├── base.html, login.html, register.html, dashboard.html, profile.html
│
├── container2-snort/               # LAYER SECURITY GATEWAY (IDS/IPS + ACL)
│   ├── Dockerfile                  # Build Ubuntu + Compile Snort 3 & Libdaq NFQ
│   ├── config/
│   │   ├── snort.lua               # Konfigurasi utama Snort (mode nfq inline)
│   │   └── snort_defaults.lua      # Variabel default Snort
│   ├── rules/
│   │   ├── local.rules             # Kustom rules deteksi serangan (alert & drop)
│   │   ├── community.rules         # Rule malware & trojan bawaan
│   │   └── custom/
│   │       └── web-attacks.rules   # Rule deteksi OWASP Top 10
│   ├── acl/
│   │   └── acl-rules.sh            # Pengamanan level network (port blocking)
│   ├── scripts/
│   │   ├── entrypoint.sh           # Setup routing, start Snort inline IPS
│   │   ├── setup-iptables.sh       # Konfigurasi NFQUEUE forward rule
│   │   ├── update-rules.sh         # Menu update community rules & reload
│   │   └── monitor.sh              # Terminal monitor alert real-time
│   └── logs/                       # Volume log alert output
│
└── container3-user/                # LAYER ATTACKER & CLIENT
    ├── Dockerfile                  # Kali Linux Rolling + Security tools
    ├── tools/
    │   └── attacker-toolkit.sh     # Interactive testing toolkit menu
    └── scripts/                    # Script simulasi serangan individu
        ├── test-normal.sh          # Simulasi user biasa (akses HTTPS, login)
        ├── test-sql-injection.sh   # Serangan SQLi (Login form & Search bar)
        ├── test-xss.sh             # Serangan XSS (Stored & Reflected)
        ├── test-dos.sh             # Serangan Flooding (SYN, HTTP, ICMP, PoD)
        ├── test-portscan.sh        # Scanning menggunakan Nmap (SYN/FIN/XMAS)
        └── test-buffer-overflow.sh # Serangan oversized payload (URL/POST body)
```

---

## 🚀 Panduan Menjalankan Project di Kali Linux

Ikuti langkah-langkah di bawah ini untuk memindahkan dan menjalankan laboratorium keamanan jaringan ini pada mesin Kali Linux VM Anda:

### Langkah 1: Persiapan Project di VM Kali Linux
1.  Buka terminal di Kali Linux Anda.
2.  Clone / Pull project dari repository git Anda:
    ```bash
    git clone <url-repository-anda> project3-security-lab
    cd project3-security-lab
    ```

### Langkah 2: Build dan Jalankan Container
Jalankan perintah berikut untuk membangun (*build*) seluruh image dan menjalankan ketiga container di latar belakang:
```bash
docker compose up --build -d
```
> [!NOTE]
> Proses build pertama kali pada container Snort 3 akan memakan waktu beberapa menit karena sistem melakukan kompilasi pustaka `libdaq` dan `snort3` langsung dari source code untuk memastikan modul **NFQUEUE (NFQ)** aktif.

Pastikan seluruh container telah berjalan dengan sukses:
```bash
docker compose ps
```
Output yang diharapkan menunjukkan `secure-web`, `snort-ids-ips`, dan `user-client` dalam status `Up`.

---

## 🖥️ Langkah Pengujian & Simulasi Serangan

Untuk melihat keefektifan Snort 3 IPS (blocking) dan respon web server, sangat disarankan menggunakan **dua jendela terminal terpisah** di Kali Linux Anda:

### TERMINAL A: Memantau Alerts Secara Real-Time (Snort)
Buka terminal baru di Kali Linux, kemudian jalankan script monitoring di container Snort untuk memantau paket yang dicurigai atau diblokir:
```bash
docker exec -it snort-ids-ips /opt/scripts/monitor.sh
```
Pilih opsi **`1`** untuk menampilkan semua alert secara real-time. Biarkan terminal ini tetap terbuka.

### TERMINAL B: Menjalankan Serangan (Attacker/User)
Kembali ke terminal utama Kali Linux Anda, kemudian masuk ke shell interaktif container User (Kali Linux):
```bash
docker exec -it user-client /opt/tools/attacker-toolkit.sh
```
Anda akan disuguhkan menu interaktif seperti berikut:
```
======================================
  SECURITY TESTING TOOLKIT
  Project 3 - Keamanan Sistem
======================================
====== TARGET: 10.10.10.10 ======

  TESTING MENU:
  1) Test Normal User Access
  2) Test SQL Injection
  3) Test XSS Attacks
  4) Test DoS Attacks
  5) Test Port Scanning
  6) Test Buffer Overflow
  7) Run ALL Tests

  UTILITIES:
  8) Ping Web Server
  9) Check Web Server Status
  0) Exit
```

---

## 🔍 Tabel Hasil Uji & Ekspektasi Blokir

| Menu Pengujian | Jenis Eksploitasi | Hasil yang Diharapkan (Terminal B) | Respon Snort IPS (Terminal A) | Analisis Keamanan |
| :--- | :--- | :--- | :--- | :--- |
| **`1` (Normal)** | Akses Web via HTTPS | HTTP `200 OK` (Berhasil) | *Tidak ada alert* | Traffic normal diizinkan lewat oleh Snort dan dienkripsi HTTPS. |
| **`2` (SQLi)** | Payload `' OR 1=1--` di form | HTTP `403 Forbidden` / `000 Connection Closed` | `[LOCAL] SQL Injection - OR 1=1 detected` (Action: **DROP**) | Paket langsung di-drop Snort di network level. Flask ORM juga mengamankan database dari bypass login. |
| **`2` (SQLi)** | URL Parameter `UNION SELECT` | HTTP `403 Forbidden` / `000` | `[LOCAL] SQL Injection - UNION SELECT detected` (Action: **DROP**) | URL mengandung malicious string terdeteksi dan diblokir total. |
| **`3` (XSS)** | Tag `<script>` pada post message | HTTP `403` / `000` | `[LOCAL] XSS - Script tag detected` (Action: **DROP**) | Snort memblokir request posting yang mengandung script tag. Bleach pada Flask juga melakukan sanitasi. |
| **`4` (DoS)** | HTTP Request Flooding (100 req) | Sebagian besar request diblokir dengan HTTP `429 Too Many Requests` | *Tidak ada alert / Rate Limit alert* | Nginx Rate Limiter membatasi request per IP untuk mencegah kelebihan beban CPU. |
| **`4` (DoS)** | SYN Flood via `hping3` | Pengiriman paket SYN cepat | `[LOCAL] DoS - SYN flood detected` (Action: **DROP**) | Snort mendeteksi banjir paket SYN dan memblokir IP penyerang sementara waktu. |
| **`5` (Scan)** | Nmap Port Scanning (`-sS`) | Port 443 terbuka, port lain terfilter | `[LOCAL] Port Scan - Nmap SYN scan detected` (Action: **ALERT**) | Snort mendeteksi aktivitas pemindaian port secara pasif (IDS alert). |
| **`6` (Buffer)**| POST Request 2MB | HTTP `413 Request Entity Too Large` | `[LOCAL] Buffer Overflow - Large POST data` (Action: **ALERT**) | Nginx langsung menolak request sebelum masuk ke memori aplikasi Flask (proteksi buffer overflow). |

---

## 🛠️ Panduan Update dan Edit Rules Secara Manual

Salah satu keunggulan sistem Snort ini adalah kemampuan melakukan update rule secara manual dan instan tanpa mematikan container:

1.  Masuk ke shell interaktif container Snort:
    ```bash
    docker exec -it snort-ids-ips /opt/scripts/update-rules.sh
    ```
2.  Anda dapat memilih opsi **`2`** untuk menambahkan rule deteksi buatan sendiri secara manual, misalnya:
    ```snort
    drop tcp any any -> $HOME_NET $HTTP_PORTS (msg:"[CUSTOM] Percobaan akses halaman rahasia"; content:"/rahasia"; nocase; sid:9999999; rev:1;)
    ```
3.  Pilih opsi **`7`** untuk me-reload Snort. Snort akan membaca ulang seluruh rule baru di latar belakang (tanpa restart container).
4.  Uji dari container User dengan memanggil URL target:
    ```bash
    curl -sk "https://10.10.10.10/rahasia"
    ```
    Request akan langsung diblokir dan terminal monitoring akan menampilkan alert `[CUSTOM] Percobaan akses halaman rahasia`.

---

## 🛑 Cara Menghentikan Lab
Jika Anda selesai menggunakan laboratorium ini, Anda dapat mematikan dan menghapus semua kontainer dengan perintah:
```bash
docker compose down -v
```
Opsi `-v` akan memastikan seluruh volume (termasuk penyimpanan database sementara) ikut dibersihkan sehingga lab dapat dimulai kembali dalam keadaan bersih (*fresh*) pada pengujian berikutnya.
