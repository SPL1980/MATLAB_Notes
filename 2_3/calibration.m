% ׼��У׼ͼ��
numImages = 4;
numLiquidColumn = 8;
files = cell(1, numImages);
for iImages = 1:numImages
    files{iImages} = fullfile(sprintf('%d.png', iImages));
end
% Display one of the calibration images

% �������������
[imagePoints, boardSize] = detectCheckerboardPoints(files);
squareSize = 29; % in millimeters ����ͼ��ʵ�ʳߴ�
worldPoints = generateCheckerboardPoints(boardSize, squareSize);
cameraParams = estimateCameraParameters(imagePoints, worldPoints);
% Evaluate calibration accuracy.
figure; showReprojectionErrors(cameraParams);
title('���ͶӰ���');

% ��ȡҪ�����Ķ����ͼ��
imOrig = imread(files{2});
[im, newOrigin] = undistortImage(imOrig, cameraParams, 'OutputView', 'full');

% ʹ��ͼ��� HSV ��ʾ�ı��ͷ������ָ��ѹ�ܡ�
imHSV = rgb2hsv(im);
saturation = imHSV(:, :, 2);
t = graythresh(saturation);
imCoin = (saturation > t);
figure; imshow(imCoin, 'InitialMagnification', 'fit');
title('�ڰ׷ָ�ͼ');

% 4���Ӳ��
% Find connected components.
blobAnalysis = vision.BlobAnalysis('AreaOutputPort', true, ...
    'CentroidOutputPort', false, 'BoundingBoxOutputPort', true, ...
    'MaximumCount',numLiquidColumn,'MinimumBlobArea', 20, ...
    'ExcludeBorderBlobs', true);

%{
AreaOutputPort��CentroidOutputPort��BoundingBoxOutputPort
Ĭ��Ϊtrue����ʾ�����[AREA,CENTROID,BBOX]
MajorAxisLengthOutputPort��MinorAxisLengthOutputPort��OrientationOutputPort��EccentricityOutputPort��
EquivalentDiameterSquaredOutputPort��ExtentOutputPort��PerimeterOutputPort��LabelMatrixOutputPort

һЩ�������������Ĭ��Ϊfalse
OutputDataType��Ĭ��double������������ݵĸ�ʽ�������� double, single, or Fixed point
Connectivity��Ĭ��8��������Щ���ص������ӵģ���ѡ4��8���㶮�ģ�һ��С��������Χ��8��С�����Ρ�
MaximumCount��Ĭ��50�����ͣ�Maximum number of labeled regions in each input image��ÿ��ͼ���������������Ҳ����ʶ�𵽵��˶����������
MinimumBlobArea��Ĭ��0�����ͣ�Minimum blob area in pixels��������С�����ռ���ٸ����أ���
MaximumBlobArea��Ĭ��Ϊ����������intmax('uint32')
Maximum blob area in pixels������ռ������������λ���أ�
�����������Կ��Կ���ʶ�𵽵������С���Ѳ���ʶ�𵽵�ɸѡ��ȥ��
ExcludeBorderBlobs��Ĭ��false
Exclude blobs that contain at least one border pixel
Set this property to true if you do not want to label blobs that contain at least one border pixel.
�ų����б߽������
    %}
    
[areas, boxes] = step(blobAnalysis, imCoin);
% Sort connected components in descending order by area
[~, idx] = sort(areas, 'Descend');
% Get the two largest components.
boxes = double(boxes(idx(1:numLiquidColumn), :));
% Adjust for coordinate system shift caused by undistortImage
boxes(:, 1:2) = bsxfun(@plus, boxes(:, 1:2), newOrigin);
% �����ѹ�ܱ�ǩ
imDetectedCoins = insertObjectAnnotation(im, ...
    'rectangle', boxes, 'Liquid column');
figure; imshow(imDetectedCoins, 'InitialMagnification', 'fit');
title('���Һ��');

% ���� Extrinsics
% Detect the checkerboard.
[imagePoints, boardSize] = detectCheckerboardPoints(im);
% Compute rotation and translation of the camera.
[R, t] = extrinsics(imagePoints, worldPoints, cameraParams);

%������ѹ�ܸ߶�
% Get the top-left and the top-right corners.
for iLiquidColumn = 1:numLiquidColumn
    boxj = double(boxes(iLiquidColumn, :));
    imagePointsLiquidColumn = [boxj(1:2);boxj(1) + boxj(3), boxj(2)];
    % Get the world coordinates of the corners
    worldPointsLiquidColumn = pointsToWorld(cameraParams, R, t, imagePointsLiquidColumn);
    % Compute the diameter of the coin in millimeters.
    d = worldPointsLiquidColumn(2, :) - worldPointsLiquidColumn(1, :);
    diameterInMillimeters = hypot(d(1), d(2));
    fprintf('������ѹ��%d�ĸ߶�= %0.2f mm\n', iLiquidColumn,diameterInMillimeters);
end

