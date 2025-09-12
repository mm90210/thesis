function section3_12_1quant
% intcalcROIanatParyv2
% custom code used in section 3.12.1
% calculates mean intensity of greater than zero value pixels on exported annotations 

desktopfd=['C:\Users\',getenv('USERNAME'),'\Desktop'];
mainfd=dir(uigetdir(desktopfd, 'Select main folder'));

tag=char(datetime('now','Format','yyMMdd-HHmm'));
OutputFolder=fullfile(desktopfd, ['intcalc ', tag]); % name of output folder
OutputXLS=fullfile(OutputFolder,'intcalc.xlsx');

F(1).name='ugh'; % struct creation
F=locator(mainfd, F, '.tif'); % locator function collects location of every .tif file in a folder and subfolders
F(1)=[]; % remove placeholder

% create the output excel structure
SlideTable=struct2table(F);
[path,fn,~]=fileparts(SlideTable.name(:));
SlideTable=[SlideTable, table(path), table(fn)];

if sum(contains(SlideTable.name,'Cy5'))
    SlideTable.tag(contains(SlideTable.name,'Cy5')) = {'CY5'};
end
if sum(contains(SlideTable.name,'DAPI'))
    SlideTable.tag(contains(SlideTable.name,'DAPI')) = {'DAPI'};
end
if sum(contains(SlideTable.name,'FITC'))
    SlideTable.tag(contains(SlideTable.name,'FITC')) = {'FITC'};
end
if sum(contains(SlideTable.name,'TRITC'))
    SlideTable.tag(contains(SlideTable.name,'TRITC')) = {'TRITC'};
end

[~,temp,~]=fileparts(SlideTable.path(:));
for i=1:length(temp)
    SlideTable.animal{i}=regexprep(temp{i}(4:8),'_','');
    SlideTable.annot{i}=temp{i}(end-1:end);

    if length(temp{i})==29
        SlideTable.slide{i}=temp{i}(10:13);
    elseif length(temp{i})==30
        SlideTable.slide{i}=temp{i}(10:14);
    else
        error('import problem')
    end
end

% annotation data (e.g. area) exported together with image is imported
[filename, filepath, ~] = MMgetfile('xlsx');
fn=char(fullfile(filepath, filename));
T=readtable(fn,'VariableNamingRule','preserve');

temp=table;
for i=1:height(SlideTable) 
    Logic=and( and( contains(T.animal, SlideTable.animal{i}), contains(T.slide, SlideTable.slide{i}) ), contains(T.Annotations, SlideTable.annot{i}) );
    temp=[temp; T(Logic, [2:5])]; 
end
SlideTable=[SlideTable, temp]; % annotation data appended to output table
mkdir([OutputFolder, '\plots']) % output folder for plots
SlideTable = intensity_calc(SlideTable, OutputFolder); % intensity calculation

tempArea=table2array(SlideTable(:,9))/10^6; % area calculation
SlideTable.AreaInt_mm2=SlideTable.MeanIntensity(:) ./ tempArea; % intensity divided by area = intensity per unit of area

% Figures and data
sheetnum=1;
Channel=unique(SlideTable.tag);
for n=1:length(Channel) % data subgrouped according to condition
    ChannelLogic=contains(SlideTable.tag, Channel(n));
    C = SlideTable(and(ChannelLogic, contains(SlideTable.treatment,'C')), :);
    T = SlideTable(and(ChannelLogic, contains(SlideTable.treatment,'T')), :);
    CS = SlideTable(and(ChannelLogic, and(contains(SlideTable.treatment,'C'), contains(SlideTable.layer,'S'))), :);
    CD = SlideTable(and(ChannelLogic, and(contains(SlideTable.treatment,'C'), contains(SlideTable.layer,'D'))), :);
    TS = SlideTable(and(ChannelLogic, and(contains(SlideTable.treatment,'T'), contains(SlideTable.layer,'S'))), :);
    TD = SlideTable(and(ChannelLogic, and(contains(SlideTable.treatment,'T'), contains(SlideTable.layer,'D'))), :);
    writetable(C, OutputXLS ,'Sheet', sheetnum) % groups placed on different sheets 
    writetable(T, OutputXLS ,'Sheet', sheetnum+1) 
    writetable(CS, OutputXLS ,'Sheet', sheetnum+2) 
    writetable(CD, OutputXLS ,'Sheet', sheetnum+3)
    writetable(TS, OutputXLS ,'Sheet', sheetnum+4)
    writetable(TD, OutputXLS ,'Sheet', sheetnum+5)
    sheetnum=sheetnum+6;
    plotData(TS.MeanIntensity, CS.MeanIntensity, Channel(n), 'Superficial', OutputFolder) % paired change plots
    plotData(TD.MeanIntensity, CD.MeanIntensity, Channel(n), 'Deep', OutputFolder)
end

disp('intcalcThres done')

%% intensity calc
function SlideTable=intensity_calc(SlideTable, OutputFolder)

for i=1:height(SlideTable)
    fn=SlideTable.name{i};
    A=imread(fn); % read image 

    if isequal(A(:,:,1),A(:,:,2),A(:,:,3))
        A=A(:,:,1); % the 3 layers of the .tif are identical 
    else 
        a=sum(A(:,:,1),'all');
        b=sum(A(:,:,2),'all');
        c=sum(A(:,:,3),'all');
        if ((a-b)<(a*0.001)) && ((a-c)<(a*0.001))
            A=A(:,:,1); % layers are within 0.1% difference
        else
            error(['tif layers are not equal: ', fn])
        end
    end

    SlideTable.MeanIntensity(i)=mean(A(A>0),'all'); % greater than zero pixels 
    OutputFolder=OutputFolder;
    
    f = figure('visible','off');
    [hist,~]=imhist(A); % original histogram
    plot(hist);
    xlim([0,100])
    ylim([0,100000])
    saveas(f, fullfile([OutputFolder, '\plots'], ...
        [SlideTable.animal{i}, ' ', SlideTable.slide{i}, ' ', SlideTable.annot{i}, ' ', SlideTable.treatment{i}, SlideTable.layer{i}, ' ', SlideTable.tag{i}, '.png']))
    close(f)
end

%% average intensity plot 
function plotData(Treat, Control, channel, layer, OutputFolder)

f=figure('Visible', 'off');
hold on
for k=1:length(Treat)
    plot(1, Control(k), 'ko', 'MarkerSize',10); % control data
    plot(2, Treat(k), 'ko', 'MarkerSize',10); % treated data 
    line([1,2], [Control(k),Treat(k)], 'Color', 'k', 'LineWidth', 2) % data pair line 
end

xlim([0.5,2.5])
ylim([0,max([Control;Treat])*1.1]);
xlabel('Control - Treatment')
ylabel('Fluorescence (unit8)')
title([channel, ' ', layer, ' Mean Intensity'])

try
    saveas(f, fullfile([OutputFolder, '\plots'], [channel, ' ', layer, ' Mean Intensity', '.png']))
catch 
    disp(fullfile([OutputFolder, '\plots'], [channel, ' ', layer, ' Mean Intensity', '.png']))
end
close(f)
