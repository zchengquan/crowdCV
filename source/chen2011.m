function [boundingBoxes,segmentedCharacterMask] = chen2011(I,varargin)
% chen2011 find text regions in an image.
%
%   boundingBoxes = chen2011(I) returns a list of bounding boxes
%   containing text regions. It is specified as a M-by-4 matrix, where each
%   bounding box is of the form [x y width height]. I is a true color or
%   grayscale image.
%
%   [boundingBoxes,segmentedCharacterMask] = chen2011(I) optionally
%   returns segmentedCharacterMask, a binary image of the same size as I.
%   Every connected component in this mask is a character candidate. This
%   allows for additional processing or Optical Character Recognition.
%
%   [...]=chen2011(..., Name, Value) Additionally allows you to set
%   the following parameters.
%
%   'TextPolarity'             A string to specify the polarity of the text
%                              'LightTextOnDark' or 'DarkTextOnLight'.
%
%                              Default: 'LightTextOnDark'
%
%   'SizeRange'                Two-element vector, [minArea maxArea]
%                              Minimum and maximum allowed size of a text
%                              region. Depends on image resolution.
%
%                              Default: [50,5000]
%
%   'MaxEccentricity'          Positive scalar between 0 and 1. Maximum
%                              allowed eccentricity of a text region.
%                              Eccentricity is a scalar that specifies the
%                              eccentricity of the ellipse that has the
%                              same second-moments.
%
%                              Default: 0.99
%
%   'MaxStrokeWidthVariation'  Positive scalar. Maximum allowed coefficient
%                              of variation (standard deviation divided by 
%                              mean) of the stroke width of a text region
%
%                              Default: 0.35
%
%   'SolidityRange'            Two-element vector, [minSolidity maxSolidity]
%                              Minimum and maximum allowed solidity of a
%                              text region. Solidity is between 0 and 1 and
%                              specifies the proportion of the pixels in
%                              the convex hull of a region that are also in
%                              the region.
%                               
%                              Only computes solidity if range is not [0,1].
%                              
%                              Default: [0,1]
%
%   'MorphologyOpenRadius'     Positive integer. Specify a radius for a 
%                              morphological open. Allows optional grouping 
%                              of text candidates using morphology. A  
%                              morphological open operation is performed 
%                              followed by a morphological close. The 
%                              final regions are returned as bounding boxes.
%
%                              Default: 25
%
%   'MorphologyCloseRadius'    Positive integer. Specify a radius for a 
%                              morphological close. Allows optional grouping 
%                              of text candidates using morphology. A  
%                              morphological open operation is performed 
%                              followed by a morphological close. The 
%                              final regions are returned as bounding boxes.
%
%                              Default: 7

% References
%
% [1] Chen, Huizhong, et al. "Robust Text Detection in Natural Images with
%     Edge-Enhanced Maximally Stable Extremal Regions." Image Processing
%     (ICIP), 2011 18th IEEE International Conference on. IEEE, 2011.

% Parse inputs
[SizeRange, MaxEccentricity, MaxStrokeWidthVariation,SolidityRange,...
    MorphologyOpenRadius,MorphologyCloseRadius,TextPolarity] ...
    = parseInputs(varargin{:});

% Detect MSER Regions

regions = detectMSERFeatures(rgb2gray(I),'RegionAreaRange',...
    [SizeRange(1) SizeRange(2)*5]);
mserPixels = vertcat(cell2mat(regions.PixelList)); % Extract regions
mserMask = false(size(I,1),size(I,2)); % Build binary image
ind = sub2ind(size(mserMask),mserPixels(:,2),mserPixels(:,1));
mserMask(ind)=true;

% Compute Canny Edges

cannyEdgesMask = edge(rgb2gray(I),'Canny');
cannyEdgesinMSERRegionsMask = cannyEdgesMask & mserMask; % Only using edges that fall in regions

% Use Canny to Segment MSER Regions

% Calculate gradient image
[~, Gdir] = imgradient(rgb2gray(I));
% Calculate gradient grown edge image
gradientGrownEdgesMask =  ...
    helperGrowEdges(cannyEdgesinMSERRegionsMask,Gdir,TextPolarity);
edgeEnhancedMSERMask = ~gradientGrownEdgesMask&mserMask; % Remove Gradient Grown Edge pixels

% Step 5: Filter Text Candidates Using Connected Component Analysis

afterGeometricFiltersMask = edgeEnhancedMSERMask; % start with previous result
% Remove points that geometric parameters
connComp = bwconncomp(edgeEnhancedMSERMask); % Find Connected components

% Only calculate solidity if necessary
if SolidityRange(1) == 0 && SolidityRange(2) == 1
    stats = regionprops(connComp,'Area','Eccentricity');
else
    stats = regionprops(connComp,'Area','Eccentricity','Solidity');
    solidities = [stats.Solidity];
    afterGeometricFiltersMask(vertcat(connComp.PixelIdxList{...
        solidities < SolidityRange(1) | solidities > SolidityRange(2)})) = 0;
end
eccentricities = [stats.Eccentricity];
afterGeometricFiltersMask(vertcat(connComp.PixelIdxList{...
    eccentricities > MaxEccentricity})) = 0;
areas = [stats.Area];
afterGeometricFiltersMask(vertcat(connComp.PixelIdxList{...
    areas < SizeRange(1) | areas > SizeRange(2)})) = 0;

% Step 6: Filter Text Candidates Using The Stroke Width Image

% Find remaining connected components
connComp = bwconncomp(afterGeometricFiltersMask);
afterStrokeWidthFilterMask = afterGeometricFiltersMask;
distanceImage = bwdist(~afterGeometricFiltersMask);  % Compute Distance Transform
strokeWidthImage = helperStrokeWidth(distanceImage); % Compute Stroke Width
for i = 1:connComp.NumObjects
    strokewidths = strokeWidthImage(connComp.PixelIdxList{i});
    % Compute coefficient of variation and compare to parameter
    if std(strokewidths)/mean(strokewidths)>MaxStrokeWidthVariation
        % Remove from text candidates
        afterStrokeWidthFilterMask(connComp.PixelIdxList{i}) = 0;
    end
end
segmentedCharacterMask=afterStrokeWidthFilterMask; % return text candidates

% Step 7: Combine Text Candidates Using Morphology

se1 = strel('disk',MorphologyOpenRadius);
se2 = strel('disk',MorphologyCloseRadius);
afterMorphologyMask = imclose(afterStrokeWidthFilterMask,se1);
afterMorphologyMask = imopen(afterMorphologyMask,se2);

% Step 8: Segment Large Regions from the Image

connComp = bwconncomp(afterMorphologyMask);
stats = regionprops(connComp,'BoundingBox','Area');
if MorphologyOpenRadius ~= 0;
    boundingBoxes = round(vertcat(stats(vertcat(stats.Area) > SizeRange(2)).BoundingBox));
else
    boundingBoxes = round(vertcat(stats.BoundingBox));
end


%==========================================================================
% Parse input
%==========================================================================
    function [SizeRange, MaxEccentricity, MaxStrokeWidthVariation,...
            SolidityRange,MorphologyOpenRadius,MorphologyCloseRadius,TextPolarity] = parseInputs(varargin)
        % Setup parser
        parser = inputParser;
        parser.CaseSensitive = true;
        parser.FunctionName  = 'chen2011';
        
        parser.addParamValue('SizeRange', [50,5000]);
        parser.addParamValue('MaxEccentricity', 0.99);
        parser.addParamValue('MaxStrokeWidthVariation',  0.35);
        parser.addParamValue('SolidityRange',  [0,1]);
        parser.addParamValue('MorphologyOpenRadius',  25);
        parser.addParamValue('MorphologyCloseRadius',  7);
        parser.addParamValue('TextPolarity','LightTextOnDark');
        
        % Parse input
        parser.parse(varargin{:});
        
        % Assign outputs
        r = parser.Results;
        [SizeRange, MaxEccentricity, MaxStrokeWidthVariation,SolidityRange,...
            MorphologyOpenRadius,MorphologyCloseRadius,TextPolarity] = ...
            deal(r.SizeRange, r.MaxEccentricity, r.MaxStrokeWidthVariation,...
            r.SolidityRange, r.MorphologyOpenRadius,r.MorphologyCloseRadius,...
            r.TextPolarity);
    end

end

function GradientGrownEdgesMask = helperGrowEdges(Edges,GradientDirection,TextPolarity)
% helperGrowEdges Grow edges along or opposite to gradients
%   This function helperGrowEdges is in support of chen2011.
%
%   GradientGrownEdgesMask =
%   helperGrowEdges(Edges,GradientDirection,TextPolarity) Aysymmetrically
%   dilates binary image edges in the direction specified by
%   gradientDirection. TextPolarity is a string specifying whether to grow
%   along or opposite the gradientDirection, 'LightTextOnDark' or
%   'DarkTextOnLight', respectively.

% Quantize to 8 cardinal and ordinal directions
GrowthDirection=round((GradientDirection + 180) / 360 * 8); 
GrowthDirection(GrowthDirection == 0) = 8;

if strcmp('DarkTextOnLight',TextPolarity) % Reverse growth direction for dark text
    GrowthDirection=mod(GrowthDirection + 3, 8) + 1;
end
% Build structuring elements

% Structuring element template to grow edges diagonally
northwestTemplate = ...
    [1,1,1,1,1,0,0;...
    1,1,1,1,1,0,0;...
    1,1,1,1,1,0,0;...
    1,1,1,1,0,0,0;...
    1,1,1,0,0,0,0;... 
    zeros(2,7)];

% Structuring element template to grow edges horizontally and vertically
northTemplate = ...
    [0,1,1,1,1,1,0;... 
    0,1,1,1,1,1,0;...
    0,1,1,1,1,1,0;...
    0,1,1,1,1,1,0;...
    zeros(3,7)];

% Each structuring element is a rotation of the element templates
N = strel(northTemplate);
W = strel(rot90(northTemplate,1));
S = strel(rot90(northTemplate,2));
E = strel(rot90(northTemplate,3));

NW = strel(northwestTemplate);
SW = strel(rot90(northwestTemplate));
SE = strel(rot90(northwestTemplate,2));
NE = strel(rot90(northwestTemplate,3));

Strels = [NE,N,NW,W,SW,S,SE,E];

% Initialize mask
GradientGrownEdgesMask = false(size(Edges));

% Use structuring element to grow Edges along each gradient direction
for i = 1:numel(Strels)
    BWCurrentDirection = false(size(Edges));
    BWCurrentDirection(Edges == true & GrowthDirection == i ) = true;
    BWCurrentDirection = imdilate(BWCurrentDirection,Strels(i));
    GradientGrownEdgesMask = GradientGrownEdgesMask | BWCurrentDirection;
end

end

function strokeWidthImage = helperStrokeWidth(DistanceImage)
% helperStrokeWidth Transforms distance image into stroke width image
%   This function helperStrokeWidth is only in support of chen2011
%
%   StrokeWidthImage = helperStrokeWidth(DistanceImage);
%   returns a Stroke Width Image computed from DistanceImage, containing a
%   value for stroke width at each non-zero pixel in the DistanceImage.
%   DistanceImage is a Euclidean distance transform of a binary image
%   computed by bwdist.
%

% References
%
% [1] Chen, Huizhong, et al. "Robust Text Detection in Natural Images with
%     Edge-Enhanced Maximally Stable Extremal Regions." Image Processing
%     (ICIP), 2011 18th IEEE International Conference on. IEEE, 2011.

DistanceImage = round(DistanceImage); % bins distances into integer values for comparison

% Define 8-connected neighbors
connectivity = [ 1 0; -1 0; 1 1; 0 1; -1 1; 1 -1; 0 -1; -1 -1]';

% Create padded version of distance image for matrix-wise neighbors comparison
paddedDistanceImage = padarray(DistanceImage,[1,1]);
Dind = find(paddedDistanceImage ~= 0);
sz=size(paddedDistanceImage);

% Compare whether eight neighbors are less than current pixel for all
% pixels in image
neighborIndices = repmat(Dind,[1,8]);
[I,J] = ind2sub(sz,neighborIndices);
I = bsxfun(@plus,I,connectivity(1,:));
J = bsxfun(@plus,J,connectivity(2,:));
neighborIndices = sub2ind(sz,I,J);
lookup = bsxfun(@lt,paddedDistanceImage(neighborIndices),paddedDistanceImage(Dind));
lookup(paddedDistanceImage(neighborIndices) == 0) = false;

% Propagate local maximum stroke values to neighbors recursively
maxStroke = max(max(paddedDistanceImage));
for Stroke = maxStroke:-1:1
    neighborIndextemp = ...
        neighborIndices(paddedDistanceImage(Dind) == Stroke,:);
    lookupTemp = lookup(paddedDistanceImage(Dind) == Stroke,:);
    neighborIndex = neighborIndextemp(lookupTemp);
    while ~isempty(neighborIndex)
        paddedDistanceImage(neighborIndex) = Stroke;       
        [~,ia,~] = intersect(Dind,neighborIndex);
        neighborIndextemp = neighborIndices(ia,:);
        lookupTemp = lookup(ia,:);
        neighborIndex = neighborIndextemp(lookupTemp);
    end
end

% Remove pad to restore original image size
strokeWidthImage = paddedDistanceImage(2:end-1,2:end-1);

end