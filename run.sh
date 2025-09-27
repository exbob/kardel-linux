#!/bin/bash
set -e

. ./config.sh

# 检查命令行参数
if [ $# -lt 1 ]; then
    echo "Usage: $0 [option]"
    echo "  -h : show help message."
    echo "  -s : quick start."
    echo "  -u : boot from u-boot."
    echo "  -d : debug mode with gdb, valid when quick start."
    exit 1
fi

# 确定启动模式
BOOT_MODE=""
DEBUG_MODE=0

while [ $# -gt 0 ]; do
    case "$1" in
        -s)
            BOOT_MODE="-s"
            ;;
        -u)
            BOOT_MODE="-u"
            ;;
        -d)
            DEBUG_MODE=1
            ;;
        -h|--help)
            echo "Usage: $0 [option]"
            echo "  -h : show help message."
            echo "  -s : quick start."
            echo "  -u : boot from u-boot."
            echo "  -d : debug mode with gdb, valid when quick start."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [option]"
            echo "  -h : show help message."
            echo "  -s : quick start."
            echo "  -u : boot from u-boot."
            echo "  -d : debug mode with gdb, valid when quick start."
            exit 1
            ;;
    esac
    shift
done

if [ -z "$BOOT_MODE" ]; then
    echo "Must specify boot mode (-s or -u)"
    echo "Usage: $0 [option]"
    echo "  -h : show help message."
    echo "  -s : quick start."
    echo "  -u : boot from u-boot."
    echo "  -d : debug mode with gdb, valid when quick start."
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

# 添加9P文件系统共享配置
HOST_SHARE_PATH=${BUILD_DIR}
QEMU_9P="-fsdev local,security_model=none,id=fsdev0,path=${HOST_SHARE_PATH} \
        -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare"

# 添加GDB调试支持
# 定义 GDB 的选项参数
GDB_PORT=9001
if [ $DEBUG_MODE -eq 1 ]; then
    QEMU_DEBUG="-S \
                -gdb tcp::${GDB_PORT}"
    echo "Starting QEMU in debug mode..."
    echo "Connect with GDB using: gdb -ex 'target remote localhost:${GDB_PORT}'"
    echo "If debugging kernel, use: "
    echo "  cd ${BUILD_DIR}/<KERNEL_SRC_VERSION>/build"
    echo "  gdb vmlinux"
    echo "  target remote localhost:${GDB_PORT}"
    echo "  continue"
else
    QEMU_DEBUG=""
fi

QEMU_HW_CFG="-name ${NAME} \
    -smp ${CPUS} \
    -m ${MEM_SIZE} \
    -nographic \
    ${QEMU_NET} \
    ${QEMU_9P} \
    ${QEMU_DEBUG} \
    -serial mon:stdio"

if [ $DEBUG_MODE -eq 1 ]; then
    QEMU_APPEND="root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init ip=dhcp earlyprintk=serial,ttyS0 nokaslr"
else
    QEMU_APPEND="root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init ip=dhcp"
fi

# 根据启动模式设置 QEMU 的软件参数
if [ "${BOOT_MODE}" = "-s" ]; then
    # 快速启动
    echo "quick start..."
    qemu-system-x86_64 ${QEMU_HW_CFG} \
    -kernel ${IMAGE_DIR}/${KERNEL_IMG} \
    -initrd ${IMAGE_DIR}/${ROOTFS_IMG} \
    -append "${QEMU_APPEND}"
elif [ "${BOOT_MODE}" = "-u" ]; then
    # 从 u-boot 启动
    echo "boot from u-boot..."
    qemu-system-x86_64 ${QEMU_HW_CFG} \
    -bios ${IMAGE_DIR}/${UBOOT_IMG} \
    -kernel ${IMAGE_DIR}/${KERNEL_IMG} \
    -initrd ${IMAGE_DIR}/${ROOTFS_IMG} 
else
    echo "Usage: $0 [option]"
    echo "  -h : show help message."
    echo "  -s : quick start."
    echo "  -u : boot from u-boot."
    echo "  -d : debug mode with gdb, valid when quick start."
    exit 1
fi