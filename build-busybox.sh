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

# 确保启用 mount 和 NFS 相关命令
#sed -e 's/^# CONFIG_FEATURE_MOUNT_NFS is not set/CONFIG_FEATURE_MOUNT_NFS=y/' -i .config
#sed -e 's/^# CONFIG_NFSMOUNT is not set/CONFIG_NFSMOUNT=y/' -i .config

# 禁用 TC ，否则在6.8以上内核上编译会报错，这是一个Bug
sed -e 's/^CONFIG_TC=y/# CONFIG_TC is not set/' -i .config

#sed -e 's/^CONFIG_EXTRA_LDLIBS=""/CONFIG_EXTRA_LDLIBS="pthread dl tirpc audit pam"/' -i .config

# 使用 pkg-config 编译
#make CFLAGS="$(pkg-config --cflags libtirpc)" LDFLAGS="$(pkg-config --libs libtirpc)" install
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