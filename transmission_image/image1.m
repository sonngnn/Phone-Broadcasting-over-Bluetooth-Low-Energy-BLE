clc; clear; close all;

%% I) Processus : décomposition de l'image 
%% 1. Charger l'image
img = imread('sos.jpg');

%% 2. Séparation des canaux de couleur
img_r = img(:,:,1);
img_g = img(:,:,2);
img_b = img(:,:,3);

%% 3. Conversion en vecteur binaire pour chaque canal
binaryStream_r = dec2bin(img_r(:), 8)';
binaryStream_g = dec2bin(img_g(:), 8)';
binaryStream_b = dec2bin(img_b(:), 8)';

%% 4. Concatenation des canaux
binaryStream = [binaryStream_r(:); binaryStream_g(:); binaryStream_b(:)] - '0';

%% 5. Sauvegarde du flux binaire dans un fichier
fileID = fopen('image_bits.bin', 'w');
fwrite(fileID, binaryStream, 'ubit1');
fclose(fileID);

% Affichage
disp('Flux binaire de l''image sauvegardé dans "image_bits.bin".');

%% II) Processus inverse : Reconstitution de l'image

%% 1. Lecture du fichier contenant le flux binaire
fileID = fopen('image_bits.bin', 'r');
binaryStream = fread(fileID, 'ubit1');
fclose(fileID);

% Nombre total de pixels
totalPixels = numel(img(:,:,1));

%% 2. Reconstruction des canaux de couleur
binaryMatrix_r = reshape(binaryStream(1:totalPixels*8), 8, []).';
binaryMatrix_g = reshape(binaryStream(totalPixels*8+1:2*totalPixels*8), 8, []).';
binaryMatrix_b = reshape(binaryStream(2*totalPixels*8+1:end), 8, []).';

%% 3. Conversion binaire → valeurs de pixels
img_r = uint8(bin2dec(num2str(binaryMatrix_r)));
img_g = uint8(bin2dec(num2str(binaryMatrix_g)));
img_b = uint8(bin2dec(num2str(binaryMatrix_b)));

%% 4. Reconstruction de l'image couleur
img_reconstructed = cat(3, reshape(img_r, size(img,1), size(img,2)), ...
                           reshape(img_g, size(img,1), size(img,2)), ...
                           reshape(img_b, size(img,1), size(img,2)));

%% 5. Affichage de l'image reconstruite
imshow(img_reconstructed);
title('Image couleur reconstruite');

disp('Reconstruction de l''image couleur terminée avec succès.');