#!/bin/sh
# SPDX-License-Identifier: MIT
#
# komodo-first-tone.sh - the first-sound check of docs/MILESTONE-6.md: ONE
# short 1 kHz tone through the Pixel 9 Pro XL's BOTTOM speaker at the
# bring-up minimum, then everything back to the minimum.
#
# Runs ON THE PHONE, as root, after "komodo-aoc-start card". Read
# docs/MILESTONE-6.md and docs/SAFETY.md first. NO WARRANTY.
#
# The CS35L41 amplifiers run WITHOUT Cirrus' protection firmware and WITHOUT
# the factory calibration. A loud or long signal can damage a speaker for
# good. That is why this script:
#   - takes no arguments: no gain, no file, no duration;
#   - generates its own signal: a 1 kHz sine, -20 dBFS peak, 2 s, 50 ms
#     fades, 16-bit stereo 48 kHz (no bass, no noise, no square waves);
#   - sets fixed levels: Bottom Digital 657 and Analog 0 (the lowest analog
#     step), Top (also the earpiece) Digital 1 and Analog 0, DSP bypassed
#     (PCM Source ASP) on both, route TDM_0_RX Mixer EP6;
#   - reads every level back and the driver's limits (Digital max 817,
#     Analog max 10) and REFUSES TO PLAY if anything differs;
#   - puts both amplifiers back to the minimum and the route off on exit,
#     also on error or Ctrl-C.
# Do not edit it to raise levels. Raising them needs the protection
# firmware and the calibration first, which is not done.
#
# aplay -R: the AoC's deep-buffer entry point EP6 drops what was written
# before START; with aplay's default start threshold (whole buffer) the
# stream stalls on a kernel without patches 0022-0023. -R starts it with
# ~50 ms written, which works with and without those patches.
#
# komodo-first-tone.sh - el primer tono del hito 6: UN tono corto de 1 kHz
# por el altavoz INFERIOR al minimo de bring-up, con niveles fijos que
# comprueba antes de reproducir (si no cuadran, no reproduce) y vuelta al
# minimo al salir. Sin argumentos a proposito. Los amplificadores van SIN
# firmware de proteccion ni calibracion: no lo modifiques para subir niveles.
set -u

CARD_NAME=google,komodo-aoc-snd-card
[ "$(id -u)" = 0 ] || { echo "run it as root (sudo)"; exit 2; }
[ $# = 0 ] || { echo "this script takes no arguments on purpose"; exit 2; }

# Card index and the EP6 playback device, by name (not hardcoded numbers).
C=$(awk -v n="$CARD_NAME" '$0 ~ " - " n "$" {print $1; exit}' /proc/asound/cards 2>/dev/null)
[ -n "$C" ] || { echo "no $CARD_NAME in /proc/asound/cards (run komodo-aoc-start card)"; exit 3; }
D=$(awk -F: -v c="$(printf '%02d' "$C")" '$1 ~ "^"c"-" && $2 ~ /^ *EP6 playback/ {split($1,a,"-"); print a[2]+0; exit}' /proc/asound/pcm)
[ -n "$D" ] || { echo "no EP6 playback device on card $C"; exit 3; }

a() { amixer -q -c "$C" cset name="$1" "$2" || echo "FAILED: $1"; }
g() { amixer -c "$C" cget name="$1" | sed -n 's/.*: values=//p'; }
mx() { amixer -c "$C" cget name="$1" | sed -n 's/.*,max=\([0-9]*\),.*/\1/p'; }
quiet() {
  a "Bottom Digital PCM Volume" 1; a "Bottom Analog PCM Volume" 0
  a "Top Digital PCM Volume" 1; a "Top Analog PCM Volume" 0
  a "TDM_0_RX Mixer EP6" 0
}

# The driver's limits without the protection firmware: refuse anything else.
for amp in Top Bottom; do
  [ "$(mx "$amp Digital PCM Volume")" = 817 ] && [ "$(mx "$amp Analog PCM Volume")" = 10 ] || {
    echo "unexpected $amp volume limits (want Digital max 817, Analog max 10); not playing"; exit 8; }
done

W=$(mktemp -d /run/komodo-tone.XXXXXX) || exit 4
trap 'quiet; rm -rf "$W"' EXIT
trap 'exit 130' INT TERM
trap 'exit 129' HUP

# 1 kHz, peak 3276 (-20 dBFS), 96000 frames, 50 ms linear fades, stereo.
{
  printf 'RIFF\044\334\005\000WAVEfmt \020\000\000\000\001\000\002\000'
  printf '\200\273\000\000\000\356\002\000\004\000\020\000data\000\334\005\000'
  awk 'BEGIN {
    n = 96000; f = 2400; pi = atan2(0, -1); line = ""
    for (i = 0; i < n; i++) {
      e = 1; if (i < f) e = i / f; if (n - 1 - i < f) e = (n - 1 - i) / f
      x = 3276 * e * sin(2 * pi * 1000 * i / 48000)
      v = (x < 0) ? -int(-x + 0.5) : int(x + 0.5)
      if (v < 0) v += 65536
      b = sprintf("\\0%03o\\0%03o", v % 256, int(v / 256))
      line = line b b
      if (i % 480 == 479) { print line; line = "" }
    }
  }' | while IFS= read -r l; do printf '%b' "$l"; done
} > "$W/tone.wav"
[ "$(wc -c < "$W/tone.wav")" = 384044 ] || { echo "tone generation failed"; exit 4; }

a "Top Digital PCM Volume" 1; a "Top Analog PCM Volume" 0
a "Top PCM Source" ASP; a "Bottom PCM Source" ASP
a "TDM_0_RX Chan" Four; a "TDM_0_RX Format" S32_LE; a "TDM_0_RX Sample Rate" SR_48K
a "TDM_0_TX Chan" Four; a "TDM_0_TX Format" S32_LE; a "TDM_0_TX Sample Rate" SR_48K
a "Bottom Digital PCM Volume" 657; a "Bottom Analog PCM Volume" 0
a "TDM_0_RX Mixer EP6" 1

BD=$(g "Bottom Digital PCM Volume"); BA=$(g "Bottom Analog PCM Volume")
TD=$(g "Top Digital PCM Volume"); TA=$(g "Top Analog PCM Volume")
BS=$(amixer -c "$C" cget name="Bottom PCM Source" | sed -n 's/.*: values=//p')
TS=$(amixer -c "$C" cget name="Top PCM Source" | sed -n 's/.*: values=//p')
echo "levels: bottom digital=$BD analog=$BA source=$BS; top digital=$TD analog=$TA source=$TS"
[ "$BD" = 657 ] && [ "$BA" = 0 ] && [ "$TD" = 1 ] && [ "$TA" = 0 ] && [ "$BS" = 0 ] && [ "$TS" = 0 ] || {
  echo "LEVELS OUTSIDE THE RULE, not playing"; exit 8; }

# buffer 500 ms, period 80 ms, start with ~50 ms written; 4 s hard stop
timeout 4 aplay -q -D "hw:$C,$D" --buffer-time=500000 --period-time=80000 -R -450000 "$W/tone.wav"
RC=$?
echo "aplay rc=$RC (expected 0, about 2 s)"
exit $RC
