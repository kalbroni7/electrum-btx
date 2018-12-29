#!/bin/bash

NAME_ROOT=electrum

# These settings probably don't need any change
export WINEPREFIX=/opt/wine64
export WINEDEBUG=-all
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=22

PYHOME=c:/python3
PYTHON="wine $PYHOME/python.exe -OO -B"


# Let's begin!
set -e

pushd ../../electrum
if ! which msgfmt > /dev/null 2>&1; then
    fail "Please install gettext"
fi
for i in ./locale/*; do
    dir=$WINEPREFIX/drive_c/electrum/electrum/$i/LC_MESSAGES
    mkdir -p $dir
    msgfmt --output-file=$dir/electrum.mo $i/electrum.po || true
done
popd

cp -f ../../LICENSE .

# Install frozen dependencies
$PYTHON -m pip install -r ../deterministic-build/requirements.txt
$PYTHON -m pip install -r ../deterministic-build/requirements-hw.txt

pushd $WINEPREFIX/drive_c/electrum
find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

pushd $WINEPREFIX/drive_c/electrum
# see https://github.com/pypa/pip/issues/2195 -- pip makes a copy of the entire directory
info "Pip installing Electrum. This might take a long time if the project folder is large."
$PYTHON -m pip install --no-warn-script-location .
popd

#rm -rf dist/

# build standalone and portable versions
wine "C:/python$PYTHON_VERSION/scripts/pyinstaller.exe" --noconfirm --ascii --clean --name electrum-btx-3.3.6 -w deterministic.spec

info "building NSIS installer"
# $VERSION could be passed to the electrum.nsi script, but this would require some rewriting in the script itself.
wine "$WINEPREFIX/drive_c/Program Files (x86)/NSIS/makensis.exe" /D electrum.nsi

echo "Done."
sha256sum dist/electrum*exe
