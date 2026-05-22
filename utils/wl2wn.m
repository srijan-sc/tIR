function wn = wl2wn(wl_nm)
% Convert wavelength (nm) to wavenumber (cm-1).
wn = 1e7 ./ wl_nm;
