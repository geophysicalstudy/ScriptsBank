function [] = vecplot(vec,AVC, hx, hy, hz)

centre = @(x) x(1:end - 1) + 0.5*diff(x);

% Rebuild dimensions from h
xn = cumsum(hx); xn = [ 0; xn];
yn = cumsum(hy); yn = [ 0; yn];
zn = cumsum(hz); zn = [ 0; zn];
% Project onto cell centres
xc = centre(xn);
yc = centre(yn);
zc = centre(zn);

[X, Y, Z] = ndgrid(xc, yc, zc);

% Average cell faces to centres to get vector for centre of cell
% Avg2c = getop(hx, hy, hz, 'avg2centres', false);
vec = AVC * real(vec);


% Break vec into it's 3 components
n = round(length(vec) / 3);
u = vec(1 : n);
v = vec(n + 1 : 2*n);
w = vec(2*n + 1 : end);

% Plot
quiver3(X(:),Y(:),Z(:),u,v,w,'LineWidth',2)
xlabel('x')
ylabel('y')
zlabel('z')
set(gca,'ZDir','reverse')
view([-45 90]);