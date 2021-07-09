function [blocchi,k] = fill(N,M,blocchi)
    k=1;
    for i=24:6:N-24
        for j=24:6:M-24
            mat=generaMat(i,j);
            disp(mat)
            blocchi{k}=mat;
            k=k+1;
        end
    end
    k=k-1;
    return;
end

