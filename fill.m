function [blocchi] = fill(K,N,M,blocchi)
    k=1;
    for i=24:12:N-24
        for j=24:12:M-24
            coin=randi([0 3],1);
            if coin==2
                mat=generaMat(i,j);
                disp(mat)
                blocchi{k}=mat;
                k=k+1;
            end
            if k>K
                return;
            end
        end
    end      
end

