fid_red = fopen('demosaic_out_red.txt', 'r');
fid_grn = fopen('demosaic_out_grn.txt', 'r');
fid_blu = fopen('demosaic_out_blu.txt', 'r');

reds=fscanf(fid_red, '%d');
grns=fscanf(fid_grn, '%d');
blus=fscanf(fid_blu, '%d');

fclose(fid_red);
fclose(fid_grn);
fclose(fid_blu);

img_out = zeros(m,n,3);

for i =1:m 
    img_out(i,:,1) = reds(((i-1)*n)+1:i*n);
    img_out(i,:,2) = grns(((i-1)*n)+1:i*n);
    img_out(i,:,3) = blus(((i-1)*n)+1:i*n);
end

img_reds = img_out(:,:,1);
img_grns = img_out(:,:,2);
img_blus = img_out(:,:,3);

img_out = uint8(img_out);
imshow(img_out)