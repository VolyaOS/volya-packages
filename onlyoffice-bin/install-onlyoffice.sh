#!/bin/bash
set -e

# Config
pkgname=onlyoffice-bin
pkgver=8.3.2
arch=x86_64
deb_url="https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v${pkgver}/onlyoffice-desktopeditors_amd64.deb"
patch_url="https://aur.archlinux.org/cgit/aur.git/plain/010-onlyoffice-bin-fix-document-opening.patch?h=onlyoffice-bin"
deb_file="onlyoffice-desktopeditors-${arch}-${pkgver}.deb"
patch_file="010-onlyoffice-bin-fix-document-opening.patch"
builddir="$(pwd)/onlyoffice-${pkgver}"

# Dependencies (Void Linux package names)
dependencies=(
  curl gtk+3 bsdtar alsa-lib libpulseaudio gstreamer1-pipewire gst-plugins-base1 gst-plugins-ugly1
  libXScrnSaver patch nss nspr dejavu-fonts-ttf font-liberation-narrow-ttf font-crosextra-carlito-ttf
  desktop-file-utils hicolor-icon-theme
)

echo "[*] Installing dependencies..."
sudo xbps-install -y "${dependencies[@]}"

# Prepare workspace
mkdir -p "$builddir/pkg"
cd "$builddir"

echo "[*] Downloading .deb and patch..."
curl -L -o "$deb_file" "$deb_url"
curl -L -o "$patch_file" "$patch_url"

echo "[*] Extracting .deb..."
bsdtar -xf "$deb_file"
bsdtar -xf data.tar.xz -C pkg

echo "[*] Patching..."
patch -d pkg -Np1 -i "$builddir/$patch_file"

echo "[*] Installing files to system..."
sudo cp -dr --no-preserve=ownership pkg/* /

echo "[*] Setting up icons..."
while IFS= read -r -d '' icon; do
    res="$(basename "$icon" | sed 's/\.png$//;s/^.*-//')"
    dest="/usr/share/icons/hicolor/${res}x${res}/apps"
    sudo mkdir -p "$dest"
    sudo ln -sf "/opt/onlyoffice/desktopeditors/$(basename "$icon")" "$dest/onlyoffice-desktopeditors.png"
done < <(find /opt/onlyoffice/desktopeditors -maxdepth 1 -name 'asc-de-*.png' -print0)

echo "[*] Linking 3rd party license..."
sudo mkdir -p /usr/share/licenses/$pkgname
sudo ln -sf /opt/onlyoffice/desktopeditors/3DPARTYLICENSE /usr/share/licenses/$pkgname/3DPARTYLICENSE

echo "[✓] onlyoffice-bin v$pkgver installed successfully on Void Linux!"
