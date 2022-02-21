#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <error.h>
#include <stdint.h>
#include <sys/mman.h>

#define HPS_TO_FPGA_LW_BASE 0xFF200000
#define HPS_TO_FPGA_LW_SPAN 0x0020000

#define VID_CMD 0x0000
#define VID_OF2 0x0010/4
#define VID_OF1 0x0020/4
#define VID_OF0 0x0030/4

#define QHD_SIZE 0x800000
#define DDR_LOCC 0x40000000

#define SCREEN_SIZE 1920*1080*4

uint32_t * frame0;
uint32_t * frame1;
uint32_t * frame2;

int main(int argc, char ** argv)
{
    void * lw_bridge_map = 0;
    uint32_t * lw_bridge_ptr = 0;
    int devmem_fd = 0;
    int result;   

    //frame0 = (uint32_t *) malloc(SCREEN_SIZE);
    //frame1 = (uint32_t *) malloc(SCREEN_SIZE);
    //frame2 = (uint32_t *) malloc(SCREEN_SIZE);

    frame0 = (uint32_t *) 0x30000000;
    frame1 = (uint32_t *) 0x31000000;
    frame2 = (uint32_t *) 0x32000000;

    if(frame0 == NULL || frame1 == NULL || frame2 == NULL){
	perror("Could not allocate memory for 3 frames\n");
	exit(EXIT_FAILURE);
    }

    // Open up the /dev/mem device (aka, RAM)
    devmem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if(devmem_fd < 0) {
        perror("devmem open");
        exit(EXIT_FAILURE);
    }

    // mmap() the entire address space of the Lightweight bridge so we can access our custom module 
    lw_bridge_map = (uint32_t*)mmap(NULL, HPS_TO_FPGA_LW_SPAN, PROT_READ|PROT_WRITE, MAP_SHARED, devmem_fd, HPS_TO_FPGA_LW_BASE); 
    if(lw_bridge_map == MAP_FAILED) {
        perror("devmem mmap");
        close(devmem_fd);
        exit(EXIT_FAILURE);
    }

    // Set the custom_led_map to the correct offset within the RAM (CUSTOM_LEDS_0_BASE is from "hps_0.h")
    lw_bridge_ptr = (uint32_t*)(lw_bridge_map);

    //*custom_led_map = (uint32_t)blink_times;
    
    printf("Setting pointers\n");
    *(lw_bridge_ptr+VID_OF2)= (uint32_t)frame2;
    *(lw_bridge_ptr+VID_OF1)= (uint32_t)frame1;
    *(lw_bridge_ptr+VID_OF0)= (uint32_t)frame0;

    uint32_t readval = *(lw_bridge_ptr+VID_OF2);
	
    printf("ReadValue: %x\n", readval);

    printf("Done\n");
  
    printf("Array addresses:\n");
    printf("%x\n",frame0);
    printf("%x\n",frame1);
    printf("%x\n",frame2);
   
    printf("AXI Array Addresses:\n");
    printf("%x\n",*(lw_bridge_ptr+VID_OF0));
    printf("%x\n",*(lw_bridge_ptr+VID_OF1));
    printf("%x\n",*(lw_bridge_ptr+VID_OF2));



    printf("\n");
    printf("Array elements:\n");
//    printf("%x\n",frame0[0]);
//    printf("%x\n",frame0[1]);
//    printf("%x\n",frame0[2]);
//    printf("%x\n",frame0[3]);

//    uint32_t i=0; uint32_t j=0;
//    for(i=0;i<16;i++){
//	for(j=0;j<16;j++){
//		printf("%x\n",&frame0[i][j]);
//        }
//    }

/*    
    printf("Writing into screen\n");
    uint32_t i=0;
    uint32_t cnt=0;
    for(i=0;i<1920*1080;i++){
        frame0[i]=0x00FF0000;
        frame1[i]=0x0000FF00;
        frame2[i]=0x000000FF;
    }
*/
    
    printf("Enabling output\n");
    *(lw_bridge_ptr+VID_CMD)=0x00000009;
    
    printf("Read: %x\n",*(lw_bridge_ptr+VID_CMD));

//    while(1);

    // Unmap everything and close the /dev/mem file descriptor
    result = munmap(lw_bridge_map, HPS_TO_FPGA_LW_SPAN); 
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

