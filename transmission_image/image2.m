clc; clear; close all;

%% 1. Charger l'image
img = imread('sos.jpg'); 
figure, imshow(img), title('Image Originale');

% === Simuler la suppression aléatoire de pixels ===
mask = rand(size(img,1), size(img,2)) > 0.98;
mask_rgb = repmat(mask, [1, 1, 3]);
img(mask_rgb) = 0;

figure, imshow(img), title('Image avec Pixels Aléatoirement Supprimés');

%% 2. Prétraitement et extraction des zones d'intérêt

gray_img = rgb2gray(img);
smoothed_img = imgaussfilt(gray_img, 2);
threshold = graythresh(smoothed_img);
binary_img = imbinarize(smoothed_img, threshold);
binary_img = imclose(binary_img, strel('disk', 3));

figure, imshow(binary_img), title('Zones d\''interet détectées');

%% 3. Compression de l'image en JPEG
imwrite(binary_img, 'compressed_img.jpg', 'Quality', 50);

%% 4. Conversion en flux de bits
fileID = fopen('compressed_img.jpg', 'r');
bitstream = fread(fileID, '*uint8');
fclose(fileID);

% Affichage de la taille du flux de bits
disp(['Longueur du flux de bits : ', num2str(length(bitstream) * 8), ' bits']);

%% 5. Reconstruction de l'image
fileID = fopen('reconstructed_img.jpg', 'w');
fwrite(fileID, bitstream, 'uint8');
fclose(fileID);

% Chargement et affichage de l'image reconstruite
reconstructed_img = imread('reconstructed_img.jpg');
figure, imshow(reconstructed_img), title('Image Reconstituée');