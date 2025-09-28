# 说明

一个简单的字符设备驱动，支持open，close，read，write函数接口。

执行`make`编译，要指定内核源码路径，例如：

``` bash
make KERNEL_DIR=~/kardel-linux/build/linux-6.6.106/build/
```

编译生成的驱动文件`memblk.ko`，复制到虚拟机里加载，并新建设备文件：

``` bash
~ # insmod  memblk.ko
[62638.541492] Major: 248, Minor: 0
[62638.543757] memblk driver init
[62638.547157] insmod (113) used greatest stack depth: 13560 bytes left
~ # lsmod
memblk 12288 0 - Live 0xffffffffc01ee000 (O)
~ # mknod /dev/memblk c 248 0
~ # ls test  -l
-rwxr-xr-x    1 1000     1000         16304 Sep 28  2025 test
```

执行`make clean`清除:

``` bash
make KERNEL_DIR=~/kardel-linux/build/linux-6.6.106/build/ clean
```

编译测试程序：

``` bash
gcc -static -Wall test.c
```

生成的`a.out`复制到虚拟机里执行，他会打开设备，写一个字符串，然后读出来，再关闭设备：

``` bash
~ # ./a.out
[70283.035738] open memblk successfully, data address 00000000693cee3c, size 256 bytes.
Device opened
[70283.053975] write memblk: 14 bytes
Written: Hello, Kernel!
[70283.061227] read memblk: 256 bytes
Read: Hello, Kernel!
[70283.062895] close memblk successfully.
Device closed
```