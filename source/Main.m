function Main(DataSetPath, AlgoList, JointAlgo)

% Plots the Cost vs Accuracy of given algorithms, a chosen algorithm with HPU 
% and only HPU.
%
%   -- Arguments --
%
%   DataSetPath                String specifying path of the dataset.  
%                              Dataset must contain PNG test files and the
%                              digitStruct.mat file containing ground
%                              truth.
%
%   AlgoList                   A cell array of strings containing names of
%                              algorithms that will be used to process to the
%                              dataset.
%
%   JointAlgo                  String specifying name of an algo to be used
%                              with HPU
%
%
%   -- Example --
%   Main('D:\testset', {'someoldguy2002','someoldguy2007','chen2011'},'chen2011')
%

%% init variables
CostList = [];
AccuracyList = [];
LabelList = [];
ElapsedSeconds = 0;

%% set time format
global formatOut
formatOut = 'HH:MM:SS:FFF dd-mmm-yy';

%% generate dataset image file-name list
StartTime = now;
disp([datestr(StartTime,formatOut), ': *started dataset image list generation'])

if DataSetPath(end) == '\' 
    DataSetPath = DataSetPath(1:end-1);
end
Files = dir([DataSetPath, '\*.png']);
ImageList = sort_nat({Files.name});
for i = 1:size(ImageList')
    ImageList{i} = [DataSetPath,'\',ImageList{i}];
end

EndTime = now;
ElapsedSeconds = (EndTime-StartTime) * 24 * 60 * 60;
disp([datestr(EndTime,formatOut), ':  finished dataset image list generation in ', num2str(ElapsedSeconds), ' seconds'])

%% load ground truth file
StartTime = now;
disp([datestr(StartTime,formatOut), ': *started loading ground truth file'])
load([DataSetPath '\digitStruct.mat'], '-mat')
EndTime = now;
ElapsedSeconds = (EndTime-StartTime) * 24 * 60 * 60;
disp([datestr(EndTime,formatOut), ':  finished loading ground truth file in ', num2str(ElapsedSeconds), ' seconds'])

%% get points for CPU protocol by iterating through list of algorithms
for AlgoName = AlgoList
    StartTime = now;
    disp([datestr(StartTime,formatOut), ': *started processing dataset with ', AlgoName{1}, ' algorithm'])
 
    [temp1, temp2] = ProcessDataset('CPU', str2func(AlgoName{1}), ImageList, digitStruct);
    CostList(end+1) = temp1;
    AccuracyList(end+1) = temp2;
    LabelList{end+1} = AlgoName;
    
    EndTime = now;
    disp([datestr(EndTime,formatOut),':  evaluated accuracy is ',num2str(temp2), '% and cost is ',num2str(temp1), ' seconds'])
    ElapsedSeconds = (EndTime-StartTime) * 24 * 60 * 60;
    disp([datestr(EndTime,formatOut), ':  finished processing dataset in ', num2str(ElapsedSeconds), ' seconds'])
end

%% get points for CPU+HPU protocol
StartTime = now;
disp([datestr(StartTime,formatOut), ': *started processing dataset with joint algorithm ', JointAlgo, '+HPU'])
[temp1, temp2] = ProcessDataset('CPU+HPU', str2func(JointAlgo), ImageList, digitStruct);
CostList(end+1) = temp1;
AccuracyList(end+1) = temp2;
LabelList{end+1} = strcat(JointAlgo,'+HPU');
EndTime = now;
disp([datestr(EndTime,formatOut),':  evaluated accuracy is ',num2str(temp2), '% and cost is ',num2str(temp1), ' seconds'])
ElapsedSeconds = (EndTime-StartTime) * 24 * 60 * 60;
disp([datestr(EndTime,formatOut), ':  finished processing dataset in ', num2str(ElapsedSeconds), ' seconds'])

%% get points for HPU protocol
StartTime = now;
disp([datestr(now,formatOut), ': *started processing dataset with HPU'])
[temp1, temp2] = ProcessDataset('HPU', '', ImageList, digitStruct);
CostList(end+1) = temp1;
AccuracyList(end+1) = temp2;
LabelList{end+1} = 'HPU';
EndTime = now;
disp([datestr(EndTime,formatOut),':  evaluated accuracy is ',num2str(temp2), '% and cost is ',num2str(temp1), ' seconds'])
ElapsedSeconds = (EndTime-StartTime) * 24 * 60 * 60;
disp([datestr(EndTime,formatOut), ':  finished processing dataset in ', num2str(ElapsedSeconds), ' seconds'])

%% output

% draw plot
figure
scatter(CostList, AccuracyList, 'fill')
xlabel('Cost (seconds)');
ylabel('Accuracy (%)');

% override axis
xmin = 0;
xmax = max(CostList) * 1.1; % Adds 10% margin
ymin = 0;
ymax = 100;
axis([xmin, xmax, ymin, ymax])

% fill in labels
for i = 1:size(CostList')
    text(CostList(i), AccuracyList(i), strcat({'  '}, LabelList{i}))
end
disp([datestr(now,formatOut), ':  scatter-plot generated on Figure ',num2str(gcf)])

end