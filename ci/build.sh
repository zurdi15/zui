#!/usr/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BUILD_PATH="${SCRIPTPATH}"/release
CONTROL_FILE="${SCRIPTPATH}"/../src/DEBIAN/control

VERSION=$(cat "${CONTROL_FILE}" | grep ^Version | cut -d' ' -f2)
RELEASE=$(cat "${CONTROL_FILE}" | grep Release | cut -d' ' -f2)
ARCH=$(cat "${CONTROL_FILE}" | grep Architecture | cut -d' ' -f2)

[ ! -d "${BUILD_PATH}" ] && mkdir "${BUILD_PATH}"
dpkg-deb -b "${SCRIPTPATH}"/../src "${BUILD_PATH}"/zui_"${VERSION}"-"${RELEASE}"_"${ARCH}".deb
