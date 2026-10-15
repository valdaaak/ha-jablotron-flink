#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/usbdevice_fs.h>

/* Rebinds the kernel driver (usbhid) to the device interfaces.
   USBDEVFS_CONNECT goes through usbfs (/dev/bus/usb), which is writable
   inside the add-on (unlike /sys). This recreates /dev/hidraw0. */
int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: usbreset /dev/bus/usb/BBB/DDD\n");
        return 1;
    }
    int fd = open(argv[1], O_RDWR);
    if (fd < 0) { perror("open"); return 1; }

    int bound = 0;
    for (int ifno = 0; ifno < 8; ifno++) {
        struct usbdevfs_ioctl cmd;
        cmd.ifno = ifno;
        cmd.ioctl_code = USBDEVFS_CONNECT;
        cmd.data = 0;
        int rc = ioctl(fd, USBDEVFS_IOCTL, &cmd);
        if (rc >= 0) {
            printf("Connected driver to interface %d\n", ifno);
            bound++;
        } else if (errno == EBUSY) {
            printf("Interface %d already has driver\n", ifno);
            bound++;
        } else if (errno != ENODEV && errno != EINVAL && errno != ENOENT) {
            printf("Interface %d: %s\n", ifno, strerror(errno));
        }
    }

    close(fd);
    if (bound == 0) {
        fprintf(stderr, "No interface could be connected\n");
        return 2;
    }
    printf("Done: %d interface(s) bound\n", bound);
    return 0;
}