% ׼��У׼ͼ��
numImages = 4;
files = cell(1, numImages);
for iImages = 1:numImages
    files{iImages} = fullfile('homework', sprintf('%d.png', iImages));
end

% �������������
[imagePoints, boardSize] = detectCheckerboardPoints(files);
squareSize = 100; % in millimeters ����ͼ��ʵ�ʳߴ�
worldPoints = generateCheckerboardPoints(boardSize, squareSize);
cameraParams = estimateCameraParameters(imagePoints, worldPoints);

% ����������׼ȷ��
figure; showReprojectionErrors(cameraParams);
title('�����ͶӰ���');
