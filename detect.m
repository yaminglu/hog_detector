clear; clc; close all;

addpath('libsvm');

BLOCK_SIZE = [32 32];
PATCH_SIZE = 4;
BINS = 8;
NORM_KERNEL_SIZE = 2;
DISPLAY = false;
STEP = 2;
TOLERANCE = 0.98;

I = rgb2gray(imread('samples/people.jpg'));

load('svm_model.mat', 'svm_model');
[m,p,g] = gradient(I);

last_y_index = BLOCK_SIZE(1) * (floor(size(I, 1) / BLOCK_SIZE(1)) - 1);
last_x_index = BLOCK_SIZE(2) * (floor(size(I, 2) / BLOCK_SIZE(2)) - 1);
x_range = 1:STEP:last_x_index;
y_range = 1:STEP:last_y_index;

f = figure;
detected_faces = [];
scores = [];
I_disp = cat(3, I, I, I);
fprintf("Processando");
for i = y_range
    for j = x_range
        b_hor = j:(j + BLOCK_SIZE(1) - 1);
        b_ver = i:(i + BLOCK_SIZE(2) - 1);
        
        if DISPLAY
            imshow(I_disp);
            hold on;
            rectangle('Position',[j i BLOCK_SIZE], 'EdgeColor', 'g');
            pause(0.0001);
        end
        
        block = I(b_ver, b_hor);
        hist = hog(block, PATCH_SIZE, BINS, NORM_KERNEL_SIZE);
        [label, accuracy, probability] = svmpredict(1, sparse(hist(:)'), svm_model, '-q -b 1');
        if label == 1 && probability(label + 1) > TOLERANCE
            rect = [i j BLOCK_SIZE];
            detected_faces = [detected_faces; rect];
            scores = [scores; probability(label + 1)];
            % Desenha um ret�ngulo amarelo
            I_disp = draw_rectangle(I_disp, [i, j], BLOCK_SIZE, [0, 0, 255]);
        end
    end
end

% Supress�o n�o-m�xima
[sorted_scores, indexes] = sort(scores, 'descend');
detected_faces = detected_faces(indexes, :);
supressed_indexes = zeros(1, size(detected_faces, 1));
for i = 1:size(detected_faces, 1)
    if supressed_indexes(i) == 0
        face = detected_faces(i, :);
        for j = 1: size(detected_faces, 1)
            if i ~= j
                intersection = rectint(detected_faces(j, :), face);
                union = 2 * prod(BLOCK_SIZE) - intersection;
                IoU = intersection / union;
                if IoU > 0.3
                    supressed_indexes(j) = 1;
                end
            end
        end
    end
end

fprintf("\nConclu�do\n");
I = cat(3, I, I, I);
for i = 1:length(supressed_indexes)
    if supressed_indexes(i) == 0
        face = detected_faces(i, 1:2);
        I = draw_rectangle(I, face, BLOCK_SIZE, [0, 0, 255]);
    end
end
imshow(I);