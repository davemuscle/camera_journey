function y = change_exposure(x,ev)

[m,n,k] = size(x);
y = x;
for i = 1:m
    for j = 1:n
        
        temp = x(i,j,:);
        temp = temp .* 2^ev;
        for p = 1:k
            if(temp(p) > 255)
                y(i,j,p) =  255;
            else
                y(i,j,p) = temp(p);
            end
        end
    
    end
end

