function modfunc = phim_vDF(x,p,Wx,Wz,Ws,ax,az,ac,q)
% function modfunc = phim(mode,x,p,Wx,Wz,lambda,q)
% ---
% Generalized model objective function for the 2D problem given by:
%                Phim = ||x||^p + lambda*||m||^q
%
% Inputs:
%             model: x
%         exponents: p,q
% derivative matrix: Wx, Wz
%            alphas: ax,az
% ---

%% Model derivatives:
Wxm = (Wx) * x;
Wzm = (Wz) * x;

% Small term in compact function
delta=1e-11;

%% Calculate p-norm:
R = 1./( abs(Wxm).^(2-p) + delta );
Rx = diag(R);
R = 1./( abs(Wzm).^(2-p) + delta );
Rz = diag(R);

part1 = ax*Wx'*Rx*Wx + az*Wz'*Rz*Wz;

if ~(nargin == 9)
   return;
end
%% Add second portion ("q-norm"):
Rc = 1./( abs(x).^(2-q) + delta );
WctWc = Ws' * diag(Rc) * Ws; 
%Should be multiplied by Ws from both side, but for now Ws = I

scaleC = (x'*(part1)*x)/(x'*WctWc*x);
% NOTE: Lambda will should be an input, it controles the relative weight
% between WctWc and (WxtWx+WztWz) after it has been scaled.

% Final model objective function:
% modfunc = ax*Wx'*Rx*Wx + az*Wz'*Rz*Wz + scaleC*ac*WctWc;
modfunc = part1 + scaleC*ac*WctWc;
return
end
