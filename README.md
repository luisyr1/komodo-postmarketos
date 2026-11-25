# Nura / postmarketOS on Google Pixel 9 Pro XL (komodo)

> **Status: Nura (edge, console UI) is installed on `userdata` and boots on our
> unit from slot B to a `login:` prompt on the screen, with SSH over USB
> (Milestone 2, 2026-11-25). No touch, battery or WiFi yet. Stock Android 17
> stays on slot A, but its data was wiped.**
>
> **Estado: Nura (edge, UI de consola) está instalado en `userdata` y arranca en
> nuestra unidad desde el slot B hasta un `login:` en pantalla, con SSH por USB
> (hito 2, 2026-11-25). Aún sin táctil, batería ni WiFi. Android 17 stock sigue
> en el slot A, pero sus datos se borraron.**

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
- Android data: **lost** when `userdata` was flashed (expected). Slot A,
  bootloader, radio and `vbmeta` untouched.
- Display: **text console on the screen** (`simpledrm` on the framebuffer the
  bootloader leaves on, `fbcon`). No GPU or acceleration, no real
  modesetting, no backlight control, no screen off/on. The display patches
  are now published with the kernel package.
- Packages: [`pmaports/device/testing/`](pmaports/device/testing/)
  (`device-google-komodo`, `linux-google-zumapro`) and
  [`scripts/mkimages-pmos.sh`](scripts/mkimages-pmos.sh).
- Known problems: the slot-B retry counter is spent on every boot and nothing
  marks the slot successful (after 3 boots the ABL falls back to slot A;
  `fastboot set_active b` beforehand); no touch input (login only over SSH);
  no battery/charging support; the power key is seen but does nothing.
- Backup of the device's partitions: done from the Milestone 1 Linux, kept
  private.
- Next: slot-B retry counter, buttons, touchscreen, battery/charging, WiFi
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
| Boot | **works** (slot B, Nura from `userdata`; each boot spends a slot-B retry) | reported (Omamobile kernel PR #276) |
| UFS storage | **works**: `userdata` read-write, every other partition kept read-only | reported (PR #276) |
| Root on userdata | **works** (ext4 image on loop, 4096-byte sectors) | reported (PR #276) |
| USB gadget (NCM/ACM/SSH) | **works** (SSH to Nura at `172.16.43.1`) | reported (PR #276) |
| Display | **partial**: text console (`simpledrm` on the bootloader framebuffer), Nura `login:` on screen; no KMS, backlight or GPU | reported (PR #276) |
| Buttons | **partial**: power key seen by logind, no action; Power+Vol− does not reach fastboot from Linux | reported (PR #276) |
| Touchscreen | **no input** (cannot type at the login) | described but disabled (PR #276) |
| GPU (Mali-G715) | untested | described but disabled (PR #276) |
| USB Type-C / charging | charging **not supported** (no `power_supply`); Type-C untested | Type-C described but disabled (PR #276) |
| WiFi | untested | described but disabled (PR #276) |
| Bluetooth | untested | unknown |
| Battery / fuel gauge | **not supported** (no `/sys/class/power_supply`) | unknown |
| Audio | untested | unknown |
| Sensors | untested | unknown |
| Modem / calls / SMS | untested | unknown |
| Cameras | untested | unknown |
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
- Datos de Android: **perdidos** al flashear `userdata` (esperado). Slot A,
  bootloader, radio y `vbmeta`, sin tocar.
- Pantalla: **consola de texto** (`simpledrm` sobre el framebuffer que deja
  encendido el bootloader, `fbcon`). Sin GPU ni aceleración, sin modesetting
  real, sin control de brillo, sin apagar/encender. Los parches de pantalla ya
  están publicados con el paquete del kernel.
- Paquetes: [`pmaports/device/testing/`](pmaports/device/testing/)
  (`device-google-komodo`, `linux-google-zumapro`) y
  [`scripts/mkimages-pmos.sh`](scripts/mkimages-pmos.sh).
- Problemas conocidos: cada arranque gasta un intento del slot B y nada marca
  el slot como correcto (tras 3 arranques el ABL vuelve al slot A; hay que
  hacer antes `fastboot set_active b`); sin táctil (login solo por SSH); sin
  soporte de batería/carga; la tecla de encendido se detecta pero no hace
  nada.
- Copia de seguridad de las particiones: hecha desde el Linux del hito 1,
  guardada en privado.
- Siguiente: contador del slot B, botones, táctil, batería/carga, WiFi
  ([docs/ROADMAP.md](docs/ROADMAP.md)).

Panel: antes se indicaba "BOE NT37290" (módulo `panel_boe_nt37290` cargado en
un build stock anterior); un bring-up de terceros lo nombra `google,gs-km4`. En
nuestra unidad el bootloader pasa `exynos_drm.panel_name=google-km4.…`, así que
el bootloader identifica el panel como `google-km4`.

### Estado del hardware

La tabla de arriba aplica. En nuestra unidad: arranque **funciona** (slot B,
Nura desde `userdata`; cada arranque gasta un intento del slot B); raíz en
`userdata` **funciona**; UFS: `userdata` en lectura/escritura y el resto en
solo lectura; gadget USB (NCM/ACM/SSH) **funciona**; pantalla **parcial**:
consola de texto con el `login:` de Nura, sin KMS, brillo ni GPU; táctil **sin
entrada** (no se puede escribir en el login); botones **parcial**: logind ve
la tecla de encendido pero no hace nada, y desde Linux Encendido + Volumen −
no lleva a fastboot; batería y carga **sin soporte** (no hay
`/sys/class/power_supply`); el resto, **sin probar**. Lo marcado como "reported" lo reporta un
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
#567 de `derekross/omamobile`); Noxyntious/linux (rama `pixel9a`); y la
comunidad de Nura (postmarketOS). Enlaces en la sección inglesa.

### Cómo seguir el proyecto

El desarrollo se hace en la rama pública `main`. La bitácora
[docs/JOURNAL.md](docs/JOURNAL.md) registra cada paso, fallos incluidos, y
[docs/ROADMAP.md](docs/ROADMAP.md) recoge las fases previstas. Antes de cada
commit o push, repasa la lista de privacidad de
[docs/SAFETY.md](docs/SAFETY.md#before-every-commit-or-push--antes-de-cada-commit-o-push).

### Licencia

[MIT](LICENSE) para todo lo escrito para este proyecto (scripts, empaquetado, documentación). Cualquier fichero derivado del kernel de Linux (device trees, parches) conserva su licencia original (GPL-2.0), indicada en su cabecera SPDX; el paquete del kernel [`pmaports/device/testing/linux-google-zumapro/`](pmaports/device/testing/linux-google-zumapro/) (parches y config incluidos) es GPL-2.0-only, como declara su `APKBUILD` (`license=`), porque los ficheros de parche y de config no llevan cabecera SPDX. El firmware extraído de la imagen de fábrica de Google **no** se redistribuye aquí.
