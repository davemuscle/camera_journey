function img_write_multi(folder)

m = 120;
n = 160;
numimages = 16; 

C_stream=zeros(m*n*numimages,1);
offset=0;

for imgnum = 1:numimages
    imgpath = sprintf('\\%d.jpg',imgnum);
    filename = strcat(folder,imgpath);
    disp(filename)
    
    A = imread(filename);
    A_red = A(:,:,1);
    A_grn = A(:,:,2);
    A_blu = A(:,:,3);

    for i = 1:m
        concat = uint32(A_red(i,:)).*(2^16) + ...
                 uint32(A_grn(i,:)).*(2^ 8) + ...
                 uint32(A_blu(i,:)).*(2^ 0);
        C_stream(((i-1)*n)+1+offset:(i*n)+offset) = concat;  
    end

 
    offset=offset+(m*n);
end

outpath=strcat(folder,'\\video_stream.txt');
disp(outpath)
dlmwrite(outpath, C_stream, 'precision', 32);



