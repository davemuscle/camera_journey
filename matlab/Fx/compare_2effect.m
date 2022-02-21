x = imread('Big.jpg');

y1 = sharpen(x);
y2 = gblur(x,3);

y1 = gblur(y1,3);
y2 = sharpen(y2);

subplot(1,3,1)
imshow(x)
subplot(1,3,2)
imshow(y1)
subplot(1,3,3)
imshow(y2)

