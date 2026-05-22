classdef tIRDataset < SpectroscopyBase
% TIRDATASET  Single tIR pump-probe dataset.
%
% Inherits plotting, filtering, and saving from SpectroscopyBase.
% Only load() is tIR-specific.
%
% Usage:
%   cfg = tIRConfig.defaults();
%   cfg.data_dir  = '/path/to/data';
%   cfg.cal_file  = '/path/to/center_3300nm.txt';
%   cfg.root_name = '50nJ_time_scan_02';
%   cfg.time_zero = 1200;   % read from plotProjection on first run
%
%   ds = tIRDataset(cfg);
%   ds.load();
%   ds.plotProjection();          % verify t=0; adjust cfg.time_zero if needed
%   ds.normalize();               % probe normalization (skipped if no probe found)
%   ds.pixelRange = [1 32];
%   ds.plotContour();
%   ds.plotSlices([2800 2860 2920]);

    properties
        stdev       % [pixel x time]  scan-to-scan standard deviation
        probeRef    % [pixel x 1]     probe reference spectrum
        hasProbe  = false
        dataNorm    % [pixel x time]  probe-normalized processedData; set by normalize()
        config      % tIRConfig struct
    end

    methods

        % -------------------------------------------------------------- %
        %  Constructor                                                     %
        % -------------------------------------------------------------- %
        function obj = tIRDataset(cfg)
            if nargin > 0
                tIRConfig.validate(cfg);
                obj.config = cfg;
                obj.label  = cfg.root_name;
            end
        end

        % -------------------------------------------------------------- %
        %  load  — implements SpectroscopyBase abstract method            %
        % -------------------------------------------------------------- %
        function load(obj)
        % Load all scan files, build corrected axes, optionally subtract background.
            cfg    = obj.config;
            direct = cfg.data_dir;
            root   = cfg.root_name;

            % --- Locate and load the three scan files by filename suffix ---
            data_file  = obj.findSuffixFile(direct, root, '_Data');
            stdev_file = obj.findSuffixFile(direct, root, '_StDev');
            time_file  = obj.findSuffixFile(direct, root, '_Time');

            raw_data  = load(data_file);
            raw_stdev = load(stdev_file);
            raw_time  = load(time_file);

            % --- Pixel region selection (top / bottom / all) ---
            total_rows   = size(raw_data, 1);
            [r1, r2]     = obj.pixelRows(total_rows);
            data_slice   = raw_data(r1:r2, :);
            stdev_slice  = raw_stdev(r1:r2, :);

            % --- Time axis: shift by absolute t0, correct sign convention ---
            % Physical delay = time_zero - raw_time when scanner runs high→low,
            % matching the original: time_ax = -1*(raw_time - time_offset).
            % If scanner ran low→high (ascending raw), raw subtract gives correct sign.
            t = raw_time(:) - cfg.time_zero;
            if t(1) > t(end)
                % Scanner ran high→low: negate to get positive delays after t=0.
                % Data column order is preserved — negation does not change alignment.
                t = -t;
            else
                % Scanner ran low→high: already ascending, but data runs backwards
                % relative to physical delay — flip both.
                data_slice  = fliplr(data_slice);
                stdev_slice = fliplr(stdev_slice);
            end
            obj.timeAxis = t';

            % --- Wavenumber or pixel axis ---
            if cfg.cm_axis && ~isempty(cfg.cal_file)
                cal            = load(cfg.cal_file);
                wn             = wl2wn(cal(:));
                [wn_s, idx]    = sort(wn);
                data_slice     = data_slice(idx, :);
                stdev_slice    = stdev_slice(idx, :);
                obj.waveAxis   = wn_s';
            else
                obj.waveAxis   = (1:size(data_slice, 1));
            end

            obj.rawData       = data_slice;
            obj.processedData = data_slice;
            obj.stdev         = stdev_slice;
            obj.isLoaded      = true;   % set before any method that calls requireLoaded()

            % --- Probe (optional) ---
            obj.loadProbe(direct);

            % --- Background subtraction (optional) ---
            if cfg.bg_subtract
                obj.subtractBackground();
            end

            % --- Display properties from config ---
            obj.sampleName = cfg.sample_name;
            obj.timeUnit   = cfg.time_unit;
            fprintf('Loaded: %s  [%d pixels x %d time points, probe: %s]\n', ...
                root, size(obj.rawData,1), size(obj.rawData,2), ...
                string(obj.hasProbe));
        end

        % -------------------------------------------------------------- %
        %  normalize                                                       %
        % -------------------------------------------------------------- %
        function normalize(obj)
        % Divide processedData by probeRef element-wise -> dataNorm.
        % If no probe was found, dataNorm = processedData with a warning.
            obj.requireLoaded();
            if ~obj.hasProbe
                warning('tIRDataset: no probe loaded — dataNorm set to processedData (unnormalized).');
                obj.dataNorm = obj.processedData;
                return
            end
            obj.dataNorm = obj.processedData ./ obj.probeRef;
        end

        function d = selectDataPublic(obj, useNorm)
        % Public wrapper for selectData — used by tIRExperiment.
            d = obj.selectData(useNorm);
        end

        % -------------------------------------------------------------- %
        %  subtractBackground                                              %
        % -------------------------------------------------------------- %
        function subtractBackground(obj)
        % Subtract mean of all pre-t0 frames from every frame.
        % Call before normalize(). Operates on rawData in-place.
            obj.requireLoaded();
            pre_t0 = obj.rawData(:, obj.timeAxis < 0);
            if isempty(pre_t0)
                warning('tIRDataset: no pre-t0 data found — background subtraction skipped.');
                return
            end
            bg                = mean(pre_t0, 2);
            obj.rawData       = obj.rawData - bg;
            obj.processedData = obj.rawData;
        end

        % -------------------------------------------------------------- %
        %  plotContour override — adds dataNorm option                    %
        % -------------------------------------------------------------- %
        function plotContour(obj, varargin)
        % Same as base, plus 'useNorm' flag to plot dataNorm instead.
        %
        %   ds.plotContour()
        %   ds.plotContour('useNorm', true)
            p = inputParser;
            addParameter(p, 'useNorm', false, @islogical);
            % Pass remaining args to base class after peeking at useNorm
            [useNorm_cell, rest] = obj.peekParam(varargin, 'useNorm', false);
            useNorm = useNorm_cell;

            if useNorm && ~isempty(obj.dataNorm)
                % Swap processedData temporarily so base class plots dataNorm
                saved             = obj.processedData;
                obj.processedData = obj.dataNorm;
                plotContour@SpectroscopyBase(obj, rest{:});
                obj.processedData = saved;
            else
                plotContour@SpectroscopyBase(obj, varargin{:});
            end
        end

        % -------------------------------------------------------------- %
        %  export                                                          %
        % -------------------------------------------------------------- %
        function export(obj, format, outdir)
        % Export processed data to file.
        %
        %   ds.export()              % CSV to data_dir
        %   ds.export('csv')
        %   ds.export('mat', '/out')
            obj.requireLoaded();
            if nargin < 2, format = 'csv'; end
            if nargin < 3, outdir = obj.config.data_dir; end

            switch lower(format)
                case 'csv'
                    obj.exportCSV(outdir);
                case 'mat'
                    obj.save('dir', outdir);
                otherwise
                    error('tIRDataset.export: unknown format ''%s''. Use ''csv'' or ''mat''.', format);
            end
        end

        % -------------------------------------------------------------- %
        %  getResults — export all processed data as a plain struct       %
        % -------------------------------------------------------------- %
        function s = getResults(obj)
        % Return a self-contained struct with all processed data and slices.
        % Use this to do custom plotting outside the class.
        %
        %   r = ds.getResults();
        %   plot(r.timeAxis_fs, r.projection.signal_norm);
        %   plot(r.waveAxis, r.timeSlices.t_500_fs.signal_norm);
            obj.requireLoaded();

            s             = struct();
            s.label       = obj.label;
            s.sampleName  = obj.sampleName;

            % --- Axes (always in fs and cm-1 regardless of timeUnit) ---
            s.timeAxis_fs = obj.timeAxis;
            s.timeAxis_ps = obj.timeAxis / 1000;
            s.waveAxis    = obj.waveAxis;

            % --- Data matrices ---
            s.rawData       = obj.rawData;
            s.processedData = obj.processedData;
            s.stdev         = obj.stdev;
            s.hasProbe      = obj.hasProbe;
            if ~isempty(obj.dataNorm)
                s.dataNorm  = obj.dataNorm;
            end

            % --- Projection (mean |signal| vs time) ---
            r = obj.activePixelRange();
            s.projection.timeAxis_fs     = obj.timeAxis;
            s.projection.timeAxis_ps     = obj.timeAxis / 1000;
            s.projection.signal          = mean(abs(obj.processedData(r(1):r(2), :)), 1);
            if ~isempty(obj.dataNorm)
                s.projection.signal_norm = mean(abs(obj.dataNorm(r(1):r(2), :)), 1);
            end

            % --- Spectral slices: time traces at fixed wavenumbers ---
            cfg = obj.config;
            if ~isempty(cfg.slice_wavenumbers)
                s.spectralSlices.timeAxis_fs = obj.timeAxis;
                s.spectralSlices.timeAxis_ps = obj.timeAxis / 1000;
                for i = 1:numel(cfg.slice_wavenumbers)
                    px     = obj.waveToPixel(cfg.slice_wavenumbers(i));
                    actual = obj.waveAxis(px);
                    fname  = sprintf('wn_%d', round(actual));
                    s.spectralSlices.(fname).wavenumber_cm1 = actual;
                    s.spectralSlices.(fname).pixel          = px;
                    s.spectralSlices.(fname).signal         = obj.processedData(px, :);
                    if ~isempty(obj.dataNorm)
                        s.spectralSlices.(fname).signal_norm = obj.dataNorm(px, :);
                    end
                end
            end

            % --- Time slices: spectra at fixed delays ---
            % slice_times are always interpreted in fs
            if ~isempty(cfg.slice_times)
                s.timeSlices.waveAxis = obj.waveAxis;
                for i = 1:numel(cfg.slice_times)
                    [~, ti]  = min(abs(obj.timeAxis - cfg.slice_times(i)));
                    actual   = obj.timeAxis(ti);
                    fname    = sprintf('t_%d_fs', round(actual));
                    s.timeSlices.(fname).time_fs   = actual;
                    s.timeSlices.(fname).time_ps   = actual / 1000;
                    s.timeSlices.(fname).signal    = obj.processedData(:, ti);
                    if ~isempty(obj.dataNorm)
                        s.timeSlices.(fname).signal_norm = obj.dataNorm(:, ti);
                    end
                end
            end

            s.config = cfg;
        end

        % -------------------------------------------------------------- %
        %  save override — also persists dataNorm and stdev               %
        % -------------------------------------------------------------- %
        function save(obj, varargin)
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'dir', '', @ischar);
            parse(p, varargin{:});
            opts = p.Results;

            s               = struct();
            s.label         = obj.label;
            s.timeAxis      = obj.timeAxis;
            s.waveAxis      = obj.waveAxis;
            s.pixelRange    = obj.pixelRange;
            s.rawData       = obj.rawData;
            s.processedData = obj.processedData;
            s.stdev         = obj.stdev;
            s.hasProbe      = obj.hasProbe;
            if ~isempty(obj.dataNorm), s.dataNorm = obj.dataNorm; end
            s.isFiltered    = obj.isFiltered;
            if obj.isFiltered, s.filterOpts = obj.filterOpts; end
            s.config        = obj.config;

            timestamp  = datestr(now, 'yyyymmdd_HHMMSS');
            safe_label = matlab.lang.makeValidName(obj.label);
            fname      = sprintf('%s_%s.mat', safe_label, timestamp);
            fpath      = fullfile(opts.dir, fname);

            save(fpath, '-struct', 's');
            fprintf('Saved: %s\n', fpath);
        end

    end

    % ------------------------------------------------------------------ %
    %  Protected — override selectData for useNorm support in base plots  %
    % ------------------------------------------------------------------ %
    methods (Access = protected)

        function t = plotTitle(obj)
        % Build title: "CdS 400nm   ZZZZ   50 nJ"
        % Parts are omitted if the corresponding config field is empty/NaN.
            parts = {};
            cfg = obj.config;
            if isfield(cfg,'sample_name') && ~isempty(cfg.sample_name)
                parts{end+1} = cfg.sample_name;
            end
            if isfield(cfg,'polarisation') && ~isempty(cfg.polarisation)
                parts{end+1} = cfg.polarisation;
            end
            if isfield(cfg,'pump_power_nJ') && ~isnan(cfg.pump_power_nJ)
                parts{end+1} = sprintf('%g nJ', cfg.pump_power_nJ);
            end
            if isempty(parts)
                t = obj.label;
            else
                t = strjoin(parts, '   ');
            end
            if obj.isFiltered && isfield(obj.filterOpts,'order')
                t = sprintf('%s  [SG ord=%d win=%d]', t, ...
                    obj.filterOpts.order, obj.filterOpts.window);
            end
        end

        function d = selectData(obj, useNorm)
            if nargin > 1 && useNorm && ~isempty(obj.dataNorm)
                d = obj.dataNorm;
            else
                d = obj.processedData;
            end
        end

    end

    % ------------------------------------------------------------------ %
    %  Private helpers                                                     %
    % ------------------------------------------------------------------ %
    methods (Access = private)

        function loadProbe(obj, direct)
            cfg = obj.config;

            if strcmpi(cfg.probe_file, 'none')
                obj.hasProbe = false;
                return
            end

            if isempty(cfg.probe_file)
                hits = dir(fullfile(direct, 'probe_*.txt'));
                if isempty(hits)
                    warning('tIRDataset: no probe file found in %s — normalization skipped.', direct);
                    obj.hasProbe = false;
                    return
                end
                probe_path = fullfile(direct, hits(1).name);
                fprintf('Auto-detected probe: %s\n', hits(1).name);
            else
                probe_path = cfg.probe_file;
            end

            raw_probe    = load(probe_path);
            total_rows   = size(raw_probe, 1);
            [r1, r2]     = obj.pixelRows(total_rows);
            n_cols       = size(raw_probe, 2);
            col          = min(cfg.probe_col, n_cols);
            obj.probeRef = raw_probe(r1:r2, col);

            % Apply same wavenumber sort as data if cm_axis is on
            if cfg.cm_axis && ~isempty(cfg.cal_file)
                cal         = load(cfg.cal_file);
                [~, idx]    = sort(wl2wn(cal(:)));
                obj.probeRef = obj.probeRef(idx);
            end

            obj.hasProbe = true;
        end

        function [r1, r2] = pixelRows(obj, total_rows)
            cfg = obj.config;
            n   = cfg.n_pixels;
            switch lower(cfg.pixel_region)
                case 'top'
                    r1 = 1;    r2 = n;
                case 'bottom'
                    r1 = n+1;  r2 = 2*n;
                case 'all'
                    r1 = 1;    r2 = total_rows;
                otherwise
                    error('tIRDataset: pixel_region must be ''top'', ''bottom'', or ''all''.');
            end
            r2 = min(r2, total_rows);
        end

        function fpath = findSuffixFile(~, direct, root, suffix)
        % Find file matching <root>*<suffix>.txt by filename — not by sort index.
            hits = dir(fullfile(direct, [root '*' suffix '.txt']));
            if isempty(hits)
                error('tIRDataset: no file found for root=''%s'', suffix=''%s'' in:\n  %s', ...
                    root, suffix, direct);
            end
            fpath = fullfile(direct, hits(1).name);
        end

        function exportCSV(obj, outdir)
        % Write rawData and dataNorm as CSVs with axes as headers.
            safe   = matlab.lang.makeValidName(obj.label);
            t_row  = [NaN, obj.dispTime(obj.timeAxis)];

            raw_out = [obj.waveAxis(:), obj.rawData];
            writematrix([t_row; raw_out], fullfile(outdir, [safe '_rawData.csv']));

            if ~isempty(obj.dataNorm)
                norm_out = [obj.waveAxis(:), obj.dataNorm];
                writematrix([t_row; norm_out], fullfile(outdir, [safe '_dataNorm.csv']));
            end
            fprintf('Exported CSV to: %s\n', outdir);
        end

        function [val, rest] = peekParam(~, args, name, default)
        % Extract a single named parameter from a varargin cell without inputParser.
            val  = default;
            rest = args;
            i    = 1;
            while i < numel(args)
                if ischar(args{i}) && strcmpi(args{i}, name)
                    val  = args{i+1};
                    rest = [args(1:i-1), args(i+2:end)];
                    return
                end
                i = i + 1;
            end
        end

    end

end
