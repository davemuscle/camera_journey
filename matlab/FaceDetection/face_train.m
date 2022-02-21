% ------------------------------------
%              USER CNTRL
% ------------------------------------
makesetup    = 1;
makefeatures = 1;
maketraining = 1;

% ------------------------------------
%              USER INPUTS
% ------------------------------------
NumFaces = 38;
NumNonFaces = 23;
size_m = 192;
size_n = 168;



%Subplot dimensions
sb_m = 8;
sb_n = 8;

NumImages = NumFaces + NumNonFaces;

input_images = uint8(zeros(size_m,size_n,NumImages));

%Read Face Images
for n = 0:NumFaces-1
    input_images(:,:,n+1) = imread(['YaleImgs/yale', num2str(n),'.pgm']);
end
%Read NonFace Images
idx = 0;
for n = NumFaces:NumImages-1
    input_images(:,:,n+1) = imread(['NotYaleImgs/nyale',num2str(idx),'.pgm']);
    idx = idx + 1;
end

% ------------------------------------
%               SETUP
% ------------------------------------
if(makesetup == 1)
    %Resize Images to 24x24
    input_images_resized = uint8(zeros(24,24,NumImages));
    for n = 0:NumImages-1
        input_images_resized(:,:,n+1) = imresize(input_images(:,:,n+1),[24,24]);
    end

    %Calculate integral images
    integral_images = zeros(24,24,NumImages);
    for n = 0:NumImages-1
        x = integralImage(input_images_resized(:,:,n+1));
        integral_images(:,:,n+1) = x(2:25,2:25);
    end

    %Convert them to 32bits FP
    integral_images = single(integral_images);
end

if(makefeatures == 1)
    build_and_apply_features;
end

% ------------------------------------
%       WEAK CLASSIFIER TRAINING
% ------------------------------------


pos_weights = ones(1,NumFaces)./(2*NumFaces);
neg_weights = ones(1,NumNonFaces)./(2*NumNonFaces);

weights = [pos_weights,neg_weights];

thresholds = zeros(1,NumFeatures);
polarities = zeros(1,NumFeatures);

train_weak;