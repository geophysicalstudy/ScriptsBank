function [Wy]=getWy_3D(mcell,dX,dY,dZ)
%Build the derivative weighting matrix
%Takes care of the fact that model is a m-by-n matrix converted to a
%m*n-by-1

nX = length(dX);
nY = length(dY);
nZ = length(dZ);

% Wx = zeros(mcell,n*(m-1));
Wy = sparse(nX*nZ*(nY-1),mcell);

count=1;
for jj=1:nY-1
    for ii=1:nX
        for kk=1:nZ
        
                if mnull(kk,ii,jj)== 0 || mnull(kk,ii,jj+1)== 0
                    
                count=count+1;
                
                else  
                dYhalf = ( dY(jj) + dY(jj+1) ) /2;
                Wy(count,count+nZ*nX) = sqrt(1 / dYhalf^2 ); 
                Wy(count,count) = -sqrt(1 / dYhalf^2 );

                count=count+1;
                end
        end
    end
end

% Wy = sparse(wy);

end