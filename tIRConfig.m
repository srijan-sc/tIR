classdef tIRConfig
% TIRCONFIG  Factory for tIR experiment configuration structs.
%
% All parameters are documented here as the single source of truth.
% No defaults contain hardcoded paths.
%
% Usage:
%   cfg = tIRConfig.defaults();          % start from defaults, fill in paths
%   cfg = tIRConfig.fromFile('my_cfg.m') % load from a config script
%   cfg = tIRConfig.fromDialog()         % interactive GUI path picker
%   tIRConfig.validate(cfg)              % warn on missing required fields

    methods (Static)

        function cfg = defaults()
        % Return a config struct with all fields and their default values.

            cfg = struct();

            % ---- Identity (shown in all plot titles) ----
            cfg.sample_name = '';  % e.g. 'CdS 400nm' — prepended to every plot title

            % ---- Paths (required — no sensible defaults) ----
            cfg.data_dir    = '';   % folder containing scan .txt files
            cfg.cal_file    = '';   % calibration .txt (pixel wavelengths in nm)
            cfg.probe_file  = '';   % probe .txt path
                                    %   ''     -> auto-detect probe_*.txt in data_dir
                                    %   'none' -> skip probe normalization entirely

            % ---- Dataset ----
            cfg.root_name      = '';    % filename prefix, e.g. '50nJ_time_scan_02'
            cfg.pump_power_nJ  = NaN;  % pump power in nJ (used in power dependence)
            cfg.polarisation   = '';   % e.g. 'ZZZZ', 'ZZYY' — shown in plot title

            % ---- Time display ----
            cfg.time_unit = 'fs';  % 'fs' or 'ps' — affects all x-axis labels and slice inputs

            % ---- Detector ----
            cfg.pixel_region = 'top';  % 'top' (rows 1:n) | 'bottom' (rows n+1:2n) | 'all'
            cfg.n_pixels     = 32;     % pixels per half-array

            % ---- File column order ----
            % Used as fallback if suffix-based detection (_Data/_StDev/_Time) fails.
            cfg.data_idx    = 1;
            cfg.stdev_idx   = 2;
            cfg.time_idx    = 3;
            cfg.probe_col   = 2;   % column of probe file that holds intensity values

            % ---- Axes ----
            cfg.cm_axis = true;    % true = wavenumber axis (cm-1) | false = pixel index

            % ---- Time ----
            % Set time_zero to the raw scanner position of pump-probe overlap (fs).
            % Run once with time_zero=0, read the peak from plotProjection(), then
            % set this value and re-run — no index hunting needed.
            cfg.time_zero = 0;

            % ---- Processing ----
            cfg.bg_subtract = false;   % subtract mean of all pre-t0 frames

            % ---- Slice positions for quick-look plots ----
            % ---- Contour plot display range ----
            cfg.plot_xRange = [];          % time window [tMin tMax] fs; [] = full range
            cfg.plot_yRange = [];          % wavenumber window [wMin wMax] cm-1; [] = full range

            % ---- Projection options ----
            cfg.projection_negate = false; % negate so negative signal plots as decay

            cfg.slice_wavenumbers = []; % e.g. [2800 2860 2920]  — any number of values
            cfg.slice_times       = []; % e.g. [500 5000 50000]  — time delays in fs
        end

        function cfg = fromFile(path)
        % Load config from a .m script that defines a struct named 'cfg'.
        %
        %   cfg = tIRConfig.fromFile('my_experiment_cfg.m')
            if ~isfile(path)
                error('tIRConfig.fromFile: file not found: %s', path);
            end
            run(path);
            if ~exist('cfg', 'var')
                error('tIRConfig.fromFile: config file must define a struct named ''cfg''.');
            end
            cfg = tIRConfig.applyDefaults(cfg);
        end

        function cfg = fromDialog(varargin)
        % Build a config interactively via GUI dialogs, then apply any
        % additional field overrides passed as name-value pairs.
        %
        %   cfg = tIRConfig.fromDialog('root_name', '50nJ_scan_01', 'time_zero', 1200)
            cfg = tIRConfig.defaults();

            % Data directory
            d = uigetdir(pwd, 'Select data directory');
            if isequal(d, 0), error('tIRConfig.fromDialog: no directory selected.'); end
            cfg.data_dir = d;

            % Calibration file
            [f, p] = uigetfile('*.txt', 'Select calibration file', d);
            if ~isequal(f, 0)
                cfg.cal_file = fullfile(p, f);
            end

            % Apply name-value overrides
            for i = 1:2:numel(varargin)
                cfg.(varargin{i}) = varargin{i+1};
            end
        end

        function validate(cfg)
        % Warn on missing or empty required fields. Does not error.
            required = {'data_dir', 'root_name', 'cal_file'};
            for i = 1:numel(required)
                f = required{i};
                if ~isfield(cfg, f) || isempty(cfg.(f))
                    warning('tIRConfig.validate: required field ''%s'' is empty.', f);
                end
            end
            valid_regions = {'top', 'bottom', 'all'};
            if isfield(cfg, 'pixel_region') && ~ismember(lower(cfg.pixel_region), valid_regions)
                warning('tIRConfig.validate: pixel_region must be ''top'', ''bottom'', or ''all''.');
            end
        end

        function toFile(cfg, path)
        % Write a config struct to a .m file compatible with fromFile().
            fid = fopen(path, 'w');
            if fid == -1
                error('tIRConfig.toFile: cannot write to %s', path);
            end
            fprintf(fid, 'cfg = tIRConfig.defaults();\n\n');
            fields = fieldnames(cfg);
            for i = 1:numel(fields)
                f = fields{i};
                v = cfg.(f);
                if ischar(v)
                    fprintf(fid, 'cfg.%s = ''%s'';\n', f, v);
                elseif islogical(v)
                    fprintf(fid, 'cfg.%s = %s;\n', f, mat2str(v));
                elseif isnumeric(v) && isscalar(v)
                    fprintf(fid, 'cfg.%s = %g;\n', f, v);
                elseif isnumeric(v)
                    fprintf(fid, 'cfg.%s = %s;\n', f, mat2str(v));
                end
            end
            fclose(fid);
        end

    end

    methods (Static, Access = private)

        function cfg = applyDefaults(cfg)
        % Fill any missing fields with defaults.
            defs   = tIRConfig.defaults();
            fields = fieldnames(defs);
            for i = 1:numel(fields)
                f = fields{i};
                if ~isfield(cfg, f)
                    cfg.(f) = defs.(f);
                end
            end
        end

    end

end
