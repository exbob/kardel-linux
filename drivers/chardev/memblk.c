#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/version.h>

// 定义memblk设备的私有数据结构
struct memblk_dev_t {
	const char *dev_name;
	dev_t dev_num;
	struct cdev cdev;
	char *data;
	bool is_open; // 标记设备是否已被打开
};

struct memblk_dev_t *memblk_dev;
#define DATA_SIZE 0x100

int dev_open(struct inode *inode, struct file *filp)
{
	struct memblk_dev_t *dev;
	int ret = 0;

	dev = container_of(inode->i_cdev, struct memblk_dev_t, cdev);
	if (!dev) {
		pr_err("get memblk_dev failed.\n");
		return -ENODEV;
	}

	// 检查设备是否已经被打开
	if (dev->is_open) {
		pr_warn("Device %s is already open, access denied.\n",
		        dev->dev_name);
		ret = -EBUSY; // 设备忙，拒绝打开
		goto out;
	}

	// 分配内存
	dev->data = kmalloc(DATA_SIZE, GFP_KERNEL);
	if (!dev->data) {
		pr_err("memblk driver init kmalloc failed.\n");
		ret = -ENOMEM;
		goto out;
	}
	memset(dev->data, 0, DATA_SIZE); // 初始化内存

	// 标记设备已打开
	dev->is_open = true;
	filp->private_data = dev;

	pr_info("open %s successfully, data address %p, size %d bytes.\n",
	        dev->dev_name, dev->data, DATA_SIZE);

out:

	return ret;
}

int dev_close(struct inode *inode, struct file *filp)
{
	struct memblk_dev_t *dev = (struct memblk_dev_t *)filp->private_data;

	if (!dev) {
		pr_err("Invalid device pointer in close\n");
		return -ENODEV;
	}

	// 释放内存
	if (dev->data) {
		kfree(dev->data);
		dev->data = NULL;
	}

	// 标记设备已关闭，允许下次打开
	dev->is_open = false;

	pr_info("close %s successfully.\n", dev->dev_name);

	return 0;
}

/********************************************************************************
用于读取设备中的数据，成功就返回读取的字节数，失败返回负数。参数：
- filp     传入的文件指针
- buf      数据缓冲区指针
- count    指定读取的数据大小
- f_pos    读的位置相对于文件开头的偏移(该参数一般不设置)
*******************************************************************************/
ssize_t dev_read(struct file *filp, char __user *buf, size_t count,
                 loff_t *f_pos)
{
	struct memblk_dev_t *dev = (struct memblk_dev_t *)filp->private_data;
	ssize_t ret = 0;
	size_t bytes_to_read;

	if (!dev) {
		pr_err("Invalid device pointer in read\n");
		return -ENODEV;
	}

	// 检查设备数据是否存在
	if (!dev->data) {
		pr_err("Device data not allocated\n");
		ret = -ENOMEM;
		goto out;
	}

	// 检查读取位置是否超出范围
	if (count > DATA_SIZE) {
		pr_info("Read position beyond data size\n");
		ret = 0; // EOF
		goto out;
	}

	// 计算实际要读取的字节数
	bytes_to_read = count;

	// 将数据从内核空间复制到用户空间
	if (copy_to_user(buf, dev->data, bytes_to_read)) {
		pr_err("Failed to copy data to user space\n");
		ret = -EFAULT;
		goto out;
	}

	ret = bytes_to_read;

	pr_info("read %s: %zu bytes\n", dev->dev_name, bytes_to_read);

out:
	return ret;
}

/********************************************************************************
向设备写入数据，成功就返回读取的字节数，失败返回负数。参数：
- filp     传入的文件指针
- buf      数据缓冲区指针
- count    指定写入的数据大小
- f_pos    写的位置相对于文件开头的偏移(该参数一般不设置)
*******************************************************************************/
ssize_t dev_write(struct file *filp, const char __user *buf, size_t count,
                  loff_t *f_pos)
{
	struct memblk_dev_t *dev = (struct memblk_dev_t *)filp->private_data;
	ssize_t ret = 0;
	size_t bytes_to_write;

	if (!dev) {
		pr_err("Invalid device pointer in write\n");
		return -ENODEV;
	}

	// 检查设备数据是否存在
	if (!dev->data) {
		pr_err("Device data not allocated\n");
		ret = -ENOMEM;
		goto out;
	}

	// 检查写入位置是否超出范围
	if (count > DATA_SIZE) {
		pr_warn("Write position beyond data size\n");
		ret = -ENOSPC; // 没有空间
		goto out;
	}

	// 计算实际要写入的字节数
	bytes_to_write = count;

	// 将数据从用户空间复制到内核空间
	if (copy_from_user(dev->data, buf, bytes_to_write)) {
		pr_err("Failed to copy data from user space\n");
		ret = -EFAULT;
		goto out;
	}

	ret = bytes_to_write;

	pr_info("write %s: %zu bytes\n", dev->dev_name, bytes_to_write);

out:
	return ret;
}

struct file_operations memblk_fops = {
    .owner = THIS_MODULE,
    .open = dev_open,
    .release = dev_close,
    .read = dev_read,
    .write = dev_write,
};

static int __init dev_init(void)
{
	int ret = 0;

	// 初始化设备私有数据结构
	memblk_dev = kmalloc(sizeof(struct memblk_dev_t), GFP_KERNEL);
	if (!memblk_dev) {
		pr_err("memblk driver init kmalloc failed\n");
		return -ENOMEM;
	}
	memset(memblk_dev, 0, sizeof(struct memblk_dev_t));
	memblk_dev->dev_name = "memblk";

	memblk_dev->is_open = false; // 初始化为未打开状态

	// 申请设备号
	ret = alloc_chrdev_region(&(memblk_dev->dev_num), 0, 1,
	                          memblk_dev->dev_name);
	if (ret) {
		pr_err("register chrdev region failed: %d\n", ret);
		goto fail_alloc_chrdev;
	}

	pr_info("Major: %d, Minor: %d\n", MAJOR(memblk_dev->dev_num),
	        MINOR(memblk_dev->dev_num));

	// 初始化 cdev
	cdev_init(&(memblk_dev->cdev), &memblk_fops);
	memblk_dev->cdev.owner = THIS_MODULE;
	ret = cdev_add(&(memblk_dev->cdev), memblk_dev->dev_num, 1);
	if (ret < 0) {
		pr_err("cdev add failed: %d\n", ret);
		goto fail_cdev_add;
	}

	pr_info("memblk driver init\n");
	return 0;

// 错误处理路径
fail_cdev_add:
	unregister_chrdev_region(memblk_dev->dev_num, 1);
fail_alloc_chrdev:

	kfree(memblk_dev);
	memblk_dev = NULL;
	return ret;
}

static void __exit dev_exit(void)
{
	if (memblk_dev) {
		pr_info("device is %s\n", memblk_dev->dev_name);

		// 清理顺序很重要
		cdev_del(&memblk_dev->cdev);
		unregister_chrdev_region(memblk_dev->dev_num, 1);

		// 如果还有未释放的数据内存，释放它
		if (memblk_dev->data) {
			kfree(memblk_dev->data);
		}

		kfree(memblk_dev);
		memblk_dev = NULL;
	}

	pr_info("memblk driver exit\n");
}

module_init(dev_init);
module_exit(dev_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("LiShaocheng <gexbob@gmail.com>");
MODULE_DESCRIPTION("A simple char device driver module - single open only");
MODULE_VERSION("1.0");