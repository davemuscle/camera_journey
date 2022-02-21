#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <error.h>
#include <stdint.h>
#include <sys/mman.h>
#include <string.h>

#define VID_CMD 0x0000
#define VID_OF2 0x0010/4
#define VID_OF1 0x0020/4
#define VID_OF0 0x0030/4
 
#define W 1920
#define H 1080
#define QHD_SIZE 0x800000

#define LW_BRIDGE_BASE 0xFF200000

#define FRAME0_OFFSET 0x30000000
#define FRAME1_OFFSET 0x31000000
#define FRAME2_OFFSET 0x32000000
 
void main()
{
    int count;

    void * lw_bridge_map = 0;
    void * frame0_map    = 0;
    void * frame1_map    = 0;
    void * frame2_map    = 0;
    
    uint32_t * lw_bridge_ptr = 0;
    uint32_t * frame0_ptr    = 0;
    uint32_t * frame1_ptr    = 0;
    uint32_t * frame2_ptr    = 0;
    
    uint32_t * ptr    = 0;
    
    uint32_t hps_frame = 0;
    uint32_t fpga_frame = 0;
    
    int devmem_fd = 0;  

    // Open up the /dev/mem device (aka, RAM)
    devmem_fd = open("/dev/mem", O_RDWR | O_SYNC);

    lw_bridge_map = (uint32_t*)mmap(NULL, 0x100, PROT_READ|PROT_WRITE, MAP_SHARED, devmem_fd, LW_BRIDGE_BASE); 
    frame0_map    = (uint32_t*)mmap(NULL, QHD_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, devmem_fd, FRAME0_OFFSET); 
    frame1_map    = (uint32_t*)mmap(NULL, QHD_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, devmem_fd, FRAME1_OFFSET); 
    frame2_map    = (uint32_t*)mmap(NULL, QHD_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, devmem_fd, FRAME2_OFFSET); 

    // Set the custom_led_map to the correct offset within the RAM (CUSTOM_LEDS_0_BASE is from "hps_0.h")
    lw_bridge_ptr = (uint32_t*)(lw_bridge_map);
    frame0_ptr = (uint32_t*)(frame0_map);
    frame1_ptr = (uint32_t*)(frame1_map);
    frame2_ptr = (uint32_t*)(frame2_map);
    
    // Set FPGA offsets for reading frames
    *(lw_bridge_ptr+VID_OF2)= (uint32_t)FRAME2_OFFSET;
    *(lw_bridge_ptr+VID_OF1)= (uint32_t)FRAME1_OFFSET;
    *(lw_bridge_ptr+VID_OF0)= (uint32_t)FRAME0_OFFSET;

    // Open an input pipe from ffmpeg and an output pipe to a second instance of ffmpeg
    //FILE *pipein = popen("ffmpeg -threads 0 -rtsp_transport tcp -i rtsp://192.168.0.196:8554/live0.264 -filter:v fps=20 -f image2pipe -vcodec rawvideo -pix_fmt bgra -", "r");
    //FILE *pipein = popen("ffmpeg -rtsp_transport tcp -i rtsp://192.168.0.196:8554/live0.264 -preset ultrafast -f image2pipe -vcodec rawvideo -pix_fmt bgra -", "r");
    //FILE *pipein = popen("ffmpeg -rtsp_transport tcp -i rtsp://192.168.0.196:8554/live0.264 -preset ultrafast -f image2pipe -vcodec rawvideo -pix_fmt bgra - -pix_fmt bgra", "r");
    FILE *pipein = popen("ffmpeg -threads 8 -rtsp_transport tcp -i  rtsp://192.168.0.196:8554/live0.264 -f image2pipe -vcodec rawvideo -pix_fmt bgra -", "r");
    //FILE *pipein = popen("ffmpeg -threads 0 -rtsp_transport tcp -i  rtsp://192.168.0.196:8554/live0.264 -vf \"scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:color=black\" -f image2pipe -vcodec rawvideo -pix_fmt bgra -", "r");
    

    //FILE *pipein = popen("ffmpeg -i /test_video/testimg.jpg -f image2pipe -vcodec rawvideo -pix_fmt rgba -", "r");
    //FILE *pipeout = popen("ffmpeg -y -f rawvideo -vcodec rawvideo -pix_fmt rgb24 -s 1280x720 -r 25 -i - -f mp4 -q:v 5 -an -vcodec mpeg4 output.mp4", "w");

    ptr = frame0_ptr;

    while(1)
    {

        
        count = fread(ptr, 4, H*W, pipein);
        if(count == 1920*1080){
            if(hps_frame == 0){
                ptr = frame0_ptr;
                hps_frame = 1;
                *(lw_bridge_ptr+VID_CMD)=0x00000009;
            }
            else if(hps_frame == 1){
                ptr = frame1_ptr;
                hps_frame = 2;
                *(lw_bridge_ptr+VID_CMD)=0x0000000A;
            }
            else if(hps_frame == 2){
                ptr = frame2_ptr;
                hps_frame = 3;
                *(lw_bridge_ptr+VID_CMD)=0x0000000C;
            }
        }
    }
     
    munmap(lw_bridge_map, 0x100); 
    munmap(frame0_map, QHD_SIZE); 
    munmap(frame1_map, QHD_SIZE); 
    munmap(frame2_map, QHD_SIZE); 

    close(devmem_fd);

    fflush(pipein);
    pclose(pipein);

}