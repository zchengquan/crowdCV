function Main(TestImageSetPath, GroundTruthPath)

% Enter list of CPU algorithm files/functions as cells.
AlgoList = {'someoldguy2002','someoldguy2007','chen2011'};

% Set CPU algorithm to be used in CPU+HPU joint algorithm
JointAlgo = 'chen2011';

% Initialize accuracy, cost and point label vectors
CostList = [];
AccuracyList = [];
LabelList = [];

formatOut = 'HH:MM:SS:FFF dd-mmm-yy';
disp([datestr(now,formatOut), ': begin program'])

% Get points for CPU protocol
for AlgoName = AlgoList
    disp([datestr(now,formatOut), ': started processing dataset with ', AlgoName{1}, ' algorithm'])
    [temp1, temp2] = ProcessDataset('CPU', str2func(AlgoName{1}), TestImageSetPath, GroundTruthPath);
    CostList(end+1) = temp1;
    AccuracyList(end+1) = temp2;
    LabelList{end+1} = AlgoName;
    disp([datestr(now,formatOut), ': ended processing'])
end

% Get points for CPU+HPU protocol
disp([datestr(now,formatOut), ': started processing dataset with joint algorithm ', JointAlgo, '+HPU'])
[temp1, temp2] = ProcessDataset('CPU+HPU', str2func(JointAlgo), TestImageSetPath, GroundTruthPath);
CostList(end+1) = temp1;
AccuracyList(end+1) = temp2;
LabelList{end+1} = strcat(JointAlgo,'+HPU');
disp([datestr(now,formatOut), ': ended processing'])

% Get points for HPU protocol
disp([datestr(now,formatOut), ': started processing dataset with HPU'])
[temp1, temp2] = ProcessDataset('HPU', '', TestImageSetPath, GroundTruthPath);
CostList(end+1) = temp1;
AccuracyList(end+1) = temp2;
LabelList{end+1} = 'HPU';
disp([datestr(now,formatOut), ': ended processing'])

% Output

% Draw plot
scatter(CostList, AccuracyList, 'fill')
xlabel('Cost (seconds)');
ylabel('Accuracy (%)');

% Fill in labels
for I = 1:size(CostList')
    text(CostList(I), AccuracyList(I), strcat({'  '}, LabelList{I}))
end

end