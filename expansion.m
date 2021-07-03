function [out,K] = expansion(out,K)
    
    SOGLIA_UNO = 8;
    SOGLIA_DUE = 1;
    j=0;
    out2=zeros(size(out,1)*2,5);
    for k=1:K
        if out(k,5) > SOGLIA_UNO
            out2=[out2;out(k,:)];
            j=j+1;
            out2(j,5)=out2(k,5)+1;
            out2=[out2;out(k,:)];
            j=j+1;
            out2(j+1,5)=out2(k,5)-1;
            
        elseif out(k,5) < SOGLIA_DUE
            out2=[out2;out(k,:)];
            j=j+1;
            out2(j,5)=out2(k,5)+0.1;
            out2=[out2;out(k,:)];
            j=j+1;
            out2(j+1,5)=out2(k,5)-0.1;
            
        else
            out2=[out2;out(k,:)];
            j=j+1;
            out2(j,5)=out2(k,5)+0.5;
            out2=[out2;out(k,:)];
            j=j+1;
            out2(j+1,5)=out2(k,5)-0.5;
        end
    end
    K = K + j;
    out = [out;out2];
end