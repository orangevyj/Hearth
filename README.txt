Hearth 0.2.0 — everything in one place
=========================================

Layout
  Windows/   server + launcher for Windows 10/11 (x64)
  Linux/     server + launcher for Linux (Debian/Ubuntu and Fedora/RHEL)
  Android/   connect-only client (no models run on the phone)

The server is the same Python application on Windows and Linux; it detects the
hardware it is installed on (CPU, RAM, GPU/VRAM, disk) and sizes its Fast /
Balanced / Smart model presets from that, so nothing here is tuned for one PC.

Windows/
  hearth-windows-0.2.0-source.zip   full server source. Unzip, then run
                                        powershell -ExecutionPolicy Bypass -File scripts\install-windows.ps1
  install-windows.ps1                   finds/installs Python 3.12, builds .venv,
                                        installs dependencies and uv, writes hearth.cmd
  hearth-windows-0.2.0-setup.exe        the installer: double-click it. Installs per user to
                                        %LOCALAPPDATA%\Programs\Hearth, then finds or installs
                                        Python 3.12 and Hearth's dependencies.
  hearth.iss + build-inno.ps1           Inno Setup 6 project and its build script. Rebuild with
                                        powershell -ExecutionPolicy Bypass -File build-inno.ps1;
                                        compiled here with ISCC 6.7 under wine.

Linux/
  hearth_0.2.0_all.deb              sudo apt install ./hearth_0.2.0_all.deb
  hearth-0.2.0-1.noarch.rpm         sudo dnf install ./hearth-0.2.0-1.noarch.rpm
  hearth-linux-0.2.0-source.tar.gz  source; ./scripts/install-desktop.sh for a menu entry
  install-desktop.sh                    adds a desktop launcher without root

  Both packages install to /opt/hearth and create /usr/bin/hearth. Their post-install
  step builds the virtualenv and pulls Python dependencies from PyPI, because PyTorch
  picks machine-specific wheels.

Android/
  hearth-android-0.2.0.apk          sideload it (Settings → allow install from Files), or
                                        drag it over USB. Then enter the server address,
                                        user and secret from Server → Remote access.
  hearth-android-0.2.0-source.zip   Gradle project. Open in Android Studio, or
                                        JAVA_HOME=... ./gradlew assembleDebug

First run
  1. Start the server: hearth (Linux) or hearth.cmd (Windows).
  2. It opens http://127.0.0.1:8772 — the launcher detects your hardware and offers presets.
  3. Install a preset to download runtimes and models, then chat.
  4. For other devices: Server → Remote access → accept connections, add an account,
     set a panel code if you want its settings reachable from that device.
     Devices without the app land on a page that offers the matching download.

Version note
  The server reports its version at GET /api/version and refuses clients older than
  the builds it stores (HTTP 426 with a download link). Keep the APK and the server
  on the same version when you update.
