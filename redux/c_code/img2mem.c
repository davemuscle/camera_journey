#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <error.h>
#include <stdint.h>
#include <sys/mman.h>
#include <string.h>

#define HPS_TO_FPGA_LW_BASE 0x30000000
#define HPS_TO_FPGA_LW_SPAN 0x00800000

#define SCREEN_SIZE 1920*1080*4

int main(int argc, char ** argv)
{
    void * sdram_map = 0;
    uint32_t * sdram_ptr = 0;
    int devmem_fd = 0;
    int result;   

    // Open up the /dev/mem device (aka, RAM)
    devmem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if(devmem_fd < 0) {
        perror("devmem open");
        exit(EXIT_FAILURE);
    }

    // mmap() the entire address space of the Lightweight bridge so we can access our custom module 
    sdram_map = (uint32_t*)mmap(NULL, HPS_TO_FPGA_LW_SPAN, PROT_READ|PROT_WRITE, MAP_SHARED, devmem_fd, HPS_TO_FPGA_LW_BASE); 
    if(sdram_map == MAP_FAILED) {
        perror("devmem mmap");
        close(devmem_fd);
        exit(EXIT_FAILURE);
    }

    // Set the custom_led_map to the correct offset within the RAM (CUSTOM_LEDS_0_BASE is from "hps_0.h")
    sdram_ptr = (uint32_t*)(sdram_map);

    uint32_t buffer[1920];
    FILE *ptr;

    ptr=fopen("output.bin","rb");
    uint32_t i =0;
    for(i=0;i<1080;i++){
        fread(buffer,4,1920,ptr);
        memcpy(sdram_ptr,buffer,1920*4);
        sdram_ptr += 1920;
    }

    // Unmap everything and close the /dev/mem file descriptor
    result = munmap(sdram_map, HPS_TO_FPGA_LW_SPAN); 
    if(result < 0) {
        perror("devmem munmap");
        close(devmem_fd);
        exit(EXIT_FAILURE);
    }

    close(devmem_fd);


//    free(frame0);
//    free(frame1);
//    free(frame2);

    exit(EXIT_SUCCESS);
}

