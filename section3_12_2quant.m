function section3_12_2quant
% tifImportSirof(type)
% custom code used in section 3.12.2

% fluorescence quantification on annotations (.tif) exported from caseviewer 
% uint8 scale: [0, 255] /[0, 2^8-1]/
%
% what does it do?
% after reading, the zero-edges appended to the annotation upon export are
% discarded from data and backgroung annotations
% background annotation is averaged and subtracted from data annotations
% data annotations are then averaged (every pixel or nonzero pixels)

% type 'bulk': choose a folder which contains more folders with exported
% images and a background image folder. Select the folder with the background 
% images (if not found automatically). Output is placed in the first
% folder. Pairing data and background images work due to alphabetical order

% type 'single': select a data image and a corresponding background image.
% Output is placed in the folder of the data image

switch type
    case 'bulk'
        dirpath=uigetdir(['C:\Users\',getenv('USERNAME'),'\Desktop'], 'Select data folder');
        folders = dir(dirpath); % data folders and bg folder
        bgToggle=1;
        
        % check for background folder
        for i=1:length(folders)
            ANS=regexp(folders(i).name,'background','ONCE');
            if ~isempty(ANS)
                bgToggle=0; % found
                bg_folder_name=folders(i).name;
                bg_folder=fullfile(dirpath,bg_folder_name);
            end
        end
        
        if bgToggle % if background folder not found
            bg_folder=uigetdir(dirpath, 'Select background folder');
            temploc=regexp(bg_folder, '\');
            bg_folder_name=bg_folder(temploc(end)+1:end);
        end
        
        % remove bg folder from data folder list
        idx=[];
        for i=1:length(folders)
            if isequal(folders(i).name, bg_folder_name) || isequal(folders(i).name, '.') || isequal(folders(i).name, '..')
                idx=[idx,i];
            end
        end
        folders(idx)=[];
        
        % name and path for data folders
        masterT=table;
        for i=1:length(folders)
            data_files = dir(fullfile(dirpath, folders(i).name, '*.tif'));
            bg_files = dir(fullfile(bg_folder, '*.tif'));
            
            T=table;
            for n=1:length(data_files)
                % channels are in alphabetical in both folders 
                data_filename=fullfile(data_files(n).folder, data_files(n).name);
                bg_filename=fullfile(bg_files(n).folder, bg_files(n).name);
                tempT=intensity_calc(data_filename, bg_filename); % intensity calculation
                T=[T;tempT];
            end
            masterT=[masterT;T];
        end
        
        % sort by path length ("kezelt" - 6, "control" - 7 characters. Meaning "treatment" and "control")
        tempLength=cellfun(@length,masterT.('Data_path'));
        [~,pathidx]=sort(tempLength);
        masterT=masterT(pathidx,:);
        
        % sort by 'Data_fn'
        masterT=sortrows(masterT, 2);
        
        % separate to channel tables and plot
        channelCheck=char(join(masterT.Data_fn'));
        
        % Cy5 channel exists -> plot
        if ~isempty(regexp(channelCheck,'Cy5','ONCE'))
            temp=regexp(masterT.Data_fn,'Cy5');
            chidx=cellfun(@isempty, temp);
            Cy5group=masterT(~chidx,:);
            temp=regexp(Cy5group.Data_path,'kezelt');
            gridx=cellfun(@isempty, temp);
            Cy5Treat=Cy5group(~gridx,:);
            Cy5Control=Cy5group(gridx,:);
            plotData(Cy5Treat,Cy5Control,'Cy5', dirpath)
        end
        
        % DAPI
        if ~isempty(regexp(channelCheck,'DAPI','ONCE'))
            temp=regexp(masterT.Data_fn,'DAPI');
            chidx=cellfun(@isempty, temp);
            DAPIgroup=masterT(~chidx,:);
            temp=regexp(DAPIgroup.Data_path,'kezelt');
            gridx=cellfun(@isempty, temp);
            DAPITreat=DAPIgroup(~gridx,:);
            DAPIControl=DAPIgroup(gridx,:);
            plotData(DAPITreat,DAPIControl,'DAPI', dirpath)
        end
        
        % FITC
        if ~isempty(regexp(channelCheck,'FITC','ONCE'))
            temp=regexp(masterT.Data_fn,'FITC');
            chidx=cellfun(@isempty, temp);
            FITCgroup=masterT(~chidx,:);
            temp=regexp(FITCgroup.Data_path,'kezelt');
            gridx=cellfun(@isempty, temp);
            FITCTreat=FITCgroup(~gridx,:);
            FITCControl=FITCgroup(gridx,:);
            plotData(FITCTreat,FITCControl,'FITC', dirpath)
        end
        
        % TRITC
        if ~isempty(regexp(channelCheck,'TRITC','ONCE'))
            temp=regexp(masterT.Data_fn,'TRITC');
            chidx=cellfun(@isempty, temp);
            TRITCgroup=masterT(~chidx,:);
            temp=regexp(TRITCgroup.Data_path,'kezelt');
            gridx=cellfun(@isempty, temp);
            TRITCTreat=TRITCgroup(~gridx,:);
            TRITCControl=TRITCgroup(gridx,:);
            plotData(TRITCTreat,TRITCControl,'TRITC', dirpath)
        end
        
        % output
        loc=regexp(dirpath,'\');
        writetable(masterT, fullfile(dirpath, [dirpath(loc(end)+1:end), '_intCalc.xlsx']))
        disp(['Done: ', dirpath(loc(end)+1:end)]);
        
        
    case 'single'
        
        [data_name, data_path, ~] = uigetfile({'*.*'},'Select data .tif', ['C:\Users\',getenv('USERNAME'),'\Desktop'],'MultiSelect','off');
        [bg_name, bg_path, ~]= uigetfile({'*.*'},'Select background .tif', ['C:\Users\',getenv('USERNAME'),'\Desktop']);
        
        data_filename=[data_path, data_name]; % data
        bg_filename=[bg_path, bg_name]; % background
        
        % file extension check
        extCheck=regexp(data_filename, '\.', 'end');
        bg_extCheck=regexp(data_filename, '\.', 'end');
        if ~strcmp(data_filename(extCheck(end):end), '.tif') || ~strcmp(data_filename(bg_extCheck(end):end), '.tif')
            error(['choose a .tif file (', data_filename,')'])
        end
        
        masterT=intensity_calc(data_filename, bg_filename);
        writetable(masterT, [data_filename, '_intCalc.xlsx'])
        
        disp(['Done: ', data_filename]);
end % switch end

function plotData(treatment, control, channel, dirpath)
X=repmat([1;2], height(treatment),1);
idx=regexp(dirpath,'\');
name=dirpath(idx(end)+1:end);

dataToPlot={'Data_mean_noBG', 'Data_mean_BG', 'Data_mean_BG_noZero', 'Data_num_pix_BG_noZero'};

for i=1:length(dataToPlot)
    f=figure('Visible', 'off');
    field=dataToPlot{i};
    
    ct=control.(field); % for line
    tr=treatment.(field);
    
    Y=zeros(height(treatment)*2,1); % for plot 
    Y(1:2:end)=ct; 
    Y(2:2:end)=tr;
    
    plot(X, Y, 'ko', 'MarkerSize',10);
    line([1,2], [ct,tr], 'Color', 'k', 'LineWidth', 2)
    
    xlim([0.5,2.5])
    ylim([0,max([ct;tr])*1.1]);
    title(regexprep([name, ' ', channel, ' ', field],'_',' '))
    xlabel('Control - Treatment')
    ylabel('Fluorescence (unit8)')
    
    saveas(f, fullfile(dirpath, [name, '_', channel, '_', field, '.png']))
end

function T=intensity_calc(data_filename, bg_filename)

A=imread(data_filename);
A=A(:,:,1); % exported image has 2-3 identical layers, only first is needed 
B=imread(bg_filename);
B=B(:,:,1);

% black frame cutoff
A2=framecutoff(A);
B2=framecutoff(B);

% intensity calc
Data_sum_int=sum(A2,'all');
Data_num_pix=size(B2,1)*size(B2,2);
Data_mean_noBG=mean(A2,'all');

Bg_sum_int=sum(B2,'all');
Bg_num_pix=size(B2,1)*size(B2,2);
Bg_mean_int=mean(B2,'all');

% background subtraction
C=A2-Bg_mean_int;
Data_mean_BG=mean(C,'all');

% zeroes exclusion
C1=C(:);
[r,~]=find(C1);
C2=C1(r);
Data_num_pix_BG_noZero=numel(C2);
Data_mean_BG_noZero=mean(C2);

% troubleshooting
% Cford=C;
% Cford(C==0)=1;
% Cford(C>0)=0;
% figure
% imagesc(C);
% figure
% imagesc(Cford);

% export
loc=regexp(data_filename,'\');
data_path=data_filename(loc(end-2):loc(end));
data_name=data_filename(loc(end)+1:end);
loc=regexp(bg_filename,'\');
bg_path=bg_filename(loc(end-2):loc(end));
bg_name=bg_filename(loc(end)+1:end);

T=table(...
    {data_path}, {data_name}, {bg_path}, {bg_name},...
    Data_mean_noBG, Data_mean_BG, Data_mean_BG_noZero, Data_num_pix_BG_noZero,...
    Data_sum_int, Data_num_pix, Bg_sum_int, Bg_num_pix, Bg_mean_int,...
    'VariableNames', {...
        'Data_path', 'Data_fn', 'Bg_path', 'Bg_fn',...
        'Data_mean_noBG', 'Data_mean_BG', 'Data_mean_BG_noZero', 'Data_num_pix_BG_noZero',...
        'Data_sum_int', 'Data_num_pix', 'Bg_sum_int', 'Bg_num_pix', 'Bg_mean_int'});

function out=framecutoff(in) % black frame cutoff
[row,col]=find(in);
upperLim=find(row(:)==min(row(:)));
upperLim=row(upperLim(1));
lowerLim=find(row(:)==max(row(:)));
lowerLim=row(lowerLim(end));
leftLim=find(col(:)==min(col(:)));
leftLim=col(leftLim(1));
rightLim=find(col(:)==max(col(:)));
rightLim=col(rightLim(end));
out=in(upperLim:lowerLim,leftLim:rightLim);
