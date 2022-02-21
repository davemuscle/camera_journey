function y = smaa(x,thresh,mix)

%get edges
edges = sobel(x,thresh);

%get blurred image
blurred = gblur(x,3);

%mix
[m,n,p] = size(blurred);
y = x;
for i = 1:m
    for j = 1:n
        if(edges(i,j) > thresh)
            y(i,j,:) = mix.*blurred(i,j,:) + (1-mix).*y(i,j,:);
        end
    end
end

