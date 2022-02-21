function y = ue4_tonemap(x)

%map x colors between 0 and 1
x_f = double(x) ./ 255;

x_f = x_f.*1;

a = 2.51;
b = 0.03;
c = 2.43;
d = 0.59;
e = 0.14;

y = (x_f.*(a.*x_f+b))./(x_f.*(c.*x_f+d)+e);
y = 255*y;
y = uint8(y);

