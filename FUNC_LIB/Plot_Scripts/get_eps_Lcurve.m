function [eps_p,eps_q] = get_eps_Lcurve(m,pct_i,Gx,Gy,Gz)
% Function [eps_p,eps_q] = get_eps(m,pct_i,Gx,Gy,Gz)
% Finds epsilon values for lp and lq norm based on the distribution of
% model parameters.
% Input:
% m : model from the l2-norm inversion
% pct_i: Base percentile increment used to compute curvature
% Gx: Gradient operator in the x-direction. 
% Gy (optional): Gradient operator in the y-direction. Assume 1D problem if
% empty
% Gz (optional): Gradient operator in the z-direction. Assume 2D problem if
% empty


%% SCRIPT STARTS HERE
% Check if 1D, 2D or 3D problem

p = 0;
q = 0;

if ~isempty(Gz) && ~isempty(Gy)
    
    gradm = sqrt( (Gx * m).^2 + (Gy * m).^2 + (Gz * m).^2 );

elseif isempty(Gz) && ~isempty(Gy)
    
    gradm = sqrt( (Gx * m).^2 + (Gy * m).^2 );
    
else
    
    gradm = abs(Gx * m);
    
end

% gradm = gradm(gradm~=0);
% m = m(m~=0);

mcell = length(m);

[msort,idx] = sort(abs(m));

set(figure, 'Position', [50 0 775 775]);
axes('Position',[0.1 .55 .38 .38]);
plot(msort);
hold on
axis square

pct = 0:pct_i:100;
mpct = prctile(abs(m),pct);
pctm = floor(mcell/100)*pct_i;

plot(0:pctm:mcell,mpct,'rx')
%                             ylim([0 100])
%                             set(figure(100), 'Position', [50 200 750 750])
%                             plot(x,model,'LineWidth',2);axis([x(1) x(end) -0.1 0.5]);hold on
%                             axis square
grid on
text(25,0.325,'(a)','interpreter','latex','FontSize',12,'HorizontalAlignment','center','VerticalAlignment','middle')

%% Eps for model gradient term

mcell = length(gradm);

dm2d2x = (mpct(1:end-2) + mpct(3:end) - 2*mpct(2:end-1));
dmdx = ((mpct(2:end-1)+mpct(3:end))/2 - (mpct(1:end-2)+mpct(2:end-1))/2);
curv = abs(dm2d2x./(1 + dmdx.^2).^(3/2));
mpct = mpct(2:end-2);
% Find the point of maximum increase in curvature
[~,idx] = max(abs(curv(1:end-1) - curv(2:end)));

plot(idx*pctm,mpct(idx),'bo');
set(gca,'XTick',0:pctm:mcell)
set(gca,'XTickLabel',pct)
xlabel('Percentile')
set(gca,'Xdir','Reverse')
ylabel('$m$','interpreter','latex','FontSize',12)

eps_p = mpct(idx);%prctile(abs(m),);
text(idx*pctm,mpct(idx),['$\epsilon_p$=' num2str(round(eps_p/10^floor(log10(eps_p)))) 'e' num2str(floor(log10(eps_p)))],'interpreter','latex','FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom')

[msort,idx] = sort(abs(gradm));


axes('Position',[0.58 .55 .38 .38]);
plot(msort);
hold on
axis square
%                             pct = 0:10:100;
mpct = prctile(abs(gradm),pct);

plot(0:pctm:mcell,mpct,'rx')
%                             ylim([0 100])
%                             set(figure(100), 'Position', [50 200 750 750])
%                             plot(x,model,'LineWidth',2);axis([x(1) x(end) -0.1 0.5]);hold on
%                             axis square
grid on

dm2d2x = (mpct(1:end-2) + mpct(3:end) - 2*mpct(2:end-1));
dmdx = ((mpct(2:end-1)+mpct(3:end))/2 - (mpct(1:end-2)+mpct(2:end-1))/2);
curv = abs(dm2d2x./(1 + dmdx.^2).^(3/2));
mpct = mpct(2:end-2);
% Find the point of maximum increase in curvature
[~,idx] = max(abs(curv(1:end-1) - curv(2:end)));

plot(idx*pctm,mpct(idx),'bo');

eps_q = mpct(idx);%prctile(abs(m),);
ylabel('$\nabla m$','interpreter','latex','FontSize',12)
text(idx*pctm,mpct(idx),['$\epsilon_q$=' num2str(round(eps_q/10^floor(log10(eps_q)))) 'e' num2str(floor(log10(eps_q)))],'interpreter','latex','FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom')
%                     eps_s = std(m)/4;
set(gca,'XTick',0:pctm:mcell)
set(gca,'XTickLabel',pct)
xlabel('Percentile')
set(gca,'Xdir','Reverse')
text(25,0.019,'(b)','interpreter','latex','FontSize',12,'HorizontalAlignment','center','VerticalAlignment','middle')

%% PLOT s_MS curve
if ~isempty(Gz) && ~isempty(Gy)
    
    gradm = sqrt( (Gx * m).^2 + (Gy * m).^2 + (Gz * m).^2 );

elseif isempty(Gz) && ~isempty(Gy)
    
    gradm = sqrt( (Gx * m).^2 + (Gy * m).^2 );
    
else
    
    gradm = abs(Gx * m);
    
end

s = zeros(1,10);
e = 10.^(-(0:0.25:8));

for ee = 1 : length(e)

    r = (m.^2 + e(ee).^2).^(p/2-1);
    s(ee) = m'*(r.*m);
    
end

% figure;plot(eps_temp,s);
e = log10(e);                            

mcell = length(m);


axes('Position',[0.1 .075 .38 .38]);
plot(e,s);
hold on
axis square

% pct = 0:pct_i:100;
% mpct = prctile(abs(m),pct);
% pctm = floor(mcell/100)*pct_i;

% plot(0:pctm:mcell,mpct,'rx')
%                             ylim([0 100])
%                             set(figure(100), 'Position', [50 200 750 750])
%                             plot(x,model,'LineWidth',2);axis([x(1) x(end) -0.1 0.5]);hold on
%                             axis square
grid on

mcell = length(gradm);

dm2d2x = (s(1:end-2)-2*s(2:end-1) + s(3:end));
dmdx = ((s(2:end-1)+s(3:end))/2 - (s(1:end-2)+s(2:end-1))/2);
curv = abs(dm2d2x./(1 + dmdx.^2).^(3/2));


% subplot(2,2,3)
% plot(e(2:end-2),abs(curv(1:end-1) - curv(2:end)),'rx');hold on

[~,idx] = max(abs(curv(1:end-1) - curv(2:end)));
    
% Find the point of maximum increase in curvature
% [~,idx] = max(abs(curv(1:end-1)-curv(2:end)));
eps_p = e(idx);%prctile(abs(m),);

% subplot(2,2,1)
plot(eps_p,s(idx),'bo');


% set(gca,'XTick',0:pctm:mcell)
% set(gca,'XTickLabel',pct)
xlabel('$log(\epsilon)$','interpreter','latex')
ylabel('$s_{MS}$','interpreter','latex','FontSize',12)
set(gca,'Xdir','Reverse')
set(gca,'Ydir','Reverse')
text(eps_p,s(idx),['$\epsilon_p$=' num2str(round(10^eps_p/10^floor((eps_p)))) 'e' num2str(floor(eps_p))],'interpreter','latex','FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom')
text(-7.5,10,'(c)','interpreter','latex','FontSize',12,'HorizontalAlignment','center','VerticalAlignment','middle')
%% Eps for model gradient term

s = zeros(1,10);
e = 10.^(-(1:0.25:8));

for ee = 1 : length(e)

    r = (gradm.^2 + e(ee).^2).^(q/2-1);
    s(ee) = gradm'*(r.*gradm);
    
end

e = log10(e); 
% figure;


axes('Position',[0.58 .075 .38 .38]);
plot(e,s);
hold on
axis square
grid on

dm2d2x = (s(1:end-2)-2*s(2:end-1) + s(3:end));
dmdx = ((s(2:end-1)+s(3:end))/2 - (s(1:end-2)+s(2:end-1))/2);
curv = abs(dm2d2x./(1 + dmdx.^2).^(3/2));
% curv = zeros(1,length(e)-1);
% 
% for ii = 2 : length(e)-1
%     
%     x = e(ii-1:ii+1);
%     y = s(ii-1:ii+1);
%     
%     mx = mean(x); my = mean(y);
%     X = x - mx; Y = y - my; % Get differences from means
%     dx2 = mean(X.^2); dy2 = mean(Y.^2); % Get variances
%     t = [X,Y]\(X.^2-dx2+Y.^2-dy2)/2; % Solve least mean squares problem
%     a0 = t(1); b0 = t(2); % t is the 2 x 1 solution array [a0;b0]
%     r = sqrt(dx2+dy2+a0^2+b0^2); % Calculate the radius
% %     a = a0 + mx; b = b0 + my; % Locate the circle's center
%     curv(ii) = 1/r; % Get the curvature
%  
% 
% 
% %     if curv > k
% %         
% %         k = curv;
% %         idx = ii;
% %     end
% end

% subplot(2,2,4)
% plot(e(2:end-2),abs(curv(1:end-1) - curv(2:end)),'rx');hold on

[~,idx] = max(abs(curv(1:end-1) - curv(2:end)));

eps_q = e(idx);%prctile(abs(m),);
% subplot(2,2,2)
plot(eps_q,s(idx),'bo');


% set(gca,'XTick',0:pctm:mcell)
% set(gca,'XTickLabel',pct)
xlabel('$log(\epsilon)$','interpreter','latex')
ylabel('$s_{MGS}$','interpreter','latex','FontSize',12)
set(gca,'Xdir','Reverse')
set(gca,'Ydir','Reverse')
text(eps_q,s(idx),['$\epsilon_q$=' num2str(round(10^eps_q/10^floor(eps_q))) 'e' num2str(floor(eps_q))],'interpreter','latex','FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom')
text(-7.5,10,'(d)','interpreter','latex','FontSize',12,'HorizontalAlignment','center','VerticalAlignment','middle')
