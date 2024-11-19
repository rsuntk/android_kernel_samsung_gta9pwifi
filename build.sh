#!/bin/bash

# Download Prebuilt Clang (AOSP)
if [ ! -d $(pwd)/toolchain/clang/host/linux-x86/clang-r416183b ]; then
    echo "Downloading Prebuilt Clang from AOSP..."
    mkdir -p $(pwd)/toolchain/clang/host/linux-x86/clang-r416183b
    curl -Lsq https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master-kernel-build-2021/clang-r416183b.tar.gz -o clang.tgz
    tar -xzf clang.tgz -C $(pwd)/toolchain/clang/host/linux-x86/clang-r416183b
else
    echo "This $(pwd)/toolchain/clang/host/linux-x86/clang-r416183b already exists."
fi

# Download Prebuilt GCC (AOSP)
if [ ! -d $(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 ]; then
    echo "Downloading Prebuilt Clang from AOSP..."
    git clone --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b master-kernel-build-2021 $(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
else
    echo "This $(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 already exists."
fi

if [ ! -d $(pwd)/toolchain/gcc/linux-x86/arm/arm-linux-androideabi-4.9 ]; then
    echo "Downloading Prebuilt Clang from AOSP..."
    git clone --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b master-kernel-build-2021 $(pwd)/toolchain/gcc/linux-x86/arm/arm-linux-androideabi-4.9
else
    echo "This $(pwd)/toolchain/gcc/linux-x86/arm/arm-linux-androideabi-4.9 already exists."
fi
# Exports
export ARCH=arm64
export CROSS_COMPILE=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-
export CROSS_COMPILE_COMPAT=$(pwd)/toolchain/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export CLANG_TOOL_PATH=$(pwd)/toolchain/clang/host/linux-x86/clang-r416183b/bin
export PATH=${CLANG_TOOL_PATH}:${PATH//"${CLANG_TOOL_PATH}:"}
export LD_LIBRARY_PATH=$(pwd)/toolchain/clang/host/linux-x86/clang-r416183b/lib64

make -C $(pwd) O=$(pwd)/out CC=clang LLVM=1 ARCH=arm64 DTC_EXT=$(pwd)/tools/dtc CLANG_TRIPLE=aarch64-linux-gnu- vendor/gta9p_eur_openx_defconfig
make -C $(pwd) O=$(pwd)/out CC=clang LLVM=1 ARCH=arm64 DTC_EXT=$(pwd)/tools/dtc CLANG_TRIPLE=aarch64-linux-gnu- -j$(nproc --all)

# Final Build
mkdir -p kernelbuild
echo "Copying Image into kernelbuild..."
cp -nf $(pwd)/out/arch/arm64/boot/Image $(pwd)/kernelbuild
echo "Done copying Image/.gz into kernelbuild."

mkdir -p modulebuild
echo "Copying modules into modulebuild..."
cp -nr $(find out -name '*.ko') $(pwd)/modulebuild
echo "Stripping debug symbols from modules..."
$(pwd)/toolchain/clang/host/linux-x86/clang-r416183b/bin/llvm-strip --strip-debug $(pwd)/modulebuild/*.ko
echo "Done copying modules into modulebuild."

# AnyKernel3 Support
cp -nf $(pwd)/kernelbuild/Image $(pwd)/AnyKernel3
cp -nr $(pwd)/modulebuild/*.ko $(pwd)/AnyKernel3/modules/system/lib/modules
cd AnyKernel3 && zip -r9 UPDATE-AnyKernel3-gta9.zip * -x .git README.md *placeholder

# Cleanups
echo "Cleaning out/ directory..."
rm -rf out/
echo "Done."
