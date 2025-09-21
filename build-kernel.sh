#!/bin/bash
set -e

. ./config.sh

# 定义多个内核版本选项
KERNEL_VERSIONS=(
    "linux-6.6.106"
    "linux-5.15.193"
)

# 显示可用的内核版本
echo "Kernel version:"
for i in "${!KERNEL_VERSIONS[@]}"; do
    echo "$((i+1)). ${KERNEL_VERSIONS[$i]}"
done

# 让用户选择内核版本
echo -n "Please select [1-${#KERNEL_VERSIONS[@]}]: "
read choice

# 验证用户输入
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#KERNEL_VERSIONS[@]} ]; then
    echo "Invalid selection, use default version: ${KERNEL_VERSIONS[0]}"
    choice=1
fi

# 设置选择的内核版本
idx=$((choice-1))
KERNEL_SRC_VERSION="${KERNEL_VERSIONS[$idx]}"
KERNEL_SRC_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/${KERNEL_SRC_VERSION}.tar.gz"

echo "Already selected: ${KERNEL_SRC_VERSION}"
echo ""

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

# 添加 9P 文件系统支持
./scripts/config --file ./build/.config --enable CONFIG_FUSE_FS
./scripts/config --file ./build/.config --enable CONFIG_VIRTIO_FS
./scripts/config --file ./build/.config --enable CONFIG_VIRTIO_PCI
./scripts/config --file ./build/.config --enable CONFIG_NET_9P
./scripts/config --file ./build/.config --enable CONFIG_NET_9P_VIRTIO
./scripts/config --file ./build/.config --enable CONFIG_9P_FS
./scripts/config --file ./build/.config --enable CONFIG_9P_FS_POSIX_ACL

# 自动处理依赖和新选项,自动使用默认值
make O=./build olddefconfig

# 编译
make O=./build -j$(nproc)

cd ${TOP_DIR}

# 更新 ${INSTALL_DIR} 下的文件
if [ -e ${INSTALL_DIR}/${KERNEL_IMG} ]; then
    rm -rf ${INSTALL_DIR}/${KERNEL_IMG}
fi
cp ${BUILD_DIR}/${KERNEL_SRC_VERSION}/build/arch/x86/boot/bzImage ${INSTALL_DIR}/${KERNEL_IMG}
echo "------"
echo "kernel build success."
echo "kernel image: ${INSTALL_DIR}/${KERNEL_IMG}"