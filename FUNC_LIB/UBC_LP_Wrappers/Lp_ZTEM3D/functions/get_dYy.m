function [dYy] = get_dYy(m, nX, nY, nZ, dX, dY, dZ,topo_model)



%% Compute the derivative terms ( WxtWx + WytWy + WztWz ) * m
dYy = zeros( nX * (nY -1) * nZ, 1);
count=1;
skip = 0;
for jj = 1 : nY
    
    for ii = 1 : nX
        
        for kk = 1 : nZ
            
            if (jj == nY) %|| mnull(kk,ii,jj)== 0 || mnull(kk,ii+1,jj)== 0

                skip=skip+1;
            else 
%                 if topo_model(count+skip)==0 || topo_model(count+skip+nZ)==0
% 
%                         dYy(count)=0;
%                         count=count+1;
% 
%                 else
                        dYmid = (dY(jj) + dY(jj+1))/2;
                        dYy(count) = sqrt(dX(ii) * dZ(kk) * dYmid);

                        count=count+1;
               
%                 end
                
            end
            
        end
    end
end
