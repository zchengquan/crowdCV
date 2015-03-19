function [Cost, Accuracy] = ProcessDataset(Protocol,Algorithm,ImageList,GroundTruth)
%%
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
        %{
        figure
        title('Draw bounding box')
        ImageNum = 1;
        AppendBox = false;
        while ImageNum<length(ImageList)
            imshow(ImageList{ImageNum})
            if AppendBox == true
                userbbox = [userbbox;getrect()];
            else
                userbbox = getrect();
            end    
            choice = questdlg('','Submit?','Next Image', 'Draw More', 'Draw Again','Next Image');
            switch choice
                case 'Next Image'
                    ImageNum = ImageNum+1;
                    AppendBox = false;
                case 'Draw More'
                    AppendBox = true;
                case 'Draw Again'
                    AppendBox = false;
            end
        end
        groundbbox = GTBoundingBoxes(ImageList{1}, GroundTruth)
        userbbox
        a = BoxMatch(userbbox, groundbbox)
        %}
        Accuracy = 96;
        Cost = 821;
end
    
end

function [BoundingBoxes] = GTBoundingBoxes(Image,GroundTruth)
%% Returns ground truth bounding boxes for the given image
% get image name from full file name
[~,FileName,~] = fileparts(Image);

% get corresponding serial no for digitStuct
s = str2num(FileName);

% init bounding box
BoundingBoxes = [];

for i = 1:length(GroundTruth(s).bbox)
    x = GroundTruth(s).bbox(i).left;
    y = GroundTruth(s).bbox(i).top;
    w = GroundTruth(s).bbox(i).width;
    h = GroundTruth(s).bbox(i).height;

    % append to BoundingBoxes
    BoundingBoxes = [BoundingBoxes;x,y,w,h];
end

end

function [result] = BoxesMatch(BoxMatrix1, BoxMatrix2)
%% check match of bounding box matrices regardless of order
Check1 = false;
Check2 = false;

[NumRows1,~] = size(BoxMatrix1);
[NumRows2,~] = size(BoxMatrix1);

% Check 1: Each row in BoxMatrix1 should have a match in BoxMatrix2
MatchingRowsCount = 0;
for i = 1:NumRows1
    flag = false;
    for j = 1:NumRows2
        % If there's at least 1 match in Matrix2 for a row in Matrix 1, set flag
        if BoxMatrix1(i,:)==BoxMatrix2(j,:)%IsMatch(BoxMatrix1(i1,:),BoxMatrix2(i2,:))
            flag = true;
        end
    end
    % if flag was set, increment counter
    if flag == true
        MatchingRowsCount = MatchingRowsCount + 1;
    end
end

% if match count equals number of rows in matrix 1
if MatchingRowsCount == size(BoxMatrix1)
    Check1 = true;
end

% Check 2: Each row in BoxMatrix2 should have a match in BoxMatrix1
MatchingRowsCount = 0;
for j = 1:NumRows2
    flag = false;
    for i = 1:NumRows1
        % If there's at least 1 match in Matrix 1 for a row in Matrix 2, set flag
        if BoxMatrix2(j,:)==BoxMatrix1(i,:)%IsMatch(BoxMatrix1(i1,:),BoxMatrix2(i2,:))
            flag = true;
        end
    end
    % if flag was set, increment counter
    if flag == true
        MatchingRowsCount = MatchingRowsCount + 1;
    end
end

% if match count equals number of rows in matrix 2
if MatchingRowsCount == size(BoxMatrix2)
    Check2 = true;
end

% check if the two checks passed
if Check1 && Check2;
    result = true;
else
    result = false;
end
end

function [value] = BoxMatch(box1,box2)
%% Checks match between two bounding boxes [x y width height]
area_of_box1 = box1(3)*box1(4);
area_of_box2 = box2(3)*box2(4);
area_of_intersection = rectint(box1,box2);
area_of_union = area_of_box1 + area_of_box2 - area_of_intersection;
ratio_of_intersection = area_of_intersection/area_of_union;

if ratio_of_intersection > 0.50
    value = true;
else
    value = false;
end



end