function start_message(p,q,l,chifact,cool_beta,iter_max)

fprintf('\n\nMIRA - AGIC\n')
fprintf('DC_lp_driver_v1.0\nCompact DC inversion\n')
fprintf('Author: D. Fournier\n')
fprintf('Last update: July 2th, 2013\n')
fprintf('\n\n**Input Parameters**\n')
fprintf(['lp-norm on gradient   ||GRAD(m)||p   : ' num2str(p) '\n'])
fprintf(['lq-norm on model         ||m||q      : ' num2str(q) '\n'])
fprintf(['Scaling factor                       : ' num2str(l) '\n'])
fprintf('Maximum number of iterations         : %i\n',iter_max)
fprintf('Trade-off parameter cooling schedule : %5.3f\n',cool_beta)
fprintf('\n\n** Ready to invert **\n')