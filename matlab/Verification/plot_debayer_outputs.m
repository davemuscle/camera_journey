
x = 640;
y = 480;

subplot(2,2,1)
img_read('debayer_output_BGGR.txt',x,y);
title('BGGR')

subplot(2,2,2)
img_read('debayer_output_GBRG.txt',x,y);
title('GBRG')

subplot(2,2,3)
img_read('debayer_output_GRBG.txt',x,y);
title('GRBG')

subplot(2,2,4)
img_read('debayer_output_RGGB.txt',x,y);
title('RGGB')
