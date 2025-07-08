#!/bin/sh
. ./config.sh

# 定义内核版本
KERNEL_SRC_VERSION="linux-5.15.175"
KERNEL_SRC_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/${KERNEL_SRC_VERSION}.tar.gz"

# 下载内核源码并解压
if [ -e ${DOWNLOAD_DIR}/${KERNEL_SRC_VERSION}.tar.gz ]; then
    echo "kernel source code has been downloaded."
else
    wget -c ${KERNEL_SRC_URL} -O ${DOWNLOAD_DIR}/${KERNEL_SRC_VERSION}.tar.gz
    if [ -e ${DOWNLOAD_DIR}/${KERNEL_SRC_VERSION}.tar.gz ]; then
        echo "kernel source code download success."
    else
        echo "kernel source code download failed."
        exit 1
    fi
fi

if [ -d ${BUILD_DIR}/${KERNEL_SRC_VERSION} ]; then
    echo "remove old kernel source code..."
    rm -rf ${BUILD_DIR}/${KERNEL_SRC_VERSION}
fi
tar -zxvf ${DOWNLOAD_DIR}/${KERNEL_SRC_VERSION}.tar.gz -C ${BUILD_DIR}

# 编译内核
cd ${BUILD_DIR}/${KERNEL_SRC_VERSION}
export ARCH=x86
make O=./build x86_64_defconfig

# 修改配置，支持一个 RAMDisk，大小为64MB
./scripts/config --file ./build/.config --enable CONFIG_BLK_DEV_RAM
./scripts/config --file ./build/.config --set-val CONFIG_BLK_DEV_RAM_COUNT 1
./scripts/config --file ./build/.config --set-val CONFIG_BLK_DEV_RAM_SIZE 65536

# 添加 NFS 客户端支持
./scripts/config --file ./build/.config --enable CONFIG_NFS_FS
./scripts/config --file ./build/.config --enable CONFIG_NFS_V3
./scripts/config --file ./build/.config --enable CONFIG_NFS_V4
./scripts/config --file ./build/.config --enable CONFIG_ROOT_NFS
./scripts/config --file ./build/.config --enable CONFIG_IP_PNP
./scripts/config --file ./build/.config --enable CONFIG_IP_PNP_DHCP

make O=./build -j8
cd ${TOP_DIR}

# 更新 ${INSTALL_DIR} 下的文件
if [ -e ${INSTALL_DIR}/${KERNEL_IMG} ]; then
    rm -rf ${INSTALL_DIR}/${KERNEL_IMG}
fi
cp ${BUILD_DIR}/${KERNEL_SRC_VERSION}/build/arch/x86/boot/bzImage ${INSTALL_DIR}/${KERNEL_IMG}
echo "------"
echo "kernel build success."
echo "kernel image: ${INSTALL_DIR}/${KERNEL_IMG}"