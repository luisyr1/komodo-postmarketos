# Milestone 6: first audio, bottom speaker and one microphone (experimental) / Hito 6: primer audio, altavoz inferior y un micrófono (experimental)

Reached on our unit on 2026-11-25 (see [JOURNAL.md](JOURNAL.md)). This is a
reproducible description of what we did on top of
[Milestone 5](MILESTONE-5.md): kernel package `linux-google-zumapro`
`pkgrel=6` installed (patches 0016–0021), the AoC firmware taken from the
owner's own factory image, and a staged bring-up done by hand. A short
1 kHz tone at the lowest analog gain came out of the **bottom speaker** and
was heard, and **microphone 0** picked it up while it played. The recipe
in this repository is already `pkgrel=7`: it adds patches 0022–0023, which
we tested by loading two rebuilt modules by hand, but **`pkgrel=7` itself
has not been built or booted yet**. *Later note: `pkgrel=7` was built,
installed and booted on 2026-11-26; a default `aplay` plays to the end on
EP6 ([JOURNAL.md](JOURNAL.md)).*

It is **not** usable audio: the desktop has no sound (PipeWire and
PulseAudio are told to ignore the card), only the bottom speaker at the
bring-up minimum and microphone 0 were tried, and everything was verified
once, on one unit.

Alcanzado en nuestra unidad el 2026-11-25 (ver [JOURNAL.md](JOURNAL.md)).
Descripción reproducible de lo que hicimos sobre el [hito 5](MILESTONE-5.md):
paquete del kernel `linux-google-zumapro` `pkgrel=6` instalado (parches
0016–0021), el firmware del AoC sacado de la imagen de fábrica del propio
dueño y una puesta en marcha por etapas hecha a mano. Un tono corto de
1 kHz con la ganancia analógica más baja salió por el **altavoz inferior**
y se oyó, y el **micrófono 0** lo captó mientras sonaba. La receta de este
repositorio ya es `pkgrel=7`: añade los parches 0022–0023, que probamos
cargando a mano dos módulos recompilados, pero **el `pkgrel=7` como tal aún
no se ha compilado ni arrancado**. *Nota posterior: el `pkgrel=7` se
compiló, instaló y arrancó el 2026-11-26; un `aplay` por defecto llega al
final en EP6.*

**No** es audio usable: el escritorio no tiene sonido (PipeWire y
PulseAudio tienen orden de ignorar la tarjeta), solo se probaron el altavoz
inferior al mínimo de puesta en marcha y el micrófono 0, y todo se
comprobó una vez, en una unidad.

> **YOU CAN DESTROY A SPEAKER.** The two Cirrus CS35L41 amplifiers run
> **without** Cirrus' speaker-protection firmware and **without** the
> factory calibration of your unit. On stock that firmware watches the
> voice coil's temperature and excursion and limits the signal; here
> nothing does. Raising the volume, playing music, bass or noise, or
> playing for long can damage a speaker **irreversibly**. This milestone
> only ever played a 2 s, 1 kHz tone at the lowest analog gain, behind the
> barriers in [step 3](#3-the-safety-barriers). **Do not raise the levels.**
> Daily use needs the protection firmware and the calibration first; that
> is pending work, and this repository publishes no way to go louder.
>
> **PUEDES DESTROZAR UN ALTAVOZ.** Los dos amplificadores Cirrus CS35L41
> funcionan **sin** el firmware de protección de Cirrus y **sin** la
> calibración de fábrica de tu unidad. En stock ese firmware vigila la
> temperatura y la excursión de la bobina y limita la señal; aquí no lo hace
> nada. Subir el volumen, poner música, graves o ruido, o reproducir mucho
> rato puede dañar un altavoz **de forma irreversible**. En este hito solo
> se reprodujo un tono de 1 kHz de 2 s con la ganancia analógica mínima,
> detrás de las barreras del [paso 3](#3-las-barreras-de-seguridad). **No
> subas los niveles.** El uso diario necesita antes el firmware de
> protección y la calibración; es trabajo pendiente y este repositorio no
> publica ninguna forma de subir el volumen.

> **The firmware is proprietary and is not in this repository.** `aoc.bin`
> (the AoC's signed firmware) and the `cs35l41-dsp1-spk-prot*` files belong
> to Google/Cirrus and come with no redistribution license we know of. You
> extract `aoc.bin` from the factory image of **your own** phone's build
> (step 5). Do not publish it, do not commit it, do not package it.
>
> **Two patches are third-party work.** 0017 and 0022 are Lef's (GitHub
> `Somnius`) pull requests
> [#204](https://github.com/derekross/linux-omamobile/pull/204) and
> [#203](https://github.com/derekross/linux-omamobile/pull/203) to the
> Omamobile kernel, taken unchanged with their author, message and
> `Signed-off-by`; both are still open there. `komodo-aoc-start` is adapted
> from Omamobile's AoC start scripts (MIT).
>
> **Our patches (0016, 0018–0021, 0023) are not upstream and have not been
> sent anywhere.** Like the rest of this repository they were written with
> AI assistance; [Nura's AI policy](https://docs.nura.eco/policies-and-processes/development/ai-policy.html)
> does not accept that, so do not submit them to Nura or to the kernel as
> is.
>
> **El firmware es propietario y no está en este repositorio:** saca
> `aoc.bin` de la imagen de fábrica del build de **tu** teléfono y no lo
> publiques. **Dos parches son de terceros:** 0017 y 0022 son los pull
> requests #204 y #203 de Lef (`Somnius`) al kernel de Omamobile, tal cual,
> con su autor, su mensaje y su `Signed-off-by`; los dos siguen abiertos.
> `komodo-aoc-start` está adaptado de los scripts de arranque del AoC de
> Omamobile (MIT). **Nuestros parches (0016, 0018–0021, 0023) no están en
> upstream ni se han enviado:** están hechos con asistencia de IA, como el
> resto del repo.

[English](#english) · [Español](#español)

---

## English

### Before you start

- Everything in [MILESTONE-5.md](MILESTONE-5.md#before-you-start) applies,
  and Milestone 5 should already work on your unit.
- **No reinstall:** only `boot_b`, `vendor_boot_b` and
  `vendor_kernel_boot_b` change, as in
  [MILESTONE-3.md step 9](MILESTONE-3.md#9-updating-the-kernel-without-reinstalling).
- `alsa-utils` on the phone (`aplay`, `arecord`, `amixer`), and root
  (`sudo`): on our unit the user session did not always have access to
  `/dev/snd/*` (`root:audio`, mode 0660).
- Read [step 3](#3-the-safety-barriers) before you plug anything in. Do the
  test with the phone on a table, without a case, in a quiet room.
- **No warranty.** We did this on one unit, once.

### 1. Inputs

| Item | Value |
|---|---|
| Kernel package, tested | `linux-google-zumapro` `pkgrel=6`: same source commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb`, patches 0001–0021 |
| Kernel package, in this repository | `pkgrel=7`: 0001–0023 ([`../pmaports/device/testing/linux-google-zumapro/`](../pmaports/device/testing/linux-google-zumapro/)); not built or booted at the time of this milestone; built and booted on 2026-11-26 |
| Kernel config | unchanged: CS35L41, Trusty, the GSA and the AoC (core, mailbox, ALSA) were already modules |
| Device package | `device-google-komodo` `pkgrel=3`, unchanged |
| Resulting `uname -r` | `7.3.0-rc6-zumapro` |
| Firmware | factory image `CP4A.261105.040.A1`, `vendor.img`, `/vendor/firmware/aoc.bin` (step 5); not redistributed |
| Phone-side files | [`../scripts/audio/`](../scripts/audio/): `komodo-audio.conf` (blacklist), `komodo-aoc-start`, `komodo-first-tone.sh` |

### 2. The hardware

| Item | Value |
|---|---|
| Speaker amplifiers | two Cirrus Logic **CS35L41**, revision **B2**, on Google's `spi_19` (HSI0 USI1, `0x111c0000`, SPI 407) |
| Top amplifier (`Top`, stock "L") | native chip select CS0; also drives the **earpiece** (stock uses it with the DSP bypassed for calls) |
| Bottom amplifier (`Bottom`, stock "R") | chip select on GPIO `gpn1-0`; the only one used in this milestone |
| Amplifier pins (stock DTBO) | resets `gpp6-3` (Top) and `gph2-1` (Bottom), interrupts `gpa5-5` and `gpa7-2` |
| Audio data path | TDM 0 from the AoC to both amplifiers (4 slots, 32 bit, 48 kHz; Top on slot 0, Bottom on slot 1); the application processor only talks to the amplifiers over SPI (registers, volume) |
| Microphones | three PDM microphones wired to the AoC, not to the application processor |
| AoC | "Always-on Compute", Google's audio and sensor coprocessor; **all audio goes through it**. Board config `KM4`, board id `0x40802`, rev `0x10000` |
| AoC start | needs **Trusty** (the secure-world OS) and the **GSA**, which authenticate the signed firmware `aoc.bin` before it runs |

These come from the stock DTB and DTBO (entry 34) and the factory image's
mixer configuration; see [DEVICE.md](DEVICE.md).

### 3. The safety barriers

Without the protection firmware, these are what keeps the speakers safe.
All were in place for every test. **Keep all of them.**

| Barrier | What it is |
|---|---|
| Driver limits | the AoC card driver caps `Digital PCM Volume` at 817 (0 dB) and `Analog PCM Volume` at 10 (10.5 dB) on both amplifiers, while stock runs behind the protection firmware at 17. Verified: asking for 17 leaves 10. `komodo-first-tone.sh` refuses to play if these limits are not what it expects |
| Boost current | patch 0020 limits the boost converter's peak current to **2.5 A** (stock: 3.5 A) |
| One speaker | only the **bottom** speaker; the top amplifier (also the earpiece) stays at Digital 1, Analog 0 |
| DSP bypassed | `PCM Source` = `ASP` on both: no DSP firmware is loaded at all |
| Levels | Bottom Digital **657** (-20 dB) and Analog **0** (0.5 dB, the lowest step): by our estimate about 57 dB below stock's full scale |
| Signal | a 1 kHz sine, **-20 dBFS**, **2 s**, with 50 ms fades. No bass (excursion is worst at low frequencies), no noise, no square waves, no music |
| No sound server | a udev rule makes PipeWire and PulseAudio **ignore** the card, so no application and no desktop sound can reach the speakers |
| Blacklist | every audio module (Trusty, GSA, AoC, amplifiers, card) is blacklisted; the AoC is started by hand, once per boot |

While testing: keep `dmesg -w` open (any CS35L41 or boost error means
stop), and keep a mute at hand:
`amixer -c <card> cset name='Bottom Digital PCM Volume' 1`.
`komodo-first-tone.sh` already puts both amplifiers back to the minimum
when it exits, also on error or Ctrl-C.

**Before any level above this:** the protection firmware loaded and
healthy, your unit's own factory calibration read (read-only), and ceilings
measured for `komodo`. None of that is done.

### 4. What the patches change

| Patch | Author | What it does | Status on our unit |
|---|---|---|---|
| 0016 | ours | `clk-zumapro`: HSI0 USI1's mux, divider and three gates (offsets follow the USI2–USI4 layout and the zuma values the Pixel 8 Pro uses) | works: spi19 runs, both amplifiers answer |
| 0017 | Lef, [PR #204](https://github.com/derekross/linux-omamobile/pull/204) | `spi-s3c64xx`: for a device on a GPIO chip select, leave the native CS in auto mode; without it the two amplifiers drive MISO at once | works: the second amplifier reads correctly |
| 0018 | ours | `zumapro.dtsi`: `usi1_hsi0` and `spi19`, disabled | works |
| 0019 | ours | `komodo`: enables Trusty, the GSA, the AoC's mailboxes and the AoC with the stock board config, and the AoC's sensor rails | works: AoC online |
| 0020 | ours | `komodo`: the two CS35L41 on spi19 (Top/Bottom prefixes, stock TDM slots, **boost peak 2.5 A**, `cirrus,dsp-no-hibernate`) and their pins | works: both identified |
| 0021 | ours | `komodo`: the AoC sound card `google,komodo-aoc-snd-card` (stock links, TDM 0 to both amplifiers, BCLK as their clock), based on the tegu card of Omamobile's PR #193 | works: card registered |
| 0022 | Lef, [PR #203](https://github.com/derekross/linux-omamobile/pull/203) | AoC ALSA: keep the playback data written before START and write it again after, and report the pointer from the AoC's live read index; only for `google,zuma-aoc` | tested by loading the rebuilt module by hand |
| 0023 | ours | makes 0022 also apply to `google,zumapro-aoc` | same |

0017 and 0022 are taken unchanged from their pull requests (author,
message, `Signed-off-by` and commit id); in this repository their dates are
in UTC. The commit messages of our 0016–0021 still say things like "not
read back yet" or "nothing here makes sound": they are kept as they were
built (only the `From:` line was normalised for publication, with the
checksums updated); this document is the current state.

Why 0022–0023: the AoC's deep-buffer entry point EP6 throws away whatever
was written before START, without an interrupt. `aplay` by default starts
with the whole buffer written; ALSA then sees a full buffer that never
drains, both sides wait, and after about 5 s `aplay` fails with
`I/O error` (no sound). We measured it with the driver's ring counters. The
same happens on the Pixel 8 Pro, where PR #203 fixes it, but only for
zuma's compatible; 0023 adds zumapro's. Without 0022–0023, `aplay -R`
(start with a small amount written) works around it.

### 5. Get the AoC firmware from your own factory image

As in [MILESTONE-4.md step 4](MILESTONE-4.md#4-get-the-firmware-from-your-own-factory-image),
from the factory image of the **build installed on your phone**, in a
private directory outside this repository. The file is `/firmware/aoc.bin`
inside `vendor.img` (`/vendor/firmware/` on Android); with an ext4
`vendor.img`, without root:

```sh
mkdir -p "$KOMODO_WORK/firmware/vendor-firmware"
debugfs -R "dump /firmware/aoc.bin $KOMODO_WORK/firmware/vendor-firmware/aoc.bin" vendor.img
sha256sum "$KOMODO_WORK/firmware/vendor-firmware/aoc.bin"
```

Delete `vendor.img` when done.

| Factory file (`/vendor/firmware`) | Size | SHA-256 | Name on the phone |
|---|---|---|---|
| `aoc.bin` (release `16099865-polygon`) | 29076224 | `99783b437e455fde0a7bbe7c92a9d30e2bcb1048a6765af2d561e46ba331d412` | `/lib/firmware/aoc-komodo.bin` |

This is a public file from Google's image of `CP4A.261105.040.A1`; it does
not identify a unit. The same image serves every zumapro board (the kernel
passes the board id and the firmware picks the configuration). There is no
installer script for it; copy it yourself and check the hash on the phone:

```sh
scp "$KOMODO_WORK/firmware/vendor-firmware/aoc.bin" <user>@172.16.43.1:aoc-komodo.bin
# on the phone:
sudo install -m 0644 aoc-komodo.bin /lib/firmware/aoc-komodo.bin && rm aoc-komodo.bin
sha256sum /lib/firmware/aoc-komodo.bin
```

The same directory holds `cs35l41-dsp1-spk-prot.wmfw` and the tunings
`cs35l41-dsp1-spk-prot.bin` and `R-cs35l41-dsp1-spk-prot.bin`, the
speaker-protection firmware. **We have not used them yet**; do not install
them for this milestone.

### 6. Blacklist before the first boot of the new kernel

With 0019–0021 in the DTB, udev would autoload Trusty, the GSA, the AoC
drivers, the amplifiers and the card at boot, in no particular order. A
half-started AoC cannot be reset without a reboot. So, on the phone,
**before** booting the new kernel:

```sh
sudo install -m 0644 komodo-audio.conf /etc/modprobe.d/komodo-audio.conf
```

with [`../scripts/audio/komodo-audio.conf`](../scripts/audio/komodo-audio.conf)
copied to the phone. `modprobe <name>` by hand still works with it.
**Keep it**: unlike Milestones 4 and 5, this blacklist is not removed at
the end.

Also keep PipeWire and PulseAudio off the card. We do it with a udev rule
that sets `PULSE_IGNORE` and `ACP_IGNORE` on the AoC card; it is not
shipped here. This is the rule we used, in
`/etc/udev/rules.d/89-komodo-audio-ignore.rules` (it matches every sound
card; the AoC card is the only one on the phone). With it, no process had
`/dev/snd` open and every PCM stayed `closed` after the card appeared:

```text
SUBSYSTEM=="sound", ENV{PULSE_IGNORE}="1", ENV{ACP_IGNORE}="1"
```

### 7. Build and install the kernel without reinstalling

As in [MILESTONE-4.md step 6](MILESTONE-4.md#6-build-and-install-the-kernel-without-reinstalling):
refresh your pmaports copy with this repository's `linux-google-zumapro`,
`"${PMB[@]}" build linux-google-zumapro`, `apk add` the package on the
phone, rebuild the images with `scripts/mkimages-pmos.sh` and flash only
`boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b`.

Note: what we booted was `pkgrel=6` (0016–0021). The `pkgrel=7` in this
repository (with 0022–0023) is the next build and has not been booted.

### 8. Stage E-1: boot with everything blacklisted

Boot cold. Nothing of the audio should load, and nothing else should
change:

```sh
lsmod | grep -E 'aoc|trusty|gsa|cs35l41'                  # nothing
ls /sys/bus/platform/devices/ | grep -E '154b0000.aoc|111c0000.spi'
systemctl --failed
```

On our unit the boot was normal, with no audio module loaded.

### 9. Stage E0: identify the amplifiers

Copy [`../scripts/audio/komodo-aoc-start`](../scripts/audio/komodo-aoc-start)
to `/usr/local/bin/` on the phone. Then:

```sh
sudo komodo-aoc-start amps
```

This only loads the amplifier driver. Without the AoC there is no TDM
clock and without the card no route, so nothing can sound. Both
amplifiers identified themselves as revision B2, with lines of this form:

```text
cs35l41 spi1.0: Cirrus Logic CS35L41 (35a40), Revision: B2
cs35l41 spi1.1: Cirrus Logic CS35L41 (35a40), Revision: B2
```

If the second one reads zeros or reports an ID mismatch, 0017 is missing.
Do not unbind and rebind; if something fails, reboot.

### 10. Stage E1: start the AoC and the card

```sh
sudo komodo-aoc-start card     # or "aoc" for the AoC alone; not both in one
                               # boot: after "aoc", "card" finds no sound card
```

It loads Trusty, the GSA and the AoC drivers in order, writes the firmware
name to the AoC, waits for its services, then loads the amplifiers and the
card. It writes a marker first: if a boot hangs or resets in the middle,
the next run refuses until you add `--retry`. **The AoC starts once per
boot**: a second firmware load takes a running AoC down and there is no
reset, so a failed start needs a reboot.

Lines we got (timestamps removed, some left out):

```text
trusty trusty: selected api version: 5 (requested 5)
google-gsa 16490000.gsa: mailbox ready, irq 66, Trusty
aoc: unsupported dmic power list, err = -22.
aoc 154b0000.aoc: failed to register acpm aoc reset callback
aoc 154b0000.aoc: attempting to load firmware "aoc-komodo.bin"
aoc: AoC board id 0x40802 rev 0x10000
aoc: successfully loaded firmware version 16099865-polygon type release
google-gsa 16490000.gsa: TZ: com.android.trusty.gsa.hwmgr.aoc connected
aoc: firmware version 16099865-polygon did become online with 94 services
```

Then `/proc/asound/cards` lists `googlekomodoaoc` /
`google,komodo-aoc-snd-card`, with three PCMs: `EP1 playback` (device 0),
`EP6 playback` (device 5) and `EP1 capture` (device 8). Both amplifiers
start at Digital 657, Analog 0, `PCM Source` `ASP`, route off.

### 11. The first tone

Copy [`../scripts/audio/komodo-first-tone.sh`](../scripts/audio/komodo-first-tone.sh)
to the phone and run it **once**, with your ear near the bottom grille:

```sh
sudo sh komodo-first-tone.sh
```

It takes no arguments on purpose. It finds the card and the EP6 device by
name, checks the driver's limits, generates its own tone (1 kHz, -20 dBFS,
2 s), sets the fixed levels of step 3, **reads them back and refuses to
play if any differs**, plays with `aplay -R` and puts everything back to
the minimum on exit. Expected: `aplay rc=0`, about 2 s. On our unit the
tone was heard from the bottom speaker. Do not edit the script to raise
levels.

Note: the script in this repository is a cleaned-up rewrite of the one we
ran (same levels, same checks, same `aplay` options; it now looks the card
up by name and generates the tone itself). The tone it generates differs
from ours by at most 2 LSB per sample. The published file was then run once on
the phone (busybox `sh` and `awk`): `aplay` returned 0 and every level was
back at the minimum afterwards; nobody was listening that time.

### 12. Microphone 0, in a closed loop

With the card up, we recorded from the AoC's `EP1 capture` while the tone
played: microphone id 0 only (capture list `0,-1,-1,-1`), DC blocker on,
`MIC Record Soft Gain (dB)` 22, routed with `EP1 TX Mixer INTERNAL_MIC_TX`;
16-bit mono, 48 kHz, 6 s, with the tone starting about 2 s in. Check the
exact control names with `amixer -c <card> controls`. **Never** put an id
that does not exist in the capture list: on the Pixel 9a a list like
`0,3,2` crashes the AoC.

We measured the recording in 0.5 s windows (RMS, and a Goertzel filter at
1 kHz and at 700 and 1300 Hz as controls; arbitrary units on S16 samples):

| Window | RMS | 1 kHz component | 700 / 1300 Hz |
|---|---|---|---|
| 0–2 s (before the tone) | 22–28 | 0.1–0.4 | — |
| 2–4 s (tone playing) | 56–61 | **59.5–76.7** | ≈0.3 |
| 4–6 s (after) | 23–29 | 0.0–9.4 | — |

The 1 kHz component appears only while the tone plays and the neighbouring
frequencies do not move: the bottom speaker emits the tone and microphone 0
hears it, with playback and capture running at the same time. This
measurement was taken with 0022–0023 loaded by hand. The recordings were
deleted; only these numbers were kept.

### 13. Results

- **E-1:** normal boot with all audio blacklisted; nothing else changed.
- **E0:** both CS35L41 identified, revision B2.
- **E1:** AoC online with firmware `16099865-polygon` and 94 services; card
  `google,komodo-aoc-snd-card` registered; driver limits verified (Digital
  max 817, Analog max 10; asking for 17 leaves 10).
- **First attempt at playback:** stalled. `aplay` with its defaults failed
  with `I/O error` after about 5 s and nothing was heard. Cause measured:
  EP6 drops what was written before START (step 4).
- **Tone:** with `aplay -R` on `pkgrel=6`, and with default `aplay` once
  0022–0023 were loaded by hand, the 2 s tone plays to the end (`rc=0`,
  2.00 s) and was heard from the bottom speaker at Digital 657, Analog 0.
- **Microphone:** microphone 0 picks the tone up only while it plays
  (step 12); simultaneous playback and capture work.

### 14. Warnings in the log

- `aoc: unsupported dmic power list, err = -22`: the AoC node has no
  `dmic_power_list` property. It only concerns how the driver powers the
  microphone rails, which are always on in `komodo`'s stock description;
  microphone 0 works anyway. To be added to the DT.
- `failed to register acpm aoc reset callback`: the callback that would let
  the AoC be recovered after a crash is not registered. It does not affect
  a normal stream, but it is why a crashed or twice-started AoC needs a
  reboot.
- `fail to parse fai_link -517`: a probe deferral of the card until the
  amplifiers appear; the card registers right after.
- `alsa: Cannot find aoc device node`: the ALSA driver looks for a
  compatible zumapro does not have, so it reads a few optional AoC features
  as absent. No effect on playback; not fixed.

### 15. Back out

- **Audio off, kernel kept:** reboot. With the blacklist in place nothing
  of the audio loads at boot.
- **Firmware off the phone:** `sudo rm /lib/firmware/aoc-komodo.bin`.
- **Previous kernel:** reflash your Milestone 5 `boot_b`, `vendor_boot_b`
  and `vendor_kernel_boot_b` and downgrade the apk on the phone, as in
  [MILESTONE-3.md step 10](MILESTONE-3.md#10-back-out). 0016 marks the USI1
  clocks as critical, so they are on at every boot with this kernel, also
  without audio.

### 16. What does not work or was not tried

1. **Safe levels:** no protection firmware, no calibration. Daily-use
   volume is blocked on that (step 3).
2. **Desktop sound:** PipeWire and PulseAudio ignore the card on purpose.
   Connecting PipeWire needs a WirePlumber rule with a volume ceiling first,
   and `pkgrel=7` (0022–0023) built and booted; neither is done.
3. **`pkgrel=7`:** not built or booted as a package. *(Built and booted
   on 2026-11-26.)*
4. **Top speaker and earpiece:** not tried. Stereo: not tried.
5. **Microphones 1 and 2:** not tried.
6. **Usable volume:** only the bring-up minimum was played.
7. **Bluetooth audio** (A2DP, headsets) and **calls:** not tried.
8. **Open warnings:** `dmic_power_list` missing in the DT; the AoC reset
   callback is not registered (no recovery after an AoC crash).
9. **Haptics** (CS40L26), USB-C audio, DisplayPort audio: not started.
10. **Upstream:** our 0016, 0018–0021 and 0023 are not sent anywhere and
    are not meant to be as is (AI-assisted, see the top of this document).

### Not verified

- That the signal on TDM slot 1 is the tone itself rather than something
  derived from it: we only know the bottom speaker emits a 1 kHz tone that
  microphone 0 picks up.
- 0016's clock offsets read back on the phone (they work, but were taken
  from the USI2–USI4 layout and the zuma values).
- Firmware of other Android builds (the hash is for `CP4A.261105.040.A1`
  only).
- Any hardware beyond what is listed in [STATUS.md](STATUS.md).

---

## Español

### Antes de empezar

Vale todo lo de [MILESTONE-5.md](MILESTONE-5.md#antes-de-empezar) y el hito
5 debe funcionar ya en tu unidad. **No se reinstala:** solo cambian
`boot_b`, `vendor_boot_b` y `vendor_kernel_boot_b`. Hacen falta `alsa-utils`
en el teléfono (`aplay`, `arecord`, `amixer`) y `sudo` (en nuestra unidad la
sesión no siempre tenía acceso a `/dev/snd/*`). Lee el paso 3 antes de
nada; haz la prueba con el teléfono sobre una mesa, sin funda, en una
habitación en silencio. **Sin garantía:** lo hicimos una vez, en una unidad.

### Resumen de pasos

Los comandos, las tablas completas y el hash están en la sección inglesa.

1. **Entradas:** probado el paquete del kernel `linux-google-zumapro`
   `pkgrel=6` (mismo commit `ffd33b7…`, parches 0001–0021); en el
   repositorio está el `pkgrel=7` (0001–0023), **sin compilar ni arrancar
   aún** (se compiló y arrancó después, el 2026-11-26). La config no cambia. Paquete del dispositivo sin cambios
   (`pkgrel=3`). Firmware `aoc.bin` de la imagen de fábrica
   `CP4A.261105.040.A1`, que no se redistribuye. Ficheros para el teléfono
   en `scripts/audio/`.
2. **Hardware:** dos Cirrus **CS35L41** revisión **B2** en el `spi_19` de
   Google (HSI0 USI1): el **Top** (CS0 nativo; también es el **auricular**)
   y el **Bottom** (CS por GPIO `gpn1-0`, el único usado aquí). Los datos
   les llegan por TDM 0 desde el **AoC**, el coprocesador de audio y
   sensores de Google, por el que **pasa todo el audio**; el procesador
   principal solo les habla por SPI. Los **tres micrófonos PDM** van al AoC.
   Para arrancar el AoC hacen falta **Trusty** (el sistema del mundo
   seguro) y la **GSA**, que verifican el firmware firmado `aoc.bin`.
3. <a id="3-las-barreras-de-seguridad"></a>**Las barreras de seguridad**,
   todas puestas en todas las pruebas; **mantenlas todas**:
   - límites del driver de la tarjeta: Digital ≤ 817 y Analog ≤ 10 en los
     dos amplificadores (stock usa 17 con el firmware de protección);
     comprobado que pedir 17 deja 10; el script del tono se niega a
     reproducir si los límites no son esos;
   - pico de corriente del boost limitado a **2,5 A** (stock: 3,5 A), en el
     parche 0020;
   - solo el altavoz **inferior**; el Top (también auricular) a Digital 1 y
     Analog 0;
   - DSP puenteado (`PCM Source` = `ASP`): no se carga ningún firmware DSP;
   - niveles: Bottom Digital **657** (-20 dB) y Analog **0** (el escalón
     más bajo), unos 57 dB por debajo del fondo de escala de stock según
     nuestra estimación;
   - señal: seno de 1 kHz a **-20 dBFS** durante **2 s**, con fundidos de
     50 ms; nada de graves, ruido, ondas cuadradas ni música;
   - los servidores de sonido **ignoran la tarjeta** (regla udev con
     `PULSE_IGNORE` y `ACP_IGNORE`): ninguna aplicación puede llegar a los
     altavoces;
   - **todos** los módulos de audio en lista negra; el AoC se arranca a
     mano, una vez por arranque.

   Durante la prueba, `dmesg -w` abierto (un error del CS35L41 o del boost
   significa parar) y el silencio a mano. **Antes de cualquier nivel por
   encima de este** hacen falta el firmware de protección cargado y sano,
   la calibración de fábrica de tu unidad leída en solo lectura y techos
   medidos para `komodo`. Nada de eso está hecho.
4. **Parches:** 0016 (nuestro) relojes de USI1 en HSI0; **0017 (Lef, PR
   #204 de Omamobile)** chip-select nativo en `spi-s3c64xx` para el
   amplificador con CS por GPIO; 0018 (nuestro) `usi1_hsi0` y `spi19` en
   `zumapro.dtsi`; 0019 (nuestro) Trusty, GSA, mailboxes y AoC en `komodo`;
   0020 (nuestro) los dos CS35L41 con el **boost a 2,5 A**; 0021 (nuestro)
   la tarjeta `google,komodo-aoc-snd-card`, basada en la de tegu del PR
   #193; **0022 (Lef, PR #203 de Omamobile)** conserva lo escrito antes del
   START en EP6; 0023 (nuestro) lo activa también para
   `google,zumapro-aoc`. 0017 y 0022 van tal cual de sus PR (autor,
   mensaje, `Signed-off-by` e id de commit), con la fecha en UTC. Los
   mensajes de nuestros 0016–0021 conservan frases de cuando aún no se
   habían probado; se mantienen como se compilaron.
5. **Firmware del AoC de tu propia imagen de fábrica:** `/firmware/aoc.bin`
   dentro de `vendor.img` (con ext4, `debugfs -R "dump /firmware/aoc.bin
   aoc.bin" vendor.img`, sin root), 29076224 bytes, SHA-256
   `99783b437e455fde0a7bbe7c92a9d30e2bcb1048a6765af2d561e46ba331d412`
   (release `16099865-polygon`), al teléfono como
   `/lib/firmware/aoc-komodo.bin`; comprueba el hash allí. Es un fichero
   público de la imagen de Google y no identifica la unidad. Los ficheros
   `cs35l41-dsp1-spk-prot*` (firmware de protección) **no** se han usado
   todavía: no los instales para este hito.
6. **Lista negra antes del primer arranque del kernel nuevo:**
   `scripts/audio/komodo-audio.conf` a `/etc/modprobe.d/`. **Se queda
   puesta** (a diferencia de los hitos 4 y 5). Y PipeWire/PulseAudio fuera
   de la tarjeta con una regla udev (`PULSE_IGNORE` y `ACP_IGNORE` sobre
   todas las tarjetas de sonido; la del AoC es la única), que no se publica
   como fichero; en la sección inglesa está la regla que usamos.
7. **Kernel sin reinstalar:** igual que en el paso 6 del hito 4. Lo que
   arrancamos fue el `pkgrel=6`; el `pkgrel=7` es el siguiente.
8. **E-1, arranque con todo en lista negra:** arranque normal, sin ningún
   módulo de audio cargado; comprueba también los nodos `154b0000.aoc` y
   `111c0000.spi`.
9. **E0, identificar los amplificadores:** `sudo komodo-aoc-start amps`;
   los dos dicen `Cirrus Logic CS35L41 (35a40), Revision: B2`. Sin AoC no
   hay reloj TDM y sin tarjeta no hay ruta: no puede sonar nada.
10. **E1, arrancar el AoC y la tarjeta:** `sudo komodo-aoc-start card`.
    Carga los módulos en orden, deja un marcador por si el arranque se
    cuelga (después hace falta `--retry`) y **solo se puede hacer una vez
    por arranque** (no hay reset del AoC). Resultado: firmware
    `16099865-polygon` con **94 servicios**, tarjeta
    `google,komodo-aoc-snd-card` con `EP1 playback`, `EP6 playback` y `EP1
    capture`.
11. **El primer tono:** `sudo sh komodo-first-tone.sh`, una vez, con la
    oreja cerca de la rejilla inferior. Sin argumentos a propósito: busca la
    tarjeta por nombre, comprueba los límites, genera su propio tono, pone
    los niveles fijos del paso 3, **los relee y se niega a reproducir si
    alguno no cuadra**, reproduce con `aplay -R` y lo deja todo al mínimo
    al salir. En nuestra unidad el tono se oyó. El script publicado es una
    reescritura limpia del que usamos (mismos niveles, comprobaciones y
    opciones de `aplay`); el fichero publicado se ejecutó después una vez en
    el teléfono (`aplay` terminó bien y los niveles volvieron al mínimo; esa
    vez nadie escuchaba). No lo modifiques para subir niveles.
12. **Micrófono 0 en bucle cerrado:** captura por `EP1 capture`, solo el
    micrófono 0 (lista `0,-1,-1,-1`; **nunca** un id inexistente, que en el
    Pixel 9a tumba el AoC), DC blocker, 22 dB de ganancia soft, mono 16 bit
    a 48 kHz, mientras sonaba el tono. La componente de 1 kHz (Goertzel,
    ventanas de 0,5 s, unidades arbitrarias sobre S16) pasa de ≈0,1–0,4 a
    **≈60–77** solo durante esos 2 s, con 700 y 1300 Hz sin cambio (≈0,3).
    Medido con 0022–0023 cargados a mano. Las grabaciones se borraron.
13. **Resultados:** E-1, E0 y E1 pasados; el primer intento de reproducción
    se atascó (`aplay` con `I/O error` a los ~5 s, sin sonido) porque EP6
    tira lo escrito antes del START; con `aplay -R`, o con 0022–0023, el
    tono de 2 s llega al final y se oye; el micrófono 0 lo capta;
    reproducción y captura simultáneas funcionan.
14. **Avisos en el log:** falta `dmic_power_list` en el DT (el micrófono 0
    funciona igual; hay que añadirlo); el callback de reset del AoC por
    ACPM no se registra (por eso un AoC caído pide reiniciar); un
    `-EPROBE_DEFER` inofensivo de la tarjeta hasta que salen los
    amplificadores; y `Cannot find aoc device node` en el driver ALSA, sin
    efecto en la reproducción.
15. **Vuelta atrás:** reiniciar (con la lista negra no carga nada de
    audio); `sudo rm /lib/firmware/aoc-komodo.bin`; el kernel anterior,
    reflasheando las tres imágenes del hito 5 y bajando el apk. Con este
    kernel los relojes de USI1 están encendidos en cada arranque, también
    sin audio.
16. **Lo que no funciona o no se ha probado:** niveles seguros (sin
    firmware de protección ni calibración); sonido en el escritorio
    (PipeWire ignora la tarjeta a propósito; antes hace falta una regla de
    WirePlumber con techo de volumen y el `pkgrel=7` arrancado); el
    `pkgrel=7` como paquete (compilado y arrancado después, el
    2026-11-26); altavoz superior y auricular, estéreo; los
    micrófonos 1 y 2; volumen de uso; audio por Bluetooth y llamadas;
    avisos abiertos (`dmic_power_list`, reset del AoC); háptica, audio por
    USB-C y DisplayPort. Nuestros parches no se han enviado a ningún sitio
    y no deben enviarse tal cual (hechos con asistencia de IA).

### Sin verificar

Que la ranura 1 del TDM lleve exactamente el tono (solo sabemos que el
altavoz inferior emite 1 kHz y el micrófono 0 lo capta); los offsets de
reloj de 0016 leídos en el teléfono; el
firmware de otros builds de Android (el hash es solo de
`CP4A.261105.040.A1`); el resto del hardware ([STATUS.md](STATUS.md)).
