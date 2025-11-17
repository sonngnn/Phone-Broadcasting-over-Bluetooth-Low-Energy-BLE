function bitstream = file_to_bitstream_image(image_path, method)
    % Effacer l'affichage et libérer la mémoire
    clc; close all;
    if method == 1
        disp('Méthode 1 : Compression JPEG et transmission en flux de bits');
        % Charger l'image
        img = imread(image_path);
        
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
        intstream = fread(fileID, '*uint8');
        fclose(fileID);

        bitstream = my_de2bi(intstream(:),8,"right-msb");

        bitstream = bitstream(:);

    elseif method == 2
        disp('Méthode 2 : Conversion en flux binaire de chaque canal de couleur');
        % Charger l'image
        img = imread(image_path);
        img_gray = rgb2gray(img);

        % Conversion en vecteur binaire
        binaryStream_gray = dec2bin(img_gray(:), 8)';
        bitstream = (binaryStream_gray(:) - '0')';

    elseif method == 3
        fileID = fopen(image_path, 'r');
        byteStream = fread(fileID, '*uint8');
        bitstream = my_de2bi(byteStream(:), 8,"right-msb")';

        bitstream = bitstream(:);
        fclose(fileID);
    else
        disp('Choix invalide. Veuillez entrer 1, 2 ou 3.');
    end
end
