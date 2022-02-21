A = imread('test_pic.jpg');
A_red = A(:,:,1);
A_grn = A(:,:,2);
A_blu = A(:,:,3);

[m,n,p] = size(A);
C = zeros(m,n);

%Un-debayer the image
for i = 1:m
    for j = 1:n
        %booleans are flipped because of matlab array indexing
        if(mod(i,2) == 0)
            %odd row
            if(mod(j,2) == 0)
            %odd column
                C(i,j) = A_blu(i,j);
           else
            %even column
                C(i,j) = A_grn(i,j);
           end
        else
            %even row
            if(mod(j,2) == 0)
            %odd column
                C(i,j) = A_grn(i,j);
           else
            %even column
                C(i,j) = A_red(i,j);
           end
        end
    end
end
        
C = uint8(C);
C_stream = zeros(m*n,1);
for i =1:m
    C_stream( ((i-1)*n)+1:i*n) = C(i,:);
end
%dlmwrite('rawstream.txt', C_stream, 'precision', 8);
X = demosaic(C,'rggb');
%imshow(X)

C_pad = zeros(m+4, n+4);
C_pad(3:m+2,3:n+2) = C;

C_red = zeros(m,n);
C_grn = zeros(m,n);
C_blu = zeros(m,n);

%test debayer algo
k0 = [0, 0, -1, 0, 0; 0, 0, 2, 0, 0;-1,2,4,2,-1;0,0,2,0,0;0,0,-1,0,0];
k1 = [0, 0, 1/2, 0, 0; 0, -1, 0, -1, 0;-1,4,5,4,-1;0,-1,0,-1,0;0,0,1/2,0,0];
k2 = [0, 0, -1, 0, 0; 0, -1, 4, -1, 0;1/2,0,5,0,1/2;0,-1,4,-1,0;0,0,-1,0,0];
k3 = [0, 0, -3/2, 0, 0; 0, 2, 0, 2, 0;-3/2,0,6,0,-3/2;0,2,0,2,0;0,0,-3/2,0,0];
k0_n = norm(k0);
k1_n = norm(k1);
k2_n = norm(k2);
k3_n = norm(k3);
k0_d = 1/k0_n;
k1_d = 1/k1_n;
k2_d = 1/k2_n;
k3_d = 1/k3_n;
scale = 256;
k0_s = k0_d * scale;
k1_s = k1_d * scale;
k2_s = k2_d * scale;
k3_s = k3_d * scale;
% R G 
% G B
for i = 1:m+4
    for j = 1:n+4
        
        if(i >= 3 && i <= m && j >= 3 && j <= n)

            %booleans are flipped because of matlab array indexing
            if(mod(i,2) == 0)
                %odd row
                if(mod(j,2) == 0)
                %odd column
                   %kernel 3
                   red = 6*C_pad(i,j) + ...
                         2*(C_pad(i-1, j-1) + C_pad(i-1,j+1) + C_pad(i+1, j-1) + C_pad(i+1, j+1)) - ...
                         (3/2)*(C_pad(i-2,j) + C_pad(i+2,j) + C_pad(i,j-2) + C_pad(i,j+2));
                   red = red/k3_n;
                   %kernel 0
                   grn = 4*C_pad(i,j) + ...
                         2*(C_pad(i-1, j) + C_pad(i+1,j) + C_pad(i,j-1) + C_pad(i,j+1)) - ...
                         (C_pad(i,j-2) + C_pad(i, j+2) + C_pad(i-2,j) + C_pad(i+2,j));
                   grn = grn/k0_n;
                   blu = C_pad(i,j);
               else
                %even column
                   %kernel 2
                   red = 5*C_pad(i,j) + ...
                         4*(C_pad(i-1,j) + C_pad(i+1,j)) + ...
                         (1/2)*(C_pad(i,j-2) + C_pad(i,j+2)) - ...
                         1*(C_pad(i-1,j-1) + C_pad(i-1,j+1) + C_pad(i-2,j)) - ...
                         1*(C_pad(i+1,j-1) + C_pad(i+1,j+1) + C_pad(i+2,j));
                   red = red/k2_n;
                   grn = C_pad(i,j);
                   %kernel 1
                   blu = 5*C_pad(i,j) + ...
                         4*(C_pad(i, j-1)+C_pad(i,j+1)) + ...
                         (1/2)*(C_pad(i-2, j) + C_pad(i+2,j)) - ...
                         1*(C_pad(i,j-2) +C_pad(i-1,j-1) + C_pad(i+1,j-1)) - ...
                         1*(C_pad(i,j+2) +C_pad(i-1,j+1) + C_pad(i+1,j+1));
                   blu = blu/k1_n;
                   
                   
               end
            else
                %even row
                if(mod(j,2) == 0)
                %odd column
                    %kernel 1
                    red = 5*C_pad(i,j) + ...
                         4*(C_pad(i, j-1)+C_pad(i,j+1)) + ...
                         (1/2)*(C_pad(i-2, j) + C_pad(i+2,j)) - ...
                         1*(C_pad(i,j-2) +C_pad(i-1,j-1) + C_pad(i+1,j-1)) - ...
                         1*(C_pad(i,j+2) +C_pad(i-1,j+1) + C_pad(i+1,j+1));
                    red = red / k1_n;
                    grn = C_pad(i,j);
                    %kernel 2
                    blu = 5*C_pad(i,j) + ...
                         4*(C_pad(i-1,j) + C_pad(i+1,j)) + ...
                         (1/2)*(C_pad(i,j-2) + C_pad(i,j+2)) - ...
                         1*(C_pad(i-1,j-1) + C_pad(i-1,j+1) + C_pad(i-2,j)) - ...
                         1*(C_pad(i+1,j-1) + C_pad(i+1,j+1) + C_pad(i+2,j));
                    blu = blu/k2_n;
               else
                %even column
                   red = C_pad(i,j);
                   %kernel 0
                   grn = 4*C_pad(i,j) + ...
                         2*(C_pad(i-1, j) + C_pad(i+1,j) + C_pad(i,j-1) + C_pad(i,j+1)) - ...
                         (C_pad(i,j-2) + C_pad(i, j+2) + C_pad(i-2,j) + C_pad(i+2,j));
                   grn = grn / k0_n;
                   %kernel 3
                   blu = 6*C_pad(i,j) + ...
                         2*(C_pad(i-1, j-1) + C_pad(i-1,j+1) + C_pad(i+1, j-1) + C_pad(i+1, j+1)) - ...
                         (3/2)*(C_pad(i-2,j) + C_pad(i+2,j) + C_pad(i,j-2) + C_pad(i,j+2));
                   blu = blu/k3_n;
               end
            end
            
            
            C_red(i-2, j-2) = red;
            C_grn(i-2, j-2) = grn;
            C_blu(i-2, j-2) = blu;
        end

    end
end

C_algo = zeros(m,n,3);
C_algo(:,:,1) = C_red;
C_algo(:,:,2) = C_grn;
C_algo(:,:,3) = C_blu;
C_algo = uint8(C_algo);

