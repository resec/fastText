#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

SHELL := /bin/bash

# Try to figure out the host system
HOST_OS :=
ifeq ($(OS),Windows_NT)
	HOST_OS = WINDOWS
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
	        HOST_OS := LINUX
	endif
	ifeq ($(UNAME_S),Darwin)
		HOST_OS := OSX
	endif
endif
HOST_ARCH := $(shell if [[ $(shell uname -m) =~ i[345678]86 ]]; then echo x86_32; else echo $(shell uname -m); fi)

CXX = c++
CXXFLAGS = -pthread -std=c++11
AR = ar
ARFLAGS = -r
OBJS = args.o dictionary.o productquantizer.o matrix.o qmatrix.o vector.o model.o utils.o fasttext.o
OBJDIR_OBJS = $(addprefix $(OBJDIR), $(OBJS))
INCLUDES = -I.

MAKEFILE_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

GENDIR := $(MAKEFILE_DIR)/gen
OBJDIR := $(GENDIR)/host/obj/
LIBDIR := $(GENDIR)/host/lib/
BINDIR := $(GENDIR)/host/bin/

# Set up Android building
ifeq ($(TARGET),android)
	ANDROID_OS_ARCH :=
	ifeq ($(HOST_OS),LINUX)
		ANDROID_OS_ARCH=linux
	endif
	ifeq ($(HOST_OS),OSX)
		ANDROID_OS_ARCH=darwin
	endif
	ifeq ($(HOST_OS),WINDOWS)
    	$(error "windows is not supported.")
	endif

    ifeq ($(HOST_ARCH),x86_32)
	    ANDROID_OS_ARCH := $(ANDROID_OS_ARCH)-x86
    else
		ANDROID_OS_ARCH := $(ANDROID_OS_ARCH)-$(HOST_ARCH)
    endif

    ifndef ANDROID_ARCH
        ANDROID_ARCH := armeabi-v7a
    endif

    ifeq ($(ANDROID_ARCH),arm64-v8a)
        TOOLCHAIN := aarch64-linux-android-4.9
        SYSROOT_ARCH := arm64
        BIN_PREFIX := aarch64-linux-android
        MARCH_OPTION :=
    endif
    ifeq ($(ANDROID_ARCH),armeabi)
        TOOLCHAIN := arm-linux-androideabi-4.9
        SYSROOT_ARCH := arm
        BIN_PREFIX := arm-linux-androideabi
        MARCH_OPTION :=
    endif
    ifeq ($(ANDROID_ARCH),armeabi-v7a)
        TOOLCHAIN := arm-linux-androideabi-4.9
        SYSROOT_ARCH := arm
        BIN_PREFIX := arm-linux-androideabi
        MARCH_OPTION := -march=armv7-a -mfloat-abi=softfp -mfpu=neon 
    endif
    ifeq ($(ANDROID_ARCH),mips)
        TOOLCHAIN := mipsel-linux-android-4.9
        SYSROOT_ARCH := mips
        BIN_PREFIX := mipsel-linux-android
        MARCH_OPTION :=
    endif
    ifeq ($(ANDROID_ARCH),mips64)
        TOOLCHAIN := mips64el-linux-android-4.9
        SYSROOT_ARCH := mips64
        BIN_PREFIX := mips64el-linux-android
        MARCH_OPTION :=
    endif
    ifeq ($(ANDROID_ARCH),x86)
        TOOLCHAIN := x86-4.9
        SYSROOT_ARCH := x86
        BIN_PREFIX := i686-linux-android
        MARCH_OPTION :=
    endif
    ifeq ($(ANDROID_ARCH),x86_64)
        TOOLCHAIN := x86_64-4.9
        SYSROOT_ARCH := x86_64
        BIN_PREFIX := x86_64-linux-android
        MARCH_OPTION :=
    endif

	ifndef NDK_ROOT
    	$(error "NDK_ROOT is not defined.")
	endif
	CXX := $(CC_PREFIX) $(NDK_ROOT)/toolchains/$(TOOLCHAIN)/prebuilt/$(ANDROID_OS_ARCH)/bin/$(BIN_PREFIX)-c++
	CXXFLAGS += \
--sysroot $(NDK_ROOT)/platforms/android-21/arch-$(SYSROOT_ARCH) \
$(MARCH_OPTION) \
-fPIC
	INCLUDES += \
-I$(NDK_ROOT)/sources/android/support/include \
-I$(NDK_ROOT)/sources/cxx-stl/llvm-libc++/include

	AR := $(NDK_ROOT)/toolchains/$(TOOLCHAIN)/prebuilt/$(ANDROID_OS_ARCH)/bin/$(BIN_PREFIX)-ar

	OBJDIR := $(GENDIR)/android/obj/$(ANDROID_ARCH)/
	LIBDIR := $(GENDIR)/android/lib/$(ANDROID_ARCH)/
	BINDIR := $(GENDIR)/android/bin/$(ANDROID_ARCH)/
endif  # android

# Settings for iOS.
ifeq ($(TARGET),ios)
	IPHONEOS_PLATFORM := $(shell xcrun --sdk iphoneos --show-sdk-platform-path)
	IPHONEOS_SYSROOT := $(shell xcrun --sdk iphoneos --show-sdk-path)
	IPHONESIMULATOR_PLATFORM := $(shell xcrun --sdk iphonesimulator --show-sdk-platform-path)
	IPHONESIMULATOR_SYSROOT := $(shell xcrun --sdk iphonesimulator --show-sdk-path)
	MIN_SDK_VERSION := 8.0
	ifndef IOS_ARCH
    	$(error "IOS_ARCH is not defined.")
	endif
	ifeq ($(IOS_ARCH),armv7)
		CXXFLAGS += -miphoneos-version-min=$(MIN_SDK_VERSION) \
		-arch armv7 \
		-mno-thumb \
		-isysroot ${IPHONEOS_SYSROOT}
	endif
	ifeq ($(IOS_ARCH),armv7s)
		CXXFLAGS += -miphoneos-version-min=$(MIN_SDK_VERSION) \
		-arch armv7s \
		-mno-thumb \
		-isysroot ${IPHONEOS_SYSROOT}
	endif
	ifeq ($(IOS_ARCH),arm64)
		CXXFLAGS += -miphoneos-version-min=$(MIN_SDK_VERSION) \
		-arch arm64 \
		-isysroot ${IPHONEOS_SYSROOT}
	endif
	ifeq ($(IOS_ARCH),i386)
		CXXFLAGS += -mios-simulator-version-min=$(MIN_SDK_VERSION) \
		-arch i386 \
		-mno-sse \
		-isysroot ${IPHONESIMULATOR_SYSROOT}
	endif
	ifeq ($(IOS_ARCH),x86_64)
		CXXFLAGS += -mios-simulator-version-min=$(MIN_SDK_VERSION) \
		-arch x86_64 \
		-isysroot ${IPHONESIMULATOR_SYSROOT}
	endif
	
	OBJDIR := $(GENDIR)/ios/obj/$(IOS_ARCH)/
	LIBDIR := $(GENDIR)/ios/lib/$(IOS_ARCH)/
	BINDIR := $(GENDIR)/ios/bin/$(IOS_ARCH)/
endif  # ios

LIB_NAME := libfasttext.a
LIB_PATH := $(LIBDIR)$(LIB_NAME)

lib: CXXFLAGS += -Os -funroll-loops
lib: $(LIB_PATH)

all: CXXFLAGS += -Os -funroll-loops
all: $(BINDIR)fasttext

debug: CXXFLAGS += -g -O0 -fno-inline
debug: $(BINDIR)fasttext

$(OBJDIR)args.o: src/args.cc src/args.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/args.cc -o $@

$(OBJDIR)dictionary.o: src/dictionary.cc src/dictionary.h src/args.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/dictionary.cc -o $@

$(OBJDIR)productquantizer.o: src/productquantizer.cc src/productquantizer.h src/utils.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/productquantizer.cc -o $@

$(OBJDIR)matrix.o: src/matrix.cc src/matrix.h src/utils.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/matrix.cc -o $@

$(OBJDIR)qmatrix.o: src/qmatrix.cc src/qmatrix.h src/utils.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/qmatrix.cc -o $@

$(OBJDIR)vector.o: src/vector.cc src/vector.h src/utils.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/vector.cc -o $@

$(OBJDIR)model.o: src/model.cc src/model.h src/args.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/model.cc -o $@

$(OBJDIR)utils.o: src/utils.cc src/utils.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/utils.cc -o $@

$(OBJDIR)fasttext.o: src/fasttext.cc src/*.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c src/fasttext.cc -o $@

$(BINDIR)fasttext: $(OBJDIR_OBJS) src/fasttext.cc
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(OBJDIR_OBJS) src/main.cc -o $(BINDIR)fasttext

$(LIB_PATH): $(OBJDIR_OBJS)
	@mkdir -p $(dir $@)
	$(AR) $(ARFLAGS) $(LIB_PATH) $(OBJDIR_OBJS)

clean:
	rm -rf $(OBJDIR)
	rm -rf $(BINDIR)
	rm -rf $(LIBDIR)
