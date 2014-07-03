#!/bin/bash
#sourcedir
SD="$(pwd)"
CODENAME="mako"
DEFCONFIG="mako_defconfig"
NRJOBS=$(( $(nproc) * 2 ))

export PATH=$PATH:$SD/chaos/toolchain/arm-eabi-4.6/bin
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-eabi-

#if we are not called with an argument, default to branch master
if [ -z "$1" ]; then
  BRANCH="master"
  echo "[BUILD]: WARNING: Not called with branchname, defaulting to $BRANCH!";
  echo "[BUILD]: If this is not what you want, call this script with the branchname.";
else
  BRANCH=$1;
  echo "[BUILD]: Current Branch: $BRANCH";
fi

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


 if [ -f "$SD/arch/arm/boot/zImage" ];
    then
        echo "[BUILD]: Done with kernel!...";
    else
        echo "[BUILD]: Error"
        exit 0
    fi

echo "[BUILD]: creating output folders";

mkdir -p $SD/out/$CODENAME
mkdir -p $SD/out/$CODENAME/kernel
#mkdir -p $SD/out/$CODENAME/modules
#mkdir -p $SD/out/$CODENAME/META-INF/com/google/android

echo "[BUILD]: moving kernel and modules to output";

mv $SD/arch/arm/boot/zImage $SD/out/$CODENAME/kernel/zImage
#find $SD/ -name \*.ko -exec cp '{}' $SD/out/$CODENAME/system/lib/modules/ ';'

echo "[BUILD]: Cleaning out directory...";
cd $SD/out/$CODENAME/
find $SD/out/$CODENAME/* -maxdepth 0 ! -name '*.zip' ! -name '*.md5' ! -name '*.sha1' ! -name kernel ! -name modules ! -name out -exec rm -rf '{}' ';'

echo "[BUILD]: copy flashing tools to output";

cp -R $SD/chaos/tools/* $SD/out/$CODENAME
cd $SD/out/$CODENAME/
 #create zip and clean folder
    echo "[BUILD]: Creating zip: ChaOS_"$CODENAME"_"$DATE"_"$BRANCH"-"$REV".zip ...";
    zip -r ChaOS_"$CODENAME"_"$DATE"_"$BRANCH"-"$REV".zip . -x "*.zip" "*.sha1" "*.md5"
echo "[BUILD]: Creating changelog: ChaOS_"$CODENAME"_"$DATE"_"$BRANCH"-"$REV".txt ...";
cd $SD
git log --pretty=format:'%h (%an) : %s' --graph $REV^..HEAD > $SD/out/$CODENAME/ChaOS_"$CODENAME"_"$DATE"_"$BRANCH"-"$REV".txt
    echo "[BUILD]: Done!...";


