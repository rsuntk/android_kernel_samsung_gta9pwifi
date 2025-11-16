#!/usr/bin/env bash
set -o pipefail
trap 'echo "Build cancelled by user."; exit 130' INT

# Download Prebuilt Clang (AOSP)
if [ ! -d $(pwd)/toolchain/clang/aosp ]; then
    echo "Downloading Prebuilt Clang from AOSP..."
    mkdir -p $(pwd)/toolchain/clang/aosp
   git clone https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6573524 $(pwd)/toolchain/clang/aosp
else
    echo "This $(pwd)/toolchain/clang/aosp already exists."
fi
# Exports
export ARCH=arm64
export CROSS_COMPILE=$(pwd)/toolchain/clang/aosp/bin
export CLANG_TOOL_PATH=$(pwd)/toolchain/clang/aosp/bin
export PATH=${CLANG_TOOL_PATH}:${PATH//"${CLANG_TOOL_PATH}:"}
export LD_LIBRARY_PATH=$(pwd)/toolchain/clang/aosp/lib
make -C $(pwd) O=$(pwd)/out CC=clang LLVM=1 ARCH=arm64 DTC_EXT=$(pwd)/tools/dtc CLANG_TRIPLE=aarch64-linux-gnu- vendor/gta9p_eur_openx_defconfig 2>&1 | tee log.txt

# Run the build
if make -C $(pwd) O=$(pwd)/out CC=clang LLVM=1 ARCH=arm64 DTC_EXT=$(pwd)/tools/dtc CLANG_TRIPLE=aarch64-linux-gnu- -j$(nproc --all) 2>&1 | tee -a log.txt; then
    echo "Build completed successfully."
else
    echo "Build failed or was cancelled. Exiting." >&2
    exit 1
fi
# Final Build
mkdir -p kernelbuild
echo "Copying Image into kernelbuild..."
cp -nf $(pwd)/out/arch/arm64/boot/Image $(pwd)/kernelbuild
echo "Done copying Image/.gz into kernelbuild."
mkdir -p modulebuild
echo "Copying modules into modulebuild..."
cp -nr $(find out -name '*.ko') $(pwd)/modulebuild
echo "Stripping debug symbols from modules..."
$(pwd)/toolchain/clang/aosp/bin/llvm-strip --strip-debug $(pwd)/modulebuild/*.ko
echo "Done copying modules into modulebuild."
# AnyKernel3 Support
cp -nf $(pwd)/kernelbuild/Image $(pwd)/AnyKernel3
cp -nr $(pwd)/modulebuild/*.ko $(pwd)/AnyKernel3/modules/system/lib/modules
cd AnyKernel3 && zip -r9 UPDATE-AnyKernel3-gta9.zip * -x .git README.md *placeholder
echo "Done."
