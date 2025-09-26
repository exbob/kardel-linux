# 在Qemu-X86虚拟机上启动u-boot

在前一篇文章[从零构建微型Linux系统并用Qemu启动](./00_从零构建微型Linux系统并用Qemu启动.md)中，我们介绍了如何从零开始构建一个微型Linux系统，并使用Qemu虚拟机启动的方法。在这篇文章中，我们将介绍如何使用Qemu虚拟机启动u-boot，然后通过u-boot引导Linux内核和根文件系统。假设已经生成了内核文件bzImage和初始化RAMDisk文件rootfs.img.gz，不再赘述。

首先从u-boot的官网<https://u-boot.org/>获取源码。我们下载了u-boot-v2024.04.tar.bz2，然后解压：

``` bash
> tar xvf u-boot-v2024.04.tar.bz2
> cd u-boot-v2024.04
> ls
Kbuild       Makefile  board   config.mk  drivers   fs       post
Kconfig      README    boot    configs    dts       include  scripts
Licenses     api       cmd     disk       env       lib      test
MAINTAINERS  arch      common  doc        examples  net      tools
```

直接使用默认的适配Qemu-X86_64虚拟机的配置，然后编译：

``` bash
make qemu-x86_64_defconfig
make
```

生成u-boot.rom文件用于Qemu启动，使用`-bios`选项指定u-boot文件：

``` bash
> qemu-system-x86_64 -smp 2 -m 1024 -nographic -bios ./u-boot.rom

U-Boot SPL 2024.04 (Sep 26 2025 - 16:54:54 +0800)
Video: 1024x768x32
Trying to boot from SPI
Jumping to 64-bit U-Boot: Note many features are missing


U-Boot 2024.04 (Sep 26 2025 - 16:54:54 +0800)

CPU:   QEMU Virtual CPU version 2.5+
DRAM:  1 GiB
Core:  20 devices, 13 uclasses, devicetree: separate
Loading Environment from nowhere... OK
Video: 1024x768x0
Model: QEMU x86 (I440FX)
Net:   e1000: 52:54:00:12:34:56
       eth0: e1000#0
Hit any key to stop autoboot:  0
```

此时已经可以启动u-boot并调试。如果要启动Linux系统，还要指定kernel和initrd文件：

``` bash
> qemu-system-x86_64 -smp 2 -m 1024 -nographic -bios ./u-boot.rom -kernel ../bzImage -initrd ../rootfs.img.gz
```

启动后进入u-boot，查看变量：

```
=> env print
arch=x86
baudrate=115200
board=qemu-x86
board_name=qemu-x86
bootargs=root=/dev/sdb3 init=/sbin/init rootwait ro
bootcmd=bootflow scan -lb
bootdelay=2
bootp_arch=6
bootp_vci=PXEClient:Arch:00006:UNDI:003000
consoledev=ttyS0
dnsip=10.0.2.3
ethact=e1000#0
ethaddr=52:54:00:12:34:56
fdtcontroladdr=3ecf9df0
filesize=1497e7
gatewayip=10.0.2.2
hostname=x86
ipaddr=10.0.2.15
kernel_addr_r=0x1000000
loadaddr=0x02000000
netdev=eth0
netmask=255.255.255.0
pciconfighost=1
ramdisk_addr_r=0x4000000
ramdiskfile=initramfs.gz
rootpath=/opt/nfsroot
scriptaddr=0x7000000
serverip=10.0.2.2
soc=qemu
stderr=serial,vidconsole
stdin=serial,i8042-kbd,usbkbd
stdout=serial,vidconsole
vendor=emulation

Environment size: 680/262140 bytes

```

注意打印出的几个env变量：
- bootargs是传递给内核的命令行参数，用于内核启动rootfs。
- bootcmd是u-boot启动内核的命令。
- kernel_addr_r是u-boot加载内核文件的内存地址。
- ramdisk_addr_r是u-boot加载initrd文件的内存地址。
- filesize=1497e7是initrd文件的大小

先设置bootargs，内核启动时需要到的命令行参数：

``` bash
=> setenv bootargs "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init"
=> env print bootargs
bootargs=root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init
```

然后手动执行启动命令，先用qfw命令将kernle和initrd文件加载到内存，这是u-boot用于向QEMU虚拟机加载固件的接口：

``` bash
=> qfw load ${kernel_addr_r} ${ramdisk_addr_r};
loading kernel to address 1000000 size a27980 initrd 4000000 size 1497e7
```

可以看到，qfw会自动计算并打印出加载的内存地址和大小，然后用zboot命令启动内核：

```
=> zboot ${kernel_addr_r} a27980 ${ramdisk_addr_r} 1497e7
Valid Boot Flag
Magic signature found
Linux kernel version 5.15.193 (lsc@Bob) #3 SMP Thu Sep 25 15:17:20 CST 2025
Building boot_params at 0x00090000
Loading bzImage at address 100000 (10647936 bytes)
Initial RAM disk at linear address 0x04000000, size 1349607 bytes
Kernel command line: "root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init"
Kernel loaded at 00100000, setup_base=0000000000090000

Starting kernel ...
...
[    3.194519] Run /sbin/init as init process
[    3.320081] mount (80) used greatest stack depth: 14240 bytes left
[    3.326269] rcS (79) used greatest stack depth: 13664 bytes left

Please press Enter to activate this console.
```

也可以在编译前配置bootargs和bootcmd两个变量，这样启动虚拟机后，u-boot会自动加载并启动内核：

``` bash
> make menuconfig
Boot options  --->
    [*] Enable boot arguments                                                
        (root=/dev/ram rw rootfstype=ext4 console=ttyS0 init=/sbin/init) Boot arg
    [*] Enable a default value for bootcmd
        (qfw load ${kernel_addr_r} ${ramdisk_addr_r}; zboot ${kernel_addr_r} - ${ramdisk_addr_r} ${filesize})
> make
> qemu-system-x86_64 -smp 2 -m 1024 -nographic -bios ./u-boot.rom -kernel ../bzImage -initrd ../rootfs.img.gz
```


更多在x86平台使用u-boot的资料可以参考官方文档：
- <https://docs.u-boot.org/en/stable/board/emulation/qemu-x86.html>
- <https://docs.u-boot.org/en/v2024.04/usage/fit/x86-fit-boot.html>
- <https://docs.u-boot.org/en/v2024.04/arch/x86/manual_boot.html>