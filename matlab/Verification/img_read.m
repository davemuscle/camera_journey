function img_read(filename, h_active, v_active)

fid = fopen(filename, 'r');
ints=fscanf(fid, '%d');
fclose(fid);

m = v_active;
n = h_active;
img_out = zeros(m,n,3);

reds = mod(ints ./(2^16),256);
grns = mod(ints ./(2^ 8),256);
blus = mod(ints ./(2^ 0),256);

for i =1:m 
    img_out(i,:,1) = reds(((i-1)*n)+1:i*n); 
    img_out(i,:,2) = grns(((i-1)*n)+1:i*n); 
    img_out(i,:,3) = blus(((i-1)*n)+1:i*n); 
end

img_out = uint8(img_out);
imshow(img_out)