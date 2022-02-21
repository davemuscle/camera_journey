% Build and Apply Features to Training Images
% This runs before the training loop

% Required inputs:
%   NumImages = variable
%   integral_images = array (x,y,z)

% Intermediate Outputs:
%   Array of feature locations and dimensions

% Outputs:
%   Array of computed features: features(NumImages,NumFeatures,6)

img_wid = 24;
img_hei = 24;

feature_len = 200000;
features = single(zeros(NumImages,feature_len,8));

% features array is:
% [type, f_width, f_height, i_loc, j_loc, diff]

for n = 1:NumImages
    ii = integral_images(:,:,n);
    feature_idx = 1;
    if(n <= NumFaces)
        isface = 1;
    else
        isface = 0;
    end
    
    % eyes cheeks
   
    % loop through possible feature widths
    for w = 2:2:img_wid-4
    % loop through possible feature heights
    for h = 2:2:img_hei-8
    % loop through row locations
    for i = 1:1:img_hei
    % loop through column locations
    for j = 1:1:img_wid

        %eyes-cheeks (b);(w)feature
        if(j+w <= img_wid && i+h <= img_hei)

            blk = compute_ii_rec(ii, [i,j], [i,j+w], [i+h/2,j], [i+h/2,j+w]);
            whi = compute_ii_rec(ii, [i+h/2,j], [i+h/2,j+w],[i+h,j],[i+h,j+w]);

            diff = blk-whi;
            
            features(n,feature_idx,1) = 0;
            features(n,feature_idx,2) = w;
            features(n,feature_idx,3) = h;
            features(n,feature_idx,4) = i;
            features(n,feature_idx,5) = j;
            features(n,feature_idx,6) = diff;
            features(n,feature_idx,7) = isface;
            features(n,feature_idx,8) = n;
            feature_idx = feature_idx + 1;

        end             
    end
    end
    end
    end
    
    
    %nose-bridge (w)-(b)-(w) feature

    % loop through possible feature widths
    for w = 3:3:img_wid-12
    % loop through possible feature heights
    for h = 2:2:img_hei-4
    % loop through row locations
    for i = 1:1:img_hei
    % loop through column locations
    for j = 1:1:img_wid

        %eyes-cheeks (b);(w)feature
        if(j+w <= img_wid && i+h <= img_hei)

            whi_1 = compute_ii_rec(ii, [i,j],[i,j+w/3],[i+h,j],[i+h,j+w/3]);
            blk   = compute_ii_rec(ii, [i,j+w/3],[i+h,j+w/3],[i,j+2*w/3],[i+h,j+2*w/3]);
            whi_2 = compute_ii_rec(ii, [i,j+w*2/3],[i,j+w],[i+h,j+2*w/3],[i+h,j+w]);
 
            diff = blk - whi_1 - whi_2;
            
            features(n,feature_idx,1) = 1;
            features(n,feature_idx,2) = w;
            features(n,feature_idx,3) = h;
            features(n,feature_idx,4) = i;
            features(n,feature_idx,5) = j;
            features(n,feature_idx,6) = diff;
            features(n,feature_idx,7) = isface;
            features(n,feature_idx,8) = n;
            feature_idx = feature_idx + 1;

        end             
    end
    end
    end
    end

    %left(w)-right(b) feature

    % loop through possible feature widths
    for w = 2:2:img_wid-2
    % loop through possible feature heights
    for h = 2:2:img_hei-2
    % loop through row locations
    for i = 1:1:img_hei
    % loop through column locations
    for j = 1:1:img_wid

        %eyes-cheeks (b);(w)feature
        if(j+w <= img_wid && i+h <= img_hei)

            whi = compute_ii_rec(ii, [i,j],[i,j+w/2],[i+h,j],[i+h,j+w/2]);
            blk = compute_ii_rec(ii, [i,j+w/2],[i,j+w],[i+h,j+w/2],[i+h,j+w]);
            

            diff = blk-whi;
            
            features(n,feature_idx,1) = 2;
            features(n,feature_idx,2) = w;
            features(n,feature_idx,3) = h;
            features(n,feature_idx,4) = i;
            features(n,feature_idx,5) = j;
            features(n,feature_idx,6) = diff;
            features(n,feature_idx,7) = isface;
            features(n,feature_idx,8) = n;
            feature_idx = feature_idx + 1;

        end             
    end
    end
    end
    end
    
    %tl(w)-tr(b);bl(b)-bl(w) feature
                
    % loop through possible feature widths
    for w = 2:2:img_wid-2
    % loop through possible feature heights
    for h = 2:2:img_hei-2
    % loop through row locations
    for i = 1:1:img_hei
    % loop through column locations
    for j = 1:1:img_wid

        %eyes-cheeks (b);(w)feature
        if(j+w <= img_wid && i+h <= img_hei)

            whi_1 = compute_ii_rec(ii,[i,j],[i,j+w/2],[i+h/2,j],[i+h/2,j+w/2]);
            blk_1 = compute_ii_rec(ii,[i,j+w/2],[i,j+w],[i+h/2,j+w/2],[i+h/2,j+w]);
            
            blk_2 = compute_ii_rec(ii,[i+h/2,j],[i+h/2,j+w/2],[i+h,j],[i+h,j+w/2]);
            whi_2 = compute_ii_rec(ii,[i+h/2,j+w/2],[i+h/2,j+w],[i+h,j+w/2],[i+h,j+w]);

            diff = blk_2 + blk_1 - whi_1 - whi_2;
            
            features(n,feature_idx,1) = 3;
            features(n,feature_idx,2) = w;
            features(n,feature_idx,3) = h;
            features(n,feature_idx,4) = i;
            features(n,feature_idx,5) = j;
            features(n,feature_idx,6) = diff;
            features(n,feature_idx,7) = isface;
            features(n,feature_idx,8) = n;
            feature_idx = feature_idx + 1;

        end             
    end
    end
    end
    end
end

%Adjust the index because of post increment
feature_idx = feature_idx - 1;

%Free up memory by trimming the vector
for n = 1:NumImages
   features = features(:,1:feature_idx,:); 
end

NumFeatures = feature_idx;

