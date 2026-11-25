# Hardware status / Estado del hardware

Last updated / Última actualización: 2026-11-25

## Device state / Estado del dispositivo

- Bootloader: **unlocked** (`verifiedbootstate` orange), active slot B (Nura).
- Both slots: stock Android 17, `CP4A.261105.040.A1` (patch 2026-11-05), same
  bootloader on both. Automatic system updates disabled.
- Linux: **Milestone 1 passed** (2026-11-24): mainline-based kernel booted
  from slot B, RAM-only. [MILESTONE-1.md](MILESTONE-1.md).
- Display: **text console on screen** since 2026-11-25 (confirmed by eye),
  with the "display A" kernel variant. [JOURNAL.md](JOURNAL.md).
- **Milestone 2 passed** (2026-11-25): Nura edge (console UI, systemd)
  installed on `userdata` and booted from slot B; kernel `7.3.0-rc6-zumapro`.
  Slot B holds the five images built by `mkimages-pmos.sh` (`vbmeta_b`
  stock), with the normal command line (no `pmos.debug-shell`). Android
  data on `userdata` was lost (expected); slot A, bootloader, radio and
  `vbmeta` untouched. [MILESTONE-2.md](MILESTONE-2.md).
- **Touchscreen works** (2026-11-25): kernel package `linux-google-zumapro`
  `pkgrel=1` (patch 0004 enables the Synaptics S3908 node). Nura was then
  reinstalled with the `buffyboard` UI (`userdata` reflashed plus the five
  `_b` images): it boots, SSH over USB at ~26 s, and the owner logged in at
  the on-screen `login:` by touch, without a cable.
  [JOURNAL.md](JOURNAL.md).
- **Milestone 3** (2026-11-25): kernel `linux-google-zumapro` `pkgrel=2`
  (11 patches) and `device-google-komodo` `pkgrel=3`; Nura reinstalled with
  **Phosh**. Real KMS (`gs-decon` stage 2, 60 Hz) with brightness control,
  Mali-G715 through Panthor + Mesa 26.3.1, fuel gauge and charger visible,
  `reboot bootloader` reaches fastboot. Graphical login by touch; zero
  failed units after a clean reboot. Still no WiFi/BT, audio, modem,
  cameras or managed USB-C; slot B retry counter unresolved.
  [MILESTONE-3.md](MILESTONE-3.md).
- **Milestone 4: WiFi works** (2026-11-25): kernel `linux-google-zumapro`
  `pkgrel=3` (patches 0012, `pcie_1` in the DTS, and 0013, the BCM4390 in
  `brcmfmac`), installed with `apk add` on the phone and only `boot_b`,
  `vendor_boot_b` and `vendor_kernel_boot_b` reflashed; device package
  unchanged (`pkgrel=3`). Firmware from the owner's own factory image, not
  redistributed. `wlan0` at boot, scan on 2.4 and 5 GHz, WPA connection from
  Phosh's settings, Internet traffic, automatic reconnection; zero failed
  units after a clean boot. Throughput not measured; WiFi Direct most likely
  broken; 6 GHz, WiFi 7, suspend, power saving and AP mode untried.
  Bluetooth untouched. [MILESTONE-4.md](MILESTONE-4.md).
- **Milestone 5: Bluetooth works** (2026-11-25): kernel
  `linux-google-zumapro` `pkgrel=4` (patches 0014, the BCM4390's Bluetooth
  on the APM UART in the DTS, and 0015, the BCM4390 in `hci_bcm`; config
  with `BT_LE`, `BT_RFCOMM` and `BT_RFCOMM_TTY`); device package unchanged
  (`pkgrel=3`). Firmware `BCM_200.hcd` from the owner's own factory image,
  not redistributed. `hci0` powered by BlueZ, a 12 s scan saw 16 devices,
  paired and connected with a phone from Phosh's settings with WiFi still
  connected; after a reboot it comes up by itself (~10 s), the pairing
  persists, zero failed units. Limits: the chip's default (generic)
  address, seven `Failed to read codec capabilities (-22)` warnings,
  Bluetooth audio untestable (no audio yet); suspend, long idle, profiles
  (HID, A2DP, tethering) and 4 Mbaud untried.
  [MILESTONE-5.md](MILESTONE-5.md).

- Bootloader: **desbloqueado** (`verifiedbootstate` orange), slot activo B (Nura).
- Ambos slots: Android 17 stock, `CP4A.261105.040.A1` (parche 2026-11-05),
  mismo bootloader en los dos. Actualizaciones automáticas desactivadas.
- Linux: **hito 1 superado** (2026-11-24): kernel de base mainline arrancado
  desde el slot B, solo en RAM.
- Pantalla: **consola de texto en pantalla** desde el 2026-11-25 (confirmado a
  ojo), con la variante de kernel "display A".
- **Hito 2 superado** (2026-11-25): Nura edge (UI de consola, systemd)
  instalado en `userdata` y arrancado desde el slot B; kernel
  `7.3.0-rc6-zumapro`. El slot B lleva las cinco imágenes de
  `mkimages-pmos.sh` (`vbmeta_b` stock), con la línea de arranque normal
  (sin `pmos.debug-shell`). Los datos de Android en `userdata` se perdieron
  (esperado); slot A, bootloader, radio y `vbmeta`, sin tocar.
- **El táctil funciona** (2026-11-25): paquete del kernel
  `linux-google-zumapro` `pkgrel=1` (el parche 0004 activa el nodo del
  Synaptics S3908). Después se reinstaló Nura con la UI `buffyboard`
  (`userdata` reflasheado y las cinco imágenes `_b`): arranca, SSH por USB a
  los ~26 s, y el dueño inició sesión en el `login:` de la pantalla tocando,
  sin cable.
- **Hito 3** (2026-11-25): kernel `linux-google-zumapro` `pkgrel=2` (11
  parches) y `device-google-komodo` `pkgrel=3`; Nura reinstalado con
  **Phosh**. KMS real (`gs-decon` stage 2, 60 Hz) con control de brillo,
  Mali-G715 con Panthor + Mesa 26.3.1, fuel gauge y cargador visibles,
  `reboot bootloader` llega a fastboot. Login gráfico tocando; cero
  unidades fallidas tras un reinicio limpio. Sigue sin WiFi/BT, audio,
  módem, cámaras ni USB-C gestionado; contador del slot B sin resolver.
- **Hito 4: el WiFi funciona** (2026-11-25): kernel `linux-google-zumapro`
  `pkgrel=3` (parches 0012, `pcie_1` en el DTS, y 0013, el BCM4390 en
  `brcmfmac`), instalado con `apk add` en el teléfono y reflasheando solo
  `boot_b`, `vendor_boot_b` y `vendor_kernel_boot_b`; paquete del
  dispositivo sin cambios (`pkgrel=3`). Firmware de la imagen de fábrica del
  propio dueño, sin redistribuir. `wlan0` al arrancar, escaneo en 2,4 y
  5 GHz, conexión WPA desde los ajustes de Phosh, tráfico a Internet y
  reconexión automática; cero unidades fallidas tras un arranque limpio.
  Velocidad sin medir; WiFi Direct casi seguro roto; 6 GHz, WiFi 7,
  suspensión, ahorro de energía y modo AP sin probar. Bluetooth sin tocar.
- **Hito 5: el Bluetooth funciona** (2026-11-25): kernel
  `linux-google-zumapro` `pkgrel=4` (parches 0014, el Bluetooth del BCM4390
  en la UART del APM en el DTS, y 0015, el BCM4390 en `hci_bcm`; config con
  `BT_LE`, `BT_RFCOMM` y `BT_RFCOMM_TTY`); paquete del dispositivo sin
  cambios (`pkgrel=3`). Firmware `BCM_200.hcd` de la imagen de fábrica del
  propio dueño, sin redistribuir. `hci0` encendido por BlueZ, un escaneo de
  12 s vio 16 dispositivos, emparejado y conectado con un teléfono desde los
  ajustes de Phosh con el WiFi conectado a la vez; tras reiniciar sube solo
  (~10 s), el emparejamiento se conserva, cero unidades fallidas. Límites:
  dirección por defecto (genérica) del chip, siete avisos `Failed to read
  codec capabilities (-22)`, audio por Bluetooth imposible de probar (aún
  no hay audio); sin probar suspensión, reposo prolongado, perfiles (HID,
  A2DP, compartir conexión) ni 4 Mbaud.

Details / Detalles: [DEVICE.md](DEVICE.md), [UNLOCK.md](UNLOCK.md).

## Legend / Leyenda

- **untested / sin probar**: not tried on our unit.
- **reported / reportado**: a third party reports it working on `komodo`; not reproduced by us.
- **disabled upstream / desactivado**: described in third-party DTS but disabled there.
- **works / funciona**, **partial / parcial**, **broken / roto**, **no output / sin salida**: verified on our unit.

Display: on our unit, with the PR #276 tree at commit `ffd33b7` as used in
Milestone 1, there is **no** display output, which qualifies the third-party
"reported". With our "display A" variant (`gs-decon` built in, a
`simple-framebuffer` node in `/chosen`, `gs_decon.stage=1`) the screen shows
the Linux text console (verified 2026-11-25), and Nura's `login:` prompt
(Milestone 2). The patches are published in
[`../pmaports/device/testing/linux-google-zumapro/`](../pmaports/device/testing/linux-google-zumapro/). / Pantalla: en nuestra unidad, con el árbol del PR #276 en
el commit `ffd33b7` tal como se usó en el hito 1, **no** hay salida de
pantalla, lo que matiza el "reported" de terceros. Con nuestra variante
"display A" (`gs-decon` integrado, nodo `simple-framebuffer` en `/chosen`,
`gs_decon.stage=1`) la pantalla muestra la consola de texto de Linux
(verificado el 2026-11-25) y el `login:` de Nura (hito 2). Los parches están
publicados en el paquete `linux-google-zumapro`.

Since Milestone 3 (kernel `pkgrel=2`, device `pkgrel=3`) the display runs as
real KMS: `gs_decon.stage=2 gs_decon.fbdev=1 gs_dsim_cmd.allow_tx=1` from
the device package's command line (it comes after the DTB's `stage=1`, and
on our unit the later value takes effect), 60 Hz, with the
`simple-framebuffer` kept in the DT as a fallback (patch 0010). Brightness
through the minimal KM4 panel driver (patches 0008–0009). / Desde el hito 3
la pantalla va con KMS real (`gs-decon` stage 2, 60 Hz) y control de brillo
con el driver mínimo del panel KM4; el `simple-framebuffer` queda en el DT
como respaldo (parche 0010).

Touchscreen: enabled by patch 0004 of the same package (`pkgrel=1`); it only
removes the `status = "disabled"` line that PR #276 left on the node by
policy. / Táctil: lo activa el parche 0004 del mismo paquete (`pkgrel=1`);
solo quita la línea `status = "disabled"` que el PR #276 dejó en el nodo por
política.

GPU: patch 0011 enables the Mali-G715; Panthor loads by itself ~5 s into the
boot since device `pkgrel=3` (it was blacklisted at first, because G3D has
no power domain driver and depends on the bootloader leaving it powered). /
GPU: el parche 0011 activa la Mali-G715; Panthor se carga solo desde el
dispositivo `pkgrel=3` (antes estaba en lista negra, porque G3D no tiene
driver de power domain y depende de que el bootloader lo deje encendido).

WiFi: patch 0012 powers `pcie_1` (`WL_REG_ON` on `gph3-4`, a 16 MiB
restricted DMA pool) and 0013 adds the BCM4390 to `brcmfmac`, following
Google's GPL bcmdhd driver where the chip differs from the BCM4398. 0013 is
not upstream and has not been sent anywhere. The firmware comes from the
owner's own factory image and is installed with
`scripts/install-wifi-firmware.sh`; this repository does not ship it. / WiFi:
el parche 0012 enciende `pcie_1` y el 0013 añade el BCM4390 a `brcmfmac`,
siguiendo el driver GPL bcmdhd de Google donde el chip difiere del BCM4398.
0013 no está en upstream ni se ha enviado. El firmware sale de la imagen de
fábrica del propio dueño y no se distribuye aquí.

Bluetooth: patch 0014 describes the BCM4390's Bluetooth half on the APM's
UART (`serial@155d0000`, `ttySAC0`) with its power latch and wake lines, at
3 Mbaud (stock uses 4), and 0015 gives `hci_bcm` a `brcm,bcm4390-bt` entry
with the stock HAL's 100 ms power-on delay (`brcm,bcm4389-bt` stays as a
fallback). Neither is upstream or sent anywhere. The firmware
(`BCM_200.hcd`, loaded as `brcm/BCM.google,zumapro-komodo.hcd`) comes from
the owner's own factory image and is installed with
`scripts/install-bt-firmware.sh`; this repository does not ship it. /
Bluetooth: el parche 0014 describe la mitad Bluetooth del BCM4390 en la UART
del APM a 3 Mbaud (stock usa 4) y el 0015 da a `hci_bcm` una entrada
`brcm,bcm4390-bt` con el retardo de encendido de 100 ms del HAL de fábrica.
Ninguno está en upstream ni se ha enviado. El firmware sale de la imagen de
fábrica del propio dueño y no se distribuye aquí.

Known issue / Problema conocido (Milestone 3 / hito 3): `buffyboard.service`
stayed enabled under Phosh and injected phantom key presses from the same
touches (stray characters in the PIN); disabled by hand, cause of it being
enabled not found yet. / seguía activo bajo Phosh e inyectaba teclas
fantasma; desactivado a mano, sin saber aún qué lo habilita.

Known issue / Problema conocido: `systemd-firstboot.service` fails on the
first boot of every new install ("Failed to set up standard input": it has no
input console) and leaves the system `degraded` for that boot; on the
previous install it did not come back on later boots. / falla en el primer
arranque de cada instalación nueva y deja el sistema `degraded` ese arranque;
en la instalación anterior no reapareció en arranques posteriores.

Source for third-party reports / Fuente de los reportes de terceros:
Omamobile kernel PR #276 (`komodo` board, depends on PR #273), per its author.
<https://github.com/derekross/linux-omarchy-mobile> (renamed on GitHub to
`linux-omamobile`; the old URL redirects / renombrado en GitHub a
`linux-omamobile`; la URL antigua redirige)

| Component / Componente | Hardware (stock) | Our unit / Nuestra unidad | Third party / Terceros | Notes / Notas |
|---|---|---|---|---|
| Boot (slot B) | ABL, boot header v4 | **works** (slot B: RAM-only rescue and Nura on `userdata`) | reported (PR #276) | Milestone 1; "display A" images (2026-11-25, USB gadget at ~26 s); Milestone 2 (Nura; in the rehearsal without `userdata` the initramfs gadget came up at ~28 s). AVB hash footer with AOSP test key, `vbmeta_b` stock; ABL appends the `vendor_boot` cmdline (verified). **Every boot spends one of slot B's 3 retries** and nothing marks it successful; at 0 the ABL boots slot A. Workaround: `fastboot set_active b` beforehand. Unresolved. Since Milestone 3, `reboot bootloader` reaches fastboot without buttons (patch 0007 + `reboot=warm`) and did not spend an extra retry. A `komodo-bootctl` tool to mark the slot ships in the device package as source only: not compiled, never used to write `devinfo` |
| UFS storage | 256 GB UFS | **works**: `userdata` read-write, everything else read-only | reported (PR #276) | Milestone 2: udev/initramfs guard keeps every UFS partition except `userdata` read-only (`--check` = 0); the whole `sda` LUN stays writable by design (it holds `userdata`) |
| Root on userdata | — | **works** | reported (PR #276) | ext4 image (GPT with 4096-byte sectors, `pmOS_boot` + `pmOS_root`) on a loop device over `userdata`, grown to 221.6 GiB on first boot. Single `userdata`: stock Android reportedly reformats it (not verified by us) |
| USB gadget (NCM/ACM/SSH) | — | **works** | reported (PR #276) | `1d6b:0104`. Milestone 1: `172.16.42.0/24`, ~24 s. Nura: `172.16.43.0/24` (phone `.1`), PC-side MAC `02:6b:6f:6d:6f:01` (fixed, from `deviceinfo`). On Nura's first boot the PC did not enumerate it (errors `-71`); it came back intermittently on some boots in Milestone 3, cause unknown. Later "drops" were the PC losing its static IP on re-enumeration (fixed with a NetworkManager profile by MAC). With `pmos.debug-shell` the debug shell on `ttyGS0` is garbled (two readers); telnet works |
| Display | panel `google-km4` (bootloader name; see note) | **works** (KMS, 60 Hz, brightness); no 120 Hz, no real panel sleep | reported (PR #276) | Milestone 3: `gs-decon` stage 2 (real KMS, fbdev on top), Phosh on it; backlight device from our minimal `google,km4` driver (patch 0008, range 0..3271, 0 = pixel off) through DSIM0 as a DCS host (0009); `simple-framebuffer` kept as fallback (0010). Not done: 120 Hz, display off/sleep-in sequence on a KMS port, suspend. Before Milestone 3, "display A" variant: `simple-framebuffer` on the bootloader framebuffer at `0xfac00000` (1344x2992, a8r8g8b8); Nura shows `login:` on it (Milestone 2); command-mode DSI panel, frames at ~60 Hz after `gs_decon.stage=1` unmasks the frame trigger. No GPU/acceleration, no real modesetting (no `km4` panel driver in the tree), no backlight device (brightness as left by the bootloader), no screen off/on. Milestone 1 tree: no output |
| Buttons (power/vol) | — | **partial** | reported (PR #276) | Milestone 3 (Phosh): no verified action for any key; the device package's logind drop-in (long press = power off, meant for console UIs) is unchecked. Earlier, console UI: logind logs "Power key pressed short", but nothing powers off or reboots. From Linux, Power+Vol− does **not** reach fastboot; we got there with a button-forced reboot and then holding Vol− (exact combination not recorded). From the bootloader/stock, Power+Vol− reaches fastboot |
| Touchscreen | Synaptics S3908, SPI, TouchComm (stock driver `syna_touch`) | **works** | disabled upstream (PR #276) | Node `touchscreen@0` (`syna,s3908`) on `spi@111d0000`, enabled by our patch 0004 (`pkgrel=1`); rails (S2MPG14 LDOs via ACPM), reset and IRQ match the stock DTBO. Driver `synaptics_tcm` (Omamobile tree, not mainline) built in; no external firmware (the chip runs the one in its own flash). dmesg: `S3908GA1B0-15.0, TouchComm v1`, 13440x29920, 10 objects; input device "Synaptics TouchComm Touchscreen"; probe does not delay boot (~0.6 s of kernel time). Verified: typing with `buffyboard` (initramfs debug shell and Nura's `login:`), chip IRQ counter rises with touches. Milestone 3: graphical login and use under Phosh by touch. Untested: real multitouch, palm rejection, accuracy/calibration, suspend/resume |
| GPU | Mali-G715 | **works** (no measurements) | disabled upstream (PR #276) | Patch 0011 (`gpu`, `cmu_g3d`, OPP 150/302 MHz). Panthor + CSF firmware `arm/mali/arch11.8/mali_csffw.bin` (Alpine `linux-firmware-arm`); Mesa 26.3.1 reports "Mali-G715 MC7 (Panfrost)", OpenGL ES 3.1; Phosh GPU-accelerated. Autoloads ~5 s into the boot (device `pkgrel=3`). No power domain driver: relies on the bootloader leaving G3D on. No DVFS beyond 302 MHz, no thermal limits, no suspend, no performance numbers |
| USB Type-C | MAX77779 TCPC (inferred) | **not supported** | disabled upstream (PR #276) | No managed USB-C (no roles, no USB-PD). A TCPC patch is prepared but not integrated |
| Charging | MAX77779 charger (`i2c@108d0000`, 0x69) | **partial**: detected, read-only | unknown | Patch 0006. From a PC USB port the input is 500 mA: the battery holds, barely charges. No charge policy, no thermal bands; wall/fast charger untested |
| Battery / fuel gauge | MAX77779 fuel gauge (`i2c@108d0000`, 0x36) | **works** (read-only) | unknown | Patch 0005: percentage and design capacity (5035 mAh) readable. Shunt value (2 mΩ) taken from the Pixel 9a reference, checked only against the design capacity (the stock DT gives 4942 mAh, about 2 % lower) |
| Power off | — | untested | unknown | not tried under Nura |
| CPU frequency | — | **works** | unknown | cpufreq (schedutil) under Nura; only `clk-acpm` and `gs101_acpm_tmu` load by modalias |
| WiFi | BCM4390 (`bcmdhd4390`), PCIe `14e4:4438`, chip revision b1 (PCI rev `0x05`) | **works** (throughput not measured) | disabled upstream (PR #276) | Milestone 4: patches 0012 (`pcie_1`, Gen3 x1 link, 16 MiB DMA pool) and 0013 (`brcmfmac`, not upstream). Firmware `27.10.1121.57.30` from the owner's own factory image, not redistributed. Scan on 2.4/5 GHz (WPA2, WPA3 seen), WPA connection from Phosh, ping ~18 ms without loss, automatic reconnection. Only an advertised link rate of 270 Mbit/s on 5 GHz; `Set join_pref error (-52)`; `p2p-dev-wlan0` not created (WiFi Direct most likely broken). Untested: 6 GHz, WiFi 7/EHT, suspend, power saving, AP mode. NVRAM chosen without reading the OTP; template MAC in it (NetworkManager randomises) |
| Bluetooth | BCM4390 combo, Bluetooth half on the APM UART (`serial@155d0000`) | **works** (with limits) | unknown | Milestone 5: patches 0014 (DTS) and 0015 (`hci_bcm`, not upstream), `hci_uart` + `btbcm` at 3 Mbaud. ROM `BCM4390B1`, factory `BCM_200.hcd` from the owner's own image (not redistributed), patch loaded in ~4 s (build 0000 → 0474). BlueZ powers `hci0` (LE central and peripheral roles); 12 s scan saw 16 devices; paired and connected with a phone from Phosh, WiFi connected at the same time; autoloads at boot (~10 s), pairing persists, zero failed units. **Default chip address** (generic, the same on every unconfigured BCM4390; the unit's own not located, to be set with `btmgmt public-addr` or similar). Seven `Failed to read codec capabilities (-22)`. Untested: Bluetooth audio (no audio yet), HID/A2DP/tethering, suspend and long idle, 4 Mbaud |
| Audio (amps/haptics) | cs35l41 / cs40l26 | **not supported** | unknown | Not started. AoC involved (unverified how) |
| Sensors | unverified | untested | unknown | |
| Modem / calls / SMS / data | unverified | **not supported** | unknown | Not started |
| Cameras | front Sony IMX858, main Samsung ISOCELL GN 50 MP (from the stock camera HAL; not read on the phone) | **not supported** | unknown | Not started; feasibility studied, see [ROADMAP.md](ROADMAP.md) |
| NFC | unverified | untested | unknown | |
| Fingerprint | unverified | untested | unknown | |
| pKVM / virtualization | active on stock | untested | unknown | |

## Panel note / Nota sobre el panel

Earlier versions of this file listed the panel as "BOE NT37290", from the
module `panel_boe_nt37290` seen loaded on the previous stock build (Android 16
Beta); a third-party bring-up names it `google,gs-km4` in Google's device
tree. **Settled on 2026-11-24 (Milestone 1):** the cmdline that the bootloader
adds on our unit contains `exynos_drm.panel_name=google-km4.…`, so the
bootloader identifies this unit's panel as `google-km4`. `panel_boe_nt37290`
was the module Android loaded.

Versiones anteriores decían "BOE NT37290", por el módulo `panel_boe_nt37290`
cargado en el build stock anterior (Android 16 Beta); un bring-up de terceros
lo nombra `google,gs-km4` en el device tree de Google. **Resuelto el
2026-11-24 (hito 1):** la cmdline que añade el bootloader en nuestra unidad
contiene `exynos_drm.panel_name=google-km4.…`, así que el bootloader identifica
el panel de esta unidad como `google-km4`. `panel_boe_nt37290` era el módulo
que cargaba Android.
