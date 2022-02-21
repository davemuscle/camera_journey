function [f_wid,f_hei,f_x,f_y] = eyes_cheeks(integral_image);
%Viola Jones Eyes Cheeks Feature
%Operates on integral image subwindow

[m,n] = size(integral_image);

acc_max = 0;
f_wid = 0;
f_hei = 0;
f_x = 0;
f_y = 0;

for feature_height = 2:2:m-16
for feature_width = 1:n

for i = 1:(m-feature_height)
    for j = 1:(n-feature_width)
        low_c = j;
        high_c = j + feature_width;
        
        low_r = i;
        mid_r = i + feature_height/2;
        high_r = i + feature_height;
        
        b = integral_image(mid_r,high_c) - ...
            integral_image(mid_r,low_c) - ...
            integral_image(low_r,high_c) + ...
            integral_image(low_r,low_c);
        w = integral_image(high_r,high_c) - ...
            integral_image(mid_r,high_c) - ...
            integral_image(high_r,low_c) + ...
            integral_image(mid_r,low_c);
        
        bw = b-w;
        bw = abs(bw);
        %bw = bw/(feature_height);
        %bw = bw/feature_width;
        
        if(bw > acc_max) 
            acc_max = bw;
            f_x = i;
            f_y = j;
            f_wid = feature_width;
            f_hei = feature_height;
        end
%         if(bw < acc_min)
%             acc_min = bw;
%             f_x = i;
%             f_y = j;
%             f_wid = feature_width;
%             f_hei = feature_height;
%         end
    end
end
end
end