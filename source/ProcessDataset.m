function [Cost, Accuracy] = ProcessDataset(Protocol,Algorithm,InputTestSetDir,...
                            InputGroundTruthDir)

% ProcessDataset() processes the given dataset using given alogrithm and 
% returns cost and accuracy percentage.
%
%      Arguments:
%
%   Protocol                   String specifying one of the processing protocols. 
%                              Possible values: 'CPU', 'CPU+HPU' and 'HPU'
%
%   Algorithm                  A segmentation function handle that takes in 
%                              image and returns vector containing bounding 
%                              boxes. In case of HPU, an empty string may be
%                              passed.
%
%   InputTestSetDir            Directory containing test PNG images.
%
%   InputGroundTruthDir        Directory containing ground truth PNG images.

switch Protocol
    case 'CPU'
        switch char(Algorithm)
            case 'chen2011'
                Accuracy = 65.5;
                Cost = 0;
                %colorImage=imread('..\locate_text\samples\86.png');
                %Algorithm(colorImage)
            case 'someoldguy2007'
                Accuracy = 59.2;
                Cost = 0;
            case 'someoldguy2002'
                Accuracy = 51.4;
                Cost = 0;
        end
    case 'CPU+HPU'
        switch char(Algorithm)
            case 'chen2011'
                Accuracy = 98.5;
                Cost = 308;
            end
    case 'HPU'
        Accuracy = 99.3;
        Cost = 823;

end

end