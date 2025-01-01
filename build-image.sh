#!/bin/sh
. ./config.sh

# 检查制作系统镜像所需的文件是否存在
if [ -d ${IMAGE_DIR} ]; then
    rm -rf ${IMAGE_DIR}/*
else
    echo "create image directory..."
    mkdir -p ${IMAGE_DIR}
fi

if [ -e ${INSTALL_DIR}/${KERNEL_IMG} ]; then
    cp -a ${INSTALL_DIR}/${KERNEL_IMG} ${IMAGE_DIR}/${KERNEL_IMG}
else
    echo "${INSTALL_DIR}/${KERNEL_IMG} : kernel image not found."
    exit 1
fi

if [ -d ${INSTALL_DIR}/${ROOTFS} ]; then
    cp -a ${INSTALL_DIR}/${ROOTFS} ${IMAGE_DIR}/${ROOTFS}
else
    echo "${INSTALL_DIR}/${ROOTFS} : rootfs not found."
    exit 1
fi

# 创建根文件系统的目录结构
echo "create rootfs image..."
cd ${IMAGE_DIR}/${ROOTFS}
mkdir -p etc proc sys mnt dev tmp

# 新建/etc/inittab : init 程序的配置文件，用于配置 init 程序的运行方式
echo -n > ./etc/inittab
echo "::sysinit:/etc/init.d/rcS" >> ./etc/inittab
echo "::respawn:-/bin/sh" >> ./etc/inittab
echo "::askfirst:-/bin/sh" >> ./etc/inittab
echo "::ctrlaltdel:/bin/umount -a -r" >> ./etc/inittab
chmod 755 etc/inittab

mkdir -p ./etc/init.d
echo -n > ./etc/init.d/rcS
echo '#!/bin/sh' >> ./etc/init.d/rcS
echo '/bin/mount -a' >> ./etc/init.d/rcS
chmod 755 etc/init.d/rcS

echo -n > ./etc/fstab
echo "proc    /proc    proc    defaults    0    0" >> ./etc/fstab
echo "tmpfs   /tmp     tmpfs   defaults    0    0" >> ./etc/fstab
echo "sysfs   /sys     sysfs   defaults    0    0" >> ./etc/fstab

# 打包压缩根文件系统镜像
cd ${IMAGE_DIR}
echo "compress rootfs image..."
dd if=/dev/zero of=./rootfs.ext4 bs=1M count=${ROOTFS_IMG_SIZE}
mkfs.ext4 ./rootfs.ext4
mkdir ./rootfs_tmp
sudo mount -o loop rootfs.ext4 ./rootfs_tmp
sudo cp -rf ./${ROOTFS}/* ./rootfs_tmp
sudo umount ${IMAGE_DIR}/rootfs_tmp
rm -rf ${IMAGE_DIR}/rootfs_tmp
gzip --best -c rootfs.ext4 > ${ROOTFS_IMG}
rm -rf ./rootfs.ext4

echo "------"
if [ -e ${ROOTFS_IMG} ]; then
    echo "rootfs image create success."
    echo "rootfs image: ${IMAGE_DIR}/${ROOTFS_IMG}"
else
    echo "rootfs image create failed."
    exit 1
fi