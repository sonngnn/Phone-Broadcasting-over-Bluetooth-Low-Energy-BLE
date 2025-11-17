% function g = GMSK_gaussian_filter(T, sps)
%     BT = 0.5;  % Produit bande × symbole, typique pour GMSK
%     t  = (-1.5*T:T/sps:1.5*T);
% 
%     alpha = sqrt(log(2)) / (BT * T);
%     g = (sqrt(pi) / alpha) * exp(- (pi^2 * t.^2) / (alpha^2));
% 
%     % Normalisation en énergie
%     g = g / sum(g);
% end

function result = GMSK_gaussian_filter(T,sps)
    t = (-1.5*T:T/sps:1.5*T); 
    BT = 0.5; % T=1

    h = (BT.*sqrt((2*pi)/log(2))).*exp((-1*(((2*pi^2)*(BT.^2))).*t.^2)./log(2)); 
    % need to scale the filter, so that there is a phase change of pi/2 for
    % every bit change.

    %K = pi/2/sum(h);
    %gfilter = K*h;
    gfilter = h;

    %normalize filter gain.
    gfilter = gfilter./sqrt(sum(gfilter));

    %figure;plot(gfilter);title('gaussian filter');
    result = gfilter;

end