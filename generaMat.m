function [mat] = generaMat(riga,colonna)
    mat=zeros(36,2);
    k=1;
    for i=0:5
        for j=0:5
            mat(k,1)=j+riga;
            mat(k,2)=i+colonna;
            k=k+1;
        end
    end
    return;
end

