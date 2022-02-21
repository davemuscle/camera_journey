function img_write_packed(filename,packratio)

%Pixel width of 8 for each color, so 32 for memory alignment

A = imread(filename);
A_red = A(:,:,1);
A_grn = A(:,:,2);
A_blu = A(:,:,3);

[m,n] = size(A_red);

%pack to RGB
A_full = uint32(zeros(m,n));
for i = 1:m
    for j = 1:n
        A_full(i,j) = uint32(A_red(i,j)).*(2^16) + ...
                      uint32(A_grn(i,j)).*(2^ 8) + ...
                      uint32(A_blu(i,j)).*(2^ 0);
    end
end

%pack to data width by lines
A_packed = zeros(m,n/packratio);
x = uint256(1);
%pack
%for i = 1:m
%    for j = 1:packratio:n
%       temp = uint32(0);
%       for t = 1:packratio
%           temp = temp + uint32(A_full(i,j).*(2^32*t)
%       end
%       
%   end
%end

%for i = 

%C_stream = zeros(m*n/packratio,1);

%for i =1:m
%    concat = uint32(A_red(i,:)).*(2^16) + ...
%             uint32(A_grn(i,:)).*(2^ 8) + ...
%             uint32(A_blu(i,:)).*(2^ 0);
%    C_stream(((i-1)*n)+1:i*n) = concat;
%end

%dlmwrite('test_stream.txt', C_stream, 'precision', 32);



