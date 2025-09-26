% bead.m
% custom code used in section 3.16
% detects beads and calculates their size 

clear all; close all;
image=load('rezo2_simple_u1'); %loading image
img=image.data.frameSetMean;
imshow(img,[],'InitialMagnification','fit');

integrated_density=[];
background=[];
integrated_density = [integrated_density,sum(img(:))];
background = [background,mean(img(:))];
row_img=reshape(img,1,[]); 
percentile=prctile(row_img,8); %  8. percentile for the baseline
f0_8=percentile;

Gaus = imgaussfilt(img,'FilterSize',5);%Gaus filter

bw = Gaus(:,:,1) >180;%converting image 

bw = bwareafilt(bw,[50 500]);%morphological operations
se = strel('disk',2);
bw = imclose(bw,se);

[B,L] = bwboundaries(bw,'noholes'); %boundaries of the detected objects
imshow(label2rgb(L,@jet,[.5 .5 .5]));
hold on
for k = 1:length(B)
  boundary = B{k};
  plot(boundary(:,2),boundary(:,1),'w','LineWidth',2)
end

stats = regionprops(L,img,'Area','Centroid','MeanIntensity','PixelList');
CTCF_all=[];
pixellist=[];
threshold = 0.3; %threshold for the roundness detection
area_um=[];
cell_body_area=[];
intensities=[];
centers=[];
% loop over the boundaries
for k = 1:length(B)
  c_intens=0;
  % obtain (X,Y) boundary coordinates corresponding to label 'k'
  boundary = B{k};
  pixlist=stats(k).PixelList;
  pixellist=[pixellist; pixlist];
  % compute a simple estimate of the object's perimeter
  delta_sq = diff(boundary).^2;    
  perimeter = sum(sqrt(sum(delta_sq,2)));
  
  % obtain the area calculation corresponding to label 'k'
  area = stats(k).Area;
  int=stats(k).MeanIntensity;
  % compute the roundness metric
  metric = 4*pi*area/perimeter^2;
  
  % display the results
  metric_string = sprintf('%2.2f',metric);
  metric_area = sprintf('%2.2f',area);
  metric_intensity=sprintf('%2.2f',int);
  centroid = stats(k).Centroid;
  centers=[centers; centroid(1) centroid(2)];
  % mark objects above the threshold with a black circle
  if metric > threshold
    plot(centroid(1),centroid(2),'ko');
  end

  if metric>threshold 
      double_int=double(int);
      intensities(end+1)=double_int;
      tmp=(double_int-d_f0);
      c_intens=tmp/d_f0;
      c_intens_str=sprintf('%2.2f',c_intens);
      text(boundary(1,2),boundary(1,1)-15,c_intens_str,'Color','k',...
      'FontSize',15,'FontWeight','bold')
  end
end
mean_int=mean(intensities);
mean_CTCF=mean(CTCF_all);
f0_8=double(f0_8);

ci_8=[];
for i=1:length(intensities)
   ci_8(i)=(intensities(i)-f0_8)/f0_8; %calculating the intensity change
end    
mean_ci_8=mean(ci_8); 
sdev=std(intensities);

