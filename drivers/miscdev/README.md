# 说明

一个简单的杂项设备（misc device）驱动，支持open，close，read，write函数接口。杂项设备是字符设备的子类，有专门的驱动框架，它将字符设备进一步封装，可以简化字符设备驱动的开发过程。下面是miscdevice结构体：

``` c
// include/linux/miscdevice.h
struct miscdevice  {
   int minor;     //次设备号，可以自定义，或者设为MISC_DYNAMIC_MINOR让内核自动分配。可以在`cat /proc/misc`查看所有杂项设备，避免次设备号重复。
   const char *name;  //设备节点名称，“/dev”目录下显示。
   const struct file_operations *fops;  //设备文件操作接口，open/read/write等。
   struct list_head list; //misc设备链表节点。
   struct device *parent; //当前设备父设备，一般为NULL。
   struct device *this_device; //当前设备，即是linux基本设备驱动框架。
   const struct attribute_group **groups;
   const char *nodename;
   umode_t mode;
};

// 注册和注销
int misc_register(struct miscdevice *misc);
void misc_deregister(struct miscdevice *misc);
```

执行`make`编译，要指定内核源码路径，例如：

``` bash
make KERNEL_DIR=~/kardel-linux/build/linux-6.6.106/build/
```

编译生成的驱动文件`memblk.ko`，复制到虚拟机里加载，驱动会自动新建设备文件：

``` bash
~ # insmod memblk.ko
[   32.161944] memblk: loading out-of-tree module taints kernel.
[   32.171336] memblk driver init
[   32.174090] insmod (69) used greatest stack depth: 13896 bytes left
~ # lsmod
memblk 12288 0 - Live 0xffffffffc016f000 (O)
~ # ls /dev/memblk  -l
crw-------    1 0        0          10, 125 Sep 28 09:22 /dev/memblk
~ # cat /proc/misc
125 memblk
126 cpu_dma_latency
236 device-mapper
237 loop-control
144 nvram
228 hpet
229 fuse
235 autofs
231 snapshot
183 hw_random
127 vga_arbiter
242 rfkill
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
[  143.041139] open successfully, data address (____ptrval____), size 256 bytes.
Device opened
[  143.048089] write 14 bytes
Written: Hello, Kernel!
[  143.051470] read 256 bytes
Read: Hello, Kernel!
[  143.052056] close successfully.
Device closed
```