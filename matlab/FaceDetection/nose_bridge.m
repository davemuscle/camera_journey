function [f_wid,f_hei,f_x,f_y] = nose_bridge(integral_image);
%Viola Jones Nose Bridge Feature
%Operates on integral image subwindow

[m,n] = size(integral_image);

acc_max = 0;
f_wid = 0;
f_hei = 0;
f_x = 0;
f_y = 0;

for feature_height = 1:m
for feature_width = 3:3:n

for i = 1:(m-feature_height)-3
    for j = 1:(n-feature_width)
        
        low_c = j;
        mid_c1 = j + feature_width/3;
        mid_c2 = j + 2*feature_width/3;
        high_c = j + feature_width;
        
        low_r = i;
        high_r = i + feature_height;
        
        b1 = integral_image(high_r,mid_c1) - ...
             integral_image(high_r,low_c) - ...
             integral_image(low_r,mid_c1) + ...
             integral_image(low_r,low_c);
         
        w = integral_image(high_r,mid_c2) - ...
            integral_image(high_r,mid_c1) - ...
            integral_image(low_r,mid_c2) + ...
            integral_image(low_r,mid_c1);
        
        b2 = integral_image(high_r,high_c) - ...
             integral_image(high_r,mid_c2) - ...
             integral_image(low_r,high_c) + ...
             integral_image(low_r,mid_c1);
         
        bw = w - b1 - b2;
        bw = abs(bw);
        if(bw > acc_max) 
            acc_max = bw;
            f_x = i;
            f_y = j;
            f_wid = feature_width;
            f_hei = feature_height;
        end

    end
end
end
end