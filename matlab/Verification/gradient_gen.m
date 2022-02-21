m=256;
n=256;

reds = zeros(m,n);
grns = zeros(m,n);
blus = zeros(m,n);

half_y = m/2;
half_x = n/2;

for i = 1:m
    for j = 1:n
        
        reds(i,j)=j-1;
        blus(i,j)=n-j-1;
        grns(i,j)=i-1;
        
        
    end
end

scrn = uint8(zeros(m,n,3));
scrn(:,:,1) = uint8(reds);
scrn(:,:,2) = uint8(grns);
scrn(:,:,3) = uint8(blus);

scrn_reds = uint8(zeros(m,n,3));
scrn_reds(:,:,1) = uint8(reds);
scrn_reds(:,:,2) = uint8(zeros(m,n));
scrn_reds(:,:,3) = uint8(zeros(m,n));

scrn_grns = uint8(zeros(m,n,3));
scrn_grns(:,:,1) = uint8(zeros(m,n));
scrn_grns(:,:,2) = uint8(grns);
scrn_grns(:,:,3) = uint8(zeros(m,n));

scrn_blus = uint8(zeros(m,n,3));
scrn_blus(:,:,1) = uint8(zeros(m,n));
scrn_blus(:,:,2) = uint8(zeros(m,n));
scrn_blus(:,:,3) = uint8(blus);

figure
imshow(scrn)