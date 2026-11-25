# Milestone 4: WiFi (Broadcom BCM4390) / Hito 4: WiFi (Broadcom BCM4390)

Reached on our unit on 2026-11-25 (see [JOURNAL.md](JOURNAL.md)). This is a
reproducible description of what we did on top of
[Milestone 3](MILESTONE-3.md): kernel package `linux-google-zumapro`
`pkgrel=3` (13 patches; the new ones are 0012 and 0013), device package
`device-google-komodo` unchanged at `pkgrel=3`, and the WiFi firmware taken
from the owner's own factory image. `wlan0` comes up at boot, scans, connects
to a WPA network from Phosh's settings and passes traffic.

It is **not** finished WiFi support: throughput was not measured, WiFi
Direct (P2P) most likely does not work, and 6 GHz, WiFi 7 (EHT), suspend,
power saving and access point mode were not tried. Bluetooth is untouched.
Everything was verified once, on one unit.

Alcanzado en nuestra unidad el 2026-11-25 (ver [JOURNAL.md](JOURNAL.md)).
Descripción reproducible de lo que hicimos sobre el [hito 3](MILESTONE-3.md):
paquete del kernel `linux-google-zumapro` `pkgrel=3` (13 parches; los nuevos
son 0012 y 0013), paquete del dispositivo `device-google-komodo` sin cambios
en `pkgrel=3`, y el firmware WiFi sacado de la imagen de fábrica del propio
dueño. `wlan0` aparece al arrancar, escanea, se conecta a una red WPA desde
los ajustes de Phosh y pasa tráfico.

**No** es un soporte WiFi terminado: no se ha medido la velocidad, WiFi
Direct (P2P) casi seguro no funciona, y no se han probado 6 GHz, WiFi 7
(EHT), suspensión, ahorro de energía ni modo punto de acceso. Bluetooth sin
tocar. Todo se comprobó una vez, en una unidad.

> **The firmware is proprietary and is not in this repository.** It belongs
> to Broadcom/Google and comes with no redistribution license we know of.
> You extract it from the factory image of **your own** phone's build
> (step 4). Do not publish it, do not commit it, do not package it in a
> public repository.
>
> **Patch 0013 is not upstream and has not been sent anywhere.** It extends
> `brcmfmac` for the BCM4390 by following Google's GPL bcmdhd driver for the
> same chip (step 3). Like the rest of this repository it was written with
> AI assistance; [Nura's AI policy](https://docs.nura.eco/policies-and-processes/development/ai-policy.html)
> does not accept that, so do not submit it to Nura or to the kernel as is.
>
> **Powering a new PCIe device is a hardware risk.** Bringing up `pcie_1`
> touches PMU isolation, the PHY and `WL_REG_ON`. On our unit it worked at
> the first try; a hang would need a forced reboot. Blacklist the modules
> before you boot the new kernel the first time (step 5), so a failure
> cannot repeat on every boot.
>
> **El firmware es propietario y no está en este repositorio:** sácalo de la
> imagen de fábrica del build de **tu** teléfono y no lo publiques. **El
> parche 0013 no está en upstream ni se ha enviado:** sigue el driver GPL
> bcmdhd de Google y está hecho con asistencia de IA, como el resto del repo.
> **Encender un dispositivo PCIe nuevo es un riesgo de hardware:** pon los
> módulos en lista negra antes del primer arranque del kernel nuevo.

[English](#english) · [Español](#español)

---

## English

### Before you start

- Everything in [MILESTONE-3.md](MILESTONE-3.md#before-you-start) applies,
  and Milestone 3 should already work on your unit: same pmbootstrap
  configuration, work directory, pmaports copy and image script.
- **No reinstall:** this milestone does not reflash `userdata`. Only
  `boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b` change, as in
  [MILESTONE-3.md step 9](MILESTONE-3.md#9-updating-the-kernel-without-reinstalling).
- **No warranty.** We did this on one unit, once.

### 1. Inputs

| Item | Value |
|---|---|
| Kernel package | `linux-google-zumapro` `pkgrel=3`: same source commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb`, same config, 13 patches ([`../pmaports/device/testing/linux-google-zumapro/`](../pmaports/device/testing/linux-google-zumapro/)) |
| Device package | `device-google-komodo` `pkgrel=3`, unchanged since Milestone 3 |
| Resulting `uname -r` | `7.3.0-rc6-zumapro` |
| Kernel config | unchanged: `CONFIG_PCIE_GS201=m`, `CONFIG_PHY_ZUMA_PCIE=m`, `CONFIG_PCI_PWRCTRL_GENERIC=y`, `CONFIG_DMA_RESTRICTED_POOL=y`, `CONFIG_BRCMFMAC=m` with PCIe were already set |
| Firmware | factory image `CP4A.261105.040.A1`, `vendor.img`, `/vendor/firmware` (table in step 4); not redistributed |
| Firmware version reported | `27.10.1121.57.30 (b1 release24)` |
| Firmware install | [`../scripts/install-wifi-firmware.sh`](../scripts/install-wifi-firmware.sh) |
| Images | [`../scripts/mkimages-pmos.sh`](../scripts/mkimages-pmos.sh), unchanged |

### 2. The hardware

| Item | Value |
|---|---|
| Chip | Broadcom BCM4390, WiFi 7 + Bluetooth combo |
| PCI ID | `14e4:4438`, class `0x028000` |
| PCI revision | `0x05` = chip revision 5 = **b1** (Broadcom's naming: 0 = a0, 2 = b0, 5 = b1) |
| PCIe controller | `pcie_1` at `0x13120000` (driver `pcie_gs201`), PHY at `0x13160000` (driver `phy_zuma_pcie`), one lane, Gen3 |
| Power | `WL_REG_ON` on `gph3-4`, the only control; the module is fed straight from the system rail |
| DMA | a 16 MiB `restricted-dma-pool` below 4 GiB, assigned to the device (as Omamobile does for the Pixel 9a) |
| Link on our unit | Gen3 x1 (8.0 GT/s), up at the first try |

These come from the stock device tree and DTBO (entry 34), the stock module
aliases, and what our kernel logged; see [DEVICE.md](DEVICE.md).

### 3. What the patches change

| Patch | What it does | Status on our unit |
|---|---|---|
| 0012 | DTS: enables `WL_REG_ON` (pin as output, function 1, like stock), `pcie_1`, its root port and PHY, the `wifi@0,0` node (`brcm,board-type = "google,zumapro-komodo"`) and the 16 MiB DMA pool | works: Gen3 x1 link, device enumerates with the pool |
| 0013 | `brcmfmac`: adds the BCM4390 (`0x4390`, PCI `0x4438`) | works: firmware boots, `wlan0`, scan, WPA connection, traffic |

0013 handles the BCM4390 like its BCM4398 sibling, which the Omamobile tree
already supports in `brcmfmac` (FLR reset, power domain requests, DB7 trap,
waiting for the boot interrupt, `JOIN_V1`, host-built 802.3/LLC headers, no
firmware supplicant). Where Google's GPL-2.0 bcmdhd driver for the BCM4390
(`kernel/google-modules/wlan/bcmdhd/bcm4390`, branch
`android-gs-caimito-6.1-android16`) does something different, 0013 follows
bcmdhd:

- **RAM size fixed at 3276800 bytes** (`0x320000`) from base `0x2a0000`,
  instead of trusting the SYSMEM bank count. NVRAM and the shared-area
  address live at the top of RAM. On our unit SYSMEM reported the same
  value, so this part turned out not to matter here.
- **"PFM kickstart"** on PMU regulator 11 for chip revisions 2 and 5 (b0,
  b1), before anything else, through the indirect backplane access in PCI
  config space. bcmdhd does this to avoid an ASR crash on a cold start.
- **One firmware set per revision**:
  `brcm/brcmfmac4390{a0,b0,b1}-pcie.google,zumapro-komodo.{bin,txt,clm_blob,txcap_blob}`,
  so the driver can never load another revision's firmware. If the board
  specific name is missing it falls back to the same name without
  `.google,zumapro-komodo`.
- **Optional power domains:** the scan MAC and SAQM domains are only
  requested if those cores exist.
- **BSS info versions 115 and 116** accepted in scan results; they share the
  v109 prefix, the only part `brcmfmac` reads.

Licensing: the `brcmfmac` files are ISC-licensed upstream, but 0013 was
written by reading bcmdhd (GPL-2.0): register addresses, values and the
order of operations come from it. Treat 0013 as GPL-2.0-only, like the whole
kernel package (`license=` in its `APKBUILD`), not as ISC.

The commit message of 0013 still says "Not tested on hardware", the one of
0012 says the phone keeps the modules blacklisted "until Wi-Fi is tested".
They are kept as they were
built (only the `From:` line was normalised for publication, with the
checksums updated); this document is the current state.

### 4. Get the firmware from your own factory image

You need the factory image of the **build installed on your phone** (ours:
`CP4A.261105.040.A1`), from Google's official factory images page for
`komodo`. Check its hash against Google's table. Work in a private directory
outside this repository, e.g. `$KOMODO_WORK/firmware/`.

In general:

1. Take `vendor.img` out of the inner `image-komodo-*.zip` (`unzip -p`).
2. If it is an Android sparse image, convert it with `simg2img`. In our build
   it was a plain ext4 image; another build could use another filesystem
   (EROFS), which needs its own extraction tool.
3. Copy the files out of `/firmware/` in that image (the partition is
   mounted at `/vendor` on Android, so this is `/vendor/firmware`). For ext4
   no root is needed: `debugfs -R 'dump /firmware/<name> <name>' vendor.img`
   for each file.
4. Delete `vendor.img` when done.

Factory files used for the b1 chip (ours) and their names for `brcmfmac`
(in `/lib/firmware/updates/brcm/` on the phone):

| Factory file (`/vendor/firmware`) | Name for brcmfmac |
|---|---|
| `fw_bcmdhd.bin_4390_b1` | `brcmfmac4390b1-pcie.google,zumapro-komodo.bin` |
| `bcmdhd.cal_USI_G6BB_6327_V27` | `brcmfmac4390b1-pcie.google,zumapro-komodo.txt` |
| `bcmdhd_clm.blob_4390_b1` | `brcmfmac4390b1-pcie.google,zumapro-komodo.clm_blob` |
| `bcmdhd_txcap.blob_4390_b1` | `brcmfmac4390b1-pcie.google,zumapro-komodo.txcap_blob` |

For b0 and a0 the script uses the same pattern with `_4390_b0` /
`bcmdhd.cal_USI_G6BB_6325_V25` and `_4390_a0` / `bcmdhd.cal_USI_G6BB_6321_V21`.
Do not use the unsuffixed `fw_bcmdhd.bin`: in this build it is a copy of the
a0 firmware.

**Which NVRAM (`.txt`).** Google's driver picks it from the module's OTP. We
could not read the OTP, so we chose `bcmdhd.cal_USI_G6BB_6327_V27`, the one
whose header names a production b1 module ("USI G6 SKU3 module(4390B1)
V2.7"), over `bcmdhd.cal_4390_b1`, which is Broadcom's reference-board
NVRAM. It worked, but it is a choice, not something we confirmed against
stock Android. The script's `--nvram-ref` switches to the reference one.

**MAC address.** The NVRAMs carry a template MAC (Broadcom's `00:90:4c`
prefix), the same for every phone. NetworkManager used a random MAC on our
unit. The script's `--mac 02:…` writes a locally administered MAC of your
choice into the staged NVRAM instead; not tried by us.

SHA-256 of the factory files of `CP4A.261105.040.A1` (public files from
Google's image; they do not identify a unit). The script pins the ones it
uses:

| Factory file | Size | SHA-256 |
|---|---|---|
| `fw_bcmdhd.bin_4390_a0` | 2852472 | `882b841c55b6e7f10bbcd016fd6713a58b1967d5ff96d9ae23e4891972885062` |
| `fw_bcmdhd.bin_4390_b0` | 2407507 | `0ebe1021dd6824fe4b8c2ff74fa0488087b3f7a8577ee78fdafe35c361876ac4` |
| `fw_bcmdhd.bin_4390_b1` | 2525343 | `f6876748f917c65e7a256b040cc5e341d7754ddc8760f948b411dbf8eb398529` |
| `bcmdhd.cal_4390_a0` | 18763 | `11b7d26e4f83210ffea9919e714868cca97f26fe1881a7ffbef7e9df27ace6ad` |
| `bcmdhd.cal_4390_b0` | 22190 | `8bbfb0b57ff870b6822fdbf40863f85c8b4b09def94a026eb92f772fc0ceb013` |
| `bcmdhd.cal_4390_b1` | 22335 | `226c3f62fca1071c6808a7eb3a90a864ed7d1872ecc63fa974255c228b57a637` |
| `bcmdhd.cal_USI_G6BB_6313_V13` | 19519 | `8746a90654b7bf465c181de5c4e965070ac09b0d0d625c636b1d9eed197dd49a` |
| `bcmdhd.cal_USI_G6BB_6321_V21` | 19128 | `807a4e4d089971659252278e3a3032e2ac5e017035b11b10dd71333c91ab5869` |
| `bcmdhd.cal_USI_G6BB_6325_V25` | 22217 | `ba51698ff5ca402fbe0e576de8a9350011f9164159f7ef86878ecf08abfaae72` |
| `bcmdhd.cal_USI_G6BB_6327_V27` | 22502 | `eb63bfd7af479f036b38e36ca9a90e11bf745627d6e75e5870f8b426dce8353b` |
| `bcmdhd_clm.blob_4390_a0` | 23040 | `afd36e3d684617041f84dc8917524fb628a1f05fbd9cb2181c65daf0d4093c9a` |
| `bcmdhd_clm.blob_4390_b0`, `_b1` (identical) | 25948 | `1a717990c013d9c09ba42b27a70b56d6659f89918456f28e9a64d994e881b0ce` |
| `bcmdhd_txcap.blob_4390_a0` | 3185 | `58d802d076e48dc73d24d334ac8a62c69b34a12fca853aa4fad993daf44b97bb` |
| `bcmdhd_txcap.blob_4390_b0`, `_b1` (identical) | 1793 | `6c257501583f41410069758a73ab559bc92f7c3c4951cc4c2ff8ed92973e3a8e` |

There are no separate signature files next to the firmware, and stock
Android loads it without one.

### 5. Blacklist before the first boot of the new kernel

As soon as `pcie_1` is enabled in the DTB, udev would load `pcie_gs201` and
`brcmfmac` by modalias on every boot. On the phone, **before** booting the
new kernel:

```sh
printf 'blacklist pcie_gs201\nblacklist brcmfmac\n' | sudo tee /etc/modprobe.d/komodo-wifi.conf
```

You remove it in step 9, once WiFi works.

### 6. Build and install the kernel without reinstalling

Refresh your pmaports copy with this repository's `linux-google-zumapro`
(deleting files that are no longer there), then:

```sh
"${PMB[@]}" build linux-google-zumapro
```

and follow [MILESTONE-3.md step 9](MILESTONE-3.md#9-updating-the-kernel-without-reinstalling):
copy the apk to the phone, `sudo apk add --allow-untrusted --no-network
./linux-google-zumapro-*.apk`, copy back `vmlinuz`, `initramfs` and
`vendor_boot.img` from `/boot`, run `scripts/mkimages-pmos.sh` on them and
flash only `boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b`. That is how
our unit got `pkgrel=3`.

### 7. Copy the firmware

```sh
KOMODO_WORK=$KOMODO_WORK scripts/install-wifi-firmware.sh --dry-run
KOMODO_WORK=$KOMODO_WORK KOMODO_SSH_HOST=<user>@172.16.43.1 \
  KOMODO_SSH_KEY=<your-key> scripts/install-wifi-firmware.sh
```

It reads the factory-named files from `$KOMODO_WORK/firmware/vendor-firmware`
(`KOMODO_WIFI_FW_SRC`), refuses any file whose SHA-256 is not the one pinned
for `CP4A.261105.040.A1`, stages the renamed set in
`$KOMODO_WORK/build/wifi-fw`, copies it to `/lib/firmware/updates/brcm/`
(it asks for your `sudo` password on the phone) and checks the hashes on the
phone. By default it installs the b1, b0 and a0 sets side by side (the driver
picks the one for the chip); `--only-b1` installs only b1. It does not touch
modules, blacklists or boot images. More in
[`../scripts/README.md`](../scripts/README.md).

### 8. Bring-up by phases

Do this by hand over SSH, with the blacklist from step 5 in place.

**Phase (a): the PCIe link, without the WiFi driver.** The controller driver
can stop after each stage (`stop_after=0..5`) and trace what it does
(`trace=1`), so a failure shows where it happened:

```sh
sudo modprobe phy_zuma_pcie
for s in 0 1 2 3 4; do
  sudo modprobe pcie_gs201 stop_after=$s trace=1; sudo dmesg | tail -n 30
  sudo rmmod pcie_gs201
done
sudo modprobe pcie_gs201 trace=1          # stage 5: WL_REG_ON, PERST#, training, enumeration
sudo dmesg | grep -iE 'gs201|pcie|link'
cat /sys/bus/pci/devices/0000:01:00.0/revision        # 0x05 on ours = b1
cat /sys/bus/pci/devices/0000:01:00.0/current_link_speed
```

On our unit all five stages passed at the first try, and the last one
logged, among others:

```text
gs201-pcie 13120000.pcie: link up on try 1
gs201-pcie 13120000.pcie: PCIe Gen.3 x1 link up
pci 0000:01:00.0: [14e4:4438] type 00 class 0x028000 PCIe Endpoint
pci 0000:01:00.0: assigned reserved memory node wifi-dma-pool
```

We ran phase (a) before 0013 existed, with a test image that differed from
Milestone 3 only in the DTB (patch 0012 applied); the helper used to swap the
DTB is not published. With the `pkgrel=3` kernel the same commands apply.

**Phase (b): the WiFi driver.** **Reboot first** (cold): Omamobile reports,
on the Pixel 8 Pro's BCM4398, that the chip keeps firmware state across
`WL_REG_ON` and FLR and a second load does not start until a reboot. We did
not test whether the BCM4390 behaves the same. Ours worked at the first
attempt, so no reload was ever needed.

```sh
sudo modprobe phy_zuma_pcie
sudo modprobe pcie_gs201
sudo modprobe brcmfmac
sudo dmesg | grep -iE 'brcmf|bcm4390'
ip -br link; iw dev
```

Lines we got, in order (quoted from the log of the clean boot in step 9):

```text
brcmfmac 0000:01:00.0: BCM4390 rev 5: PFM kickstart set (ssctrl was 0x00080080)
brcmfmac: brcmf_chip_sysmem_ramsize: BCM4390: SYSMEM reports 3276800 bytes, using 3276800
brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4390b1-pcie for chip BCM4390/5
brcmfmac: brcmf_c_process_txcap_blob: TxCap blob found, loading
brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4390/5 wl0: Sep 17 2026 16:08:08 version 27.10.1121.57.30 (ge2638ec b1 release24) FWID 01-2d6ca23d
```

`wlan0` appeared at the first try. Then connect from Phosh's settings, or:

```sh
nmcli dev wifi list
nmcli --ask dev wifi connect "<network>"
```

### 9. Remove the blacklist and reboot

```sh
sudo rm /etc/modprobe.d/komodo-wifi.conf
sudo reboot
```

On our unit, in that clean boot: the PCIe link was up ~5.7 s into the boot
and the firmware loaded at ~7.7 s; `wlan0` reconnected by itself to the
saved network; zero failed systemd units.

### 10. Checks we ran and what we saw

```sh
uname -r; systemctl --failed
ethtool -i wlan0                     # driver brcmfmac, bus-info 0000:01:00.0
iw dev wlan0 link                    # link rate (contains the network name: do not paste it)
nmcli -f IN-USE,BARS,SECURITY,CHAN dev wifi list
ping -c 10 <a public host>
sudo apk update
```

- **Scan:** networks on 2.4 GHz and 5 GHz, WPA2 and WPA3 among them.
- **Connection:** to a WPA network from Phosh's settings; automatic
  reconnection after a reboot.
- **Traffic:** ping to the Internet ~18 ms with no loss; `apk update` works,
  so the phone no longer depends on the USB cable for network access.
- **Speed:** **not measured.** The only figure is the link rate the driver
  reported, 270 Mbit/s on a 5 GHz channel, which says nothing about real
  throughput.

### 11. Warnings in the log

Seen in the log of the clean boot of step 9; none stopped WiFi from working,
and we have not investigated them:

- `brcmf_c_set_joinpref_default: Set join_pref error (-52)` (twice): the
  firmware rejects the default join preferences, which steer the choice of
  band when a network is seen on several.
- `brcmf_p2p_create_p2pdev: timeout occurred` and `add iface p2p-dev-wlan0
  type 10 failed: err=-5`: the P2P device is not created, so **WiFi Direct
  most likely does not work**.
- `brcmf_construct_chaninfo: Ignoring unexpected firmware channel 169`
  (also 173 and 177): the firmware lists 5 GHz channels `brcmfmac` does not
  expect.
- `brcmf_msgbuf_process_rx_complete: Received unexpected monitor pkt`,
  repeated about forty times within a second, shortly after the interface
  comes up.

### 12. Back out

- **WiFi off, kernel kept:** put the blacklist from step 5 back and reboot.
  With `pcie_gs201` blacklisted the chip is never powered.
- **Firmware off the phone:**
  `KOMODO_WORK=… KOMODO_SSH_HOST=… scripts/install-wifi-firmware.sh --remove`
  (deletes `/lib/firmware/updates/brcm/brcmfmac4390*` only).
- **Previous kernel:** reflash your Milestone 3 `boot_b`, `vendor_boot_b`
  and `vendor_kernel_boot_b` and downgrade the apk on the phone, as in
  [MILESTONE-3.md step 10](MILESTONE-3.md#10-back-out). Without 0012 in the
  DTB, `pcie_1` stays disabled.
- If something hangs the SoC: force a reboot with the buttons; with the
  blacklist in place it will not happen again on boot.

### 13. What does not work or was not tried

1. **Throughput:** not measured (no `iperf3` or download test). Only the
   advertised link rate is known.
2. **WiFi Direct (P2P):** the P2P interface fails to be created (step 11);
   probably not working.
3. **6 GHz and WiFi 7 (EHT / MLO):** not tried. The CLM blob decides which
   channels are allowed; we did not check the regulatory domain the firmware
   applies.
4. **Suspend, power saving, battery cost:** not tried. Whether the chip
   enters low power states is unknown.
5. **Access point / hotspot mode:** not tried.
6. **Firmware crash recovery:** not tried. Reloading the driver without a
   reboot may not work (see phase (b)).
7. **NVRAM:** chosen without reading the module's OTP (step 4).
8. **MAC address:** template MAC in the NVRAM; NetworkManager uses a random
   one. A stable per-phone MAC is not set up.
9. **Bluetooth:** untouched. It is the same BCM4390, on a UART; it is not
   described in our device tree yet.
10. **Upstream:** 0013 is not sent anywhere and is not meant to be as is
    (AI-assisted, see the top of this document).

### Not verified

- That bcmdhd's RAM size and PFM kickstart are needed on this unit: SYSMEM
  reported the same RAM size, and we never tried without the PFM kickstart.
- That stock Android uses the same NVRAM we chose.
- Behaviour on chip revisions a0 or b0 (only b1 was seen).
- Firmware files of other Android builds (the pins are for
  `CP4A.261105.040.A1` only).
- Any hardware beyond what is listed in [STATUS.md](STATUS.md).

---

## Español

### Antes de empezar

Vale todo lo de [MILESTONE-3.md](MILESTONE-3.md#antes-de-empezar) y el hito 3
debe funcionar ya en tu unidad. **No se reinstala:** `userdata` no se toca;
solo cambian `boot_b`, `vendor_boot_b` y `vendor_kernel_boot_b`. **Sin
garantía:** lo hicimos una vez, en una unidad.

### Resumen de pasos

Los comandos, las tablas completas y los hashes están en la sección inglesa.

1. **Entradas:** paquete del kernel `linux-google-zumapro` `pkgrel=3` (mismo
   commit `ffd33b7…`, misma config, 13 parches); paquete del dispositivo sin
   cambios (`pkgrel=3`); firmware de la imagen de fábrica
   `CP4A.261105.040.A1` (`vendor.img`, `/vendor/firmware`), que no se
   redistribuye; versión de firmware `27.10.1121.57.30 (b1 release24)`.
2. **Hardware:** Broadcom BCM4390 (combo WiFi 7 + Bluetooth), PCI
   `14e4:4438`, revisión PCI `0x05` = revisión de chip 5 = **b1**; en
   `pcie_1` (`pcie_gs201`, PHY `phy_zuma_pcie`), una lane, Gen3;
   `WL_REG_ON` en `gph3-4`; pool DMA restringido de 16 MiB. En nuestra unidad,
   enlace Gen3 x1 (8,0 GT/s) al primer intento.
3. **Parches:** 0012 (DTS) enciende `WL_REG_ON`, `pcie_1`, el puerto raíz, la
   PHY, el nodo `wifi@0,0` y el pool DMA. 0013 añade el BCM4390 a `brcmfmac`
   tratándolo como su hermano BCM4398 y, donde el driver GPL-2.0 bcmdhd de
   Google para el 4390 hace otra cosa, sigue a bcmdhd: tamaño de RAM fijo de
   3276800 bytes (en nuestra unidad SYSMEM daba lo mismo), "PFM kickstart"
   del PMU para las revisiones 2 y 5, un juego de firmware por revisión
   (`brcmfmac4390{a0,b0,b1}-pcie.google,zumapro-komodo.*`), dominios de
   potencia opcionales y BSS info v115/v116. Licencia: los ficheros de
   `brcmfmac` son ISC en upstream, pero 0013 se escribió leyendo bcmdhd
   (GPL-2.0): trátalo como GPL-2.0-only, igual que todo el paquete del
   kernel. Los mensajes de 0012 y 0013 dicen todavía que no está probado:
   se conservan como se compilaron (el comentario del `APKBUILD` ya está
   corregido).
4. **Firmware de tu propia imagen de fábrica:** la del build que tenga tu
   teléfono, de la página oficial de Google, con el hash comprobado. Saca
   `vendor.img` del zip interior; si es sparse, `simg2img`; en nuestro build
   era ext4 y basta `debugfs -R 'dump /firmware/<nombre> <nombre>'` sin root
   (otro build podría usar EROFS). Borra `vendor.img` al terminar. Para b1:
   `fw_bcmdhd.bin_4390_b1` → `.bin`, `bcmdhd.cal_USI_G6BB_6327_V27` → `.txt`,
   `bcmdhd_clm.blob_4390_b1` → `.clm_blob`, `bcmdhd_txcap.blob_4390_b1` →
   `.txcap_blob`, todos con el prefijo
   `brcmfmac4390b1-pcie.google,zumapro-komodo`. No uses `fw_bcmdhd.bin` sin
   sufijo (es una copia del a0). La NVRAM USI se eligió sin poder leer la
   OTP del módulo; `--nvram-ref` usa la de la placa de referencia. La MAC de
   la NVRAM es de plantilla, igual en todos los teléfonos; NetworkManager usó
   una aleatoria. Los SHA-256 son de ficheros públicos de la imagen de
   Google y no identifican la unidad.
5. **Lista negra antes del primer arranque del kernel nuevo:**
   `/etc/modprobe.d/komodo-wifi.conf` con `blacklist pcie_gs201` y
   `blacklist brcmfmac`.
6. **Kernel sin reinstalar:** compilar `linux-google-zumapro`, `apk add` en
   el teléfono y reflashear solo `boot_b`, `vendor_boot_b` y
   `vendor_kernel_boot_b`, como en el paso 9 del hito 3.
7. **Copiar el firmware** con `scripts/install-wifi-firmware.sh` (primero
   `--dry-run`): comprueba los SHA-256 fijados, prepara los ficheros
   renombrados dentro de `KOMODO_WORK`, los copia a
   `/lib/firmware/updates/brcm/` (pide la contraseña de `sudo` del teléfono)
   y comprueba los hashes allí. No toca módulos, listas negras ni imágenes.
8. **Por fases, a mano por SSH:** (a) `phy_zuma_pcie` y `pcie_gs201` etapa a
   etapa con `stop_after=0..5 trace=1`: las cinco pasaron a la primera,
   enlace Gen3 x1, `[14e4:4438]` enumerado con el pool DMA. Esta fase se
   hizo antes de existir 0013, con una imagen de prueba que solo cambiaba el
   DTB (parche 0012). (b) **Reiniciar en frío antes** (Omamobile lo reporta
   para el BCM4398 del Pixel 8 Pro; en el 4390 no lo hemos comprobado, y en
   nuestra unidad funcionó al primer intento) y
   cargar `brcmfmac`: `PFM kickstart set`, `SYSMEM reports 3276800 bytes`,
   `using brcm/brcmfmac4390b1-pcie for chip BCM4390/5`, `TxCap blob found`,
   firmware `27.10.1121.57.30`. `wlan0` al primer intento.
9. **Quitar la lista negra y reiniciar:** en el arranque limpio, enlace PCIe
   a los ~5,7 s, firmware a los ~7,7 s, reconexión automática a la red
   guardada, cero unidades de systemd fallidas.
10. **Resultados:** escanea redes de 2,4 y 5 GHz (WPA2 y WPA3); se conecta a
    una red WPA desde los ajustes de Phosh; ping a Internet de ~18 ms sin
    pérdidas; `apk update` funciona. **Velocidad sin medir:** solo se conoce
    la tasa de enlace anunciada, 270 Mbit/s en un canal de 5 GHz.
11. **Avisos en el log**, sin investigar y sin impedir el uso:
    `Set join_pref error (-52)`; fallo al crear `p2p-dev-wlan0` (timeout,
    `err=-5`), así que WiFi Direct casi seguro no funciona; "Ignoring
    unexpected firmware channel" 169, 173 y 177; "Received unexpected monitor
    pkt" repetido al levantar la interfaz.
12. **Vuelta atrás:** volver a poner la lista negra y reiniciar (el chip no
    se enciende); `install-wifi-firmware.sh --remove` borra solo
    `brcmfmac4390*` del teléfono; el kernel anterior, reflasheando las tres
    imágenes del hito 3 y bajando el apk. Si algo cuelga el SoC, reinicio
    forzado; con la lista negra no se repite al arrancar.
13. **Lo que no funciona o no se ha probado:** velocidad real; WiFi Direct;
    6 GHz y WiFi 7 (EHT/MLO), ni qué dominio regulatorio aplica el firmware;
    suspensión, ahorro de energía y consumo; modo punto de acceso; recuperación
    tras un fallo del firmware; NVRAM elegida sin leer la OTP; MAC estable
    por teléfono; Bluetooth (mismo BCM4390, por UART, aún sin describir en el
    device tree). El parche 0013 no se ha enviado a ningún sitio y no debe
    enviarse tal cual (hecho con asistencia de IA).

### Sin verificar

Que el tamaño de RAM y el PFM kickstart de bcmdhd hagan falta en esta unidad
(SYSMEM daba el mismo tamaño y nunca se probó sin el kickstart); que Android
stock use la misma NVRAM; el comportamiento con chips a0 o b0 (solo se ha
visto b1); el firmware de otros builds de Android (los hashes fijados son
solo de `CP4A.261105.040.A1`); el resto del hardware ([STATUS.md](STATUS.md)).
