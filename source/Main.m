function Main(DataSetPath, AlgoList, JointAlgo)

% Plots the Cost vs Accuracy of given algorithms, a chosen algorithm + HPU 
% and HPU to find cost and performance.
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

%% Initialize accuracy, cost and point label vectors
CostList = [];
AccuracyList = [];
LabelList = [];

formatOut = 'HH:MM:SS:FFF dd-mmm-yy';
disp([datestr(now,formatOut), ': begin program'])

%% Get points for CPU protocol by iterating through list of algorithms
for AlgoName = AlgoList
    disp([datestr(now,formatOut), ': started processing dataset with ', AlgoName{1}, ' algorithm'])
    [temp1, temp2] = ProcessDataset('CPU', str2func(AlgoName{1}), DataSetPath);
    CostList(end+1) = temp1;
    AccuracyList(end+1) = temp2;
    LabelList{end+1} = AlgoName;
    disp([datestr(now,formatOut), ': finished processing dataset'])
end

%% Get points for CPU+HPU protocol
disp([datestr(now,formatOut), ': started processing dataset with joint algorithm ', JointAlgo, '+HPU'])
[temp1, temp2] = ProcessDataset('CPU+HPU', str2func(JointAlgo), DataSetPath);
CostList(end+1) = temp1;
AccuracyList(end+1) = temp2;
LabelList{end+1} = strcat(JointAlgo,'+HPU');
disp([datestr(now,formatOut), ': finished processing dataset'])

%% Get points for HPU protocol
disp([datestr(now,formatOut), ': started processing dataset with HPU'])
[temp1, temp2] = ProcessDataset('HPU', '', DataSetPath);
CostList(end+1) = temp1;
AccuracyList(end+1) = temp2;
LabelList{end+1} = 'HPU';
disp([datestr(now,formatOut), ': finished processing dataset'])

%% Output

% Draw plot
scatter(CostList, AccuracyList, 'fill')
xlabel('Cost (seconds)');
ylabel('Accuracy (%)');

% Fill in labels
for I = 1:size(CostList')
    text(CostList(I), AccuracyList(I), strcat({'  '}, LabelList{I}))
end

end