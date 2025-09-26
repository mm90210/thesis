% invitro_dendrite.m
% custom code used in section 3.18 (thiolene)
% detects neurites and calculates their size

clear all; close all;
ny=open('nyulvany.mat'); %loading the file
img=ny.F13_folia.IMAGE;
img=imrotate(img,90);
[x,y]=ginput() %getting one pixel value for reference
px=impixel(img,x,y); 

Gaus = imgaussfilt(img,'FilterSize',5);%Gaus filter
bw = Gaus(:,:,1) >px(1,1);%converting image 
bw2=bw;
bw2 = bwareafilt(bw,[50 100000]); %filterint by size

se = strel('disk',1); %morphological operations
bw2 = imclose(bw2,se);

bw2 = bwareafilt(bw,[50 1000]); %filtering by area

pixel2um=ny.F13_folia.WidthStep; %size of one pixel in um
[B,L] = bwboundaries(bw2,'noholes'); %boundaries of detected objects
imshow(label2rgb(L,@jet,[.5 .5 .5]));
hold on
for k = 1:length(B)
  boundary = B{k};
  plot(boundary(:,2),boundary(:,1),'w','LineWidth',2)
end

stats = regionprops(L,img,'Area','Centroid','MeanIntensity','Orientation','MinorAxisLength');
orient=[];
ma=[];
metrics=[];
width=[];
threshold = 0.15; %threshold for roundness

% loop over the boundaries
for k = 1:length(B)
  
  % obtain (X,Y) boundary coordinates corresponding to label 'k'
  boundary = B{k};
  
  % compute a simple estimate of the object's perimeter
  delta_sq = diff(boundary).^2;    
  perimeter = sum(sqrt(sum(delta_sq,2)));
  
  % obtain the area calculation corresponding to label 'k'
  area = stats(k).Area;
  int=stats(k).MeanIntensity;
  minoraxis=stats(k).MinorAxisLength;
  orientation = stats(k).Orientation;
  % compute the roundness metric
  metric = 4*pi*area/perimeter^2;
  % display the results
  metric_string = sprintf('%2.2f',metric);
  metric_area = sprintf('%2.2f',area);
  metric_intensity=sprintf('%2.2f',int);
  % mark objects above the threshold with a black circle
  if metric < threshold
    centroid = stats(k).Centroid;
    orient(end+1)=orientation;
    ma(end+1)=minoraxis;
    metrics(end+1)=metric;
    plot(centroid(1),centroid(2),'ko');
    c_intens_str=sprintf('%2.4f',metric);
      text(boundary(1,2),boundary(1,1)-15,c_intens_str,'Color','k',...
      'FontSize',15,'FontWeight','bold')
  end

end
for i=1:length(ma)
    width(end+1)=ma(i)*pixel2um; %the width of the dendrites
end
mean_w=mean(width);
title(['Metrics closer to 1 indicate that ',...
       'the object is approximately round'])
 h1 = drawline('SelectedColor','yellow');




