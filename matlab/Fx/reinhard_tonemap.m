function y = reinhard_tonemap(x)

%map x colors between 0 and 1
x_f = double(x) / 255;

%Get luminance
L = 0.2126.*(x_f(:,:,1)) + ...
    0.7152.*(x_f(:,:,2)) + ...
    0.0722.*(x_f(:,:,3));

y = x_f ./ (0.5 + L);
y = y*255;
y = uint8(y);


