function u = P5D_Dubins_htc(rel_sys, uMode, s, p, g, deriv)

% Relative dynamics matrix
Q = zeros(5,3);
Q(1,1) = 1;
Q(2,2) = 1;
Q(3,3) = 1;

rel_x = s - Q*p;

dV = eval_u(g, deriv, rel_x);

% Find optimal control of relative system (no performance control)
u = rel_sys.optCtrl([], rel_x, dV, uMode);

end