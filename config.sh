#!/bin/bash
set -e

# 获取当前目录
TOP_DIR=$(pwd)

# 定义下载目录，构建过程中下载的文件都放在这个目录
DOWNLOAD_DIR="${TOP_DIR}/download"
mkdir -p ${DOWNLOAD_DIR}

# 定义编译目录，构建过程中生成的文件都放在这个目录
BUILD_DIR="${TOP_DIR}/build"
mkdir -p ${BUILD_DIR}

# 编译生成，用于制作系统镜像的文件安装到这个目录下
INSTALL_DIR="${BUILD_DIR}/install"
mkdir -p ${INSTALL_DIR}

# 将 ${INSTALL_DIR} 下的文件放到这个目录下，然后制作系统镜像
IMAGE_DIR="${BUILD_DIR}/image"
mkdir -p ${IMAGE_DIR}

# 定义 u-boot、内核镜像、根文件系统
UBOOT_IMG=u-boot.rom
KERNEL_IMG=vmlinuz
ROOTFS=rootfs
ROOTFS_IMG=rootfs.img.gz
ROOTFS_IMG_SIZE=32 # MB

# 定义 GDB 的选项参数
GDB_PORT=9001
