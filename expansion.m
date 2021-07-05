function [out] = expansion(out,K)
    
    DELTA_UNO=1;
    DELTA_DUE=3;
    DELTA_TRE=10;
    outout=zeros(0,5);
    out2=0;
    out3=0;
    for k=1:K
        if out(k,4) >= 1 && out(k,4) <= 2 
            out2=[out(k,1),out(k,2),out(k,3),out(k,4),out(k,5)+DELTA_UNO/10];
            out3=[out(k,1),out(k,2),out(k,3),out(k,4),out(k,5)+2*DELTA_UNO/10];
            
        elseif out(k,4) > 2 && out(k,4) <=5 
            out2=[out(k,1),out(k,2),out(k,3),out(k,4),out(k,5)+DELTA_DUE/10];
            out3=[out(k,1),out(k,2),out(k,3),out(k,4),out(k,5)-DELTA_DUE/10];
            
        elseif out(k,4) > 5
            out2=[out(k,1),out(k,2),out(k,3),out(k,4),out(k,5)+DELTA_TRE/10];
            out3=[out(k,1),out(k,2),out(k,3),out(k,4),out(k,5)+2*DELTA_TRE/10];
        end
        
        outout = [outout;out2;out3];  
    end
    %K = K + size(outout,1);
    out = [out;outout];
end