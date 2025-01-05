# Kardel Linux

Kardel Linux 是一个微型 Linux 发行版，命名来自 Dota2 游戏的矮人火枪手：卡德尔·鹰眼（Kardel Sharpeye），目标是构建一个基于 busybox 和 musl 的最简 Linux 发行版，并探索 Linux 系统的基本概念。

文件说明：

1. config.sh 配置了一些公用的变量，其他脚本会调用它，来确定文件读写的路径。
2. busy-uboot.sh 将u-boot源码下载到 `${DOWNLOAD_DIR}` 下面，然后解压到 `${BUILD_DIR}` 下编译，生成的 bootloader 安装到 `${INSTALL_DIR}` 路径下。
3. build-kernel.sh 将内核源码下载到 `${DOWNLOAD_DIR}` 下面，然后解压到 `${BUILD_DIR}` 下编译，生成的内核文件安装到 `${INSTALL_DIR}` 路径下。
4. build-busybox.sh 将 Busybox 的源码下载到 `${DOWNLOAD_DIR}` 下面，然后解压到 `${BUILD_DIR}` 下编译，生成的基础 rootfs 安装到 `${INSTALL_DIR}` 路径下。
5. build-image.sh 会从 `${INSTALL_DIR}` 路径获取制作系统镜像所需的文件，复制到 `${IMAGE_DIR}` 路径下，完成制作，主要进一步制作 rootfs 。
6. run.sh 会使用 `${IMAGE_DIR}` 下的系统镜像文件，启动一个 Qemu 虚拟机。

使用前需要安装 qemu 虚拟机：

```
$ sudo apt-get install qemu qemu-system
$ qemu-system-x86_64 --version
QEMU emulator version 4.2.1 (Debian 1:4.2-3ubuntu6.30)
Copyright (c) 2003-2019 Fabrice Bellard and the QEMU Project developers
```

然后依次执行如下脚本生成所需的组件：

```
$ ./build-uboot.sh
$ ./build-kernel.sh
$ ./build-busybox.sh
$ ./build-image.sh
```

可以执行 `./run.sh -s` 直接启动 kernel 和 rootfs，无需 u-boot。如果要完整启动，需要用 `-u` 选项：

```
$ ./run.sh -u
```

使用 `-u` 选项可以让 Qemu 虚拟机先启动 u-boot，然后 u-boot 会加载 kernel 和 rootfs 到内存，并启动：

```
U-Boot 2024.04 (Jan 05 2025 - 10:51:33 +0800)

CPU:   QEMU Virtual CPU version 2.5+
DRAM:  1 GiB
Core:  20 devices, 13 uclasses, devicetree: separate
Loading Environment from nowhere... OK
Video: 1024x768x0
Model: QEMU x86 (I440FX)
Net:   e1000: 52:54:00:12:34:56
       eth0: e1000#0
Hit any key to stop autoboot:  0
loading kernel to address 1000000 size a067a0 initrd 4000000 size 16b2dc
Valid Boot Flag
Magic signature found
Linux kernel version 5.15.175 (lsc@Bob) #1 SMP Sun Jan 5 10:55:23 CST 2025
Building boot_params at 0x00090000
Loading bzImage at address 100000 (10512288 bytes)
Initial RAM disk at linear address 0x04000000, size 1487580 bytes
Kernel command line: "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init"
Kernel loaded at 00100000, setup_base=0000000000090000

Starting kernel ...
```

启动成功后，按下回车可以进入命令行提示符：

![boot success](./_pics/bootsuccess_20250105110705.png)

可以执行 `poweroff` 命令关机，如果要直接关闭 Qemu 虚拟机，可以按下组合键`Ctrl+a`，然后按 `x` 键。

该虚拟机添加了 `-monitor tcp:127.0.0.1:4444` 选项，可以用 `telnet 127.0.0.1 4444` 连接虚拟机的监视器，查看虚拟机的配置和状态，例如：

![qemu monitor](./_pics/qemu-monitor_20241231200440.png)

注意，按下 `Ctrl+]` 组合键可以只退出监视器而不关闭虚拟机，如果执行 q 命令，会关闭虚拟机。

> 更多内容参考 `docs/` 下的文档。