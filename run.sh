#!/bin/sh
. ./config.sh

# 检查命令行参数
if [ $# -ne 1 ]; then
    echo "Usage: $0 [-h]"
    exit 1
fi

# 确定启动模式
if [ "$1" = "-s" ]; then
    BOOT_MODE="-s"
elif [ "$1" = "-u" ]; then
    BOOT_MODE="-u"
else
    echo "Usage: $0 [option]"
    echo "  -h : show help message."
    echo "  -s : quick start."
    echo "  -u : boot from u-boot."
    exit 1
fi

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
NAME="kardel"
CPUS="2"
MEM_SIZE="1024" # MB

# 添加网络支持
QEMU_NET="-netdev user,id=net0,hostfwd=tcp::2222-:22 -device e1000,netdev=net0"

QEMU_HW_CFG="-name ${NAME} \
    -smp ${CPUS} \
    -m ${MEM_SIZE} \
    -nographic \
    ${QEMU_NET} \
    -monitor tcp:127.0.0.1:4444,server,nowait "

# 定义 QEMU 的软件参数
QEMU_BOOTLOADER="-bios ${IMAGE_DIR}/${UBOOT_IMG}"
QEMU_KERNEL="-kernel ${IMAGE_DIR}/${KERNEL_IMG}"
QEMU_INITRD="-initrd ${IMAGE_DIR}/${ROOTFS_IMG}"
QEMU_APPEND='-append "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init ip=dhcp"'

# 跟进启动模式设置 QEMU 的软件参数
if [ "${BOOT_MODE}" = "-s" ]; then
    # 快速启动
    echo "quick start..."
    qemu-system-x86_64 ${QEMU_HW_CFG} \
    -kernel ${IMAGE_DIR}/${KERNEL_IMG} \
    -initrd ${IMAGE_DIR}/${ROOTFS_IMG} \
    -append "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init ip=dhcp"
elif [ "${BOOT_MODE}" = "-u" ]; then
    # 从 u-boot 启动
    echo "boot from u-boot..."
    qemu-system-x86_64 ${QEMU_HW_CFG} \
    -bios ${IMAGE_DIR}/${UBOOT_IMG} \
    -kernel ${IMAGE_DIR}/${KERNEL_IMG} \
    -initrd ${IMAGE_DIR}/${ROOTFS_IMG} 
else
    echo "Usage: $0 [-h]"
    exit 1
fi