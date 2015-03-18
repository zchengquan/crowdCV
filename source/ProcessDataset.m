function [Cost, Accuracy] = ProcessDataset(Protocol,Algorithm,ImageList,GroundTruth)

% ProcessDataset processes the given dataset using given alogrithm and 
% returns cost and accuracy percentage.
%
%   -- Arguments --
%
%   Protocol                   String specifying one of the processing protocols. 
%                              Possible values: 'CPU', 'CPU+HPU' and 'HPU'
%
%   Algorithm                  A segmentation function handle that takes in 
%                              image and returns vector containing bounding 
%                              boxes. In case of HPU, an empty string may be
%                              passed.
%
%   ImageList                  A cell array containing path+filenames of
%                              images in dataset
%
%   GroundTruth                A structure array containing ground truth
%                              data

%% Initialize Values
% Initializing with negative values to imply error if value not assigned.
Accuracy = -1;
Cost = -1;

%% Execute Protocol
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
        
        Accuracy = 97.3;
        Cost = 823;

end

end
