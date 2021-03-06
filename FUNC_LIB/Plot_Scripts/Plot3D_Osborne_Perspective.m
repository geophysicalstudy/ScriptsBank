% Create figure through 3D model
clear all



addpath ..\..\FUNC_LIB;

%% Input Files
% work_dir = 'C:\Users\dominiquef.MIRAGEOSCIENCE\ownCloud\Research\Modelling\Synthetic\Nut_Cracker\Tiled_AMI\Tile1';
% work_dir = 'C:\Users\dominiquef.MIRAGEOSCIENCE\ownCloud\Research\Modelling\Synthetic\Nut_Cracker\Tiled_CMI\Tile1';
% work_dir = 'C:\Users\dominiquef.MIRAGEOSCIENCE\ownCloud\Research\Modelling\Synthetic\SingleBlock\CMI\MVI';
work_dir = 'C:\Users\dominiquef.MIRAGEOSCIENCE\ownCloud\Research\Osborne\Inversion\ROT40\CMI\CMI_as1';

meshfile = 'Tile1.msh';

dsep = '\';

% obsfile = 'Tile_data.dat';
% model_true = '..\..\Block.sus';
geo_unit = 'C:\Users\dominiquef.MIRAGEOSCIENCE\ownCloud\Research\Osborne\Section_21360.dat';

% mag_vecfile = '\l2l2\Mvec_TMVI_iter_.fld';
% predfile = '\l2l2\TMVI_iter_.pre';

mag_vecfile = 'Tile1_MVI.fld';
obsfile = 'Tile1_MVI.pre';

% mag_vecfile = '..\..\m_rem.dat';
% obsfile = '..\Obs_loc_TMI.obs';

% mag_vecfile = '..\magvec.fld';
% obsfile = '..\..\Obs_RAW_REM_GRID_TMI.obs';


zpanel = 5;
ypanel = 8;

padE = 10;
padW = 15;

padN = 12;
padS = 12;

padT = 0;
padB = 10;

iso_cut_surf = 0.01;
iso_cut_vec = 0.01;

mmax = 0.75;

cam_ang = [-15 30];

vscale = 1;

% Define cutting planes
% nvec(1,1:3) = [0 -0.2 1]; xo = 1000; yo = 850  ; zo = 1420;
% nvec(2,1:3) = [0 1 0]; xo(2) = 1000; yo(2) = 730  ; zo(2) = 1440;
nvec(3,1:3) = [0 1 0]; x0 = 455970; y0 = 7556190  ; z0 = 300;

nvec = spdiags( 1./ sqrt(sum(nvec.^2,2)) , 0 ,3 ,3) * nvec;

cut_name = ['A','B','C'];

% Color scheme

%% Load in model and plot
set(figure, 'Position', [200 50 750 400]); 

% Load data
[H, HI, HD, MI,MD, obsx, obsy, obsz, d, wd] = read_MAG3D_obs([work_dir dsep obsfile]);
% H=1000;

[xn,yn,zn] = read_UBC_mesh([work_dir '\' meshfile]);

% Move to local coordinates
% obsx = obsx - xn(1);
% obsy = obsy - yn(1);
% obsz = obsz - zn(1);

% xn = xn - xn(1);
% yn = yn - yn(1);
% zn = zn - zn(1);

dx = xn(2:end) - xn(1:end-1); nx = length(dx);
dy = yn(2:end) - yn(1:end-1); ny = length(dy);
dz = zn(1:end-1) - zn(2:end); nz = length(dz);
xx = (xn(2:end) + xn(1:end-1))/2;   xx = xx(padW+1:end-padE);
yy = (yn(2:end) + yn(1:end-1))/2;   yy = yy(padS+1:end-padN);
zz = (zn(2:end) + zn(1:end-1))/2;   zz = zz(padT+1:end-padB);

[XX,ZZ,YY] = meshgrid(xx,zz,yy); 

% Load mag true
% m_true = load([work_dir '\' model_true]);
% m_true = reshape(m_true,nz,nx,ny);


% Load magnetization vector
mag_model = load([work_dir '\' mag_vecfile]);

% Load geo unit
bif = load(geo_unit);

% Load inverted model
% m = load([work_dir '\..\..\Effec_sus_20mGrid.sus']);
m = sqrt(sum(mag_model.^2,2));
m = reshape(m,nz,nx,ny);


mcell = size(mag_model,1);
%% Create model magnetization vectors
% Azimuth and dip of magnitization
if size(mag_model,2)==2
    
    mag_xyz = azmdip_2_xyz( mag_model(:,1)+180 , mag_model(:,2) );
    

else
    
    mag_xyz = mag_model;
%     mag_xyz(mag_xyz(:,3)~=0,1:2)=0;
%     mag_xyz(mag_xyz(:,3)~=0,3)=m(mag_xyz(:,3)~=0);
%     M = [spdiags(m_true(:).*mag_model(:,1),0,mcell,mcell);spdiags(m_true(:).*mag_model(:,2),0,mcell,mcell);spdiags(m_true(:).*mag_model(:,3),0,mcell,mcell)];

   
end

mx = reshape(mag_xyz(:,1),nz,nx,ny);
my = reshape(mag_xyz(:,2),nz,nx,ny);
mz = reshape(-mag_xyz(:,3),nz,nx,ny);

mx = mx( padT+1:end-padB,padW+1:end-padE,padS+1:end-padN );
my = my( padT+1:end-padB,padW+1:end-padE,padS+1:end-padN );
mz = mz( padT+1:end-padB,padW+1:end-padE,padS+1:end-padN );
    
% m_true = m_true( padT+1:end-padB,padW+1:end-padE,padS+1:end-padN );
m = m( padT+1:end-padB,padW+1:end-padE,padS+1:end-padN );




%%



[XX2D,ZZ2D] = meshgrid(min(xx):10:max(xx),min(zz):10:max(zz));
YY2D = ones(size(XX2D)) * y0;
% Interpolate on cutting plane
% m2D = get_model_top(m1,nx,ny,nz,-100);

% cvec = [min(m(:)) prctile(m(m>0),[10 30 60]) max(m(:))];
% bb = interp1([cvec'],[255 255 255;77 190 238;255 255 0;255 127 0;255 0 0]/255,sort(m(:)));

m2D = griddata(XX(:),YY(:),ZZ(:),m(:),XX2D,YY2D,ZZ2D,'natural'); 
% m2D = F(XX2D,YY2D,ZZ2D);

% F = TriScatteredInterp(XX(:),YY(:),ZZ(:),mx(:),'natural'); 
mx2D = squeeze(mx(:,:,15));%F(XX2D,YY2D,ZZ2D);

% F = TriScatteredInterp(XX(:),YY(:),ZZ(:),my(:),'natural'); 
my2D = squeeze(my(:,:,15));%F(XX2D,YY2D,ZZ2D);

% F = TriScatteredInterp(XX(:),YY(:),ZZ(:),mz(:),'natural'); 
mz2D = squeeze(mz(:,:,15));%F(XX2D,YY2D,ZZ2D);

% F = TriScatteredInterp(XX(:),YY(:),ZZ(:),m_true(:),'natural'); 
% m2D_true = F(XX2D,YY2D,ZZ2D);



% temp = (temp');
vec = sum([mx2D(:).^2 my2D(:).^2 mz2D(:).^2],2).^0.5;

    
ax1 = axes('Position',[0.075 .2 .75 .75]);
%     h = imagesc(xx,yy,m2D); hold on

% scatter(min(XX2D(:)), max(YY2D(:)),'k.'); hold on
% text(min(XX2D(:)), max(YY2D(:)),['\textbf{' cut_name(ii) '}'],'interpreter', 'latex','FontSize',14,'VerticalAlignment','top');
% scatter(max(XX2D(:)), min(YY2D(:)),'k.')
% text(max(XX2D(:)), min(YY2D(:)),['\textbf{' cut_name(ii) '"}'],'interpreter', 'latex','FontSize',14,'HorizontalAlignment','right');
%     title('$Model$','interpreter', 'latex','FontSize',14);

%     qq = quiver(xx,yy,mx2D,my2D,'LineWidth',1,'Color','k','MaxHeadSize',1);
h = surf(XX2D,YY2D,ZZ2D,m2D,'EdgeColor','none'); hold on
alpha(0.85)
view(cam_ang)
set(gca,'YDir','normal')

% for ii = 1 : 2
%     for jj = 1 : 2
%         j = (-1)^ii;
%         k = (-1)^jj;
%         quiver3(k*j*60,j*60,-140+j*60,0,-j*120,0,'LineWidth',2,'Color','k','ShowArrowHead','off','AutoScale','off');
%         quiver3(j*60,k*j*60,-140+j*60,-j*120,0,0,'LineWidth',2,'Color','k','ShowArrowHead','off','AutoScale','off');
%         quiver3(j*60,k*j*60,-140+j*60,0,0,-j*120,'LineWidth',2,'Color','k','ShowArrowHead','off','AutoScale','off');
%     end
% end

scatter3(bif(:,1),bif(:,2),bif(:,3),'k.')
% quiver3(0,min(yy),-min(dz),0,-2*sum(yy),0,'LineWidth',2,'Color','k','ShowArrowHead','off','AutoScale','off');


% colormap('jet')
%plot_vec(ax1,XX2D,YY2D,ZZ2D,mx2D,my2D,mz2D,m2D,iso_cut_vec,0,0.5,1.25,3)

% axis([min(XX2D(:)) max(XX2D(:)) min(YY2D(:)) max(YY2D(:))])

set(gca,'YTickLabel',[],'Box','on')
% set(gca,'XTickLabel',[],'Box','on')
zlabel('$z$', 'interpreter', 'latex','FontSize',14)
ylabel('$y$', 'interpreter', 'latex','FontSize',14)
zlabh = get(gca,'ZLabel');
set(zlabh,'Position',get(zlabh,'Position') - [0.05 0 0])

% ylabh = get(gca,'YLabel');
% set(ylabh,'Position',get(ylabh,'Position') - [1 0 0])

set(get(gca,'ZLabel'),'Rotation',360);
axis equal
grid on

set(gca, 'YAxisLocation', 'right')
set(gca,'YDir','normal')
hold on

[XX2D,ZZ2D] = meshgrid(xx+min(dx)/2,zz+min(dx)/2);
YY2D = ones(size(XX2D)) * y0;
arrow3([XX2D(:),YY2D(:),ZZ2D(:)],[mx2D(:)./vec,my2D(:)./vec,mz2D(:)./vec],'k',vec*0.5/max(vec),vec/max(vec),'cone')


cvec = mmax*[0 0.2 0.4 0.6 0.8 1.05];
bb = interp1([cvec'],[255 255 255;77 190 238;255 255 0;255 127 0;255 0 0;255 153 200]/255,0:1e-4:mmax,'linear');
colormap(ax1,bb);
%colormap(ax2,bb);
caxis(ax1,[0 mmax])
ylim([y0-10, y0 + 10])
% caxis(ax2,[0 mmax])
%% Add color bar
%%
ax = axes('Position',[0.3 -0.1 .30 .30]);

% bb = interp1([cvec'],[255 255 255;77 190 238;255 255 0;255 127 0;255 0 0]/255,min(cvec):1e-4:max(cvec));

cbar = colorbar(ax,'NorthOutside');
% caxis([0 mmax]);

colormap(ax,bb);
caxis([0 mmax])
% set(cbar,'Ticks',[0 0.25 0.5 0.75 1])
% set(cbar,'TickLabels',round(cvec*10000)/10000)

set(gca,'Visible','off');
text(0.5,2.2,'$\kappa_{e}$', 'interpreter', 'latex','FontSize',16,'HorizontalAlignment','center')
% text(0.45,8.25,'$(a)$', 'interpreter', 'latex','FontSize',14,'HorizontalAlignment','center')


%% Plot Data
% Load data
a = axes('Position',[0.725 .6 .35 .35]);
nx = 100;
ny = 100;

xmin = ( min(obsx) );
xmax = ( max(obsx) );
ymin = ( min(obsy) );
ymax = ( max(obsy) );

dx = (( xmax - xmin) / nx);
dy = (( ymax - ymin) / ny);

x = xmin + cumsum(ones(1,nx)*dx);
y = ymin + cumsum(ones(1,ny)*dy);

[X,Y] = meshgrid(x,y);

data_interp     = griddata(obsx, obsy, d,X,Y,'linear'); 
% data_interp(isnan(data_interp)) = min(data_interp(:))*2;


% h =imagesc(x,y,data_interp);hold on
% set(h,'alphadata',~isnan(data_interp))
% caxis([min(data_interp(:)) max(data_interp(:))]);
% colormap(a,jet);
contour(x,y,data_interp,'k'); hold on
% scatter(obsx,obsy,2,'k.')
set(gca,'YDir','normal')
% xlabel('\bfEasting (m)')
% ylabel('$y$', 'interpreter', 'latex','FontSize',14)
xlabel('$x$', 'interpreter', 'latex','FontSize',14)
set(get(gca,'YLabel'),'Rotation',360);
% set(gca, 'XAxisLocation', 'top')
axis([min(x) max(x) min(y) max(y)])
% set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
grid on
axis equal
axis tight
% title('$d^{Fwr}$', 'interpreter', 'latex','FontSize',14)
% text(min(xx)-dx*20, mean(yy),'$(a)$', 'interpreter', 'latex','FontSize',14)



%% Add colorbars
% ax = axes('Position',[0.66 -0.1 .30 .30]);
% cbar = colorbar('NorthOutside');
% colormap(ax,jet);
% set(cbar,'Ticks',[0 1])
% set(cbar,'TickLabels',round([min(data_interp(:)) max(data_interp(:))]))
% set(gca,'Visible','off');
% text(0.5,2.2,'$TMI\;(nT)$', 'interpreter', 'latex','FontSize',12,'HorizontalAlignment','center')
% text(0.45,8.4,'$(b)$', 'interpreter', 'latex','FontSize',14)
