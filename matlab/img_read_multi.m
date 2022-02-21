function x=img_read_multi(filename, h_active, v_active)

fid = fopen(filename, 'r');
ints=fscanf(fid, '%d');
fclose(fid);

len = length(ints);

num_images = floor(len / (v_active*h_active));


m = v_active;
n = h_active;

imgs_out.img = zeros(m,n,3);

reds = mod(ints ./(2^16),256);
grns = mod(ints ./(2^ 8),256);
blus = mod(ints ./(2^ 0),256);

for k = 1:num_images

    for i =1:m
        imgs_out(k).img(i,:,1) = reds(((i-1)*n)+1+(m*n*(k-1)):i*n+(m*n*(k-1))); 
        imgs_out(k).img(i,:,2) = grns(((i-1)*n)+1+(m*n*(k-1)):i*n+(m*n*(k-1))); 
        imgs_out(k).img(i,:,3) = blus(((i-1)*n)+1+(m*n*(k-1)):i*n+(m*n*(k-1))); 
    end

end

%img_out = uint8(img_out);
%imshow(img_out)
x = imgs_out;
tt = ceil(num_images^0.5);
figure
for k = 1:num_images
    subplot(tt,tt,k);
    imshow(uint8(imgs_out(k).img))
end
%figure
%for k = 1:num_images-1
%    subplot(tt,tt,k);
%    imshow(uint8(10*abs(imgs_out(k+1).img - imgs_out(k).img)))
%end
