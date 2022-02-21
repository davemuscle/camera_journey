filename = 'framebuffer_reset_output.txt';
fid = fopen(filename, 'r');
ints=fscanf(fid, '%d');
fclose(fid);

h_active = 640;
v_active = 480;



m = v_active;
n = h_active;
img_out = zeros(m,n,3);

reds = mod(ints ./(2^16),256);
grns = mod(ints ./(2^ 8),256);
blus = mod(ints ./(2^ 0),256);


sel = 2;
low = ((sel-1)*(m*n))+1;
high = ((sel)*(m*n));

reds = reds(low:high);
grns = grns(low:high);
blus = blus(low:high);

for i =1:m 
    img_out(i,:,1) = reds(((i-1)*n)+1:i*n); 
    img_out(i,:,2) = grns(((i-1)*n)+1:i*n); 
    img_out(i,:,3) = blus(((i-1)*n)+1:i*n); 
end

img_out = uint8(img_out);
imshow(img_out)