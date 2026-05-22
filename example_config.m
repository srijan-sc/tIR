cfg = tIRConfig.defaults();

cfg.sample_name   = 'FeRuFe dmso';
cfg.data_dir      = '/Users/srijan/Downloads/vscode/HBQ_3DVE/tIR/tIR/V3/2026_05/2026_05_21/';
cfg.cal_file      = fullfile(fileparts(mfilename('fullpath')), 'cailbration', 'center_3500nm.txt');
cfg.probe_file    = '/Users/srijan/Downloads/vscode/HBQ_3DVE/tIR/tIR/V3/2026_05/2026_05_21/probe_4716_150g_SampleReverence.txt';

cfg.root_name     = 'FeRuFe_DMSO_trace02_4716_150g_011_Row0';
cfg.pump_power_nJ = 50;
cfg.polarisation  = 'ZZZZ';

cfg.pixel_region  = 'bottom';
cfg.n_pixels      = 32;

cfg.time_zero     = -26998.7;
cfg.time_unit     = 'ps';

cfg.bg_subtract   = false;

cfg.plot_xRange   = [];
cfg.plot_yRange   = [];

cfg.slice_wavenumbers = [2950 3000 3050 3100];
cfg.slice_times       = [0 500 2000 10000];
