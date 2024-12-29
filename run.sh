#!/bin/sh
. ./config.sh

# 检查内核镜像、根文件系统镜像是否存在
if [ ! -e ${KERNEL_IMG} ]; then
    echo "${KERNEL_IMG} : kernel image not found."
    exit 1
fi
if [ ! -e ${ROOTFS_IMG} ]; then
    echo "${ROOTFS_IMG} : rootfs image not found."
    exit 1
fi

# 启动 QEMU
qemu-system-x86_64  -nographic \
    -kernel ${KERNEL_IMG} \
    -initrd ${ROOTFS_IMG} \
    -append "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init"