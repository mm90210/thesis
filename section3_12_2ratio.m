function section3_12_2ratio(type)
% tifSlideRatio(type)
% custom code used in section 3.12.2
% calculates the ratio of backgound and tissue on annotations (.tif) exported from caseviewer 
% v 21-05-17

switch type
    
    case 'bulk'
        dirpath=uigetdir(['C:\Users\',getenv('USERNAME'),'\Desktop'], 'Select data folder');
        folders = dir(dirpath); % data folders and background folder
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
                tempT=bgratio_calc(data_filename, bg_filename); % background ratio calculation
                T=[T;tempT];
            end
            masterT=[masterT;T];
        end
        
        % sort by path length ("kezelt" - 6, "control" - 7 characters. Meaning "treatment" and "control")
        tempLength=cellfun(@length,masterT.('Data_path'));
        [~,pathidx]=sort(tempLength);
        masterT=masterT(pathidx,:);
        masterT=sortrows(masterT, 2); % sort by 'Data_fn'
        
        % output
        loc=regexp(dirpath,'\');
        writetable(masterT, fullfile(dirpath, [dirpath(loc(end)+1:end), '_bgRatio.xlsx']))
        disp(['Done: ', dirpath(loc(end)+1:end)]);
        
        
    case 'single'
        
        [data_name, data_path, ~] = uigetfile({'*.*'},'Select data .tif', ['C:\Users\',getenv('USERNAME'),'\Desktop']);
        [bg_name, bg_path, ~]= uigetfile({'*.*'},'Select background .tif', ['C:\Users\',getenv('USERNAME'),'\Desktop']);
        
        data_filename=[data_path, data_name]; % data
        bg_filename=[bg_path, bg_name]; % background
        
        % file extension check
        extCheck=regexp(data_filename, '\.', 'end');
        bg_extCheck=regexp(data_filename, '\.', 'end');
        if ~strcmp(data_filename(extCheck(end):end), '.tif') || ~strcmp(data_filename(bg_extCheck(end):end), '.tif')
            error(['choose a .tif file (', data_filename,')'])
        end
        
        masterT=bgratio_calc(data_filename, bg_filename);
        writetable(masterT, [data_filename, '_bgRatio.xlsx'])
        
        disp(['Done: ', data_filename]);
end % switch end

function T=bgratio_calc(data_filename, bg_filename)

annot=imread(data_filename);
annot=annot(:,:,1);
A1=annot;
A1(annot==0)=[];

backg=imread(bg_filename);
backg=backg(:,:,1);
B1=backg;
B1(backg==0)=[];

Y = prctile(B1,95);
bgpix=numel(A1(A1<=Y)); % background pixels in annotation
annotpix=numel(A1(A1>Y)); % data pixels in annotation
Ratio=annotpix/bgpix;

% export
loc=regexp(data_filename,'\');
data_path=data_filename(loc(end-2):loc(end));
data_name=data_filename(loc(end)+1:end);
loc=regexp(bg_filename,'\');
bg_path=bg_filename(loc(end-2):loc(end));
bg_name=bg_filename(loc(end)+1:end);

Data_pix_wFrame=numel(annot);
Data_pix_noFrame=numel(A1);
BG_pix_wFrame=numel(backg);
BG_pix_noFrame=numel(B1);
Data_pix_bg=bgpix;
Data_pix_slice=annotpix;


T=table(...
    {data_path}, {data_name}, {bg_path}, {bg_name},...
    Data_pix_wFrame, Data_pix_noFrame, BG_pix_wFrame, BG_pix_noFrame, Data_pix_bg, Data_pix_slice, Ratio,...
    'VariableNames', {...
    'Data_path', 'Data_fn', 'Bg_path', 'Bg_fn',...
    'Data_pix_wFrame', 'Data_pix_noFrame', 'BG_pix_wFrame', 'BG_pix_noFrame',...
    'Data_pix_bg', 'Data_pix_slice', 'Ratio'});

