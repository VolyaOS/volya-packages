#!/bin/bash
set -e

###########################
# Configuration Variables #
###########################

pkgname="onlyoffice-bin"
pkgver="8.3.2"
pkgrel="1"
arch="x86_64"
pkg_full="${pkgname}-${pkgver}_${pkgrel}"

deb_url="https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v${pkgver}/onlyoffice-desktopeditors_amd64.deb"
patch_url="https://aur.archlinux.org/cgit/aur.git/plain/010-onlyoffice-bin-fix-document-opening.patch?h=onlyoffice-bin"

deb_file="onlyoffice-desktopeditors-${arch}-${pkgver}.deb"
patch_file="010-onlyoffice-bin-fix-document-opening.patch"

# Directories for building and staging
builddir="$(pwd)/build_onlyoffice"
staging_dir="$(pwd)/staging_onlyoffice"

###############################
# Prepare Build Environment
###############################

mkdir -p "$builddir"
cd "$builddir"

###############################
# Download Source + Patch Files
###############################

echo "[*] Downloading .deb and patch..."
curl -L -o "$deb_file" "$deb_url"
curl -L -o "$patch_file" "$patch_url"

##############################
# Extract the .deb and Apply Patch
##############################

echo "[*] Extracting deb contents..."
bsdtar -xf "$deb_file"

mkdir -p pkg
bsdtar -xf data.tar.xz -C pkg

echo "[*] Applying patch..."
# Using absolute path to the patch file ensures it is found.
patch -d pkg -Np1 -i "$builddir/$patch_file"

#########################################
# Prepare Staging Directory for Packaging
#########################################

echo "[*] Setting up staging directory..."
rm -rf "$staging_dir"
mkdir -p "$staging_dir"
cp -a pkg/. "$staging_dir/"

# Create icon symlinks
echo "[*] Creating icon symlinks..."
while IFS= read -r -d '' icon; do
    res="$(basename "$icon" | sed 's/\.png$//;s/^.*-//')"
    dest="$staging_dir/usr/share/icons/hicolor/${res}x${res}/apps"
    mkdir -p "$dest"
    ln -sf "../../../../../../opt/onlyoffice/desktopeditors/$(basename "$icon")" \
        "$dest/onlyoffice-desktopeditors.png"
done < <(find "$staging_dir/opt/onlyoffice/desktopeditors" -maxdepth 1 -type f -name 'asc-de-*.png' -print0)

# License link
echo "[*] Linking 3rd party license..."
mkdir -p "$staging_dir/usr/share/licenses/${pkgname}"
ln -sf "../../opt/onlyoffice/desktopeditors/3DPARTYLICENSE" "$staging_dir/usr/share/licenses/${pkgname}/3DPARTYLICENSE"

#################################
# Create the XBPS Binary Package
#################################

echo "[*] Creating XBPS package..."
xbps-create \
    -A "$arch" \
    -n "${pkg_full}" \
    -s "An office suite that combines text, spreadsheet and presentation editors" \
    -S "OnlyOffice Binary Package" \
    -H "https://www.onlyoffice.com/" \
    -m "Fabian Constantinescu <fabian.constantinescu@protonmail.com>" \
    -l "AGPL-3.0" \
    -D "curl>=0 gtk+3>=0 bsdtar>=0 alsa-lib>=0 libpulseaudio>=0 gstreamer1-pipewire>=0 gst-plugins-base1>=0 gst-plugins-ugly1>=0 libXScrnSaver>=0 patch>=0 nss>=0 nspr>=0 dejavu-fonts-ttf>=0 font-liberation-ttf>=0 font-crosextra-carlito-ttf>=0 desktop-file-utils>=0 hicolor-icon-theme>=0" \
    -P "onlyoffice=${pkgver}" \
    -R "onlyoffice" \
    -c "Initial package for OnlyOffice binary suite" \
    "$staging_dir"

echo "[✓] Package created!"
