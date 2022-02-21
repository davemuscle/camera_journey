function y = celshade(x,thresh)
[m,n,k] = size(x);

x_gry = rgb2gray(x);

kernel_sobel_horz = [1,0,-1;2,0,-2;1,0,-1];
kernel_sobel_vert = [1,2,1;0,0,0;-1,-2,-1];

s_h = conv2(x_gry,kernel_sobel_horz,'same');
s_v = conv2(x_gry,kernel_sobel_vert,'same');

s_c = (s_h(:,:).^2 + s_v(:,:).^2).^0.5;

s_o = s_c;
for mm = 1:m
    for nn = 1:n
        if(s_c(mm,nn) > thresh)
            s_o(mm,nn) = s_c(mm,nn);
        else
            s_o(mm,nn) = 0;
        end
    end
end
s_o = uint8(s_o);
x_o = x;
x_o(:,:,1) = x_o(:,:,1) - s_o;
x_o(:,:,2) = x_o(:,:,2) - s_o;
x_o(:,:,3) = x_o(:,:,3) - s_o;

y = x_o;
