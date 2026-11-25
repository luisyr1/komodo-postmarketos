# Hardware status / Estado del hardware

Last updated / Última actualización: 2026-11-25

## Device state / Estado del dispositivo

- Bootloader: **unlocked** (`verifiedbootstate` orange), active slot A.
- Both slots: stock Android 17, `CP4A.261105.040.A1` (patch 2026-11-05), same
  bootloader on both. Automatic system updates disabled.
- Linux: **Milestone 1 passed** (2026-11-24): mainline-based kernel booted
  from slot B, RAM-only. Nura not installed yet.
  [MILESTONE-1.md](MILESTONE-1.md).
- Display: **text console on screen** since 2026-11-25 (confirmed by eye),
  with the "display A" kernel variant, whose five images now sit on slot B in
  place of the Milestone 1 ones (`vbmeta_b` stock, slot A untouched). Still
  RAM-only. [JOURNAL.md](JOURNAL.md).

- Bootloader: **desbloqueado** (`verifiedbootstate` orange), slot activo A.
- Ambos slots: Android 17 stock, `CP4A.261105.040.A1` (parche 2026-11-05),
  mismo bootloader en los dos. Actualizaciones automáticas desactivadas.
- Linux: **hito 1 superado** (2026-11-24): kernel de base mainline arrancado
  desde el slot B, solo en RAM. Nura aún no instalado.
- Pantalla: **consola de texto en pantalla** desde el 2026-11-25 (confirmado a
  ojo), con la variante de kernel "display A", cuyas cinco imágenes ocupan ahora
  el slot B en lugar de las del hito 1 (`vbmeta_b` stock, slot A intacto).
  Sigue siendo solo RAM.

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
the Linux text console (verified 2026-11-25). Those display patches are not
published here yet. / Pantalla: en nuestra unidad, con el árbol del PR #276 en
el commit `ffd33b7` tal como se usó en el hito 1, **no** hay salida de
pantalla, lo que matiza el "reported" de terceros. Con nuestra variante
"display A" (`gs-decon` integrado, nodo `simple-framebuffer` en `/chosen`,
`gs_decon.stage=1`) la pantalla muestra la consola de texto de Linux
(verificado el 2026-11-25). Esos parches de pantalla aún no están publicados
aquí.

Source for third-party reports / Fuente de los reportes de terceros:
Omamobile kernel PR #276 (`komodo` board, depends on PR #273), per its author.
<https://github.com/derekross/linux-omarchy-mobile>

| Component / Componente | Hardware (stock) | Our unit / Nuestra unidad | Third party / Terceros | Notes / Notas |
|---|---|---|---|---|
| Boot (slot B) | ABL, boot header v4 | **works** (RAM-only, slot B) | reported (PR #276) | Milestone 1, and again with the "display A" images (2026-11-25, USB gadget at ~26 s); AVB hash footer with AOSP test key, `vbmeta_b` stock; ABL appends the `vendor_boot` cmdline (verified) |
| UFS storage | 256 GB UFS | **detected, read-only tested** | reported (PR #276) | 62 partitions, all read-only, none mounted; writing never tested |
| Root on userdata | — | untested | reported (PR #276) | single `userdata`: stock Android reportedly reformats it (not verified by us) |
| USB gadget (NCM/ACM/SSH) | — | **works** | reported (PR #276) | `1d6b:0104`; enumerates ~24 s after reboot; default subnet `172.16.42.0/24` can clash with other postmarketOS phones on the same PC |
| Display | panel `google-km4` (bootloader name; see note) | **partial**: text console (`simpledrm` + `fbcon`, 84x93 characters) | reported (PR #276) | "display A" variant: `simple-framebuffer` on the bootloader framebuffer at `0xfac00000` (1344x2992, a8r8g8b8); command-mode DSI panel, frames at ~60 Hz after `gs_decon.stage=1` unmasks the frame trigger. No GPU/acceleration, no real modesetting (no `km4` panel driver in the tree), no backlight device (brightness as left by the bootloader), no screen off/on. Milestone 1 tree: no output. Variant B (`gs_decon.stage=2 gs_decon.fbdev=1`, KMS flip-only) built, untested |
| Buttons (power/vol) | — | untested under Linux; Power+Vol− reaches fastboot | reported (PR #276) | |
| Touchscreen | Synaptics (`syna_touch`) | untested | disabled upstream (PR #276) | still untested with the text console working |
| GPU | Mali-G715 | untested | disabled upstream (PR #276) | |
| USB Type-C | — | untested | disabled upstream (PR #276) | |
| Charging | MAX77779 family | untested | unknown | |
| Battery / fuel gauge | MAX77779 family | untested | unknown | |
| WiFi | BCM4390 (`bcmdhd4390`) | untested | disabled upstream (PR #276) | |
| Bluetooth | unverified | untested | unknown | |
| Audio (amps/haptics) | cs35l41 / cs40l26 | untested | unknown | AoC involved (unverified how) |
| Sensors | unverified | untested | unknown | |
| Modem / calls / SMS / data | unverified | untested | unknown | |
| Cameras | unverified | untested | unknown | |
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
