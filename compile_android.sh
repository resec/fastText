#!/bin/bash
# This is a composite script to build all for Android OS

ARCHS="arm64-v8a armeabi armeabi-v7a mips mips64 x86 x86_64"

USAGE="usage: compile_android.sh [-A architecture]

A script to build fasttext for android.

Options:
-A architecture
Target platforms to compile. The default is: $ARCHS."

if [[ -z "${NDK_ROOT}" ]]; then
    echo "NDK_ROOT should be set as an environment variable" 1>&2
    echo "$USAGE"
    exit 1
fi

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
  make TARGET=android ANDROID_ARCH=${ARCH} clean
  make -j4 TARGET=android ANDROID_ARCH=${ARCH} lib
  if [ $? -ne 0 ]
  then
    echo "${ARCH} compilation failed."
    exit 1
  fi
done