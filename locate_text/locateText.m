function [boundingBoxes,segmentedCharacterMask] = helperDetectText(I,varargin)
% helperDetectText find text regions in an image
%
%   boundingBoxes = helperDetectText(I) returns a list of bounding boxes
%   containing text regions. It is specified as a M-by-4 matrix, where each
%   bounding box is of the form [x y width height]. I is a true color or
%   grayscale image.
%
%   [boundingBoxes,segmentedCharacterMask] = helperDetectText(I) optionally
%   returns segmentedCharacterMask, a binary image of the same size as I.
%   Every connected component in this mask is a character candidate. This
%   allows for additional processing or Optical Character Recognition.
%
%   [...]=helperDetectText(..., Name, Value) Additionally allows you to set
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
        parser.FunctionName  = 'helperDetectText';
        
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