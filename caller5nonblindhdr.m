% Image Watermarking System -- Embedder
% Experimental Version -- Light Weight
% Non blind, perceptual loop
%
% Guerrini Fabrizio
% 16/06/19 - rev5 18/06/21
%


% *******************
% ** PRELIMINARIES **
% *******************

%Inizializzazioni
%clear;
%for a=1:100
warning('off');
close all;
chiave = 235764532; % chiave segreta
rng(chiave);

% Paths
pathiniz = 'C:\Users\marco\Documents\GitHub\HDR_Regression\'; % path di lavoro
%pathiniz = pwd;
addpath(pathiniz);
pathtemp = strcat(pathiniz,'temp/');
pathdb = strcat(pathiniz,'db/');
pathwat = strcat(pathiniz,'wat/');
pathtmo = strcat(pathiniz,'tmo/');
pathvdp = strcat(pathiniz,'hdrvdp-2.2.1/');
pathmat = strcat(pathiniz,'mat/');
pathkey = strcat(pathiniz,'key/');
pathcsv = strcat(pathiniz,'csv/');
cd (pathiniz);
tic;
delete key/*.dat;
% Variabili globali
wavlevel = 2; % livello di scomposizione
DIMBLOCCO=36;
dim = 6; % dimensione blocchi
C = .55; % coverage blocchi
global summax; % da passare al minimizzatore
global x0; % da passare al minimizzatore



% Selezione immagini nel db
directory = dir(pathdb);
immsel = 1:1; % guardare directory per scegliere le immagini
Nimm = size(immsel,2);

% definizione neighbourhood per la maschera (filtro di lunghezza 8, 2 livelli)
ln = 1;
sn = 2*ln+1;
sn2 = 4*ln+8;

% Variabili maschera percettiva
Strength = 24; % fattore globale - blind 24
StrengthSum = 0.3; % norma L1 max - blind 0.3
mask = cell(Nimm,1); % salvataggio maschera (nuova)
oldmask = cell(Nimm,1); % salvataggio maschera (vecchia)

% Variabili feature
korig = cell(Nimm,1); % feature originali
hsol = cell(Nimm,1); % feature obiettivo
h = cell(Nimm,1); % feature quantizzate
hwat = cell(Nimm,1); % feature marchiate
marked = cell(Nimm,1); % blocchi da considerare
selez = cell(Nimm,1); % flag di scelta opzione
y = cell(Nimm,1); % blocchi marchiati
VincViol = cell(Nimm,1); % flag di vincoli attivi
W = cell(Nimm,1); % maschera

% Misure di distorsione
DWR = zeros(Nimm,1);

% Immagini marchiate e originali
immaginewat = cell(Nimm,1);
immagineorig = cell(Nimm,1);

for contimm = 1 % ciclo sulle immagini
    
    % *************
    % ** LOADING **
    % *************
    
    % Image loading
    cd (pathdb);
    % hdr format: rle
    [immagineorigrgb, fileinfo] = read_rle_rgbe(directory(immsel(contimm)+3).name);
    [Ni,Mi,RGBflag] = size(immagineorigrgb);
    % rle -> logluv
    [immagineoriglogluv,maxRGB,offset,alpha] = rgb2logluv(immagineorigrgb); % RGB --> logLUV
    immagine = immagineoriglogluv(:,:,1);
    % normalizzazione
    %[immagine,Transf] = histeq(immagine/max(max(immagine)));
    maxImm = 1;%max(max(immagine)); % vale alpha in (:,:,1)
    minImm = 0;%min(min(immagine)); % vale qualcosa piu di offset
    immagine = (immagine-minImm)/(maxImm-minImm); % immagine in [0,1]
    immagineorig{contimm} = immagine; % save original
    cd (pathiniz);
    
    %DA ELIMINARE
    %coverage = (2^15-1)*ones(200,100);
    
    % Image decomposition
    %[ci,si] = wavedec2(coverage,wavlevel,'db4'); % scomposizione wavelet
    [ci,si] = wavedec2(immagine,wavlevel,'db4'); % scomposizione wavelet
    cai2 = appcoef2(ci,si,'db4',wavlevel); % sottobanda di approssimazione
    [cd2h,cd2v,cd2d] = detcoef2('all',ci,si,2); % bande di dettaglio livello 2 (maschera)
    [cd1h,cd1v,cd1d] = detcoef2('all',ci,si,1); % bande di dettaglio livello 1 (maschera)
    [N,M] = size(cai2); % dimensioni sottobanda

    % Shift and blocks loading -- key generation
    strchiave = sprintf('%d',chiave);
    filechiave = strcat(pathkey,'key_nb_',strchiave,'_',directory(immsel(contimm)+3).name(1:end-4),'.dat');
    rigenkey = 0;
    fkey = fopen(filechiave,'r');
    if fkey == -1
        fprintf('FILE CHIAVE NON TROVATO, RIGENERAZIONE IN CORSO...\n');
        rigenkey = 1;
    else
        chiavefkey = fscanf(fkey,'%f ',[1 1]);
        Cfkey = fscanf(fkey,'%f ',[1 1]);
        K = 3*fscanf(fkey,'%d ',[1 1]);
        Nfkey = fscanf(fkey,'%d ',[1 1]);
        Mfkey = fscanf(fkey,'%d ',[1 1]);
        if chiavefkey~=chiave || Cfkey ~= C || Nfkey ~= N || Mfkey ~= M
            fprintf('FILE CHIAVE NON COMPATIBILE, RIGENERAZIONE IN CORSO...\n');
            rigenkey = 1;
            fclose(fkey);
        end
    end
    if rigenkey == 1
        [flagfun] = keygeneration5(C,N,M,dim,ln,chiave,filechiave);
        if flagfun == 0
            fprintf('\nPROBLEMI CON LA GENERAZIONE DELLA CHIAVE, ESCO...\n');
            return;
        end
        fkey = fopen(filechiave,'r');
        chiavefkey = fscanf(fkey,'%f ',[1 1]);
        Cfkey = fscanf(fkey,'%f ',[1 1]);
        K = fscanf(fkey,'%d ',[1 1]);
        Nfkey = fscanf(fkey,'%d ',[1 1]);
        Mfkey = fscanf(fkey,'%d ',[1 1]);
    end
    demb = fscanf(fkey,'%f ',[K 1]);
    ncoeff = fscanf(fkey,'%d ',[K 1]);
    blocchi = cell(K,1);
    for k = 1:K
        blocchi{k} = fscanf(fkey,'%d ',[ncoeff(k) 2]);
    end
    fclose(fkey);
    
    
    
    % Istanzia variabili feature
    korig{contimm} = zeros(K,1); % feature originali
    hsol{contimm} = cell(K,1); % feature obiettivo
    h{contimm} = zeros(K,1); % feature quantizzate
    hwat{contimm} = zeros(K,1); % feature marchiate
    marked{contimm} = zeros(K,1); % blocchi da considerare
    selez{contimm} = zeros(K,2); % flag di scelta opzione
    y{contimm} = cell(K,1); % blocchi marchiati
    VincViol{contimm} = zeros(K,2); % flag di vincoli attivi
    
    % Componenti maschera percettiva
    Theta = 0.32*55;
    Lambda = cell(K,1);
    Csi = cell(K,1);
    Gamma = cell(K,1);
    W{contimm} = cell(K,1); % maschera
       
    % Neighbourhood (maschera percettiva)
    maxdimblocco = 0;
    for k = 1:K
        maxdimblocco = max([maxdimblocco,size(blocchi{k},1)]);
    end
    neighcmax = (-ln:ln)'*ones(1,maxdimblocco);
    neighcmax = neighcmax';
    neighrmax = neighcmax(:)*ones(1,sn);
    neighrmax = reshape(neighrmax',maxdimblocco,sn^2);

    neighc2max = (-7-2*ln:2*ln)'*ones(1,maxdimblocco);
    neighc2max = neighc2max';
    neighr2max = neighc2max(:)*ones(1,sn2);
    neighr2max = reshape(neighr2max',maxdimblocco,sn2^2);
    
    % ***********************************
    % ** BLOCK WATERMARK PRE-EMBEDDING **
    % ***********************************

    % Variabili wavelet
    ciwat = ci;
    %ciwat2 = ci;
    siwat = si;
    cai2wat = cai2;
    cai2watblock = cai2;
    %cai2wat2 = cai2;

    % Variabili quantizzazione
    kurtosep = [1; 2; 5; inf];
    kurtosfas = [0.5; 0.5; 0];
    deltasep = [1; 3; 10];
    
    % Opzioni fmincon (minimizzatore)
    tolcon = 1e-6;
    %options = optimset('outputfcn',@outfun,'Diagnostics','off','Display','final','LargeScale','off','MaxIter',1000,'MaxFunEvals',100000,'TolCon',tolcon);
    options = optimset('Diagnostics','off','Display','final','LargeScale','off','MaxIter',1000,'MaxFunEvals',100000,'TolCon',tolcon);

    % Calcolo contorni (maschera percettiva)
    %[edges,th] = edge(cai2,'canny','nothinning');
    %edges = edge(cai2,'canny',[th(1) 4*th(1)],'nothinning');
    [~,th] = edge(cai2,'canny');
    edges = edge(cai2,'canny',[th(1) 4*th(1)]);
    Avg = ones(5,5)*0.05 + [zeros(1,5); zeros(1,5); 0 0 0.15 0 0; zeros(1,5); zeros(1,5)];
    edgesfilt = filter2(Avg,edges);
    index_out=0;
    for k = 1:K

        % Blocco originale
        x0 = cai2(sub2ind(size(cai2),blocchi{k}(:,1),blocchi{k}(:,2)));

        % Preparazione variabili per maschera percettiva
        dimblocco = size(blocchi{k},1);
        neighc = neighcmax(1:dimblocco,:);
        neighr = neighrmax(1:dimblocco,:);
        neighc2 = neighc2max(1:dimblocco,:);
        neighr2 = neighr2max(1:dimblocco,:);

        col = blocchi{k}(:,2)*ones(1,sn);
        col = col+neighc;
        col = reshape(col(:)*ones(1,sn),dimblocco,sn^2);
        col = col';

        col2 = 2*blocchi{k}(:,2)*ones(1,sn2);
        col2 = col2+neighc2;
        col2 = reshape(col2(:)*ones(1,sn2),dimblocco,sn2^2);
        col2 = col2';

        row = blocchi{k}(:,1)*ones(1,sn);
        row = row(:)*ones(1,sn);
        row = reshape(row,dimblocco,sn^2);
        row = row+neighr;
        row = row';

        row2 = 2*blocchi{k}(:,1)*ones(1,sn2);
        row2 = row2(:)*ones(1,sn2);
        row2 = reshape(row2,dimblocco,sn2^2);
        row2 = row2+neighr2;
        row2 = row2';

        % Calcolo maschera percettiva
        Lambda{k} = 1-((1/(2^17-4))*x0)+(((1/(2^17-4))*x0)>=0.5).*(((1/(2^17-4))*x0)*2-1);

        Csi{k} =  1/4*1/(sn^2*3)*sum([cd2h(sub2ind(size(cd2h),row,col)); cd2v(sub2ind(size(cd2v),row,col)); cd2d(sub2ind(size(cd2d),row,col))].^2) .*...
            1/(sn2^2*3) .*sum([cd1h(sub2ind(size(cd1h),row2,col2)); cd1v(sub2ind(size(cd1v),row2,col2)); cd1d(sub2ind(size(cd1d),row2,col2))].^2).*...
            var(cai2(sub2ind(size(cai2),row,col)),1);

        Gamma{k} = 10.^edgesfilt(sub2ind(size(edgesfilt),blocchi{k}(:,1),blocchi{k}(:,2))).^(-1.5);      
        
        %f=Strength * ones(dimblocco,1) .* Lambda{k} .* (Csi{k}.^0.1)' .* Gamma{k};
        %Theta = x0/f'*3/10;
        W{contimm}{k} = Strength * ones(dimblocco,1) * Theta .* Lambda{k} .* (Csi{k}.^0.1)' .* Gamma{k};
        summax = StrengthSum*sum(W{contimm}{k});

        % Kurtosis originale
        korig{contimm}(k) = kurtosis(x0);
        if isnan(korig{contimm}(k))
            x0 = x0 + WGN(size(x0),1);
            korig{contimm}(k) = kurtosis(x0);
        end    

        % Blocchi marchiati
        y{contimm}{k} = zeros(size(x0,1),3); % scelta definitiva, prima opzione, seconda opzione
       
        % Quantizzazione feature
        indexq = [0;0];
        indexq(1) = sum(korig{contimm}(k)>=kurtosep);
        if xor(demb(k)>=0,korig{contimm}(k)-kurtosep(indexq(1))>=deltasep(indexq(1))/2)
            indexq(2) = indexq(1)+(demb(k)<0)*2-1;
            if indexq(2) > length(deltasep) || indexq(2) == 0
                indexq(2) = [];
            end
        else
            indexq(2) = [];
        end

        hsol{contimm}{k} = round((korig{contimm}(k)-demb(k)*deltasep(indexq)-kurtosfas(indexq))./deltasep(indexq)).*deltasep(indexq)+demb(k)*deltasep(indexq)+kurtosfas(indexq);
        for i = 1:length(indexq)
            while hsol{contimm}{k}(i)>kurtosep(indexq(i))
                hsol{contimm}{k}(i) = hsol{contimm}{k}(i)-deltasep(indexq(i));
            end
            while hsol{contimm}{k}(i)<kurtosep(indexq(i))
                hsol{contimm}{k}(i) = hsol{contimm}{k}(i)+deltasep(indexq(i));
            end
        end


        % Calcolo 1 oppure 2 possibili soluzioni 
        temp = zeros(length(x0),2);
        exitflag = zeros(2,1);
        fval = zeros(2,1);
        VincMatrA = [-1*diag(ones(size(x0)));diag(ones(size(x0)))];
        VincMatrB = [W{contimm}{k}-x0;x0+W{contimm}{k}]; % vincolo della forma Ax <= B
        for i = 1:length(hsol{contimm}{k})
            fprintf('******************************************\n');
            fprintf('** INIZIO PRE-EMBEDDING\t\t\t**\n');
            if K<1000
                fprintf('** BLOCCO %d/%d\t\t\t\t**\n',k,K);
            else
                fprintf('** BLOCCO %d/%d\t\t\t**\n',k,K);
            end
            if length(hsol{contimm}{k}) == 2
                fprintf('** TARGET %d/2\t\t\t\t**\n',i);
            else
                fprintf('** TARGET UNICO\t\t\t\t**\n');
            end
            fprintf('** KURTOSIS ORIGINALE : %2.4f\t\t**\n',korig{contimm}(k));
            fprintf('** OBIETTIVO :          %2.4f\t\t**\n',hsol{contimm}{k}(i));
            fprintf('******************************************\n\n');
            [temp(:,i),fval(i),exitflag(i),output] = fmincon(@(x)abs(kurtosis(x)-hsol{contimm}{k}(i)),x0,VincMatrA,VincMatrB,[],[],[],[],@vincolo,options);
        end

        % Scelta opzione definitiva
        y{contimm}{k}(:,2) = temp(:,1); % prima opzione (sempre)
        if length(hsol{contimm}{k}) == 2 % eventuale seconda opzione
            y{contimm}{k}(:,3) = temp(:,2);
            if xor(abs(kurtosis(temp(:,1))-hsol{contimm}{k}(1))<1e-3,...
                    abs(kurtosis(temp(:,2))-hsol{contimm}{k}(2))<1e-3) % scelgo quella che converge
                indconv = find([abs(kurtosis(temp(:,1))-hsol{contimm}{k}(1))<1e-3,...
                    abs(kurtosis(temp(:,2))-hsol{contimm}{k}(2))<1e-3]==1);
                y{contimm}{k}(:,1) = temp(:,indconv);
                h{contimm}(k) = hsol{contimm}{k}(indconv);
                hwat{contimm}(k) = kurtosis(temp(:,indconv));
                selez{contimm}(k,1) = indconv;
                selez{contimm}(k,2) = 1;
            elseif abs(kurtosis(temp(:,1))-hsol{contimm}{k}(1))<1e-3 && ...
                    abs(kurtosis(temp(:,2))-hsol{contimm}{k}(2))<1e-3 % convergono entrambe, scelgo la norma L1 del marchio minima
                indminL1 = find(sum(abs(temp-x0*ones(1,2)))==min(sum(abs(temp-x0*ones(1,2)))));
                y{contimm}{k}(:,1) = temp(:,indminL1(1));
                h{contimm}(k) = hsol{contimm}{k}(indminL1(1));
                hwat{contimm}(k) = kurtosis(temp(:,indminL1(1)));
                selez{contimm}(k,1) = indminL1(1);
                selez{contimm}(k,2) = 2;
            else % non convergono entrambe, scelgo la piu vicina al valore quantizzato
                indminfval = find(fval==min(fval));
                y{contimm}{k}(:,1) = temp(:,indminfval(1));
                h{contimm}(k) = hsol{contimm}{k}(indminfval(1));
                hwat{contimm}(k) = kurtosis(temp(:,indminfval(1)));
                selez{contimm}(k,1) = indminfval(1);
                selez{contimm}(k,2) = 3;
            end
        else % solo una opzione disponibile
            y{contimm}{k}(:,1) = temp(:,1);
            h{contimm}(k) = hsol{contimm}{k}(1);
            hwat{contimm}(k) = kurtosis(temp(:,1));
            selez{contimm}(k,1) = 3;
            selez{contimm}(k,2) = 0;
        end
        VincViol{contimm}(k,1) = sum(VincMatrA*y{contimm}{k}(:,1)-VincMatrB >= -tolcon); % numero vincoli Linf violati
        VincViol{contimm}(k,2) = sum(abs(y{contimm}{k}(:,1)-x0)) >= summax; % numero vincoli L1 violati

        if abs(h{contimm}(k)-hwat{contimm}(k))<1e-3  % soluzione scelta converge
                %sum(abs(y{k,1,contimm}-x0))/summax <= 0.5 % non troppo vicina al vincolo
            marked{contimm}(k) = 1; % marchiato
        else
            % undo embedding
            y{contimm}{k}(:,1) = x0; 
            hwat{contimm}(k) = korig{contimm}(k);
            marked{contimm}(k) = 0; % non marchiato
        end
        cai2wat(sub2ind(size(cai2wat),blocchi{k}(:,1),blocchi{k}(:,2))) = y{contimm}{k}(:,1); % embedding vero e proprio
        fprintf('\n KURTOSIS OTTENUTA: %2.4f, MARKED %d\n\n',hwat{contimm}(k),marked{contimm}(k));
            
        for i=1:36
            out2(k,i)=x0(i);
        end
        for i=1:36
            out2(k,i+36)=y{contimm}{k}(i,1);
        end
    end
    
%     *********************
%     ** PERCEPTUAL TEST **
%     *********************
    
    R = immagineoriglogluv(:,:,1); % reference image, originale
    fprintf('\n TEST PERCETTIVO...\n');
    cd (pathvdp);
    ciwat(1,1:N*M) = (cai2wat(:))';
    T = (maxImm-minImm)*double(waverec2(ciwat,siwat,'db4'))+minImm;
    newres = hdrvdp(T,R,'luminance',30);
    imshow(hdrvdp_visualize('pmap',newres.P_map,{'context_image',T})); drawnow;
    perc_tot=max(newres.P_map(:));
    fprintf('CON TUTTI I BLOCCHI, P = %1.5f\n',perc_tot);
    impact = zeros(K,1);
    index_out=0;
    
    for k=1:K
        %%aggiungo al file csv
        media_csi=zeros(K);
        media_lambda=zeros(K);
        media_gamma=zeros(K);
        media_w=zeros(K);
        for t=1:DIMBLOCCO
            media_csi(k)=Csi{k}(t)+media_csi(k);
            media_lambda(k)=Lambda{k}(t)+media_lambda(k);
            media_gamma(k)=Gamma{k}(t)+media_gamma(k);
            media_w(k)=W{contimm}{k}(t)+media_w(k);
        end
        out(k,1)=media_csi(k)/DIMBLOCCO;           
        out(k,2)=media_lambda(k)/DIMBLOCCO;                         
        out(k,3)=media_gamma(k)/DIMBLOCCO;
        out(k,4)=media_w(k)/DIMBLOCCO;
        out(k,5)=korig{1}(k);
        out(k,6)=h{1}(k); 
    end
    
    
    %[out,K] = expansion(out,K);
    
    for k = 1:K
        % analisi impatto percettivo dei singoli blocchi
        if ~marked{contimm}(k)
            fprintf('BLOCCO %d/%d IMPATTO NULLO (NON MARKED)\n',k,K);
            continue
        end % nessun embedding
        cai2watblock = cai2; % ricomincia da zero
        ciwatblock = ciwat;
        cai2watblock(sub2ind(size(cai2watblock),blocchi{k}(:,1),blocchi{k}(:,2))) = y{contimm}{k}(:,1); % solo blocco k
        ciwatblock(1,1:N*M) = (cai2watblock(:))';
        T = (maxImm-minImm)*double(waverec2(ciwatblock,siwat,'db4'))+minImm; % ricostruzione con un singolo blocco
        newres = hdrvdp(T,R,'luminance',30); % calcola nuova distorsione percettiva
        %imshow(hdrvdp_visualize('pmap',newres.P_map,{'context_image',T})); drawnow; % mostrala
        newres.P_map(newres.P_map<1e-3) = 0; % sogliala
        impact(k) = max(newres.P_map(:));
        fprintf('BLOCCO %d/%d IMPATTO %1.5f\n',k,K,impact(k));
        %aggiungo al csv        
        out(k,7)=impact(k); 
        out2(k,73)=impact(k);
    end
    toc
    cd(pathcsv);
    writematrix(out2,'M2.csv')
    writematrix(out,'M.csv') 
    cd (pathiniz);

    % **************************************
    % ** WATERMARKED IMAGE RECONSTRUCTION **
    % ************************************ **
    
    % ricostruzione immagini marchiate
    ciwat(1,1:N*M) = (cai2wat(:))';
    %ciwat2(1,1:N*M) = (cai2wat2(:))';
    immaginewatlogluv = immagineoriglogluv;
    immaginewatlogluv(:,:,1) = (maxImm-minImm)*double(waverec2(ciwat,siwat,'db4'))+minImm;
    immaginewat{contimm} = logluv2rgb(immaginewatlogluv,maxRGB,offset,alpha);
    immaginewat{contimm}(immaginewat{contimm}<0) = 0;
    %immaginewat2{contimm} = double(waverec2(ciwat2,siwat,'db4'));
    %figure(1), imshow(immagine/255), title('ORIG');
    %figure(2), imshow(immaginewat/255), title('WAT');
    %figure(3), imshow(abs(immagine-immaginewat)/255*64); title('DIFF');
    
    % salvataggio immagini marchiate
    cd (pathwat);
    %imwrite(immaginewat{contimm},strcat('wat',directory(immsel(contimm)+3).name(1:end-4),'.png'));
    %imwrite(uint8(round(immaginewat2{contimm})),strcat('wat2',directory(immsel(contimm)+3).name));
    hdrwrite(immaginewat{contimm},strcat('wat',directory(immsel(contimm)+3).name(1:end-4),'_',strchiave,'.hdr'))
    cd (pathiniz);
    %save('immwat.mat','immaginewat')
    
    % misura SNR
    DWR(contimm) = 10*log10(sum(sum(immaginewatlogluv(:,:,1).^2))/sum(sum((immaginewatlogluv(:,:,1)-immagineoriglogluv(:,:,1)).^2)));
    
    % *****************
    % ** MASK SAVING **
    % *****************

    mask{contimm} = zeros(size(cai2));
    oldmask{contimm} = zeros(size(cai2));
    for k = 1:K
        mask{contimm}(sub2ind(size(cai2wat),blocchi{k}(:,1),blocchi{k}(:,2))) = W{contimm}{k};
        oldmask{contimm}(sub2ind(size(cai2wat),blocchi{k}(:,1),blocchi{k}(:,2))) = W{contimm}{k}./Gamma{k};
    end
    
    % ******************
    % ** MARKED FLAGS **
    % ******************
    
    filemarked = strcat(pathmat,'mark_',strchiave,'_',directory(immsel(contimm)+3).name(1:end-4),'.mat');
    thismarked = marked{contimm};
    thiskorig = korig{contimm};
    save(filemarked,'thismarked','thiskorig');
end
%end
   