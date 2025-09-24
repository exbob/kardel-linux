# 从零构建微型Linux系统并用Qemu启动

在这篇文章中，我将详细介绍如何从零开始构建一个微型Linux系统，并使用Qemu虚拟机运行它。我们将涵盖从Linux内核编译、基础根文件系统构建、到Qemu虚拟机配置的全过程，帮助理解Linux系统的工作原理。

## 1. 准备工作

以 WSL 的 Ubuntu24.04 系统为例，在开始之前，我们需要准备一些必要的工具和库：

``` bash
sudo apt-get install git cmake build-essential bison flex swig python3-dev \
libssl-dev libncurses-dev libelf-dev bc zstd libtirpc-dev rpcbind libnsl-dev pkgconf
```

安装Qemu虚拟机：

``` bash
sudo apt-get install qemu-system
```

默认安装的Qemu版本是8.2.2：

``` bash
> qemu-system-x86_64 --version
QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.10)
Copyright (c) 2003-2023 Fabrice Bellard and the QEMU Project developers
```

## 2. 编译Linux内核

以 Linux 5.15.193 版本为例。

### 2.1 下载

``` bash
wget https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-5.15.193.tar.gz
tar -zxvf linux-5.15.193.tar.gz
cd linux-5.15.193
```

下载linux-5.15.193的内核源码，这是一个LTS版本。

### 2.2 配置

``` bash
export ARCH=x86
make O=./build x86_64_defconfig
```

选项参数`O=./build`表示编译过程生成的文件都输出到`./build`路径下。我们构建的是x86_64架构的虚拟机，所以要配置`ARCH=x86`，这样编译系统会在相应架构的路径`arch/x86/configs/`下找到配置文件`x86_64_defconfig`：

``` bash
> ls -l arch/x86/configs/
total 24
-rw-r--r-- 1 lsc lsc 5970 Sep 11 23:17 i386_defconfig
-rw-r--r-- 1 lsc lsc  147 Sep 11 23:17 tiny.config
-rw-r--r-- 1 lsc lsc 5919 Sep 11 23:17 x86_64_defconfig
-rw-r--r-- 1 lsc lsc  744 Sep 11 23:17 xen.config
```

### 2.3 修改配置

``` bash
# 添加RAMDisk支持
./scripts/config --file ./build/.config --enable CONFIG_BLK_DEV_RAM
./scripts/config --file ./build/.config --set-val CONFIG_BLK_DEV_RAM_COUNT 1
./scripts/config --file ./build/.config --set-val CONFIG_BLK_DEV_RAM_SIZE 65536
make O=./build olddefconfig
```

`./scripts/config`是Linux内核源码提供的一个实用工具脚本，用于在命令行中修改内核配置文件（通常是`.config`文件），而无需通过交互式的配置界面（如`make menuconfig`等）。基本语法是`./scripts/config [option] <command>`，默认修改的是`./.config`文件，可以用`--file`选项指定配置文件，常用的命令有：
- `--enable [option]`，将指定的内核配置设为y。
- `--disable [option]`，将指定的内核配置设为n。
- `--set-val [option] [value]`，设置指定内核配置的数值。
- `--set-str [option] [value]`，设置指定内核配置的字符串。

因为我们要用 ramdisk 启动根文件系统，所以这里要使能内核的RAMdisk设备支持，并设置数量和大小。

使用`./scripts/config`就是手动修改`.config`文件，不会处理依赖关系，所以需要运行`make olddefconfig`，它会自动启用所有依赖项，解决一些冲突，还会使用默认值填充新的配置选项。

### 2.4 编译

``` bash
make O=./build -j$(nproc)
```

选项`-j$(nproc)`表示根据CPU核心数量启动并行编译，编译完成后，内核镜像文件位于`build/arch/x86/boot/bzImage`：

``` bash
> file build/arch/x86/boot/bzImage
build/arch/x86/boot/bzImage: Linux kernel x86 boot executable bzImage, version 5.15.193 (lsc@Bob) #1 SMP Wed Sep 24A
```
bzImage 是一个经过gzip压缩的内核镜像文件。

## 3. 编译BusyBox并生成根文件系统

BusyBox是一个集成了众多Unix工具的单一可执行文件，非常适合构建微型Linux系统。

### 3.1 下载

``` bash
wget https://www.busybox.net/downloads/busybox-1.36.1.tar.bz2
tar -xvf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
```

### 3.2 配置

``` bash
make defconfig
```

先使用默认配置，然后改为静态编译：

``` bash
make menuconfig

Location:                                                                              
    -> Settings
        [*] Build static binary (no shared libs)
```

另外注意，在Ubuntu24.04上编译有个[Bug 15934](https://lists.busybox.net/pipermail/busybox-cvs/2024-January/041752.html)，需要禁用`CONFIG_TC`，否则无法编译通过。

### 3.3 编译

``` bash
make -j$(nproc)
make install
```

编译完成后，生成的安装文件位于`_install`目录下：

``` bash
> ls -l _install/
total 12
drwxr-xr-x 2 lsc lsc 4096 Sep 24 16:50 bin
lrwxrwxrwx 1 lsc lsc   11 Sep 24 16:50 linuxrc -> bin/busybox
drwxr-xr-x 2 lsc lsc 4096 Sep 24 16:50 sbin
drwxr-xr-x 4 lsc lsc 4096 Sep 24 16:50 usr
```

### 3.4 创建基本的根文件系统


``` bash
cd _install
# 新建必要的目录
mkdir -p etc proc sys mnt dev tmp

# 创建inittab文件
cat > etc/inittab << EOF
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::askfirst:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
EOF
chmod 755 etc/inittab

# 创建启动脚本
mkdir -p etc/init.d
cat > etc/init.d/rcS << EOF
#!/bin/sh
/bin/mount -a
EOF
chmod 755 etc/init.d/rcS

# 创建fstab文件
cat > etc/fstab << EOF
proc    /proc    proc    defaults    0    0
tmpfs   /tmp     tmpfs   defaults    0    0
sysfs   /sys     sysfs   defaults    0    0
EOF
```

根文件系统的结构可以参考 Filesystem Hierarchy Standard，这是Linux基金会维护的文件系统层次结构标准，最新版本是3.0：<https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html>。主要的几个文件：
- `etc/inittab`，根文件系统启动后第一个执行的是 init 进程，这是 init 进程的核心配置文件，第一行定义了 init 首先要执行 `/etc/init.d/rcS`，接下来要启动 `/bin/sh` shell。详细说明可以参考busybox源码的 `examples/inittab` 文件。
- `etc/init.d/rcS`，这是init 进程执行的第一个脚本，`/bin/mount -a`命令的作用是挂载`/etc/fstab`文件中定义的所有文件系统。
- `etc/fstab`，描述了默认的文件系统挂载配置。

用上面制作的根文件系统生成ext4格式的rootfs镜像：

``` bash
dd if=/dev/zero of=rootfs.ext4 bs=1M count=32
mkfs.ext4 rootfs.ext4
mkdir rootfs_tmp
sudo mount -o loop rootfs.ext4 rootfs_tmp
sudo cp -rf _install/* rootfs_tmp/
sudo umount rootfs_tmp
gzip --best -c rootfs.ext4 > rootfs.img.gz
```

## 4. 用Qemu虚拟机启动

至此，我们已经准备好了内核镜像 bzImage 和根文件系统镜像 rootfs.img.gz，可以使用Qemu启动我们的微型Linux系统了：

``` bash
qemu-system-x86_64 \
-name kardel \
-smp 2 -m 1024 -nographic \
-kernel ./bzImage \
-initrd ./rootfs.img.gz \
-append "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init"
```

- `-name` 定义了虚拟机的名字
- `-smp 2 -m 1024 -nographic` 是虚拟机的硬件配置，表示2个CPU核，1024M内存，没有图形界面，使用文本控制台。
- `-kernel` 定义了使用的内核文件，这个配置会跳过BIOS/UEFI启动过程，直接启动内核。
- `-initrd` 指定了初始RAM磁盘文件（init RAM Disk），initrd是在启动阶段被Linux内核调用的临时文件系统，用于根目录被挂载之前的准备工作，我们直接用它来研究Linux比较简单。
- `-append` 定义了内核启动参数字符串：
    - `root=/dev/ram`表示挂载`/dev/ram`作为根文件系统
    - `console=ttyS0` 定义了控制台输出到串口0（配合-nographic使用）
    - `init=/sbin/init` 定义了init进程。

启动后的Qemu虚拟机：

```
[    2.819865] devtmpfs: mounted
[    2.903966] Freeing unused kernel image (initmem) memory: 1488K
[    2.904265] Write protecting the kernel read-only data: 24576k
[    2.907148] Freeing unused kernel image (text/rodata gap) memory: 2032K
[    2.908811] Freeing unused kernel image (rodata/data gap) memory: 1292K
[    2.909390] Run /sbin/init as init process
[    3.046032] mount (79) used greatest stack depth: 14272 bytes left
[    3.050250] rcS (78) used greatest stack depth: 14128 bytes left

Please press Enter to activate this console.
~ # df
Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/root                26596      2496     21812  10% /
devtmpfs                495408         0    495408   0% /dev
tmpfs                   498472         0    498472   0% /tmp

~ # poweroff
The system is going down NOW!
Sent SIGTERM to all processes
Sent SIGKILL to all processes
Requesting system poweroff
[  305.271084] sh (80) used greatest stack depth: 13960 bytes left
[  306.527946] ACPI: PM: Preparing to enter system sleep state S5
[  306.534926] reboot: Power down
```

可以执行 `poweroff` 命令关机，如果要直接关闭 Qemu 虚拟机，可以按下组合键`Ctrl+a`，然后按 `x` 键。