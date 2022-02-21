function y = gblur(x,type)

if(type == 3)
   kernel = (1/16).*[1,2,1;2,4,2;1,2,1];
elseif(type == 5)
   kernel = (1/256).*[1,4,6,4,1; ...
                      4,16,24,16,4; ...
                      6,24,36,24,6; ...
                      4,16,24,16,4; ...
                      1,4,6,4,1];
else
   disp('No Kernel')
   y = 0;
   return
end
y(:,:,1) = conv2(x(:,:,1),kernel,'same');
y(:,:,2) = conv2(x(:,:,2),kernel,'same');
y(:,:,3) = conv2(x(:,:,3),kernel,'same');
y = uint8(y);