clear; clc; close all;

% PNG 파일 경로를 cell array로 저장
filenames = {'Cylinder_contour_Tmax.png', 'Cylinder_contour_Elp.png', 'Cylinder_contour_time.png', ...
             'Tubular_contour_Tmax.png', 'Tubular_contour_Elp.png', 'Tubular_contour_time.png'};

% 고화질 배율 설정 (예: 2배 해상도)
scaleFactor = 2;

% 이미지 읽기
images = cell(2, 3);
maxRows = 0;
maxCols = 0;

% 각 이미지의 크기와 최대 크기 찾기
for i = 1:6
    originalImage = imread(filenames{i});
    images{i} = imresize(originalImage, scaleFactor); % 고화질로 조정
    
    % 최대 크기 갱신
    [rows, cols, ~] = size(images{i});
    if rows > maxRows
        maxRows = rows;
    end
    if cols > maxCols
        maxCols = cols;
    end
end

% 이미지 간격 설정 (예: 20픽셀)
padding = 20;

% 최대 크기에 맞춰 흰색 배경의 빈 캔버스 생성 (배경을 흰색으로)
outputImage = 255 * ones(2*maxRows + padding, 3*maxCols + 2*padding, 3, 'uint8');

% 이미지 배열하기
for row = 1:2
    for col = 1:3
        % 현재 이미지 가져오기
        img = images{(row-1)*3 + col};
        [rows, cols, ~] = size(img);
        
        % 현재 이미지를 최대 크기로 패딩(확장)
        paddedImage = 255 * ones(maxRows, maxCols, 3, 'uint8'); % 흰색으로 패딩
        paddedImage(1:rows, 1:cols, :) = img;
        
        % 위치 계산 (간격 포함)
        rowStart = (row-1)*maxRows + (row-1)*padding + 1;
        rowEnd = row*maxRows + (row-1)*padding;
        colStart = (col-1)*maxCols + (col-1)*padding + 1;
        colEnd = col*maxCols + (col-1)*padding;
        
        % 패딩된 이미지 배치
        outputImage(rowStart:rowEnd, colStart:colEnd, :) = paddedImage;
    end
end

% 결과 이미지 저장 (고화질)
imwrite(outputImage, 'figure3.png', 'png', 'BitDepth', 16);
