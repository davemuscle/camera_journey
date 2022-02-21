function y = colorinvert(x)

[m,n,k] = size(x);
y = x;
for i = 1:m
    for j = 1:n
        y(i,j,:) = 255-x(i,j,:);
    end
end

y = uint8(y);