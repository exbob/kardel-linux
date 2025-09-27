# 模块名称
obj-m := hello.o

# 内核源码的路径存储在 KER_SRC 环境变量，如不存在就使用默认值
ifdef KER_SRC
  KERNEL_DIR := $(KER_SRC)
else
  KERNEL_DIR := /lib/modules/$(shell uname -r)/build
endif

PWD := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) clean

.PHONY: all clean