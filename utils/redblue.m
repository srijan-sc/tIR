function c = redblue(m)
% Blue-white-red diverging colormap.
% Unified replacement for redblue_1.m and redblue_3.m.
% Compatible with both @redblue function-handle and redblue(m) usage.
%
% Original algorithm: Adam Auton, 9th October 2009.

if nargin < 1, m = size(get(gcf, 'colormap'), 1); end

if mod(m, 2) == 0
    m1 = m / 2;
    r  = (0:m1-1)' / max(m1-1, 1);
    g  = r;
    r  = [r; ones(m1, 1)];
    g  = [g; flipud(g)];
    b  = flipud(r);
else
    m1 = floor(m / 2);
    r  = (0:m1-1)' / max(m1, 1);
    g  = r;
    r  = [r; ones(m1+1, 1)];
    g  = [g; 1; flipud(g)];
    b  = flipud(r);
end

c = [r g b];
