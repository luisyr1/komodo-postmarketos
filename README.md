# Nura / postmarketOS on Google Pixel 9 Pro XL (komodo)

> **Status: Nura (edge) with the Phosh UI is installed on `userdata` and boots
> on our unit from slot B (Milestones 3 to 6, 2026-11-25): real KMS display
> with brightness control, Mali-G715 GPU through Panthor and Mesa,
> touchscreen, battery level readout, `reboot bootloader` to fastboot, SSH
> over USB, **WiFi** (BCM4390; connects and passes traffic, throughput not
> measured) and **Bluetooth** (same chip; scans, pairs and connects, but
> with the chip's generic default address); firmware for both from your own
> factory image. **Audio is experimental** (Milestone 6): one short test
> tone on the bottom speaker at the lowest gain, and one microphone; no
> desktop sound, and the amplifiers run without their protection firmware,
> so a higher volume can damage a speaker. Not working yet: usable audio,
> modem, cameras, managed USB-C; charging from a PC port barely keeps up.
> Since 2026-11-26 slot B is marked successful on our unit, so boots no
> longer spend its retries ([docs/SLOT-B.md](docs/SLOT-B.md)). Stock
> Android 17 stays on slot A, but its data was wiped.**
>
> **Estado: Nura (edge) con la UI Phosh está instalado en `userdata` y arranca
> en nuestra unidad desde el slot B (hitos 3 a 6, 2026-11-25): pantalla con
> KMS real y control de brillo, GPU Mali-G715 con Panthor y Mesa, táctil,
> lectura del nivel de batería, `reboot bootloader` hasta fastboot, SSH por
> USB, **WiFi** (BCM4390; conecta y pasa tráfico, velocidad sin medir) y
> **Bluetooth** (mismo chip; escanea, empareja y conecta, pero con la
> dirección por defecto, genérica, del chip); el firmware de ambos, de tu
> propia imagen de fábrica. **El audio es experimental** (hito 6): un tono
> de prueba corto por el altavoz inferior con la ganancia mínima y un
> micrófono; sin sonido en el escritorio, y los amplificadores van sin su
> firmware de protección, así que un volumen mayor puede dañar un altavoz.
> Aún no funcionan: audio usable, módem, cámaras ni USB-C gestionado; desde
> un puerto de PC casi no carga. Desde el 2026-11-26 el slot B está marcado
> como correcto en nuestra unidad y los arranques ya no gastan sus intentos.
> Android 17 stock sigue en el slot A, pero sus datos se borraron.**

[English](#english) · [Español](#español)

---

## English

### What is this

An independent, community effort to bring [Nura](https://postmarketos.org)
(formerly postmarketOS, renamed on 2026-09-27 according to the project's
announcement) to the **Google Pixel 9 Pro XL**
(codename `komodo`, SoC Google Tensor G4 / `zumapro`).

There is no official `komodo` port in pmaports/Nura, and mainline Linux has no
`zumapro` support (as of 2026-11-24). This repository builds on the work of the
[Omamobile](https://github.com/derekross/omamobile) project and its Tensor kernel
fork. It is **not** affiliated with Nura, postmarketOS, Google or Omamobile.

### Current status (honest)

- Bootloader: **unlocked** on our unit (verified boot state orange).
- Stock: Android 17 stable `CP4A.261105.040.A1` on **both** slots (same
  bootloader on both), automatic updates disabled. How:
  [docs/UNLOCK.md](docs/UNLOCK.md). Slot B's five boot partitions now carry
  Nura's images (`vbmeta_b` stock), and slot B is the one we boot.
- Milestone 1 (2026-11-24): mainline-based kernel booted RAM-only from slot
  B, USB gadget with serial console and SSH, UFS read-only.
  [docs/MILESTONE-1.md](docs/MILESTONE-1.md).
- **Milestone 2 passed (2026-11-25): Nura on `userdata`.** Built with
  pmbootstrap 3.12.1 (edge, console UI, systemd); kernel
  `7.3.0-rc6-zumapro`; root filesystem written to `userdata` (ext4 image on a
  loop device with 4096-byte sectors, grown to 221.6 GiB on first boot); the
  five slot-B boot images built from the pmbootstrap output (`vbmeta_b`
  stock). Nura reaches `login:` on the screen; over SSH (USB NCM,
  `172.16.43.1`): system `running`, 0 failed units, 15.1 GiB RAM, 8 CPUs,
  UFS read-only guard clean. Procedure:
  [docs/MILESTONE-2.md](docs/MILESTONE-2.md).
- **Touchscreen works (2026-11-25).** Synaptics S3908 over SPI (TouchComm),
  driven by the `synaptics_tcm` driver of the Omamobile tree (not mainline,
  already built in). The board DTS already described it, disabled by policy
  in PR #276; our kernel patch 0004 enables it (package `pkgrel=1`). No
  external firmware is needed. Nura was then reinstalled with the
  `buffyboard` UI (framebuffer console with an on-screen keyboard), and the
  owner logged in at `login:` by touch, without a cable: the first local
  session without a PC (a graphical UI followed in Milestone 3). Untested:
  real multitouch, palm rejection, accuracy/calibration, touch across
  suspend/resume.
- **Milestone 3 (2026-11-25): Phosh on real KMS with the GPU.** Kernel
  package `pkgrel=2` (11 patches on the same commit) and device package
  `pkgrel=3`. Display: `gs-decon` stage 2 (real KMS) at 60 Hz, brightness
  through a minimal `google,km4` panel driver of our own. GPU: Mali-G715 with
  Panthor and Arm's CSF firmware (Alpine `linux-firmware-arm`); Mesa 26.3.1
  reports "Mali-G715 MC7 (Panfrost)", OpenGL ES 3.1; no performance numbers.
  Battery: the MAX77779 fuel gauge reads the percentage and design capacity
  (5035 mAh); the charger is detected, but from a PC USB port (500 mA) the
  battery barely charges. `reboot bootloader` reaches fastboot without
  buttons. Nura reinstalled with Phosh: graphical login by touch,
  GPU-accelerated, zero failed units after a clean reboot.
  [docs/MILESTONE-3.md](docs/MILESTONE-3.md).
- **Milestone 4 (2026-11-25): WiFi.** The chip is a Broadcom BCM4390 (WiFi
  7 + Bluetooth, PCI `14e4:4438`, revision b1). Kernel package `pkgrel=3`:
  patch 0012 powers the PCIe link (`pcie_1`, Gen3 x1, 16 MiB restricted DMA
  pool) and patch 0013 adds the chip to `brcmfmac`, following Google's GPL
  bcmdhd driver where it differs from the BCM4398. **0013 is not upstream
  and has not been sent anywhere.** The firmware is proprietary and not in
  this repository: you extract it from your own factory image and install it
  with [`scripts/install-wifi-firmware.sh`](scripts/install-wifi-firmware.sh).
  Result: `wlan0` at boot, scan on 2.4 and 5 GHz, WPA connection from
  Phosh's settings, ping ~18 ms without loss, `apk update` over WiFi,
  automatic reconnection. Throughput **not measured**; WiFi Direct most
  likely broken; 6 GHz, WiFi 7, suspend, power saving and AP mode untried.
  [docs/MILESTONE-4.md](docs/MILESTONE-4.md).
- **Milestone 5 (2026-11-25): Bluetooth.** The Bluetooth half of the same
  BCM4390, on the APM's UART. Kernel package `pkgrel=4`: patch 0014
  describes the UART, the power latch and the wake lines in the DTS, and
  0015 adds the chip to `hci_bcm` with the stock HAL's 100 ms power-on
  delay; the config adds `BT_LE`, `BT_RFCOMM` and `BT_RFCOMM_TTY`. **0014
  and 0015 are not upstream and have not been sent anywhere.** The firmware
  (`BCM_200.hcd`) is proprietary and not in this repository: you extract it
  from your own factory image and install it with
  [`scripts/install-bt-firmware.sh`](scripts/install-bt-firmware.sh).
  Result: `hci0` powered by BlueZ, a 12 s scan saw 16 devices, pairing and
  connection with a phone from Phosh's settings with WiFi connected at the
  same time, autoload at boot (~10 s), pairing kept across reboots. The
  controller uses the chip's **default address** (generic, the same on
  every unconfigured BCM4390), seven `Failed to read codec capabilities
  (-22)` warnings; Bluetooth audio untestable (no audio yet); suspend,
  profiles (HID, A2DP, tethering) and 4 Mbaud untried.
  [docs/MILESTONE-5.md](docs/MILESTONE-5.md).
- **Milestone 6 (2026-11-25): first audio, experimental.** All audio goes
  through the AoC, Google's audio coprocessor, which Trusty and the GSA
  start with its signed firmware; two Cirrus CS35L41 amplifiers drive the
  speakers. Kernel package `pkgrel=6` (patches 0016–0021) installed: the
  AoC comes online (firmware `16099865-polygon`, 94 services, from your own
  factory image, not in this repository), both amplifiers are identified
  and the sound card appears. A 2 s, 1 kHz tone at the lowest analog gain
  was heard from the **bottom speaker**, and **microphone 0** picked it up.
  **Warning: the amplifiers run without Cirrus' protection firmware and
  without the factory calibration; raising the volume can damage a speaker
  irreversibly.** Every audio module stays blacklisted and the levels at
  the bring-up minimum. Patches 0017 and 0022 are Lef's pull requests #204
  and #203 to the Omamobile kernel; `pkgrel=7` (with 0022–0023) was built,
  installed and booted on 2026-11-26, and a default `aplay` now plays to
  the end on EP6. PipeWire ignores the card on purpose, so the desktop has no
  sound; the top speaker/earpiece, stereo, usable volume, the other two
  microphones, Bluetooth audio and calls are untried.
  [docs/MILESTONE-6.md](docs/MILESTONE-6.md).
- Android data: **lost** when `userdata` was flashed (expected). Slot A,
  bootloader, radio and `vbmeta` untouched.
- Packages: [`pmaports/device/testing/`](pmaports/device/testing/)
  (`device-google-komodo`, `linux-google-zumapro`) and
  [`scripts/mkimages-pmos.sh`](scripts/mkimages-pmos.sh).
- Slot-B retry counter: **resolved on our unit on 2026-11-26** (one byte of
  `devinfo`, written and verified; the counter no longer drops, and the ABL
  no longer falls back to slot A by itself (deduced: no failed boot has been tried with B marked)). Each owner decides; see
  [docs/SLOT-B.md](docs/SLOT-B.md) and [docs/SAFETY.md](docs/SAFETY.md).
- Known problems: audio only experimental (above), no modem or cameras; WiFi and Bluetooth
  limits as listed above (warnings `Set join_pref error (-52)` and a failed P2P interface in
  the log); no managed USB-C (a TCPC patch is
  prepared, not integrated); no verified button actions; power off untested;
  intermittent USB enumeration failures (`error -71`) on some boots;
  `buffyboard` had to be disabled by hand under Phosh (it injected phantom
  key presses); on the first boot of every new install
  `systemd-firstboot.service` fails (no input console) and leaves the system
  `degraded` for that boot.
- Backup of the device's partitions: done from the Milestone 1 Linux, kept
  private.
- Next, in this order: audio (PipeWire with a volume ceiling, the
  speaker-protection firmware and calibration, the top
  speaker, the other microphones, Bluetooth audio); then a Bluetooth
  address of our own, cameras (feasibility studied: likely weeks of work,
  quality far below stock), easy unlock and the NPU; buttons,
  USB-C/charging and WiFi throughput stay open
  ([docs/ROADMAP.md](docs/ROADMAP.md)).

Panel: previously listed as "BOE NT37290" (module `panel_boe_nt37290` loaded on
an earlier stock build); a third-party bring-up names it `google,gs-km4`. On
our unit the bootloader passes `exynos_drm.panel_name=google-km4.…`, so the
bootloader identifies the panel as `google-km4`.

### Hardware status

"Reported" means a third party reports it working on `komodo`; the "Our unit"
column is what we verified ourselves. Full matrix in [docs/STATUS.md](docs/STATUS.md).

| Component | Our unit | Third-party reports |
|---|---|---|
| Boot | **works** (slot B, Nura from `userdata`; slot B marked successful since 2026-11-26, the retry counter no longer drops); `reboot bootloader` reaches fastboot | reported (Omamobile kernel PR #276) |
| UFS storage | **works**: `userdata` read-write, every other partition kept read-only | reported (PR #276) |
| Root on userdata | **works** (ext4 image on loop, 4096-byte sectors) | reported (PR #276) |
| USB gadget (NCM/ACM/SSH) | **works** (SSH to Nura at `172.16.43.1`); intermittent `error -71` enumeration failures on some boots | reported (PR #276) |
| Display | **works**: real KMS (`gs-decon` stage 2), 60 Hz, brightness control; no 120 Hz, no real panel sleep | reported (PR #276) |
| Buttons | **partial**: keys seen, no verified action under Phosh | reported (PR #276) |
| Touchscreen | **works** (Synaptics S3908, SPI; Phosh graphical login and use by touch); multitouch, palm rejection, accuracy and suspend/resume untested | described but disabled (PR #276) |
| GPU (Mali-G715) | **works** (Panthor + Mesa 26.3.1, OpenGL ES 3.1; no measurements) | described but disabled (PR #276) |
| USB Type-C / charging | charger **detected**, 500 mA from a PC port (barely charges); managed Type-C **not supported** | Type-C described but disabled (PR #276) |
| WiFi | **works** (BCM4390 through our `brcmfmac` patch 0013, not upstream; firmware from your own factory image); throughput not measured, P2P most likely broken, 6 GHz/WiFi 7/suspend untested | described but disabled (PR #276) |
| Bluetooth | **works** (BCM4390 on the APM UART through our patches 0014–0015, not upstream; firmware from your own factory image); chip's generic default address, audio/profiles/suspend untested | unknown |
| Battery / fuel gauge | **works**, read-only (percentage, design capacity) | unknown |
| Audio | **experimental**: bottom speaker at the bring-up minimum and microphone 0 only; no desktop sound; amplifiers without protection firmware (a higher volume can damage a speaker) | unknown |
| Sensors | untested | unknown |
| Modem / calls / SMS | **not supported** | unknown |
| Cameras | **not supported** | unknown |
| NFC | untested | unknown |
| Fingerprint | untested | unknown |

### Risk warning

Flashing anything to this phone **wipes all user data** (unlocking the
bootloader alone does), can leave it **unbootable or bricked**, and may
permanently lose device-unique calibration/identity data if you skip backups.
Everything here is provided **as is, without any warranty**. Read
[docs/SAFETY.md](docs/SAFETY.md) before touching your device. You are solely
responsible for your hardware.

### AI disclosure

This project is developed **with the assistance of generative AI agents**
(research, documentation, scripts and possibly kernel/device code).
[Nura's AI policy](https://docs.nura.eco/policies-and-processes/development/ai-policy.html)
does not accept generative-AI contributions to official pmaports, so this
is deliberately an **independent repository**, and nothing from here should be
submitted upstream to Nura as-is. Human review is applied, but treat all content
with appropriate scepticism.

### Credits

- [Omamobile](https://github.com/derekross/omamobile) and its kernel fork
  [linux-omarchy-mobile](https://github.com/derekross/linux-omarchy-mobile)
  (mainline + Tensor support, Pixel 9a `tegu` work, `komodo` board in PR #276).
  The kernel repository has since been renamed on GitHub to
  [linux-omamobile](https://github.com/derekross/linux-omamobile); the old
  links redirect.
- The `komodo` bring-up work in Omamobile itself:
  [PR #914](https://github.com/derekross/omamobile/pull/914) and
  [PR #567](https://github.com/derekross/omamobile/pull/567) of
  `derekross/omamobile`.
- [Noxyntious/linux](https://github.com/Noxyntious/linux), branch `pixel9a`
  (`zumapro-komodo.dts`, not verified on hardware).
- The Nura (postmarketOS) community, for pmbootstrap, pmaports and the
  gs101 (Pixel 6) groundwork.
- Google's GPL-2.0 bcmdhd driver for the BCM4390
  (`kernel/google-modules/wlan/bcmdhd/bcm4390` on android.googlesource.com),
  the reference for patch 0013, which builds on the BCM4398/BCM4383 support
  in the Omamobile kernel's `brcmfmac`.
- The Pixel 9a (`tegu`) and Pixel 8 Pro Bluetooth work in the Omamobile
  kernel (`hci_bcm` with the `brcm,ble-dbo` latch), on which patches
  0014–0015 build.
- The Pixel 9a and Pixel 8 Pro audio work in Omamobile: Lef's (`Somnius`)
  pull requests [#204](https://github.com/derekross/linux-omamobile/pull/204)
  and [#203](https://github.com/derekross/linux-omamobile/pull/203) of
  `derekross/linux-omamobile`, carried unchanged as patches 0017 and 0022;
  the tegu sound card of PR #193, base of patch 0021; and Omamobile's AoC
  start scripts (MIT), adapted as `scripts/audio/komodo-aoc-start`.

### Following the project

Development happens on the public `main` branch. The journal in
[docs/JOURNAL.md](docs/JOURNAL.md) records every step, including failures, and
[docs/ROADMAP.md](docs/ROADMAP.md) lists the planned phases. Contributors:
run the privacy checklist in
[docs/SAFETY.md](docs/SAFETY.md#before-every-commit-or-push--antes-de-cada-commit-o-push)
before every commit or push.

### License

[MIT](LICENSE) for everything written for this project (scripts, packaging, docs). Any file derived from the Linux kernel (device trees, patches) keeps its upstream license (GPL-2.0), stated in its SPDX header; the kernel package [`pmaports/device/testing/linux-google-zumapro/`](pmaports/device/testing/linux-google-zumapro/) (its patches and kernel config included) is GPL-2.0-only, as its `APKBUILD` declares (`license=`), since patch and config files carry no SPDX header. Firmware extracted from Google's factory image is **not** redistributed here.

---

## Español

### Qué es

Un esfuerzo comunitario e independiente para llevar [Nura](https://postmarketos.org)
(antes postmarketOS, renombrado el 2026-09-27 según el anuncio del proyecto) al **Google Pixel 9 Pro XL**
(nombre en clave `komodo`, SoC Google Tensor G4 / `zumapro`).

No hay port oficial de `komodo` en pmaports/Nura y el Linux mainline no soporta
`zumapro` (a fecha 2026-11-24). Este repositorio parte del trabajo de
[Omamobile](https://github.com/derekross/omamobile) y su fork del kernel con
soporte Tensor. **No** está afiliado a Nura, postmarketOS, Google ni Omamobile.

### Estado actual (honesto)

- Bootloader: **desbloqueado** en nuestra unidad (estado de arranque
  verificado orange).
- Stock: Android 17 estable `CP4A.261105.040.A1` en **ambos** slots (mismo
  bootloader en los dos), actualizaciones automáticas desactivadas. Cómo:
  [docs/UNLOCK.md](docs/UNLOCK.md). Las cinco particiones de arranque del
  slot B llevan ahora las imágenes de Nura (`vbmeta_b` stock) y es el slot que
  arrancamos.
- Hito 1 (2026-11-24): kernel de base mainline arrancado solo en RAM desde
  el slot B, gadget USB con consola serie y SSH, UFS en solo lectura.
  [docs/MILESTONE-1.md](docs/MILESTONE-1.md).
- **Hito 2 superado (2026-11-25): Nura en `userdata`.** Construido con
  pmbootstrap 3.12.1 (edge, UI de consola, systemd); kernel
  `7.3.0-rc6-zumapro`; raíz escrita en `userdata` (imagen ext4 en un loop
  con sectores de 4096, ampliada a 221,6 GiB en el primer arranque); las
  cinco imágenes de arranque del slot B salen de lo que genera pmbootstrap
  (`vbmeta_b` stock). Nura llega a `login:` en pantalla; por SSH (USB NCM,
  `172.16.43.1`): sistema `running`, 0 unidades fallidas, 15,1 GiB de RAM,
  8 CPU, guardia de solo lectura del UFS sin avisos. Procedimiento:
  [docs/MILESTONE-2.md](docs/MILESTONE-2.md).
- **El táctil funciona (2026-11-25).** Synaptics S3908 por SPI (TouchComm),
  con el driver `synaptics_tcm` del árbol de Omamobile (no es mainline; ya
  venía integrado en el kernel). El DTS de la placa ya lo describía,
  desactivado por política en el PR #276; nuestro parche de kernel 0004 lo
  activa (paquete `pkgrel=1`). No hace falta firmware externo. Después se
  reinstaló Nura con la UI `buffyboard` (consola de framebuffer con teclado
  en pantalla) y el dueño inició sesión en el `login:` tocando, sin cable: la
  primera sesión local sin PC (la UI gráfica llegó en el hito 3). Sin
  probar: multitáctil real, rechazo de palma, precisión/calibración, táctil
  tras suspender/reanudar.
- **Hito 3 (2026-11-25): Phosh sobre KMS real con GPU.** Paquete del kernel
  `pkgrel=2` (11 parches sobre el mismo commit) y del dispositivo `pkgrel=3`.
  Pantalla: `gs-decon` stage 2 (KMS real) a 60 Hz, brillo con un driver
  mínimo propio del panel `google,km4`. GPU: Mali-G715 con Panthor y el
  firmware CSF de Arm (`linux-firmware-arm` de Alpine); Mesa 26.3.1 la
  presenta como "Mali-G715 MC7 (Panfrost)", OpenGL ES 3.1; sin medidas de
  rendimiento. Batería: el fuel gauge MAX77779 lee el porcentaje y la
  capacidad de diseño (5035 mAh); el cargador se detecta, pero desde un USB
  de PC (500 mA) casi no carga. `reboot bootloader` llega a fastboot sin
  botones. Nura reinstalado con Phosh: login gráfico tocando, acelerado por
  GPU, cero unidades fallidas tras un reinicio limpio.
  [docs/MILESTONE-3.md](docs/MILESTONE-3.md).
- **Hito 4 (2026-11-25): WiFi.** El chip es un Broadcom BCM4390 (WiFi 7 +
  Bluetooth, PCI `14e4:4438`, revisión b1). Paquete del kernel `pkgrel=3`:
  el parche 0012 enciende el enlace PCIe (`pcie_1`, Gen3 x1, pool DMA
  restringido de 16 MiB) y el 0013 añade el chip a `brcmfmac`, siguiendo el
  driver GPL bcmdhd de Google donde difiere del BCM4398. **El 0013 no está
  en upstream ni se ha enviado a ningún sitio.** El firmware es propietario
  y no está en este repositorio: lo sacas de tu propia imagen de fábrica y
  lo instalas con
  [`scripts/install-wifi-firmware.sh`](scripts/install-wifi-firmware.sh).
  Resultado: `wlan0` al arrancar, escaneo en 2,4 y 5 GHz, conexión WPA
  desde los ajustes de Phosh, ping de ~18 ms sin pérdidas, `apk update` por
  WiFi, reconexión automática. Velocidad **sin medir**; WiFi Direct casi
  seguro roto; 6 GHz, WiFi 7, suspensión, ahorro de energía y modo AP sin
  probar. [docs/MILESTONE-4.md](docs/MILESTONE-4.md).
- **Hito 5 (2026-11-25): Bluetooth.** La mitad Bluetooth del mismo BCM4390,
  por la UART del APM. Paquete del kernel `pkgrel=4`: el parche 0014
  describe en el DTS la UART, el biestable de encendido y las líneas de
  wake, y el 0015 añade el chip a `hci_bcm` con el retardo de encendido de
  100 ms del HAL de fábrica; la config añade `BT_LE`, `BT_RFCOMM` y
  `BT_RFCOMM_TTY`. **0014 y 0015 no están en upstream ni se han enviado a
  ningún sitio.** El firmware (`BCM_200.hcd`) es propietario y no está en
  este repositorio: lo sacas de tu propia imagen de fábrica y lo instalas
  con [`scripts/install-bt-firmware.sh`](scripts/install-bt-firmware.sh).
  Resultado: `hci0` encendido por BlueZ, un escaneo de 12 s vio 16
  dispositivos, emparejamiento y conexión con un teléfono desde los ajustes
  de Phosh con el WiFi conectado a la vez, carga automática al arrancar
  (~10 s) y emparejamiento conservado tras reiniciar. El controlador usa la
  **dirección por defecto** del chip (genérica, igual en todo BCM4390 sin
  configurar); siete avisos `Failed to read codec capabilities (-22)`;
  audio por Bluetooth imposible de probar (aún no hay audio); suspensión,
  perfiles (HID, A2DP, compartir conexión) y 4 Mbaud sin probar.
  [docs/MILESTONE-5.md](docs/MILESTONE-5.md).
- **Hito 6 (2026-11-25): primer audio, experimental.** Todo el audio pasa
  por el AoC, el coprocesador de audio de Google, que Trusty y la GSA
  arrancan con su firmware firmado; dos amplificadores Cirrus CS35L41
  mueven los altavoces. Instalado el paquete del kernel `pkgrel=6`
  (parches 0016–0021): el AoC arranca (firmware `16099865-polygon`, 94
  servicios, de tu propia imagen de fábrica, no está en este repositorio),
  los dos amplificadores se identifican y aparece la tarjeta de sonido. Un
  tono de 1 kHz de 2 s con la ganancia analógica mínima se oyó por el
  **altavoz inferior** y el **micrófono 0** lo captó. **Aviso: los
  amplificadores funcionan sin el firmware de protección de Cirrus y sin la
  calibración de fábrica; subir el volumen puede dañar un altavoz de forma
  irreversible.** Todos los módulos de audio siguen en lista negra y los
  niveles, en el mínimo de puesta en marcha. Los parches 0017 y 0022 son
  los pull requests #204 y #203 de Lef al kernel de Omamobile; el
  `pkgrel=7` (con 0022–0023) se compiló, instaló y arrancó el 2026-11-26, y
  un `aplay` por defecto ya llega al final en EP6. PipeWire ignora la tarjeta
  a propósito, así que el escritorio no tiene sonido; sin probar el altavoz
  superior/auricular, estéreo, volumen de uso, los otros dos micrófonos,
  audio por Bluetooth ni llamadas.
  [docs/MILESTONE-6.md](docs/MILESTONE-6.md).
- Datos de Android: **perdidos** al flashear `userdata` (esperado). Slot A,
  bootloader, radio y `vbmeta`, sin tocar.
- Paquetes: [`pmaports/device/testing/`](pmaports/device/testing/)
  (`device-google-komodo`, `linux-google-zumapro`) y
  [`scripts/mkimages-pmos.sh`](scripts/mkimages-pmos.sh).
- Contador del slot B: **resuelto en nuestra unidad el 2026-11-26** (un byte
  de `devinfo`, escrito y verificado; el contador ya no baja y el ABL ya no
  vuelve solo al slot A (deducción: no se ha provocado un fallo con B marcado)). Lo decide cada dueño; ver
  [docs/SLOT-B.md](docs/SLOT-B.md) y [docs/SAFETY.md](docs/SAFETY.md).
- Problemas conocidos: audio solo experimental (arriba), sin módem ni
  cámaras; WiFi y
  Bluetooth con los límites de arriba (avisos `Set join_pref error (-52)` y fallo de la
  interfaz P2P en el log); sin USB-C gestionado
  (parche del TCPC preparado, sin integrar); botones sin acción comprobada;
  apagado sin probar; fallos intermitentes de enumeración USB (`error -71`)
  en algunos arranques; bajo Phosh hubo que desactivar `buffyboard` a mano
  (inyectaba teclas fantasma); en el primer arranque de cada instalación
  nueva falla `systemd-firstboot.service` (no tiene consola de entrada) y
  deja el sistema `degraded` en ese arranque.
- Copia de seguridad de las particiones: hecha desde el Linux del hito 1,
  guardada en privado.
- Siguiente, en este orden: audio (PipeWire con techo de volumen,
  firmware de protección y calibración,
  altavoz superior, los otros micrófonos, audio por Bluetooth); después,
  dirección Bluetooth propia, cámaras (viabilidad estudiada: probablemente
  semanas de trabajo, calidad muy inferior a la de stock), desbloqueo
  cómodo y la NPU; siguen abiertos los botones, USB-C/carga y el
  rendimiento del WiFi ([docs/ROADMAP.md](docs/ROADMAP.md)).

Panel: antes se indicaba "BOE NT37290" (módulo `panel_boe_nt37290` cargado en
un build stock anterior); un bring-up de terceros lo nombra `google,gs-km4`. En
nuestra unidad el bootloader pasa `exynos_drm.panel_name=google-km4.…`, así que
el bootloader identifica el panel como `google-km4`.

### Estado del hardware

La tabla de arriba aplica. En nuestra unidad: arranque **funciona** (slot B,
Nura desde `userdata`; slot B marcado como correcto desde el 2026-11-26, el
contador ya no baja) y
`reboot bootloader` llega a fastboot; raíz en `userdata` **funciona**; UFS:
`userdata` en lectura/escritura y el resto en solo lectura; gadget USB
(NCM/ACM/SSH) **funciona**, con fallos intermitentes `error -71` en algunos
arranques; pantalla **funciona**: KMS real (`gs-decon` stage 2), 60 Hz,
control de brillo, sin 120 Hz ni reposo real del panel; GPU **funciona**
(Panthor + Mesa 26.3.1, OpenGL ES 3.1, sin medidas); táctil **funciona**
(Synaptics S3908 por SPI; login y uso de Phosh tocando; multitáctil, rechazo
de palma, precisión y suspensión/reanudación sin probar); botones
**parcial**: sin acción comprobada bajo Phosh; batería **funciona** en solo
lectura (porcentaje, capacidad de diseño); cargador **detectado**, 500 mA
desde un USB de PC (casi no carga); WiFi **funciona** (BCM4390 con nuestro
parche 0013 de `brcmfmac`, sin enviar a upstream; firmware de tu propia
imagen de fábrica; velocidad sin medir, P2P casi seguro roto, 6 GHz, WiFi 7
y suspensión sin probar); Bluetooth **funciona** (BCM4390 por la UART del
APM con nuestros parches 0014–0015, sin enviar a upstream; firmware de tu
propia imagen de fábrica; dirección por defecto genérica del chip; audio,
perfiles y suspensión sin probar); audio **experimental** (solo el
altavoz inferior al mínimo de puesta en marcha y el micrófono 0, sin sonido
en el escritorio; amplificadores sin firmware de protección, un volumen
mayor puede dañar un altavoz); USB-C gestionado, módem y cámaras **sin
soporte**; el resto, **sin probar**. Lo marcado como "reported" lo reporta un
tercero (autor del PR #276 del kernel de Omamobile) y no lo hemos reproducido
salvo donde se indica. Matriz completa en [docs/STATUS.md](docs/STATUS.md).

### Aviso de riesgo

Flashear cualquier cosa **borra todos los datos** (desbloquear el bootloader ya
lo hace), puede dejar el teléfono **sin arrancar o brickeado**, y si te saltas
las copias de seguridad puedes perder para siempre datos únicos del dispositivo
(calibración, identidad). Todo se ofrece **tal cual, sin garantía de ningún
tipo**. Lee [docs/SAFETY.md](docs/SAFETY.md) antes de tocar tu dispositivo. Tu
hardware es responsabilidad tuya.

### Declaración de uso de IA

Este proyecto se desarrolla **con asistencia de agentes de IA generativa**
(investigación, documentación, scripts y quizá código de kernel/dispositivo). La
[política de IA de Nura](https://docs.nura.eco/policies-and-processes/development/ai-policy.html)
no acepta contribuciones hechas con IA generativa en
pmaports oficial, así que esto es a propósito un **repositorio independiente** y
nada de aquí debe enviarse tal cual a Nura. Hay revisión humana, pero conviene
tratar todo el contenido con el escepticismo apropiado.

### Créditos

Omamobile y su fork de kernel linux-omarchy-mobile, renombrado después en
GitHub a linux-omamobile (los enlaces antiguos redirigen) (PR #276, placa
`komodo`); el trabajo de bring-up de `komodo` en el propio Omamobile (PR #914 y
#567 de `derekross/omamobile`); Noxyntious/linux (rama `pixel9a`); la
comunidad de Nura (postmarketOS); y el driver GPL-2.0 bcmdhd de Google para el
BCM4390, referencia del parche 0013, que se apoya en el soporte del
BCM4398/BCM4383 del `brcmfmac` del kernel de Omamobile; y el trabajo de
Bluetooth del Pixel 9a (`tegu`) y del Pixel 8 Pro en el kernel de Omamobile
(`hci_bcm` con el biestable `brcm,ble-dbo`), base de los parches 0014–0015;
y el trabajo de audio del Pixel 9a y del Pixel 8 Pro en Omamobile: los pull
requests #204 y #203 de Lef (`Somnius`) a `derekross/linux-omamobile`, que
van tal cual como parches 0017 y 0022, la tarjeta de tegu del PR #193, base
del parche 0021, y los scripts de arranque del AoC de Omamobile (MIT),
adaptados en `scripts/audio/komodo-aoc-start`. Enlaces en la sección
inglesa.

### Cómo seguir el proyecto

El desarrollo se hace en la rama pública `main`. La bitácora
[docs/JOURNAL.md](docs/JOURNAL.md) registra cada paso, fallos incluidos, y
[docs/ROADMAP.md](docs/ROADMAP.md) recoge las fases previstas. Antes de cada
commit o push, repasa la lista de privacidad de
[docs/SAFETY.md](docs/SAFETY.md#before-every-commit-or-push--antes-de-cada-commit-o-push).

### Licencia

[MIT](LICENSE) para todo lo escrito para este proyecto (scripts, empaquetado, documentación). Cualquier fichero derivado del kernel de Linux (device trees, parches) conserva su licencia original (GPL-2.0), indicada en su cabecera SPDX; el paquete del kernel [`pmaports/device/testing/linux-google-zumapro/`](pmaports/device/testing/linux-google-zumapro/) (parches y config incluidos) es GPL-2.0-only, como declara su `APKBUILD` (`license=`), porque los ficheros de parche y de config no llevan cabecera SPDX. El firmware extraído de la imagen de fábrica de Google **no** se redistribuye aquí.
