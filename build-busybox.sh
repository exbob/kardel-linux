#!/bin/sh
. ./config.sh

# 定义 Busybox 版本
BUSYBOX_SRC_VERSION="busybox-1.36.1"
BUSYBOX_SRC_URL="https://www.busybox.net/downloads/${BUSYBOX_SRC_VERSION}.tar.bz2"

# 下载Busybox源码并解压
if [ -e ${DOWNLOAD_DIR}/${BUSYBOX_SRC_VERSION}.tar.bz2 ]; then
    echo "busybox source code has been downloaded."
else
    wget -c ${BUSYBOX_SRC_URL} -O ${DOWNLOAD_DIR}/${BUSYBOX_SRC_VERSION}.tar.bz2
    if [ -e ${DOWNLOAD_DIR}/${BUSYBOX_SRC_VERSION}.tar.bz2 ]; then
        echo "busybox source code download success."
    else
        echo "busybox source code download failed."
        exit 1
    fi
fi

if [ -d ${BUILD_DIR}/${BUSYBOX_SRC_VERSION} ]; then
    echo "remove old busybox source code..."
    rm -rf ${BUILD_DIR}/${BUSYBOX_SRC_VERSION}
fi
tar -xvf ${DOWNLOAD_DIR}/${BUSYBOX_SRC_VERSION}.tar.bz2 -C ${BUILD_DIR}

# 编译 Busybox
cd ${BUILD_DIR}/${BUSYBOX_SRC_VERSION}
make defconfig
sed -e 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' -i .config
make install
cd ${TOP_DIR}

# 更新 ${INSTALL_DIR} 下的目录
if [ -d ${INSTALL_DIR}/${ROOTFS} ]; then
    rm -rf ${INSTALL_DIR}/${ROOTFS}
fi
cp -r ${BUILD_DIR}/${BUSYBOX_SRC_VERSION}/_install/ ${INSTALL_DIR}/${ROOTFS}
echo "------"
echo "busybox build success."
echo "rootfs path: ${INSTALL_DIR}/${ROOTFS}"