function y = sharpen(x)

kernel = [0,-1,0;-1,5,-1;0,-1,0];

y(:,:,1) = conv2(x(:,:,1),kernel,'same');
y(:,:,2) = conv2(x(:,:,2),kernel,'same');
y(:,:,3) = conv2(x(:,:,3),kernel,'same');

y = uint8(y);