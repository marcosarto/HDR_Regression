function Aout = logluv2rgb(Ain,maxRGB,offset,alpha)

if size(Ain,3) ~= 3
    fprintf('L''IMMAGINE NON E'' 3-D!!!\n');
    return;
end

Ain = double(Ain);

Y = 2.^(Ain(:,:,1)/alpha-offset);
Y(Ain(:,:,1)==0) = 0;
u = Ain(:,:,2)/32768;
v = Ain(:,:,3)/32768;

x = 9*u./(6*u-16*v+12);
y = 4*v./(6*u-16*v+12);

X = x.*Y./y;  X(y==0) = 0;
Z = Y./y-X-Y; Z(y==0) = 0;
X(X<0) = 0; Y(Y<0)= 0 ; Z(Z<0) = 0;

varR = X*0.032406-Y*0.015372-Z*0.004986;
varG = -X*0.009689+Y*0.018758+Z*0.000415;
varB = X*0.000557-Y*0.002040+Z*0.010570;

varR = double(varR > 0.0031308) .* (1.055*(varR.^(1/2.4))-0.055) + double(varR <= 0.0031308) .* varR * 12.92;
varG = double(varG > 0.0031308) .* (1.055*(varG.^(1/2.4))-0.055) + double(varG <= 0.0031308) .* varG * 12.92;
varB = double(varB > 0.0031308) .* (1.055*(varB.^(1/2.4))-0.055) + double(varB <= 0.0031308) .* varB * 12.92;

Aout(:,:,1) = varR*maxRGB;
Aout(:,:,2) = varG*maxRGB;
Aout(:,:,3) = varB*maxRGB;


% Aout(:,:,1) = X*2.690-Y*1.276-Z*0.414;
% Aout(:,:,2) = -X*1.022+Y*1.978+Z*0.044;
% Aout(:,:,3) = X*0.061-Y*0.224+Z*1.163;

