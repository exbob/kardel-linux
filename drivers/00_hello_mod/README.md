# 说明

执行`make`编译，要指定内核源码路径，例如：

```
make KERNEL_DIR=~/kardel-linux/build/linux-6.6.106/build/
```

生成的内核模块是hello.ko，复制到虚拟机的共享路径中加载：

```
~ # insmod /mnt/image/hello.ko
[   30.497337] hello: loading out-of-tree module taints kernel.
[   30.504824] Hello, World! Module loaded.
[   30.506675] insmod (65) used greatest stack depth: 13896 bytes left
~ # lsmod
hello 12288 0 - Live 0xffffffffc0267000 (O)
~ # rmmod hello
[  655.207449] Goodbye, World! Module unloaded.
```

执行`make clean`清除:

```
make KERNEL_DIR=~/kardel-linux/build/linux-6.6.106/build/ clean
```