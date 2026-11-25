// SPDX-License-Identifier: Apache-2.0
/*
 * komodo-bootctl: read, and only under explicit flags update, the A/B slot
 * bytes that the Pixel bootloader (ABL) keeps in the "devinfo" partition.
 * Target: Google Pixel 9 Pro XL (komodo, Tensor G4 / zumapro),
 * bootloader ripcurrentpro-17.0-16433847, devinfo layout 3.19.
 *
 * Layout and update rule from Google's Pixel boot-control HAL
 * (Apache-2.0): https://android.googlesource.com/device/google/gs-common
 *   bootctrl/aidl/DevInfo.h        devinfo_t, devinfo_ab_slot_data_t
 *   bootctrl/aidl/BootControl.cpp  markBootSuccessful(): slots[cur].successful = 1;
 *                                  DevInfoSync(): write sizeof(devinfo_t)=128
 *                                  bytes at offset 0, O_WRONLY|O_DSYNC.
 * Cross-checked against Omamobile's omamobile-bootctl.c (cheetah/tegu,
 * layout 3.15) and against this phone's own backup (layout 3.19) and the
 * ABL's console log ("[A/B] slot data b: 0x00001401" = bytes 0x34-0x37
 * read as a little-endian u32).
 *
 *   devinfo_t (128 bytes, packed):
 *     0x00 u32 magic "DEVI"     0x04 u16 ver_major   0x06 u16 ver_minor
 *     0x08 u8  unused[40]       (ABL-owned, never touched here)
 *     0x30 slot a: +0 retry_count, +1 flags, +2..3 unused
 *     0x34 slot b: idem
 *     0x38 u8  unused1[72]      (ABL-owned, never touched here)
 *   flags (LSB first): bit0 unbootable, bit1 successful, bit2 active,
 *                      bit3 fastboot_ok, bits4-7 unnamed (bit4 is set on
 *                      komodo and tegu; meaning unknown; preserved).
 *   0x80..end: ABL/factory records ("DIUS" TLVs). They hold unique device
 *   data (serial numbers): this tool never prints their values.
 *
 * Commands:
 *   komodo-bootctl dump  <devinfo>                 decode (read-only)
 *   komodo-bootctl check <devinfo> <a|b>           exit 0 if successful, 1 if not
 *   komodo-bootctl mark-successful <devinfo> <a|b> dry run: print the change
 *   komodo-bootctl mark-successful <devinfo> <a|b> --write --i-understand-devinfo
 *                                                  WRITE (see write_slot_flag)
 * <devinfo> is an image file or the block device (/dev/sdd1 on komodo).
 * Exit codes: 0 ok, 1 "no"/refused, 2 usage or I/O error, 3 verify failed.
 *
 * Build (host test):  cc -O2 -Wall -Wextra -o komodo-bootctl komodo-bootctl.c
 * Build (phone):      aarch64 cross compiler, or abuild in the device package.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <linux/fs.h>	/* BLKFLSBUF, BLKROGET, BLKSSZGET */

#define DEVINFO_MAGIC	0x49564544u	/* "DEVI" little-endian */
#define HDR_SIZE	128		/* sizeof(devinfo_t): what the HAL writes */
#define KOMODO_SIZE	8192		/* sdd1 = 2 x 4096-byte sectors */
#define MAX_READ	(1024 * 1024)

#define OFF_VER_MAJOR	0x04
#define OFF_VER_MINOR	0x06
#define OFF_SLOTS	0x30
#define SLOT_SIZE	4
#define F_UNBOOTABLE	0x01
#define F_SUCCESSFUL	0x02
#define F_ACTIVE	0x04
#define F_FASTBOOT_OK	0x08
#define F_KNOWN		0x0f
#define F_SEEN_HIGH	0x10	/* observed on komodo (and tegu); preserved */

/*
 * Layouts this tool may WRITE. Reading accepts any 3.3+ (HAL rule).
 * 3.19 = komodo, ripcurrentpro-17.0-16433847 (backup 2026-11-24).
 */
static const struct { uint16_t maj, min; } write_ok[] = { { 3, 19 } };

static const char *me = "komodo-bootctl";

static uint32_t rd32(const uint8_t *p) { return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24; }
static uint16_t rd16(const uint8_t *p) { return p[0] | p[1] << 8; }

static int usage(void)
{
	fprintf(stderr,
		"usage: %s dump <devinfo>\n"
		"       %s check <devinfo> <a|b>\n"
		"       %s mark-successful <devinfo> <a|b> [--write --i-understand-devinfo]\n",
		me, me, me);
	return 2;
}

static int is_blockdev(const char *path)
{
	struct stat st;
	return stat(path, &st) == 0 && S_ISBLK(st.st_mode);
}

/*
 * Read the whole file/partition. With direct=1 on a block device the page
 * cache is dropped first (BLKFLSBUF) so the bytes come from the UFS, not
 * from what we just wrote into memory.
 */
static uint8_t *read_all(const char *path, size_t *len, int direct)
{
	int fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0) {
		fprintf(stderr, "%s: open %s: %s\n", me, path, strerror(errno));
		return NULL;
	}
	if (direct && is_blockdev(path) && ioctl(fd, BLKFLSBUF, 0) != 0) {
		fprintf(stderr, "%s: BLKFLSBUF %s: %s\n", me, path, strerror(errno));
		close(fd);
		return NULL;
	}
	uint8_t *buf = malloc(MAX_READ + 1);
	size_t n = 0;
	while (buf && n <= MAX_READ) {
		ssize_t r = pread(fd, buf + n, MAX_READ + 1 - n, n);
		if (r < 0 && errno == EINTR)
			continue;
		if (r < 0) {
			fprintf(stderr, "%s: read %s: %s\n", me, path, strerror(errno));
			free(buf);
			buf = NULL;
			break;
		}
		if (r == 0)
			break;
		n += (size_t)r;
	}
	close(fd);
	if (!buf)
		return NULL;
	if (n > MAX_READ || n < HDR_SIZE) {
		fprintf(stderr, "%s: %s: size %zu is not plausible for devinfo\n", me, path, n);
		free(buf);
		return NULL;
	}
	*len = n;
	return buf;
}

static int parse_slot(const char *s)
{
	if (!strcmp(s, "a") || !strcmp(s, "_a"))
		return 0;
	if (!strcmp(s, "b") || !strcmp(s, "_b"))
		return 1;
	return -1;
}

static int header_ok(const uint8_t *d)
{
	uint32_t magic = rd32(d);
	uint16_t maj = rd16(d + OFF_VER_MAJOR), min = rd16(d + OFF_VER_MINOR);
	if (magic != DEVINFO_MAGIC) {
		fprintf(stderr, "%s: bad magic 0x%08x (want \"DEVI\")\n", me, magic);
		return 0;
	}
	if (((uint32_t)maj << 16 | min) < 0x00030003u) {
		fprintf(stderr, "%s: version %u.%u has no A/B data (HAL needs 3.3+)\n", me, maj, min);
		return 0;
	}
	return 1;
}

static int version_writable(const uint8_t *d)
{
	uint16_t maj = rd16(d + OFF_VER_MAJOR), min = rd16(d + OFF_VER_MINOR);
	for (size_t i = 0; i < sizeof(write_ok) / sizeof(write_ok[0]); i++)
		if (write_ok[i].maj == maj && write_ok[i].min == min)
			return 1;
	return 0;
}

static void print_slot(const uint8_t *d, int i)
{
	const uint8_t *s = d + OFF_SLOTS + i * SLOT_SIZE;
	uint8_t f = s[1];
	printf("slot %c: bytes 0x%02x-0x%02x = %02x %02x %02x %02x (ABL log: 0x%08x)\n",
	       'a' + i, OFF_SLOTS + i * SLOT_SIZE, OFF_SLOTS + i * SLOT_SIZE + 3,
	       s[0], s[1], s[2], s[3], rd32(s));
	printf("  retry-count: %u\n", s[0]);
	printf("  active:      %s\n", f & F_ACTIVE ? "yes" : "no");
	printf("  successful:  %s\n", f & F_SUCCESSFUL ? "yes" : "no");
	printf("  unbootable:  %s\n", f & F_UNBOOTABLE ? "yes" : "no");
	printf("  fastboot-ok: %s\n", f & F_FASTBOOT_OK ? "yes" : "no");
	if (f & ~F_KNOWN)
		printf("  high flag bits: 0x%02x (unnamed in the HAL; preserved)%s\n", f & ~F_KNOWN,
		       (f & ~F_KNOWN) & ~F_SEEN_HIGH ? " WARNING: not seen before" : "");
	if (s[2] || s[3])
		printf("  WARNING: unused bytes are not zero\n");
}

/*
 * Records after the header, as seen on komodo: "DI" + 2-letter tag,
 * u32 payload length, u32 name length, then name (NUL-terminated) and
 * value; next record at +12+payload. "DIUS" carries a name; other tags
 * ("DIFR") are listed by tag only. Names and sizes only, NEVER values
 * (one of them is the device serial).
 */
static void list_records(const uint8_t *d, size_t len)
{
	size_t off = HDR_SIZE, n = 0;
	while (off + 12 <= len && d[off] == 'D' && d[off + 1] == 'I') {
		uint32_t pay = rd32(d + off + 4), klen = rd32(d + off + 8);
		if (pay > len || off + 12 + pay > len)
			break;
		if (n < 64) {
			printf("  record @0x%04zx  %c%c%c%c  payload %3u", off,
			       d[off], d[off + 1], d[off + 2] >= 0x20 && d[off + 2] < 0x7f ? d[off + 2] : '?',
			       d[off + 3] >= 0x20 && d[off + 3] < 0x7f ? d[off + 3] : '?', pay);
			if (!memcmp(d + off, "DIUS", 4) && klen && klen <= pay) {
				printf("  name \"");
				for (uint32_t k = 0; k < klen && d[off + 12 + k]; k++) {
					uint8_t c = d[off + 12 + k];
					putchar(c >= 0x20 && c < 0x7f ? c : '?');
				}
				printf("\"");
			}
			printf("  (value not shown)\n");
		}
		n++;
		off += 12 + pay;
	}
	printf("  %zu record(s) parsed from 0x80; parsing stopped at 0x%04zx\n", n, off);
}

static int consistency(const uint8_t *d, size_t len, int verbose)
{
	int bad = 0;
	const uint8_t *a = d + OFF_SLOTS, *b = d + OFF_SLOTS + SLOT_SIZE;
	if (len != KOMODO_SIZE) {
		if (verbose)
			printf("note: size %zu, komodo's devinfo is %d\n", len, KOMODO_SIZE);
		bad = 1;
	}
	if ((a[1] & F_ACTIVE) && (b[1] & F_ACTIVE)) {
		if (verbose)
			printf("note: both slots marked active\n");
		bad = 1;
	}
	if (a[2] || a[3] || b[2] || b[3] || ((a[1] | b[1]) & ~(F_KNOWN | F_SEEN_HIGH))) {
		if (verbose)
			printf("note: reserved slot bits/bytes not as observed on komodo\n");
		bad = 1;
	}
	if (a[0] > 7 || b[0] > 7) {
		if (verbose)
			printf("note: retry count out of range\n");
		bad = 1;
	}
	return !bad;
}

static int cmd_dump(const char *path)
{
	size_t len;
	uint8_t *d = read_all(path, &len, 0);
	if (!d)
		return 2;
	if (!header_ok(d)) {
		free(d);
		return 2;
	}
	printf("devinfo: %s (%zu bytes)\n", path, len);
	printf("magic:   \"DEVI\"\n");
	printf("version: %u.%u (%s)\n", rd16(d + OFF_VER_MAJOR), rd16(d + OFF_VER_MINOR),
	       version_writable(d) ? "layout verified for komodo" : "unverified layout: read-only");
	for (int i = 0; i < 2; i++)
		print_slot(d, i);
	printf("HAL's active slot rule (b if its active bit is set, else a): %c\n",
	       d[OFF_SLOTS + SLOT_SIZE + 1] & F_ACTIVE ? 'b' : 'a');
	int nz = 0;
	for (int i = 8; i < HDR_SIZE; i++)
		if ((i < OFF_SLOTS || i >= OFF_SLOTS + 8) && d[i])
			nz++;
	printf("opaque header bytes 0x08-0x2f/0x38-0x7f: %d non-zero (ABL-owned, never written)\n", nz);
	list_records(d, len);
	printf("consistency: %s\n", consistency(d, len, 1) ? "as expected for komodo" : "UNEXPECTED (writes refused)");
	free(d);
	return 0;
}

static int cmd_check(const char *path, int slot)
{
	size_t len;
	uint8_t *d = read_all(path, &len, 0);
	if (!d)
		return 2;
	if (!header_ok(d)) {
		free(d);
		return 2;
	}
	int ok = d[OFF_SLOTS + slot * SLOT_SIZE + 1] & F_SUCCESSFUL;
	printf("slot %c successful: %s\n", 'a' + slot, ok ? "yes" : "no");
	free(d);
	return ok ? 0 : 1;
}

/*
 * The only write in this tool. HAL semantics (markBootSuccessful): set the
 * successful bit of one slot, nothing else. Guards:
 *  - layout version in write_ok[], size 8192, consistency() passes;
 *  - target slot is active and not unbootable;
 *  - exactly one byte (0x31 or 0x35) changes, verified on the planned image;
 *  - the device is re-read right before writing and must be unchanged;
 *  - write 128 bytes at offset 0 with O_DSYNC + fsync (as DevInfoSync);
 *  - read back all bytes from the device (page cache dropped) and compare
 *    with the planned image; mismatch = exit 3 and the before-image is
 *    printed as a path the caller must restore from.
 * Making the partition writable (blockdev --setrw) is NOT done here: the
 * caller (komodo-boot-success) opens the guard and closes it again.
 */
static int write_slot_flag(const char *path, int slot, int do_write)
{
	size_t len;
	uint8_t *orig = read_all(path, &len, 0);
	if (!orig)
		return 2;
	if (!header_ok(orig)) {
		free(orig);
		return 2;
	}
	if (!version_writable(orig)) {
		fprintf(stderr, "%s: devinfo %u.%u is not a layout verified for komodo; refusing\n",
			me, rd16(orig + OFF_VER_MAJOR), rd16(orig + OFF_VER_MINOR));
		free(orig);
		return 1;
	}
	if (!consistency(orig, len, 1)) {
		fprintf(stderr, "%s: devinfo does not look as expected; refusing\n", me);
		free(orig);
		return 1;
	}
	uint8_t *fl = orig + OFF_SLOTS + slot * SLOT_SIZE + 1;
	if (!(*fl & F_ACTIVE) || (*fl & F_UNBOOTABLE)) {
		fprintf(stderr, "%s: slot %c is %s; refusing\n", me, 'a' + slot,
			*fl & F_UNBOOTABLE ? "unbootable" : "not active");
		free(orig);
		return 1;
	}
	printf("before:\n");
	print_slot(orig, slot);
	if (*fl & F_SUCCESSFUL) {
		printf("slot %c is already successful: nothing to write\n", 'a' + slot);
		free(orig);
		return 0;
	}

	uint8_t *want = malloc(len);
	if (!want) {
		free(orig);
		return 2;
	}
	memcpy(want, orig, len);
	want[OFF_SLOTS + slot * SLOT_SIZE + 1] |= F_SUCCESSFUL;

	int changes = 0;
	for (size_t i = 0; i < len; i++) {
		if (want[i] == orig[i])
			continue;
		changes++;
		if (i != (size_t)(OFF_SLOTS + slot * SLOT_SIZE + 1)) {
			fprintf(stderr, "%s: internal error: byte 0x%zx would change\n", me, i);
			goto refuse;
		}
		printf("planned change: offset 0x%02zx: %02x -> %02x (slot %c successful)\n",
		       i, orig[i], want[i], 'a' + slot);
	}
	if (changes != 1) {
		fprintf(stderr, "%s: internal error: %d changes planned\n", me, changes);
		goto refuse;
	}
	if (!do_write) {
		printf("dry run: nothing written (add --write --i-understand-devinfo)\n");
		free(want);
		free(orig);
		return 0;
	}

	if (is_blockdev(path)) {
		int rfd = open(path, O_RDONLY | O_CLOEXEC), ro = 1;
		if (rfd >= 0) {
			if (ioctl(rfd, BLKROGET, &ro) != 0)
				ro = 1;
			close(rfd);
		}
		if (ro) {
			fprintf(stderr, "%s: %s is read-only (guard closed); the caller must open it\n", me, path);
			goto refuse;
		}
	}

	size_t len2;
	uint8_t *again = read_all(path, &len2, 1);
	if (!again || len2 != len || memcmp(again, orig, len)) {
		fprintf(stderr, "%s: %s changed since it was read; refusing\n", me, path);
		free(again);
		goto refuse;
	}
	free(again);

	int fd = open(path, O_WRONLY | O_DSYNC | O_CLOEXEC);
	if (fd < 0) {
		fprintf(stderr, "%s: open %s for writing: %s\n", me, path, strerror(errno));
		goto refuse;
	}
	ssize_t w = pwrite(fd, want, HDR_SIZE, 0);
	int sync_err = fsync(fd);
	close(fd);
	if (w != HDR_SIZE || sync_err) {
		fprintf(stderr, "%s: WRITE ERROR on %s (%s): check with 'dump' and restore the backup\n",
			me, path, w < 0 ? strerror(errno) : (sync_err ? "fsync" : "short write"));
		free(want);
		free(orig);
		return 3;
	}

	uint8_t *after = read_all(path, &len2, 1);
	if (!after || len2 != len || memcmp(after, want, len)) {
		fprintf(stderr, "%s: VERIFY FAILED: %s does not read back as planned; restore the backup\n",
			me, path);
		free(after);
		free(want);
		free(orig);
		return 3;
	}
	printf("written and verified (%zu bytes compared, 1 byte changed)\nafter:\n", len);
	print_slot(after, slot);
	free(after);
	free(want);
	free(orig);
	return 0;

refuse:
	free(want);
	free(orig);
	return 1;
}

int main(int argc, char **argv)
{
	int do_write = 0, understood = 0, n = 0;
	char *args[3] = { 0 };
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--write"))
			do_write = 1;
		else if (!strcmp(argv[i], "--i-understand-devinfo"))
			understood = 1;
		else if (n < 3)
			args[n++] = argv[i];
		else
			return usage();
	}
	if (n == 2 && !strcmp(args[0], "dump") && !do_write)
		return cmd_dump(args[1]);
	if (n == 3 && !strcmp(args[0], "check") && !do_write) {
		int s = parse_slot(args[2]);
		return s < 0 ? usage() : cmd_check(args[1], s);
	}
	if (n == 3 && !strcmp(args[0], "mark-successful")) {
		int s = parse_slot(args[2]);
		if (s < 0)
			return usage();
		if (do_write != understood) {
			fprintf(stderr, "%s: --write needs --i-understand-devinfo (and vice versa)\n", me);
			return 2;
		}
		return write_slot_flag(args[1], s, do_write);
	}
	return usage();
}
