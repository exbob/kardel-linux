#!/bin/sh
. ./config.sh

# 检查内核镜像、根文件系统镜像是否存在
if [ ! -e ${IMAGE_DIR}/${KERNEL_IMG} ]; then
    echo "${IMAGE_DIR}/${KERNEL_IMG} : kernel image not found."
    exit 1
fi
if [ ! -e ${IMAGE_DIR}/${ROOTFS_IMG} ]; then
    echo "${IMAGE_DIR}/${ROOTFS_IMG} : rootfs image not found."
    exit 1
fi

# 定义 QEMU 虚拟机硬件参数
QEMU_NAME="kardel"
QEMU_CPU="2"
QEMU_MEM="1024" # MB

QEMU_CFG="-name ${QEMU_NAME} \
    -smp ${QEMU_CPU} \
    -m ${QEMU_MEM} \
    -nographic \
    -monitor tcp:127.0.0.1:4444,server,nowait "

# 启动 QEMU
qemu-system-x86_64 ${QEMU_CFG} \
    -kernel ${IMAGE_DIR}/${KERNEL_IMG} \
    -initrd ${IMAGE_DIR}/${ROOTFS_IMG} \
    -append "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init"