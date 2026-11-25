# Nura / postmarketOS on Google Pixel 9 Pro XL (komodo)

> **Status: mainline-based Linux boots on our unit (RAM-only from slot B) and
> shows a text console on the screen. Nura is not installed yet. Stock Android
> 17 stays on slot A.**
>
> **Estado: Linux (base mainline) arranca en nuestra unidad (solo en RAM desde
> el slot B) y muestra una consola de texto en la pantalla. Nura aún no está
> instalado. Android 17 stock sigue en el slot A.**

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
  bootloader on both), active slot A, automatic updates disabled. How:
  [docs/UNLOCK.md](docs/UNLOCK.md).
- Linux flashed: the five slot-B boot images of the "display A" kernel variant
  (they replaced the Milestone 1 images; `vbmeta_b` stock); slot A untouched.
- Boots: **yes, RAM-only** (Milestone 1 passed, 2026-11-24): kernel
  `7.3.0-rc6-omamobile-push1` from slot B, USB gadget with serial console and
  SSH, UFS detected and kept read-only, stable for more than 7 minutes.
  Procedure: [docs/MILESTONE-1.md](docs/MILESTONE-1.md).
- Display: **text console on the screen** (confirmed by eye on 2026-11-25).
  The "display A" kernel variant builds `gs-decon` in and adds a
  `simple-framebuffer` node pointing at the framebuffer the bootloader leaves
  on; `simpledrm` drives it and `fbcon` draws the Linux console. No GPU or
  acceleration, no real modesetting, no backlight control, no screen off/on.
  The display patches are not published in this repository yet (they will be
  later). Details: [docs/JOURNAL.md](docs/JOURNAL.md).
- Backup of the device's partitions: done from that Linux, kept private.
- Next: Milestone 2, Nura with pmbootstrap and root on `userdata`; on the
  display side, a panel driver/KMS, backlight and GPU
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
| Boot | **works** (RAM-only, slot B) | reported (Omamobile kernel PR #276) |
| UFS storage | **detected, read-only tested** | reported (PR #276) |
| Root on userdata | untested | reported (PR #276) |
| USB gadget (NCM/ACM/SSH) | **works** | reported (PR #276) |
| Display | **partial**: text console (`simpledrm` on the bootloader framebuffer); no KMS, backlight or GPU | reported (PR #276) |
| Buttons | Power+Vol− reaches fastboot; under Linux untested | reported (PR #276) |
| Touchscreen | untested | described but disabled (PR #276) |
| GPU (Mali-G715) | untested | described but disabled (PR #276) |
| USB Type-C / charging | untested | Type-C described but disabled (PR #276) |
| WiFi | untested | described but disabled (PR #276) |
| Bluetooth | untested | unknown |
| Battery / fuel gauge | untested | unknown |
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

[MIT](LICENSE) for everything written for this project (scripts, packaging, docs). Any file derived from the Linux kernel (device trees, patches) keeps its upstream license (GPL-2.0), stated in its SPDX header. Firmware extracted from Google's factory image is **not** redistributed here.

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
  bootloader en los dos), slot activo A, actualizaciones automáticas
  desactivadas. Cómo: [docs/UNLOCK.md](docs/UNLOCK.md).
- Linux flasheado: las cinco imágenes de arranque del slot B de la variante de
  kernel "display A" (sustituyeron a las del hito 1; `vbmeta_b` stock); el
  slot A, intacto.
- Arranca: **sí, solo en RAM** (hito 1 superado, 2026-11-24): kernel
  `7.3.0-rc6-omamobile-push1` desde el slot B, gadget USB con consola serie y
  SSH, UFS detectado y en solo lectura, estable más de 7 minutos.
  Procedimiento: [docs/MILESTONE-1.md](docs/MILESTONE-1.md).
- Pantalla: **consola de texto en pantalla** (confirmado a ojo el
  2026-11-25). La variante "display A" integra `gs-decon` en el kernel y añade
  un nodo `simple-framebuffer` que apunta al framebuffer que deja encendido el
  bootloader; `simpledrm` lo gestiona y `fbcon` pinta la consola de Linux. Sin
  GPU ni aceleración, sin modesetting real, sin control de brillo
  (backlight), sin apagar/encender la pantalla. Los parches de pantalla aún no
  están publicados en este repositorio (se publicarán más adelante). Detalle:
  [docs/JOURNAL.md](docs/JOURNAL.md).
- Copia de seguridad de las particiones: hecha desde ese Linux, guardada en
  privado.
- Siguiente: hito 2, Nura con pmbootstrap y raíz en `userdata`; en pantalla,
  driver de panel/KMS, backlight y GPU ([docs/ROADMAP.md](docs/ROADMAP.md)).

Panel: antes se indicaba "BOE NT37290" (módulo `panel_boe_nt37290` cargado en
un build stock anterior); un bring-up de terceros lo nombra `google,gs-km4`. En
nuestra unidad el bootloader pasa `exynos_drm.panel_name=google-km4.…`, así que
el bootloader identifica el panel como `google-km4`.

### Estado del hardware

La tabla de arriba aplica. En nuestra unidad: arranque **funciona** (solo
RAM, slot B); UFS **detectado, probado solo en lectura**; gadget USB
(NCM/ACM/SSH) **funciona**; pantalla **parcial**: consola de texto
(`simpledrm` sobre el framebuffer del bootloader), sin KMS, brillo ni GPU;
táctil, **sin probar**; botones: solo
verificado que Encendido + Volumen − lleva a fastboot (bajo Linux, sin
probar); el resto, **sin probar**. Lo marcado como "reported" lo reporta un
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

Omamobile y su fork de kernel linux-omarchy-mobile (PR #276, placa
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

[MIT](LICENSE) para todo lo escrito para este proyecto (scripts, empaquetado, documentación). Cualquier fichero derivado del kernel de Linux (device trees, parches) conserva su licencia original (GPL-2.0), indicada en su cabecera SPDX. El firmware extraído de la imagen de fábrica de Google **no** se redistribuye aquí.
