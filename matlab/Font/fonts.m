fonts_bmp = imread('CourierNew36_FontMap_MonoChrome.bmp');
rows = 4;
[m,n] = size(fonts_bmp);

% top trim
trim = 1;
fonts_bmp = fonts_bmp(trim:m,:);
[m,n] = size(fonts_bmp);

% bottom trim
trim = 6;
fonts_bmp = fonts_bmp(1:m-trim,:);
[m,n] = size(fonts_bmp);

% round the width for even rows
fudge = 0;
row_width = floor(m/rows);
fonts_rows = zeros(row_width-2*fudge,n,rows);

trim = m - (rows*row_width);
fonts_bmp = fonts_bmp(1:m-trim,:);

for i = 1:rows
    low = ((i-1)*row_width)+1;
    high = i*row_width;
    low = low + fudge;
    high = high-fudge;
    fonts_rows(:,:,i) = fonts_bmp(low:high,:);
end

row_trims = [8,8,8,153];
[m,n,p] = size(fonts_rows);

row_1 = fonts_rows(:,1:n-row_trims(1),1);
row_2 = fonts_rows(:,1:n-row_trims(2),2);
row_3 = fonts_rows(:,1:n-row_trims(3),3);
row_4 = fonts_rows(:,1:n-row_trims(4),4);


numchar_1 = 25;
numchar_2 = 25;
numchar_3 = 25;
numchar_4 = 20;


[m1,n1] = size(row_1);
[m2,n2] = size(row_2);
[m3,n3] = size(row_3);
[m4,n4] = size(row_4);


char_width1 = n1/numchar_1;
char_width2 = n2/numchar_2;
char_width3 = n3/numchar_3;
char_width4 = n4/numchar_4;


total_chars = numchar_1 + numchar_2 + numchar_3 + numchar_4;
char_cnt = 1;
chars = zeros(m,char_width1,total_chars);

chars_1 = zeros(m1,char_width1,numchar_1);
chars_2 = zeros(m1,char_width2,numchar_2);
chars_3 = zeros(m1,char_width3,numchar_3);
chars_4 = zeros(m1,char_width4,numchar_4);

%seperate chars by row
for i = 1:numchar_1
    low = ((i-1)*char_width1)+1;
    high = i*char_width1;
    chars_1(:,:,i) = row_1(:,low:high);
    chars(:,:,char_cnt) = row_1(:,low:high);
    char_cnt = char_cnt + 1;
end

for i = 1:numchar_2
    low = ((i-1)*char_width2)+1;
    high = i*char_width2;
    chars_2(:,:,i) = row_2(:,low:high);
    chars(:,:,char_cnt) = row_2(:,low:high);
    char_cnt = char_cnt + 1;
end

for i = 1:numchar_3
    low = ((i-1)*char_width3)+1;
    high = i*char_width3;
    chars_3(:,:,i) = row_3(:,low:high);
    chars(:,:,char_cnt) = row_3(:,low:high);
    char_cnt = char_cnt + 1;
end

for i = 1:numchar_4
    low = ((i-1)*char_width4)+1;
    high = i*char_width4;
    chars_4(:,:,i) = row_4(:,low:high);
    chars(:,:,char_cnt) = row_4(:,low:high);
    char_cnt = char_cnt + 1;
end


%trim L, l, and @
%todo: check later if issues
chars(:,29,76-32+1) = 1;
chars(:,29,64-32+1) = 1;
chars(:,29,108-32+1) = 1;

%take each character and place on top of each other
[m,n,p] = size(chars);
char_toprint = zeros(m*p,n);
for i = 1:total_chars
   low = ((i-1)*m)+1;
   high = i*m;
   char_toprint(low:high,:) = chars(:,:,i); 
end

char_H = 72-32+1;
char_e = 101-32+1;
char_y = 121-32+1;
char_ex = 33-32+1;

str = [chars(:,:,char_H),chars(:,:,char_e),chars(:,:,108-32+1),chars(:,:,108-32+1),chars(:,:,111-32+1)];

chars_data = zeros(m*p,n);
for i = 1:total_chars

    low = ((i-1)*m)+1;
    high = i*m;
    
    chars_data(low:high,:) = chars(:,:,i);
   
   
end

dlmwrite('font_data.txt',chars_data);
