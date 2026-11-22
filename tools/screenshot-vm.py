#!/usr/bin/env python3
"""
Avvia una ISO in QEMU e cattura screenshot via QMP (senza display).

Uso:
    ./tools/screenshot-vm.py dist/PeachOS-1.0-amd64.iso --out screenshots

Produce screenshot PNG e il log seriale nella cartella indicata.
Richiede: qemu-system-x86_64, python3. KVM opzionale ma consigliato.
"""
import argparse
import json
import os
import socket
import struct
import subprocess
import sys
import time
import zlib


def qmp_connect(path, timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(path)
            stream = sock.makefile("rwb")
            stream.readline()  # greeting
            stream.write(json.dumps({"execute": "qmp_capabilities"}).encode() + b"\n")
            stream.flush()
            stream.readline()
            return sock, stream
        except OSError:
            time.sleep(0.5)
    raise RuntimeError("QMP non disponibile: " + path)


def qmp_command(stream, command, arguments=None):
    message = {"execute": command}
    if arguments:
        message["arguments"] = arguments
    stream.write(json.dumps(message).encode() + b"\n")
    stream.flush()
    while True:
        line = stream.readline()
        if not line:
            raise RuntimeError("connessione QMP chiusa")
        event = json.loads(line)
        if "return" in event or "error" in event:
            return event


def ppm_to_png(source, destination):
    with open(source, "rb") as handle:
        data = handle.read()

    tokens = []
    index = 0
    while len(tokens) < 4:
        while index < len(data) and data[index:index + 1].isspace():
            index += 1
        if data[index:index + 1] == b"#":
            while index < len(data) and data[index:index + 1] not in (b"\n", b"\r"):
                index += 1
            continue
        start = index
        while index < len(data) and not data[index:index + 1].isspace():
            index += 1
        tokens.append(data[start:index])

    magic, width, height, maxval = tokens[0], int(tokens[1]), int(tokens[2]), int(tokens[3])
    if magic != b"P6" or maxval != 255:
        raise ValueError("formato PPM non supportato")
    index += 1
    pixels = data[index:index + width * height * 3]

    raw = b"".join(
        b"\x00" + pixels[y * width * 3:(y + 1) * width * 3] for y in range(height)
    )

    def chunk(kind, payload):
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
        )

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 6))
    png += chunk(b"IEND", b"")
    with open(destination, "wb") as handle:
        handle.write(png)


def main():
    parser = argparse.ArgumentParser(description="Screenshot di una ISO in QEMU")
    parser.add_argument("iso")
    parser.add_argument("--out", default="screenshots")
    parser.add_argument("--shots", default="25,50,80", help="secondi (separati da virgola)")
    parser.add_argument("--memory", default="3072")
    parser.add_argument("--cpus", default="2")
    parser.add_argument("--no-kvm", action="store_true")
    parser.add_argument("--uefi", action="store_true", help="avvia in modalita' UEFI (OVMF)")
    parser.add_argument("--secure-boot", action="store_true",
                        help="UEFI con Secure Boot attivo (firmware Microsoft)")
    parser.add_argument("--ovmf-dir", default="/usr/share/OVMF")
    args = parser.parse_args()

    if not os.path.isfile(args.iso):
        sys.exit("ISO non trovata: " + args.iso)

    os.makedirs(args.out, exist_ok=True)
    qmp_path = "/tmp/peach-qmp.sock"
    serial_log = os.path.join(args.out, "serial.log")
    if os.path.exists(qmp_path):
        os.unlink(qmp_path)

    command = [
        "qemu-system-x86_64",
        "-m", args.memory,
        "-smp", args.cpus,
        "-cdrom", args.iso,
        "-boot", "d",
        "-display", "none",
        "-vga", "std",
        "-no-reboot",
        "-qmp", "unix:%s,server=on,wait=off" % qmp_path,
        "-serial", "file:" + serial_log,
    ]
    if not args.no_kvm and os.path.exists("/dev/kvm"):
        command.insert(1, "-enable-kvm")

    if args.uefi or args.secure_boot:
        suffix = ".ms" if args.secure_boot else ""
        code = os.path.join(args.ovmf_dir, "OVMF_CODE_4M%s.fd" % suffix)
        vars_source = os.path.join(args.ovmf_dir, "OVMF_VARS_4M%s.fd" % suffix)
        for path in (code, vars_source):
            if not os.path.isfile(path):
                sys.exit("Firmware OVMF non trovato: " + path)
        vars_copy = os.path.join(args.out, "ovmf-vars.fd")
        with open(vars_source, "rb") as source, open(vars_copy, "wb") as target:
            target.write(source.read())
        command[1:1] = [
            "-drive", "if=pflash,format=raw,readonly=on,file=" + code,
            "-drive", "if=pflash,format=raw,file=" + vars_copy,
        ]

    print("==> avvio QEMU")
    process = subprocess.Popen(
        command,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT,
    )

    try:
        sock, stream = qmp_connect(qmp_path)
    except Exception:
        process.kill()
        raise

    shots = sorted(int(value) for value in args.shots.split(",") if value.strip())
    started = time.time()

    try:
        for seconds in shots:
            remaining = seconds - (time.time() - started)
            if remaining > 0:
                time.sleep(remaining)
            ppm = os.path.join(args.out, "shot-%03d.ppm" % seconds)
            png = os.path.join(args.out, "shot-%03d.png" % seconds)
            qmp_command(stream, "screendump", {"filename": ppm})
            time.sleep(0.5)
            ppm_to_png(ppm, png)
            os.unlink(ppm)
            print("==> screenshot a %ds: %s" % (seconds, png))
    finally:
        try:
            qmp_command(stream, "quit")
        except Exception:
            pass
        try:
            process.wait(timeout=15)
        except subprocess.TimeoutExpired:
            process.kill()
        sock.close()

    print("==> log seriale:", serial_log)
    print("==> fatto")


if __name__ == "__main__":
    main()
