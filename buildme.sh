#!/bin/bash
#sourcedir
SOURCE_DIR="$(pwd)"
CODENAME="mako"
DEFCONFIG="mako_defconfig"
NRJOBS=$(( $(nproc) * 2 ))
BRANCH="exp"
export PATH=$PATH:/usr/local/share/arm-eabi-4.6/bin
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-eabi-


#saving new rev
REV=$(git log --pretty=format:'%h' -n 1)
echo "[BUILD]: Saved current hash as revision: $REV...";
#date of build
DATE=$(date +%Y%m%d_%H%M%S)
echo "[BUILD]: Start of build: $DATE...";

#build the kernel
echo "[BUILD]: Cleaning kernel (make mrproper)...";
make mrproper
echo "[BUILD]: Using defconfig: $DEFCONFIG...";
make $DEFCONFIG
echo "[BUILD]: Changing CONFIG_LOCALVERSION to: -ChaOS-"$CODENAME"-"$BRANCH" ...";
sed -i "/CONFIG_LOCALVERSION=\"/c\CONFIG_LOCALVERSION=\"-ChaOS-"$CODENAME"-"$BRANCH"\"" .config



echo "[BUILD]: Bulding the kernel...";
time make -j$NRJOBS || { return 1; }
echo "[BUILD]: Done with kernel!...";



