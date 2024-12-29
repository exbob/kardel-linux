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

# 拷贝 Busybox 可执行文件
cp -r ${BUILD_DIR}/${BUSYBOX_SRC_VERSION}/_install/ ${ROOTFS}
echo "------"
echo "busybox build success."
echo "rootfs path: ${ROOTFS}"