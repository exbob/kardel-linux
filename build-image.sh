#!/bin/sh
. ./config.sh

# 检查内核镜像、根文件系统是否存在
if [ ! -e ${KERNEL_IMG} ]; then
    echo "${KERNEL_IMG} : kernel image not found."
    exit 1
fi
if [ ! -d ${ROOTFS} ]; then
    echo "${ROOTFS} : rootfs not found."
    exit 1
fi

if [ -e ${ROOTFS_IMG} ]; then
    rm -rf ${ROOTFS_IMG}
fi

# 创建根文件系统的目录结构
echo "create rootfs image..."
cd ${ROOTFS}
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
echo 'echo "Welcome to linux..."' >> ./etc/init.d/rcS
chmod 755 etc/init.d/rcS

echo -n > ./etc/fstab
echo "proc    /proc    proc    defaults    0    0" >> ./etc/fstab
echo "tmpfs   /tmp     tmpfs   defaults    0    0" >> ./etc/fstab
echo "sysfs   /sys     sysfs   defaults    0    0" >> ./etc/fstab

sudo mknod ./dev/console c 5 1
sudo mknod ./dev/null c 1 3
sudo mknod ./dev/tty1 c 4 1

# 打包压缩根文件系统镜像
cd ${IMAGE_DIR}
echo "compress rootfs image..."
dd if=/dev/zero of=./rootfs.ext4 bs=1M count=${ROOTFS_IMG_SIZE}
mkfs.ext4 ./rootfs.ext4
mkdir ./rootfs_tmp
sudo mount -o loop rootfs.ext4 ./rootfs_tmp
sudo cp -rf ${ROOTFS}/* ./rootfs_tmp
sudo umount ${IMAGE_DIR}/rootfs_tmp
rm -rf ${IMAGE_DIR}/rootfs_tmp
gzip --best -c rootfs.ext4 > ${ROOTFS_IMG}

if [ -e ${ROOTFS_IMG} ]; then
    echo "rootfs image create success."
    echo "rootfs image: ${ROOTFS_IMG}"
else
    echo "rootfs image create failed."
    exit 1
fi
