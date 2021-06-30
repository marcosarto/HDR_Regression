function [Aout,maxRGB,offset,alpha] = rgb2logluv(Ain)

if size(Ain,3) ~= 3
    fprintf('L''IMMAGINE NON E'' 3-D!!!\n');
    return;
end

Ain = double(Ain);
maxRGB = max(Ain(:));

varR = Ain(:,:,1)/maxRGB;
varG = Ain(:,:,2)/maxRGB;
varB = Ain(:,:,3)/maxRGB;

varR = 100*((varR > 0.04045) .* (((varR + 0.055)/1.055).^2.4) + (varR <= 0.04045) .* varR / 12.92);
varG = 100*((varG > 0.04045) .* (((varG + 0.055)/1.055).^2.4) + (varG <= 0.04045) .* varG / 12.92);
varB = 100*((varB > 0.04045) .* (((varB + 0.055)/1.055).^2.4) + (varB <= 0.04045) .* varB / 12.92);

X = varR*0.4124+varG*0.3576+varB*0.1805;
Y = varR*0.2126+varG*0.7152+varB*0.0722;
Z = varR*0.0193+varG*0.1192+varB*0.9505;

% X = Ain(:,:,1)*0.497+Ain(:,:,2)*0.339+Ain(:,:,3)*0.164;
% Y = Ain(:,:,1)*0.256+Ain(:,:,2)*0.678+Ain(:,:,3)*0.066;
% Z = Ain(:,:,1)*0.023+Ain(:,:,2)*0.113+Ain(:,:,3)*0.864;

x = X./(X+Y+Z);
y = Y./(X+Y+Z);
x(isnan(x)) = 0;
y(isnan(y)) = 0;

u = (Y~=0) .* (4*x./(-2*x+12*y+3)); % mai == NaN?
v = (Y~=0) .* (9*y./(-2*x+12*y+3));

%Aout(:,:,1) = (Y~=0) .* (log(Y)/log(2)+64)*256;
offset = ceil(abs(min(log2(Y(Y>0)))));
alpha = 2^15/(max(log2(Y(Y>0)))+offset);
Aout(:,:,1) = (Y>0) .* ((log2(Y)+offset)*alpha);
Aout(:,:,2) = u*32768;
Aout(:,:,3) = v*32768;
Aout(isnan(Aout)) = 0;

