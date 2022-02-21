x = imread('test_pic.jpg');

%y = smaa(x,70,1);
x = gblur(x,3);
y = sobel(x,150);
%y = celshade(x,70);
%y = reinhard_tonemap(x);

%y = ue4_tonemap(x);

%y = change_exposure(x,0);

%y1 = change_exposure(x,0.5);
%y2 = change_exposure(x,-0.5);

%y3 = mix(y1,y2,0.5);
%y = y3;

subplot(1,2,1)
imshow(x)
subplot(1,2,2)
imshow(y)

