#!/bin/bash
#sourcedir
SD="$(pwd)"
CODENAME="mako"
DEFCONFIG="mako_defconfig"
RD=ramdisk
MKRam=$SD/chaos/tools/mkbootfs
MKBoot=$SD/chaos/tools/mkbootimg
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
mkdir -p $SD/out/$CODENAME/system/lib/modules
mkdir -p $SD/out/$CODENAME/META-INF/com/google/android

echo "[BUILD]: moving kernel and modules to output";

mv $SD/arch/arm/boot/zImage $SD/out/$CODENAME/kernel/zImage
 find $SD/ -name \*.ko -exec cp '{}' $SD/out/$CODENAME/system/lib/modules/ ';'

echo "[BUILD]: copy flashing tools to output";

cp -R $SD/chaos/tools/update-binary $SD/out/$CODENAME/META-INF/com/google/android/update-binary
cp -R $SD/chaos/tools/updater-script $SD/out/$CODENAME/META-INF/com/google/android/updater-script
cp -R $SD/chaos/tools/flash_image $SD/out/$CODENAME/flash_image

echo "[BUILD]: creating boot.img ...";
cd $SD/out/$CODENAME
$SD/chaos/tools/mkbootfs $SD/chaos/$RD | gzip > $SD/out/$CODENAME/boot.img-ramdisk.cpio.gz
$SD/chaos/tools/mkbootimg --base 0 --pagesize 2048 --kernel_offset 0x80208000 --ramdisk_offset 0x81800000 --second_offset 0x81100000 --tags_offset 0x80200100 --cmdline 'console=ttyHSL0,115200,n8 androidboot.hardware=mako lpj=67677 user_debug=31' --kernel $SD/out/$CODENAME/kernel/zImage --ramdisk $SD/out/$CODENAME/boot.img-ramdisk.cpio.gz -o boot.img

echo "[BUILD]: creating flashing-zip";

cd $SD/out/$CODENAME
zip -r "$CODENAME"_"$DATE"_"$BRANCH"-"$REV".zip META-INF/ system/ boot.img flash_image
OUTPUT_ZIP=$CODENAME"_"$DATE"_"$BRANCH"-"$REV"
cd $SD
echo "[BUILD]: Siging";
java -jar $SD/chaos/tools/signapk.jar $SD/chaos/tools/testkey.x509.pem $SD/chaos/tools/testkey.pk8 $SD/out/$CODENAME/$OUTPUT_ZIP.zip $SD/out/$CODENAME/$OUTPUT_ZIP-signed.zip
rm $SD/out/$CODENAME/$OUTPUT_ZIP.zip

echo "[BUILD]: Done!! look in /out ;)";

