 %getpath
%Compute N number of randomely generated ray paths.
%First determine if ray intersects a receiver
%If NO, ray path is only plotted.
%If YES, ray path populate a data matrix, then plotted

close all
clear all
addpath data
addpath functions

load data


% For now all the cells have dimension 1x1x1
dX = ones(1,82)*2;
dZ = ones(1,100)*3;

X0 = -2;
Z0 = 300;

% length of land surveyed
nX = length(dX);
nZ = length(dZ);

Rx.X=160;
Tx.X=0;
%Generate ray path for every tx-tx pairs
counter=1;

for ii=1:size(data,1)
    
    
        
        rangeX = Rx.X - Tx.X;
        rangeZ = data(ii,1) - data(ii,2);
        
        angl_in = atan(rangeZ/rangeX);
                
        G(counter,:) = compG(X0,Z0,nX,nZ,dX,dZ,Rx.X,data(ii,1),Tx.X,data(ii,2));
%         TxZ(counter) = Tx.Z(ii);
%         RxZ(counter) = Rx.Z(jj);
        counter=counter+1;
%         figure(1)
%         plot([Tx.X Rx.X],[data(ii,2) data(ii,1)],'g--')
%         hold on
        
        
    
end

%Create data matrix
% data = G * m ;

%Corrupt with 5% random noise
% d = awgn(data,-12.5);
% noise = ( (data.*.05) .* randn(length(data),1) );
% d = data + noise;

%Create mesh group
mesh{1}=[X0 Y0 Z0];
mesh{2}=dX;
mesh{3}=dZ;

save ('data/kernel','G');
% save ('data/model','m');
save ('data/mesh','mesh');

