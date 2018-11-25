%%% UNIVERSIDADE FEDERAL DO CEAR�
%%% CAMPUS SOBRAL
%%% PROCESSAMENTO DIGITAL DE SINAIS 2018.2

%%% ABNER SOUSA NASCIMENTO 374864

function [ M, P, G ] = gradient( I )
%GRADIENT Calcula o gradiente de uma imagem e retorna a magnitude e a fase.
%   Os gradientes s�o calculados a partir da convolu��o dos operadores de
%   Sobel sobre a imagem. O resultado s�o os coeficientes horizontais e
%   verticais dos vetores. Ent�o, os equivalentes em coordenadas polares
%   (�ngulo e magnitude) s�o calculados e retornados pela fun��o.
%
%   Inputs:
%       I - Imagem em escala de cinzas.
%   
%   Outputs:
%       M - Magnitude dos gradientes.
%       P - �ngulo dos gradientes em rela��o ao semi-eixo x > 0.
%       G - Coordenadas ortogonais dos vetores gradiente.

% Filtros de Sobel
sobel_x = [-1 0 1; -2 0 2; -1 0 1];
sobel_y = [1 2 1; 0 0 0; -1 -2 -1];

% Convolu��o 2D dos filtros de Sobel
G = cat(3, conv2(I, sobel_x, 'same'), conv2(I, sobel_y, 'same'));

% Magnitude dos vetores
M = sqrt(sum(G.^2, 3));

% Fase dos vetores
P = atan2(G(:,:,2), G(:,:,1));

end

