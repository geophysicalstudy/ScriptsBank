% Generate model and observations for 3D gravity
% Dominique Fournier 2013/01/23
% close all
clear all
close all

% addpath C:\Users\dominiquef\Dropbox\Master\INVMAG3D\

addpath ..\FUNC_LIB\;

% Project folders
work_dir = 'C:\Users\dominiquef.MIRAGEOSCIENCE\Documents\Projects\Research\Modelling\Synthetic\Dual_Block_v2';
inpfile = 'MAG3CampB_input.inp';

[meshfile,obsfile,wr_flag,chi_target,alphas,beta,pvec,qvec,lvec] = MAG3Cinv_read_inp([work_dir '\' inpfile]);

% Load mesh file and convert to vectors (UBC format)
[xn,yn,zn] = read_UBC_mesh([work_dir '\' meshfile]);
dx = xn(2:end) - xn(1:end-1); nx = length(dx);
dy = yn(2:end) - yn(1:end-1); ny = length(dy);
dz = zn(1:end-1) - zn(2:end); nz = length(dz);

mcell = (length(xn)-1) * (length(yn)-1) * (length(zn)-1);

% Load synthetic model
% m = load([work_dir '\' model_sus]);
load([work_dir '\nullcell.dat']);

% Load observation file (3C UBC-MAG format)
[H, I, Dazm, D, obsx, obsy, obsz, d, wd] = read_MAG3D_obs([work_dir '\' obsfile]);
% plot_mag3C(obsx,obsy,d,I,D,'Observed 3C-data')
% plot_TMI(obsx,obsy,d,d,wd,'Observed vs Predicted Magnitude');
ndata = length(obsx);
datax = d(1:ndata) ; wdx = wd(1:ndata);
datay = d(ndata+1:2*ndata) ; wdy = wd(ndata+1:2*ndata);
dataz = d(2*ndata+1:3*ndata) ; wdz = wd(2*ndata+1:3*ndata);

ampd = sqrt( datax.^2 + datay.^2 + dataz.^2 );
wd = sqrt( wdx.^2 + wdy.^2 + wdz.^2 );

Wd   = spdiags(1./wd,0,ndata,ndata);
Wdx   = spdiags(1./wdx,0,ndata,ndata);
Wdy   = spdiags(1./wdy,0,ndata,ndata);
Wdz   = spdiags(1./wdz,0,ndata,ndata);

nstn = length(obsx);

%% Create model magnetization vectors
m_azm = ones(mcell,1)*Dazm;
m_dip = ones(mcell,1)*I;
mv = azmdip_2_xyz(m_azm,m_dip,mcell);

M = [spdiags(H * mv(:,1),0,mcell,mcell);spdiags(H * mv(:,2),0,mcell,mcell);spdiags(H * mv(:,3),0,mcell,mcell)];

%% Load T matrix generated by FMAG3C
load([work_dir '\Tx']);
load([work_dir '\Ty']);
load([work_dir '\Tz']);

%% Compute depth weighting
wr = get_wr(obsx, obsy, obsz, D, I, xn, yn, zn, nullcell, wr_flag);
save([work_dir '\wr.dat'],'-ascii','wr');


%% Create gradient matrices and corresponding volume vectors
[Wx, Wy, Wz, Vx, Vy, Vz] = get_GRAD_op3D_v4(dx,dy,dz,nullcell);
[Ws, v ] = getWs3D(dx,dy,dz);

%% Depth weighting
IWr = spdiags(1./wr,0,mcell,mcell);
Wr = spdiags(wr,0,mcell,mcell);

V = spdiags((v),0,mcell,mcell);

%% Forward operator and apply depth weighting
Fx = Tx * M;
Fy = Ty * M;
Fz = Tz * M;

clear Tx Ty Tz

Fx = Wdx * Fx * IWr;
Fy = Wdy * Fy * IWr;
Fz = Wdz * Fz * IWr;

ampB = @(m) ( (Fx * m).^2 + (Fy * m).^2 + (Fz * m).^2 ) .^ 0.5;

%% Inversion
delta=1e-10;     %Small term in compact function

nl=length(lvec);
nq=length(qvec);
np=length(pvec);

target = chi_target * ndata;

d = Wd * ampd;
 
% fprintf('Iteration %i of %i.\n',sub2ind([nl,nq,np],ll,qq,pp),np*nq*nl); 
count=1;
mref = zeros(mcell,1);

comp_phi = @(m,phi,l) norm(ampB(m) - d).^2 +...
    (m)' * l * phi * (m);

counter = 1;
for ll= 1:length(lvec)

    for pp = 1:length(pvec)
        
        for qq = 1:length(qvec)   
            
            % Initialize inversion
            invmod      = Wr* ones(mcell,1)*1e-4;       % Initial model       
            mref        = zeros(mcell,1);       % Reference model 
            
            phi_init    = sum((G * invmod - d).^2);   % Initial misfit
            phi_d       = phi_init;
            phi_m       = [];         
            
            count=1;
            countbar = 0;
            
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
                    
            while phi_d(end)>target


                bx  = spdiags( Fx * invmod , ndata, ndata);
                by  = spdiags( Fy * invmod , ndata, ndata);
                bz  = spdiags( Fz * invmod , ndata, ndata);

                lBl   = ampB(invmod)  ;
        
                lBl   = spdiags( lBl.^-1 , 0 , ndata, ndata);

                J   = lBl * [bx by bz] * [Fx;Fy;Fz];
                
                if count==1                 

%                     [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF(invmod,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alpha,2,2,1);
                    [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF_mGRAD(invmod,nx,ny,nz,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alphas,2,2,1);
              
                    MOF_start = MOF;
                    
                    if isempty(beta)==1
                        beta = full( sum(sum(G.^2,1)) / sum(diag(MOF,0)) * 1e+4 );
                        
                    end
                        
                    lambda = beta ;
                    phi = norm(G*invmod - d).^2 +...
                        invmod' * lambda * MOF * invmod;
                    
                else
%                     [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF(invmod,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alpha,pvec(pp),qvec(qq),lvec(ll));

                    [MOF,aVRWs,aVRWx,aVRWy,aVRWz] = get_lp_MOF_mGRAD(invmod,nx,ny,nz,V,Ws,Vx,Wx,Vy,Wy,Vz,Wz,alphas,pvec(pp),qvec(qq),lvec(ll));

                    mu = ( invmod'* MOF_start * invmod ) / (invmod'*MOF*invmod ) ;

                    lambda = beta(count) * mu;



                end
   
                diagA = sum(J.^2,1) + lambda*spdiags(MOF,0)';
                PreCon     = ProG * spdiags(1./diagA(:),0,mcell,mcell);
                    
                 A = [ J * ProG ;...
                    sqrt( lambda ) * aVRWs * ProG ;...
                    sqrt( lambda ) * aVRWx * ProG ;...
                    sqrt( lambda ) * aVRWy * ProG ;...
                    sqrt( lambda ) * aVRWz * ProG ];

                g = [- (ampB(invmod) - d) ; ...
                    - sqrt( lambda ) * ( aVRWs *  (invmod - mref) ) ;...
                    - sqrt( lambda ) * ( aVRWx * (invmod - mref) ) ;...
                    - sqrt( lambda ) * ( aVRWy * (invmod - mref) ) ;...
                    - sqrt( lambda ) * ( aVRWz * (invmod - mref) ) ];


                %% Projected steepest descent
                dm = zeros(mcell,1);
                [dm,r,iter] = CGLSQ( dm, A , g, PreCon );

                pin = max( abs( dm ) );
                pac = max( abs( (speye(mcell) - ProG) * (A'*g) ) );

                p = 1;
                if pin < pac

                    p = pin / pac / 10;

                end

                dm = dm + p * ( speye(mcell) - ProG) * (A'*g) ;

                %% Step length, line search
                alpha = 2;

                % Initialise phi^k
                phi_temp = 0;   
                while (phi_temp > phi(end) || alpha == 2) 

                    alpha = 0.5 * alpha;

                    m_temp = invmod + alpha * dm;
                    lb =  m_temp >= 0;
                    % Apply bound on model
                    m_temp(lb==0) = 0;
                    ProG = spdiags(nullcell.*lb,0,mcell,mcell);

                    phi_temp = comp_phi(m_temp,MOF,lambda);

                end

                % Update model
                invmod = m_temp;

                %%
                clear A

                phi(count) = comp_phi(invmod,MOF,lambda);
                phi_d(count) = sum((ampB(invmod)-d).^2);

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
                fprintf(fid,'phis:\t %8.5e\n',invmod'*alphas(1)*WstWs*invmod);
                fprintf(fid,'phix:\t %8.5e\n',invmod'*alphas(2)*WxtWx*invmod);
                fprintf(fid,'phiy:\t %8.5e\n',invmod'*alphas(3)*WytWy*invmod);
                fprintf(fid,'phiz:\t %8.5e\n',invmod'*alphas(4)*WztWz*invmod);
                fprintf(fid,'phim:\t %8.5e\n',invmod'*MOF*invmod);
                fprintf(fid,'phi:\t %8.5e\n',phi(count));
                fprintf(fid,'Number of Inactive cells: %i\n',mcell-sum(lb));
                fprintf(fid,'Number of CGS iterations: %i\n',iter);

               % Output interation result
               
                model_out = IWr * invmod;
                model_out(nullcell==0) = -100;
                save([work_dir '\TMI_' 'p' num2str(pvec(pp)) 'q' num2str(qvec(qq)) 'l' num2str(lvec(ll)) '_iter_' num2str(count) '.sus'],'-ascii','model_out')
                write_MAG3D_TMI(work_dir,['\lBl_iter_' num2str(count) '.pre'],H,I,Dazm,obsx,obsy,obsz,ampB(invmod).*wd,wd)
                
              count=count+1;
              countbar = 0;  
            end
            
            count=count-1;            
            
            fprintf(fid,'End of lp inversion. Number of iterations: %i\n',count);
            fclose(fid);
            counter = counter+1;
           
        end
        
    end
    
end

% plot_TMI(obsx,obsy,d,pred,wd,'Observed vs Predicted')

%     invmod = IWr*invmod;
pred3C = ampB(invmod);
plot_TMI(obsx,obsy,d./wd,pred./wd,wd,'Observed vs Predicted Magnitude')
% plot_mag3C(obsx,obsy,pred3C./[wdx;wdy;wdz],I,D,' Inversion - Predicted')

 model_out = IWr * invmod;
model_out(nullcell==0) = -100;
save([work_dir '\' 'p' num2str(pvec(pp)) 'q' num2str(qvec(qq)) 'l' num2str(lvec(ll)) '.sus'],'-ascii','model_out')
   
