#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

int main()
{
  int fd;
  const char *test_data = "Hello, Kernel!";
  char buffer[256] = {0};
  
  // 打开设备
  fd = open("/dev/memblk", O_RDWR);
  if (fd < 0) {
      perror("open");
      return 1;
  }
  printf("Device opened\n");
  
  // 写入数据
  write(fd, test_data, strlen(test_data));
  printf("Written: %s\n", test_data);
  
  // 读取数据并打印
  read(fd, buffer, sizeof(buffer));
  printf("Read: %s\n", buffer);
  
  // 关闭设备
  close(fd);
  printf("Device closed\n");
  
  return 0;
}