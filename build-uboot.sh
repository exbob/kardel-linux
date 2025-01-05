#!/bin/sh
# 编译支持 x86_64 架构的 u-boot ，参考：https://source.denx.de/u-boot/u-boot/-/blob/v2022.10/doc/arch/x86.rst?ref_type=tags

. ./config.sh

# 定义 u-boot 版本
UBOOT_SRC_VERSION="v2024.04"
UBOOT_SRC_URL="https://source.denx.de/u-boot/u-boot/-/archive/${UBOOT_SRC_VERSION}/u-boot-${UBOOT_SRC_VERSION}.tar.bz2"

# 下载 u-boot 源码并解压
if [ -e ${DOWNLOAD_DIR}/u-boot-${UBOOT_SRC_VERSION}.tar.bz2 ]; then
    echo "u-boot source code has been downloaded."
else
    wget -c ${UBOOT_SRC_URL} -O ${DOWNLOAD_DIR}/u-boot-${UBOOT_SRC_VERSION}.tar.bz2
    if [ -e ${DOWNLOAD_DIR}/u-boot-${UBOOT_SRC_VERSION}.tar.bz2 ]; then
        echo "u-boot source code download success."
    else
        echo "u-boot source code download failed."
        exit 1
    fi
fi

if [ -d ${BUILD_DIR}/u-boot-${UBOOT_SRC_VERSION} ]; then
    echo "remove old u-boot source code..."
    rm -rf ${BUILD_DIR}/u-boot-${UBOOT_SRC_VERSION}
fi
tar -xvf ${DOWNLOAD_DIR}/u-boot-${UBOOT_SRC_VERSION}.tar.bz2 -C ${BUILD_DIR}

# 编译 u-boot
cd ${BUILD_DIR}/u-boot-${UBOOT_SRC_VERSION}
make qemu-x86_64_defconfig

# 修改bootargs和bootcmd
./scripts/config --file ./.config --set-str CONFIG_BOOTARGS 'root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init'
./scripts/config --file ./.config --set-str CONFIG_BOOTCOMMAND 'qfw load ${kernel_addr_r} ${ramdisk_addr_r}; zboot ${kernel_addr_r} - ${ramdisk_addr_r} ${filesize}'

make
cd ${TOP_DIR}

# 更新 ${INSTALL_DIR} 下的文件
if [ -e ${INSTALL_DIR}/${UBOOT_IMG} ]; then
    rm -rf ${INSTALL_DIR}/${UBOOT_IMG}
fi

cp ${BUILD_DIR}/u-boot-${UBOOT_SRC_VERSION}/${UBOOT_IMG} ${INSTALL_DIR}/${UBOOT_IMG}
echo "------"
echo "u-boot build success."
echo "u-boot image: ${INSTALL_DIR}/${UBOOT_IMG}"
