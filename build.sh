#!/bin/sh
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE="ramdiskcm14"
export PARENT_DIR=`readlink -f ..`
export USE_SEC_FIPS_MODE=true
export CROSS_COMPILE=toolchain/bin/arm-eabi-

# if [ "${1}" != "" ];then
#  export KERNELDIR=`readlink -f ${1}`
# fi

RAMFS_TMP="ramdiskcm14_tmp"

VER="\"-a mystery lies\""
cp -f arch/arm/configs/0googymax3_cm12_defconfig 0googymax3_cm12_defconfig
sed "s#^CONFIG_LOCALVERSION=.*#CONFIG_LOCALVERSION=$VER#" 0googymax3_cm12_defconfig > arch/arm/configs/0googymax3_cm12_defconfig

if [ "${2}" = "x" ];then
 make mrproper || exit 1
# make -j5 0googymax3_defconfig || exit 1
fi

# if [ ! -f $KERNELDIR/.config ];
# if [ "${2}" = "y" ];then
find -name '*.ko' -exec rm -rf {} \;
# fi

# 
make 0googymax3_cm12_defconfig VARIANT_DEFCONFIG=jf_eur_defconfig SELINUX_DEFCONFIG=selinux_defconfig SELINUX_LOG_DEFCONFIG=selinux_log_defconfig || exit 1

. $KERNELDIR/.config

export KCONFIG_NOTIMESTAMP=true
export ARCH=arm

cd $KERNELDIR/
make -j3 CONFIG_NO_ERROR_ON_MISMATCH=y || exit 1

#remove previous ramfs files
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
rm -rf $RAMFS_TMP.cpio.gz
rm -rf $RAMFS_TMP/*
#copy ramfs files to tmp directory
cp -ax $RAMFS_SOURCE $RAMFS_TMP
#clear git repositories in ramfs
find $RAMFS_TMP -name .git -exec rm -rf {} \;
#remove orig backup files
find $RAMFS_TMP -name .orig -exec rm -rf {} \;
#remove empty directory placeholders
find $RAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
#remove mercurial repository
rm -rf $RAMFS_TMP/.hg
#copy modules into ramfs
mkdir -p Googy-Max3-Kernel/GT-I9505_GoogyMax3_CM12.CWM/system/lib/modules
rm -rf Googy-Max3-Kernel/GT-I9505_GoogyMax3_CM12.CWM/system/lib/modules/*
find -name '*.ko' -exec cp -av {} Googy-Max3-Kernel/GT-I9505_GoogyMax3_CM12.CWM/system/lib/modules/ \;
#${CROSS_COMPILE}strip --strip-unneeded Googy-Max3-Kernel/GT-I9505_GoogyMax3_CM12.CWM/system/lib/modules/*

./mkbootfs $RAMFS_TMP | gzip > ramdisk.gz
cmd_line="console=ttyHSL0,115200,n8 androidboot.hardware=qcom user_debug=31 ehci-hcd.park=3 maxcpus=2 androidboot.selinux=permissive"
./mkbootimg --cmdline "$cmd_line" --kernel $KERNELDIR/arch/arm/boot/zImage --ramdisk ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $KERNELDIR/boot.img

mv -f -v boot.img Googy-Max3-Kernel/GT-I9505_GoogyMax3_CM12.CWM/boot.img
cd Googy-Max3-Kernel/GT-I9505_GoogyMax3_CM12.CWM
echo aa > podia
#zip --symlinks -r GoogyMax3_CM12-Kernel_${1}_CWM.zip .


