#!/bin/bash
# Builds the fasttext library with ARM and x86 architectures for iOS, and
# packs them into a fat file.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GENDIR=${SCRIPT_DIR}/gen
LIBDIR=${GENDIR}/ios/lib
LIB_NAME=libfasttext.a
ARCHS="armv7 armv7s arm64 i386 x86_64"

USAGE="usage: compile_ios.sh [-A architecture]

A script to build fasttext for ios.
This script can only be run on MacOS host platforms.

Options:
-A architecture
Target platforms to compile. The default is: $ARCHS."

while
  ARG="${1-}"
  case "$ARG" in
  -*)  case "$ARG" in -*A*) ARCHS="${2?"$USAGE"}"; shift; esac
       case "$ARG" in -*[!A]*) echo "$USAGE" >&2; exit 2;; esac;;
  "")  break;;
  *)   echo "$USAGE" >&2; exit 2;;
  esac
do
  shift
done

for ARCH in ${ARCHS}; do
  make TARGET=ios IOS_ARCH=${ARCH} clean
  make -j4 TARGET=ios IOS_ARCH=${ARCH} lib
  if [ $? -ne 0 ]
  then
    echo "${ARCH} compilation failed."
    exit 1
  fi
  ARCH_LIBS="${ARCH_LIBS} ${LIBDIR}/${ARCH}/${LIB_NAME}"
done

lipo \
${ARCH_LIBS} \
-create \
-output ${LIBDIR}/${LIB_NAME}
