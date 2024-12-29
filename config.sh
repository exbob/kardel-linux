#!/bin/sh

# 获取当前目录
TOP_DIR=$(pwd)

# 定义下载目录
DOWNLOAD_DIR="${TOP_DIR}/download"
mkdir -p ${DOWNLOAD_DIR}

# 定义编译目录
BUILD_DIR="${TOP_DIR}/build"
mkdir -p ${BUILD_DIR}

# 定义镜像目录
IMAGE_DIR="${BUILD_DIR}/image"
mkdir -p ${IMAGE_DIR}

# 定义内核镜像、根文件系统
KERNEL_IMG=${IMAGE_DIR}/vmlinuz
ROOTFS=${IMAGE_DIR}/rootfs
ROOTFS_IMG=${IMAGE_DIR}/rootfs.img.gz
ROOTFS_IMG_SIZE=32 # MB
