# Peach OS 1.0 «Trixie»

Distribuzione Linux **live** basata su **Debian 13 (trixie)** con desktop **XFCE**,
costruita con `live-build`. Avvia sia in **BIOS** che in **UEFI**, è in italiano e
ha un'identità visiva dedicata (tema pesca, sfondi e splash originali).

![Peach OS](config/includes.chroot/usr/share/backgrounds/peachos/peach-wallpaper.svg)

## Caratteristiche

| Componente | Scelta |
|---|---|
| Base | Debian 13 «trixie», kernel `linux-image-amd64` |
| Desktop | XFCE 4.20, LightDM con autologin |
| Tema | Arc, icone Papirus, accento pesca (#ff7a45) |
| Applicazioni | Firefox ESR, Thunderbird, LibreOffice, GIMP, VLC, Transmission, GParted, Synaptic |
| Hardware | firmware `non-free-firmware` + microcodice Intel/AMD |
| Lingua | `it_IT.UTF-8`, tastiera italiana, fuso `Europe/Rome` |
| Utente | `peach` / password `live`, sudo senza password |
| Avvio | GRUB ibrido BIOS + UEFI, menu e splash brandizzati |

## Requisiti

- **Windows 10/11 con WSL2** (distro predefinita: `Ubuntu`) — oppure un host **Debian 13**
- ~10 GB liberi e connessione internet (la prima build scarica ~2 GB di pacchetti)
- 4 GB di RAM (consigliati 8)

## Build

### Da Windows (consigliato)

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

Lo script:

1. prepara un chroot **Debian 13** isolato in `/srv/peach-build` (solo la prima volta);
2. sincronizza il progetto e normalizza i permessi;
3. esegue `live-build` (20–40 minuti circa);
4. copia il risultato in `dist\PeachOS-1.0-amd64.iso` + checksum SHA-256.

### Su Debian 13 nativo

```bash
sudo apt install live-build debootstrap debian-archive-keyring \
    syslinux-common syslinux-utils isolinux grub-pc-bin grub-efi-amd64-bin \
    mtools dosfstools squashfs-tools xorriso
sudo ./build.sh
```

## Provarla

```bash
./run-qemu.sh
```

Oppure scrivi la ISO su una chiavetta con `dd`, Rufus o balenaEtcher:
l'immagine è ibrida e avvia sia in BIOS che in UEFI.

**Credenziali:** utente `peach`, password `live`; `sudo` senza password.

Per una verifica automatica senza display, `tools/screenshot-vm.py` avvia la ISO in
QEMU e salva degli screenshot:

```bash
./tools/screenshot-vm.py dist/PeachOS-1.0-amd64.iso --out screenshots
```

## Struttura del progetto

```
auto/
  config                     opzioni di live-build (distro, kernel, bootloader...)
build.ps1                    build da Windows via WSL
build.sh                     build su Linux (root)
run-qemu.sh                  avvio di prova in QEMU
config/
  package-lists/*.list.chroot pacchetti installati (core, desktop, app, firmware)
  hooks/normal/*.hook.chroot  personalizzazioni eseguite nel chroot
  hooks/normal/*.hook.binary  personalizzazioni eseguite prima di creare la ISO
  includes.chroot/            file copiati nel filesystem della ISO
  bootloaders/                splash e tema del menu GRUB
tools/                        setup ambiente, sync, build nel chroot, raccolta ISO
```

## Personalizzazione rapida

| Cosa | Dove |
|---|---|
| Sfondo del desktop | `config/includes.chroot/usr/share/backgrounds/peachos/peach-wallpaper.svg` |
| Sfondo alternativo | `.../peach-dawn.svg` |
| Logo / icona | `config/includes.chroot/usr/share/pixmaps/peachos-logo.svg` |
| Pacchetti | `config/package-lists/*.list.chroot` |
| Tema e icone | `config/includes.chroot/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml` |
| Nome e versione | `config/includes.chroot/etc/os-release` + `auto/config` |
| Splash di avvio | `config/bootloaders/splash.svg` |
| Menu GRUB | `config/bootloaders/grub-pc/live-theme/theme.txt` + `0300-peach-bootmenu.hook.binary` |
| Applicazioni nel menu | `config/includes.chroot/usr/share/applications/` |

Dopo ogni modifica basta rilanciare `build.ps1` (o `build.sh`).

## Come funziona

1. `auto/config` genera la configurazione di `live-build` (Debian 13, XFCE, ISO ibrida).
2. `live-build` crea un chroot Debian con i pacchetti delle liste.
3. Gli hook `*.hook.chroot` applicano locale, timezone, permessi e branding.
4. Gli hook `*.hook.binary` rinominano le voci del menu GRUB.
5. Il chroot viene compresso in SquashFS e inserito nella ISO con GRUB (BIOS + UEFI).
6. `build.sh` rinomina l'immagine in `dist/PeachOS-1.0-amd64.iso` e ne calcola lo SHA-256.

## Limitazioni e prossimi passi

- **Nessun installer grafico**: al momento è una live. Il passo naturale è aggiungere
  Calamares (o il `debian-installer` in modalità live) per installare su disco.
- **Nessuna persistenza**: le modifiche si perdono al riavvio. Si può aggiungere una
  partizione con label `persistence` e il parametro `persistence` in avvio.
- **Secure Boot**: i binari non sono firmati. Su PC con Secure Boot attivo va
  disattivato, oppure va firmata la catena di avvio.
- **URL e marchio**: `peachos.example.org` è un segnaposto; sostituiscilo con il tuo dominio.
- **Repository proprio**: non c'è un archivio Peach OS dedicato; la distro usa i
  repository Debian.

## Note legali

Peach OS è un progetto dimostrativo e non è affiliato a Debian, XFCE, Mozilla,
The Document Foundation o ad altri progetti citati. «Debian» è un marchio della
Software in the Public Interest, Inc. Le immagini e i loghi inclusi sono originali
e rilasciabili con la stessa licenza del progetto.
