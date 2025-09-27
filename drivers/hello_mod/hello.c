#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>

// 模块加载时调用的函数
static int __init hello_init(void)
{
  printk(KERN_INFO "Hello, World! Module loaded.\n");
  return 0;  // 返回0表示成功
}

// 模块卸载时调用的函数
static void __exit hello_exit(void)
{
  printk(KERN_INFO "Goodbye, World! Module unloaded.\n");
}

// 指定模块的初始化和清理函数
module_init(hello_init);
module_exit(hello_exit);

// 模块信息
MODULE_LICENSE("GPL");
MODULE_AUTHOR("LiShaocheng <gexbob@gmail.com>");
MODULE_DESCRIPTION("A simple Hello World kernel module");
MODULE_VERSION("1.0");