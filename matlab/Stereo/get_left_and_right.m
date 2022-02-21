inp = 'boys_orig.jpg';
inp_img = imread(inp);
[m,n,p]=size(inp_img);

tm=480;
tn=640;

tgrab=floor((m-tm)/2);
lgrab=1;
rgrab=tn;

img_left = inp_img(tgrab:tgrab+tm,lgrab:lgrab+tn,:);
img_right = inp_img(tgrab:tgrab+tm,n-rgrab:n,:);
close all;
%figure
%imshow(inp_img)

%figure
%subplot(1,2,1)
%imshow(img_left)
%subplot(1,2,2)
%imshow(img_right)

ss=4;
img_o_left = img_left(1:ss:tm,1:ss:tn,:);
img_o_right = img_left(1:ss:tm,1:ss:tn,:);

