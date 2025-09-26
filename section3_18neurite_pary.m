% neurite_detection.m
% custom code used in section 3.18 (parylene)
% detects neurites and calculates their size

clear all;
% close all;
clc;

%% Neurite detection based on the article of Vallotton & co.

%% WORKFLOW: create mask to get the parameters
%{
1. Binning 
2. Gaussian filter 
3. Take the gradient
4. Filtering based on magnitude and angle 
5. Basic noise reduction: morphological open, morphological close, remove small objects
%}

% img = imread( 'data_img2.tiff' );
% signal = img(:,:,2);
load('export_F12.mat')
img = data2.IMAGE;
signal = double(img);
signal = (signal-min(signal(:)))./(max(signal(:))-min(signal(:)));


% 1st step - smoothing with Gaussian filter
Gaus = imgaussfilt(signal,'FilterSize',15);

figure;
subplot(121); imshow(signal,[]); title('signal');
subplot(122); imshow(Gaus,[]); title('Gaussian filtered');
linkaxes;

% 2nd step - instead fo nonmax. suppression, get the gradient
[Gx, Gy] = imgradientxy(Gaus);
Gmag  = abs(sqrt(Gx.^2 +Gy.^2));
angle  = 180*atan2(Gy,Gx)/pi;

% figure;
% subplot(121); imshow(Gmag,[]); title('Gradient magnitude');
% subplot(122); imshow(angle, []); title('Gradient direction');
% linkaxes;

%% take the gradient magnitude & angle (direction)
A = Gmag.*angle;
AA = A/max(A(:));
figure; imhist(AA);
bw = zeros(size(AA));
bw(AA>0.15) = 1;

figure;  
subplot(121); imshow(AA); title('magnitude x direction');
subplot(122); imshow(bw); title('binary image');
linkaxes;

%% Noise reduction - Delete the small objects

bw2 = imopen(bw, strel('line',3, 135)); % morphologycal open
one = bwmorph(bw2,'bridge'); % fill the holes
two = bwmorph(one,'bridge');
bw3 = imclose(two, strel('line',20, 135));% morphologycal close
bw4 = bwareaopen(bw3, 20); % remove small objects that has fewer than #filter pixel

figure;  
subplot(221); imshow(signal,[]); title('signal');
subplot(222); imshow(bw2); title('morphologycal opening');
subplot(223); imshow(bw3); title('morph. closing');
subplot(224); imshow(bw4); title('remove small objects');

linkaxes;

%%

axis_min_maj = [];

stats = regionprops( bw4, signal, 'MajorAxisLength', 'MinorAxisLength', 'Orientation','PixelIdxList');
j = 1;
mask = bw4;
for i = 1: length(stats)
    if stats(i).MajorAxisLength > 25 %25
        axis_min_maj(j,1) = stats(i).MinorAxisLength; % thickness
        axis_min_maj(j,2) = stats(i).MajorAxisLength; % length
        j = j+1;
    else
        mask(stats(i).PixelIdxList) = 0;
    end
end

figure; imshow(mask);
TT = double(img).*mask;
figure; imshow(TT,[]);
%%
[len,idx] = sort([stats.MajorAxisLength]');
thick = [stats(idx).MinorAxisLength]';


%% For the images with parylene

%{

bw2 = imopen(bw, strel('line',1, 0)); % morphologycal open
one = bwmorph(bw2,'bridge'); 
two = bwmorph(one,'bridge');
bw3 = imclose(two, strel('line',5, 0));% morphologycal close
bw4 = bwareaopen(bw3, 30); % remove small objects that has fewer than #filter pixel

figure;  
subplot(221); imshow(control); title('control');
subplot(222); imshow(bw2); title('morphologycal opening');
subplot(223); imshow(bw3); title('filled holes');
subplot(224); imshow(bw4); title('remove small objects');

linkaxes;
%}
