% Inversion code with lp,lq norm for 3D magnetostatic
% DEVELOPMENT CODE
% Under sub-functions are required to run the code
% Written by: Dominique Fournier 
% Last update: 2014/04/10

clear all
close all

addpath ..\FUNC_LIB\;
% Project folders
work_dir = 'C:\Users\dominiquef.MIRAGEOSCIENCE\Google Drive\Research\Modelling\Topo_adjust\Shell_Sphere';
obsfile     = 'Obs_1pc_1em3floor.dat';
meshfile    = 'Mesh_5m.msh';
% model_sus   = 'Dual_susc.sus';

% Load mesh file and convert to vectors (UBC format)
[xn,yn,zn]=read_UBC_mesh([work_dir '\' meshfile]);
dx = xn(2:end) - xn(1:end-1); nx = length(dx);
dy = yn(2:end) - yn(1:end-1); ny = length(dy);
dz = zn(1:end-1) - zn(2:end); nz = length(dz);

mcell = (length(xn)-1) * (length(yn)-1) * (length(zn)-1);

% Load synthetic model
% m = load([work_dir '\' model_sus]);
load([work_dir '\nullcell.dat']);

% Load observation file (3C UBC-MAG format)
[H, I, Dazm, D, obsx, obsy, obsz, data, wd] = read_MAG3D_obs([work_dir '\' obsfile]);
% plot_mag3C(obsx,obsy,d,I,D,'Observed 3C-data')
% plot_TMI(obsx,obsy,d,d,wd,'Observed vs Predicted Magnitude');

ndata = length(data);
Wd   = spdiags(1./wd,0,ndata,ndata);

nstn = length(obsx);

%% Create model magnetization vectors
m_azm = ones(mcell,1)*Dazm;
m_dip = ones(mcell,1)*I;
mv = azmdip_2_xyz(m_azm,m_dip);

M = [spdiags(H * mv(:,1),0,mcell,mcell);spdiags(H * mv(:,2),0,mcell,mcell);spdiags(H * mv(:,3),0,mcell,mcell)];

%% TMI forward projector
P = [spdiags(ones(nstn,1)* (cosd(I) * cosd(D)),0,nstn,nstn) ...
    spdiags(ones(nstn,1)* (cosd(I) * sind(D)),0,nstn,nstn) ...
    spdiags(ones(nstn,1)* sind(I),0,nstn,nstn)];

%% Load T matrix generated by FMAG3C
load([work_dir '\Tx']);
load([work_dir '\Ty']);
load([work_dir '\Tz']);

G = [Tx;Ty;Tz] * M;

clear Tx Ty Tz

G = P*G;

%% Load RTC correction
load([work_dir '\tTx']);
load([work_dir '\tTy']);
load([work_dir '\tTz']);
load([work_dir '\aPt']);

% G_RTC =  G_RTC;

% clear tTx tTy tTz

%% Compute depth weighting
wr = get_wr(obsx, obsy, obsz, D, I, xn, yn, zn, nullcell, 'DISTANCE');
save([work_dir '\wr.dat'],'-ascii','wr');


%% Create gradient matrices and corresponding volume vectors
[Wx, Wy, Wz, Vx, Vy, Vz] = get_GRAD_op3D_v4(dx,dy,dz,nullcell);
[Ws, v ] = getWs3D(dx,dy,dz);

%% Depth weighting
IWr = spdiags(1./wr,0,mcell,mcell);
Wr = spdiags(wr,0,mcell,mcell);

V = spdiags((v),0,mcell,mcell);

%% Apply depth and data weighting on sensitivity
% sens = mean((abs(G*V)),1)'/ndata;
% save([work_dir '\sens.dat'],'-ascii','sens');
G = G * IWr;
G   = Wd * G;
data = Wd * data;

d_RTC = @(mm) Wd * P *...
                [tTx*(aPt*M*IWr*mm);
                tTy*(aPt*M*IWr*mm);
                tTz*(aPt*M*IWr*mm)];
            
%% Inversion
Lx = 20;
Ly = 20;
Lz = 20;

alpha(1) = 1/Lx^2;
alpha(2) = 1;
alpha(3) = 1;
alpha(4) = 1;

% Pick the p-norm, q-norm and scale
pvec = 2;%[0 1 2]%0:0.5:2;
qvec = 2;%[0 1 2]%0:0.5:2;
lvec = 1.0;%[0.5 1 1.5]%0.25:0.5:1.75;

nl=length(lvec);
nq=length(qvec);
np=length(pvec);
    
delta=1e-10;     %Small term in compact function

target = ndata;     % Target misifit

% Compute total objective function
comp_phi = @(m,d,phi,l) norm(G*(m) - d).^2 +...
    (m)' * l * phi * (m);

counter = 1;               
for ll= 1:length(lvec)

    for pp = 1:length(pvec)
        
        for qq = 1:length(qvec)
                
            % Initialize inversion
            invmod      = Wr * ones(mcell,1)*1e-4;       % Initial model       
            mref        = zeros(mcell,1);       % Reference model 
            
            % RTC adjustment of data
            d = data - d_RTC(invmod);
            phi_init    = sum((G * invmod - d).^2);   % Initial misfit
            phi_d       = phi_init;
            phi_m       = [];         
            
            count=1;
            
            % Message prompt
            head = ['lp' num2str(pvec(pp)) '_lq' num2str(qvec(qq)) '_mu' num2str(lvec(ll))];
            logfile = [work_dir '\Log_' head '.log'];
            fid = fopen(logfile,'w');
            fprintf(fid,'Starting lp inversion %s\n',head);
            fprintf(fid,'Starting misfit %e\n',phi_init);
            fprintf(fid,'Target misfit %e\n',target);
            
            % Initiate active cell
            ProG = spdiags(nullcell,0,mcell,mcell);
            
            WxtWx = ( Vx * Wx )' * ( Vx * Wx ) ;
            WytWy = ( Vy * Wy )' * ( Vy * Wy ) ;
            WztWz = ( Vz * Wz )' * ( Vz * Wz ) ;

            WstWs = ( V * Ws )' * ( V * Ws ) ;
                    
            while phi_d(end) > target 
                
                
                %First iteration uses the usual smallness and smoothness
                %regularization. Choose a beta on the ratio of the traces 
                % of the elements of objective function
                if count==1                 

%                     [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF(invmod,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alpha,2,2,1);
                    [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF_mGRAD(invmod,nx,ny,nz,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alpha,2,2,1);
              
                    MOF_start = MOF;
            
                    beta = full( sum(sum(G.^2,1)) / sum(diag(MOF,0)) * 1e+4 );
                    lambda = beta ;
                    
                    phi = norm(G*invmod - d).^2 +...
                        invmod' * lambda * MOF * invmod;
                    
                else
%                     [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF(invmod,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alpha,pvec(pp),qvec(qq),lvec(ll));                   
                    [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF_mGRAD(invmod,nx,ny,nz,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alpha,pvec(pp),qvec(qq),lvec(ll));

                    mu = ( invmod'* MOF_start * invmod ) / (invmod'*MOF*invmod ) ;

                    lambda = beta(count) * mu;



                end

                % Direct solver using '\'
%                 A = G'*G + lambda * phim;
% 
%                 RHS = G'*d;
%                 
%                 invmod = A\RHS;

                %% Pre-conditionner
                diagA = sum(G.^2,1) + lambda*spdiags(MOF,0)';
                PreCon     = ProG * spdiags(1./diagA(:),0,mcell,mcell);

                % Gaussian Newton solver
                % Form Hessian and gradient (only half since solving using
                % CGLSQ)
                A = [ G * ProG ;...
                    sqrt( lambda ) * aVRWs * ProG ;...
                    sqrt( lambda ) * aVRWx * ProG ;...
                    sqrt( lambda ) * aVRWy * ProG ;...
                    sqrt( lambda ) * aVRWz * ProG ];

                g = [- (G *invmod - d) ; ...
                    - sqrt( lambda ) * ( aVRWs *  (invmod - mref) ) ;...
                    - sqrt( lambda ) * ( aVRWx * (invmod - mref) ) ;...
                    - sqrt( lambda ) * ( aVRWy * (invmod - mref) ) ;...
                    - sqrt( lambda ) * ( aVRWz * (invmod - mref) ) ];
               
                dm = zeros(mcell,1);
                [dm,r,iter] = CGLSQ( dm, A , g, PreCon);
                
                
                % Projected steepest descent
%                 H = P * (G'*G + lambda*phim) *P;
%                     
% 
%                 g = - P*(G'*(G *invmod - d) + lambda*phim*(invmod-mref));
%                 
%                 dm = zeros(mcell,1);
%                 [dm,r,iter]=CGiter(dm,H,g);

                pin = max( abs( dm ) );
                pac = max( abs( (speye(mcell) - ProG) * (A'*g) ) );
                
                p = 1;
                if pin < pac
                    
                    p = pin / pac / 10;
                    
                end
                
                dm = dm + p * ( speye(mcell) - ProG) * (A'*g) ;
                
                %% Step length, line search
                gamma = 2;

                % Initialise phi^k
                phi_temp = 0;   
                while phi_temp > phi(end) || gamma == 2
                    
                    
                    
                    gamma = 0.5 * gamma;
                    
                    m_temp = invmod + gamma * dm;
                    delta_d = d_RTC(m_temp);
                    
                    % RTC adjustment of data
                    d = data - delta_d;
                    
                    lb =  m_temp > 0;
                    % Apply bound on model
                    m_temp(lb==0) = 0;
                    ProG = spdiags(nullcell.*lb,0,mcell,mcell);
                    
                    phi_temp = comp_phi(m_temp,d,MOF,lambda);
   
                end
                   
                % Update model
                invmod = m_temp;
               
                    
                % RTC adjustment of data
                delta_d = d_RTC(invmod);
                d = data - delta_d;
                
                %% Save iteration and continue
                clear A

                phi(count) = comp_phi(invmod,d,MOF,lambda);
            
                phi_d(count) = sum((G*(invmod)-d).^2);

                % Cool beta
                if phi_d(count) < target*2 && count~=1
                    
                  beta(count+1) = 0.5 * beta(count);

                else

                  beta(count+1) = 0.5 * beta(count);

                end

                fprintf(fid,'Iteration: \t %i  \nBeta: \t %8.5e \n',count,beta(count));
                fprintf('Iteration: \t %i  \nBeta: \t %8.5e \n',count,beta(count));
                fprintf(fid,'phid:\t %8.5e\n',phi_d(count));
                fprintf('phid:\t %8.5e\n',phi_d(count))
                fprintf(fid,'phis:\t %8.5e\n',invmod'*alpha(1)*WstWs*invmod);
                fprintf(fid,'phix:\t %8.5e\n',invmod'*alpha(2)*WxtWx*invmod);
                fprintf(fid,'phiy:\t %8.5e\n',invmod'*alpha(3)*WytWy*invmod);
                fprintf(fid,'phiz:\t %8.5e\n',invmod'*alpha(4)*WztWz*invmod);
                fprintf(fid,'phim:\t %8.5e\n',invmod'*MOF*invmod);
                fprintf(fid,'phi:\t %8.5e\n',phi(count));
                fprintf(fid,'Number of Inactive cells: %i\n',mcell-sum(lb));
                fprintf(fid,'Number of CGS iterations: %i\n',iter);
               % Output interation result
               
                model_out = IWr * invmod;
                model_out(nullcell==0) = -100;
                save([work_dir '\TMI_' 'p' num2str(pvec(pp)) 'q' num2str(qvec(qq)) 'l' num2str(lvec(ll)) '_iter_' num2str(count) '.sus'],'-ascii','model_out')
                write_MAG3D_TMI(work_dir,['\TMI_iter_' num2str(count) '.pre'],H,I,Dazm,obsx,obsy,obsz,(G*invmod+delta_d).*wd,wd)
                count=count+1;
                
            end
            
            count=count-1;            
            
            fprintf(fid,'End of lp inversion. Number of iterations: %i\n',count);
%             fprintf('Final data misfit: %8.3e. Final l1-model error: %8.3e\n\n',phi_d(count),norm(m-model_out,1))
            fclose(fid);
            counter = counter+1;
            
        end
    end
end

 

