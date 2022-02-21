function z = mix(x,y,ratio)

[m,n,k] = size(x);
z = x;
for i = 1:m
    for j = 1:n
        for p = 1:k
           z(i,j,p) = ratio*x(i,j,p) + (1-ratio).*y(i,j,p); 
        end
    end
end

z = uint8(z);