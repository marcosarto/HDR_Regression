function [flagfun,K]=keygeneration5(C,N,M,dim,ln,chiave,filechiave,newk)

% INIZIALIZZAZIONE PRNG CON LA CHIAVE
rng(chiave);
%rng('shuffle'); % chiave random


% INIZIALIZZAZIONE VARIABILI INTERNE
flagfun = 0; % variabile ritornata (0 errore, 1 ok)
border = 6+ln; % bordo della sottobanda da non utilizzare
toll = 0.9; % area minima del blocco: toll * dim^2
smooth = 0.8; % coefficiente di smoothness dei confini
ft = 0.3; % frequenza di taglio del lpf applicato ai confini
L = 20; % lunghezza del lpf applicato ai confini

K = newk;

% ESTRAZIONE SHIFT DEL CODEBOOK
d = rand(K,1) - 1/2;

% TEST DI COMPERTURA DEL MOSAICO
coverage = zeros(N,M);

% DEFINIZIONE BLOCCHI
% definizione variabili
blocchi = cell(K,1);

blocchi = fill(K,N,M,blocchi);


% TEST DI COPERTURA DEI BLOCCHI
coverage = ones(N,M);
for k = 1:K
    for i = 1:size(blocchi{k},1)
        coverage(blocchi{k}(i,1),blocchi{k}(i,2)) = 0.5;
    end
end
imshow(coverage); drawnow;
%pause;
%close;


% SALVATAGGIO
fid = fopen(filechiave,'w');
fprintf(fid,'%f %f %d %d %d ',chiave,C,K,N,M);
fprintf(fid,'%f ',d);
for k = 1:K
    fprintf(fid,'%d ',size(blocchi{k},1));
end
fprintf(fid,'%d ',blocchi{:});
fclose(fid);
flagfun = 1;
return;