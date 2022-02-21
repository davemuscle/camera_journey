% Face Detection Script

% Load Image
img_i = imread('Face.jpg');
[m,n,p] = size(img_i);

% Convert to gray-scale
% Taken from Wikipedia
img_gry = 0.2126*img_i(:,:,1) + 0.7152*img_i(:,:,2) + 0.0722*img_i(:,:,3);

% Create image scales
img_gry_fs = img_gry;
img_gry_s2 = img_gry(1:2:m,1:2:n);
img_gry_s4 = img_gry(1:4:m,1:4:n);
img_gry_s8 = img_gry(1:8:m,1:8:n);


% Calculate integral image
% Used Wikipedia formula again, should be easy to calculate in HW
% Might not need to buffer up the entire integral image, only points of
% interest.
img_int_fs = integralImage(img_gry_fs);
img_int_s2 = integralImage(img_gry_s2);
img_int_s4 = integralImage(img_gry_s4);
img_int_s8 = integralImage(img_gry_s8);

img_int_fs = img_int_fs(2:m+1,2:n+1);
img_int_s2 = img_int_s2(2:m/2+1,2:n/2+1);
img_int_s4 = img_int_s4(2:m/4+1,2:n/4+1);
img_int_s8 = img_int_s8(2:m/8+1,2:n/8+1);

subwindow_size = 24;

%Prune image size to line up with subwindow
fs_r = subwindow_size*floor(m/subwindow_size);
fs_c = subwindow_size*floor(n/subwindow_size);
img_int_prc_fs = img_int_fs(1:fs_r,1:fs_c);

s2_r = fs_r/2;
s2_c = fs_c/2;
img_int_prc_s2 = img_int_s2(1:s2_r,1:s2_c);

s4_r = fs_r/4;
s4_c = fs_c/4;
img_int_prc_s4 = img_int_s4(1:s4_r,1:s4_c);

s8_r = fs_r/8;
s8_c = fs_c/8;
img_int_prc_s8 = img_int_s8(1:s8_r,1:s8_c);

%sub windows in full scale image
idx_r = 1;
idx_c = 1;

eyes_cheeks_img = zeros(fs_r,fs_c);
for i = 1:floor(n/subwindow_size)-1
    for j = 1:floor(m/subwindow_size)-1
    
        %calculate eyes-cheeks feature
        b_tl_r = idx_r;
        b_tl_c = idx_c;
        b_tr_r = idx_r;
        b_tr_c = idx_c+subwindow_size;
        b_bl_r = idx_r+subwindow_size/2;
        b_bl_c = idx_c;
        b_br_r = idx_r+subwindow_size/2;
        b_br_c = idx_c+subwindow_size;
        w_tl_r = idx_r+subwindow_size/2;
        w_tl_c = idx_c;
        w_tr_r = idx_r+subwindow_size/2;
        w_tr_c = idx_c+subwindow_size;
        w_bl_r = idx_r+subwindow_size;
        w_bl_c = idx_c;
        w_br_r = idx_r+subwindow_size;
        w_br_c = idx_c+subwindow_size;
        
        b = img_int_prc_fs(b_br_r,b_br_c) - ...
            img_int_prc_fs(b_tr_r,b_tr_c) - ...
            img_int_prc_fs(b_bl_r,b_bl_c) + ...
            img_int_prc_fs(b_tl_r,b_tl_c);
        
        w = img_int_prc_fs(w_br_r,w_br_c) - ...
            img_int_prc_fs(w_tr_r,w_tr_c) - ...
            img_int_prc_fs(w_bl_r,w_bl_c) + ...
            img_int_prc_fs(w_tl_r,w_tl_c);
        
        eyes_cheeks = b-w;

        eyes_cheeks_img(idx_r:idx_r+subwindow_size,idx_c:idx_c+subwindow_size) = eyes_cheeks;
        
        idx_c = idx_c + subwindow_size;

        
        
    end
    idx_c = 1;
    idx_r = idx_r + subwindow_size;
end

img_o = 255.*ones(fs_r,fs_c,3);
for i = 1:fs_r
    for j = 1:fs_c
       
        if(eyes_cheeks_img(i,j) < 0) 
            img_o(i,j,1) = 255;
            img_o(i,j,2) = 0;
            img_o(i,j,3) = 0;
        end
        
    end 
end
subplot(1,2,1)
imshow(img_i)
subplot(1,2,2)
imshow(img_o)