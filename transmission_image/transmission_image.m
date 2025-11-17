function transmission_image(image_path, method)
    % Effacer l'affichage et libérer la mémoire
    clc; close all;
    
    % Charger l'image
    img = imread(image_path);
    figure, imshow(img), title('Image Originale');
    
    if method == 1
        disp('Méthode 1 : Compression JPEG et transmission en flux de bits');
        
        % Convertir l'image en niveaux de gris et prétraitement
        gray_img = rgb2gray(img);
        smoothed_img = imgaussfilt(gray_img, 2);
        threshold = graythresh(smoothed_img);
        binary_img = imbinarize(smoothed_img, threshold);
        binary_img = imclose(binary_img, strel('disk', 3));

        figure, imshow(binary_img), title('Zones d''intérêt détectées');

        % Compression JPEG
        imwrite(binary_img, 'compressed_img.jpg', 'Quality', 50);

        % Conversion en flux de bits
        fileID = fopen('compressed_img.jpg', 'r');
        bitstream = fread(fileID, '*uint8');
        fclose(fileID);

        % Affichage de la taille du flux de bits
        disp(['Longueur du flux de bits : ', num2str(length(bitstream) * 8), ' bits']);

        % Reconstruction de l'image
        fileID = fopen('reconstructed_img.jpg', 'w');
        fwrite(fileID, bitstream, 'uint8');
        fclose(fileID);

        % Chargement et affichage de l'image reconstruite
        reconstructed_img = imread('reconstructed_img.jpg');
        figure, imshow(reconstructed_img), title('Image Reconstituée');
        
    elseif method == 2
        disp('Méthode 2 : Conversion en flux binaire de chaque canal de couleur');

        % Séparation des canaux de couleur
        img_r = img(:,:,1);
        img_g = img(:,:,2);
        img_b = img(:,:,3);

        % Conversion en vecteur binaire
        binaryStream_r = dec2bin(img_r(:), 8)';
        binaryStream_g = dec2bin(img_g(:), 8)';
        binaryStream_b = dec2bin(img_b(:), 8)';

        % Concatenation des canaux
        binaryStream = [binaryStream_r(:); binaryStream_g(:); binaryStream_b(:)] - '0';

        % Sauvegarde du flux binaire
        fileID = fopen('image_bits.bin', 'w');
        fwrite(fileID, binaryStream, 'ubit1');
        fclose(fileID);

        disp('Flux binaire de l''image sauvegardé dans "image_bits.bin".');

        % Reconstruction de l'image
        fileID = fopen('image_bits.bin', 'r');
        binaryStream = fread(fileID, 'ubit1');
        fclose(fileID);

        % Nombre total de pixels
        totalPixels = numel(img(:,:,1));

        % Reconstruction des canaux de couleur
        binaryMatrix_r = reshape(binaryStream(1:totalPixels*8), 8, []).';
        binaryMatrix_g = reshape(binaryStream(totalPixels*8+1:2*totalPixels*8), 8, []).';
        binaryMatrix_b = reshape(binaryStream(2*totalPixels*8+1:end), 8, []).';

        % Conversion binaire vers valeurs de pixels
        img_r = uint8(bin2dec(num2str(binaryMatrix_r)));
        img_g = uint8(bin2dec(num2str(binaryMatrix_g)));
        img_b = uint8(bin2dec(num2str(binaryMatrix_b)));

        % Reconstruction de l'image couleur
        img_reconstructed = cat(3, reshape(img_r, size(img,1), size(img,2)), ...
                                   reshape(img_g, size(img,1), size(img,2)), ...
                                   reshape(img_b, size(img,1), size(img,2)));

        % Affichage de l'image reconstruite
        figure, imshow(img_reconstructed), title('Image couleur reconstruite');
        disp('Reconstruction de l''image couleur terminée avec succès.');
    else
        disp('Choix invalide. Veuillez entrer 1 ou 2.');
    end
end
