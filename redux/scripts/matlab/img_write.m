function img_write(filename)

A = imread(filename);
A_red = A(:,:,1);
A_grn = A(:,:,2);
A_blu = A(:,:,3);

[m,n] = size(A_red);

C_stream = zeros(m*n,1);

for i =1:m
    concat = uint32(A_red(i,:)).*(2^16) + ...
             uint32(A_grn(i,:)).*(2^ 8) + ...
             uint32(A_blu(i,:)).*(2^ 0);
    C_stream(((i-1)*n)+1:i*n) = concat;
end

dlmwrite('test_stream.txt', C_stream, 'precision', 32);



