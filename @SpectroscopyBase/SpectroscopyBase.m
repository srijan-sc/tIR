classdef (Abstract) SpectroscopyBase < handle
% SPECTROSCOPYBASE  Abstract base for 2D spectroscopy experiment classes.
%
% Subclasses must implement load(). All plotting, filtering, and saving
% are inherited and work identically across experiment types (tIR, 1DVE, etc.).
%
% Typical subclass usage:
%   exp = MyExperiment(cfg);
%   exp.pixelRange = [pMin pMax];
%   exp.load();
%   exp.filter('order', 5, 'window', 11);
%   exp.plotContour();
%   exp.plotSlices([2800, 2900]);
%   exp.save();

    properties
        rawData         % [pixel x time]  after load, before filter
        processedData   % [pixel x time]  after filter (equals rawData if unfiltered)
        timeAxis        % [1 x nTime]  fs
        waveAxis        % [1 x nPixel] cm-1 (or pixel index if cm_axis=false)
        pixelRange      % [pMin pMax]  active spectral window; empty = full range
        label      = '' % scan name (root_name)
        sampleName = '' % human label added to all plot titles, e.g. 'CdS 400nm'
        timeUnit   = 'fs' % 'fs' or 'ps' — controls x-axis label and display scaling
        isLoaded   = false
        isFiltered = false
    end

    properties (Access = protected)
        filterOpts = struct()
    end

    % ------------------------------------------------------------------ %
    %  Abstract — subclasses must implement                               %
    % ------------------------------------------------------------------ %
    methods (Abstract)
        load(obj)
    end

    % ------------------------------------------------------------------ %
    %  Public — shared across all experiment types                        %
    % ------------------------------------------------------------------ %
    methods

        function px = waveToPixel(obj, wn)
        % Return pixel index closest to wavenumber wn (cm-1).
            obj.requireLoaded();
            [~, px] = min(abs(obj.waveAxis(:) - wn));
        end

        function filter(obj, varargin)
        % Apply Savitzky-Golay smoothing to rawData -> processedData.
        %
        %   exp.filter('order', 5, 'window', 11)            along wavelength (dim 1)
        %   exp.filter('order', 3, 'window', 11, 'dim', 2)  along time
        %   exp.filter('apply', false)                       revert to rawData
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'order',  5,    @isnumeric);
            addParameter(p, 'window', 11,   @isnumeric);
            addParameter(p, 'dim',    1,    @isnumeric);
            addParameter(p, 'apply',  true, @islogical);
            parse(p, varargin{:});
            opts = p.Results;

            if ~opts.apply
                obj.processedData = obj.rawData;
                obj.isFiltered    = false;
                obj.filterOpts    = struct();
                return
            end

            win = opts.window;
            if mod(win, 2) == 0, win = win + 1; end

            r = obj.activePixelRange();
            d = obj.rawData(r(1):r(2), :);
            obj.processedData               = obj.rawData;
            obj.processedData(r(1):r(2), :) = sgolayfilt(d, opts.order, win, [], opts.dim);
            obj.isFiltered       = true;
            obj.filterOpts       = opts;
            obj.filterOpts.window = win;
        end

        function plotContour(obj, varargin)
        % Filled contour plot of processedData.
        %
        %   exp.plotContour()
        %   exp.plotContour('clevels', [0.1 0.3 0.5 1.0], 'figureNum', 1)
        %   exp.plotContour('xRange', [0 50000], 'yRange', [2900 3100])
        %   exp.plotContour('Axes', ax)   % render into a uiaxes handle
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'clevels',      [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.85 0.9 0.95 1.0], @isnumeric);
            addParameter(p, 'lineLevels',   [-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9], @isnumeric);
            addParameter(p, 'customScalar', 1.5,            @isnumeric);
            addParameter(p, 'colormap',     @redblue,       @(x) ischar(x)||isa(x,'function_handle'));
            addParameter(p, 'symmetric',    true,           @islogical);
            addParameter(p, 'showLines',    true,           @islogical);
            addParameter(p, 'lineWidth',    2.2,            @isnumeric);
            addParameter(p, 'fontSize',     16,             @isnumeric);
            addParameter(p, 'fontName',     'Aptos Body',   @ischar);
            addParameter(p, 'figWidthCm',   13,             @isnumeric);
            addParameter(p, 'figHeightCm',  10,             @isnumeric);
            addParameter(p, 'cbarLabel',    '\DeltaA (mOD)',@ischar);
            addParameter(p, 'figureNum',    [],             @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'pixelRange',   obj.pixelRange, @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'xRange',       [],             @(x) isempty(x)||(isnumeric(x)&&numel(x)==2));
            addParameter(p, 'yRange',       [],             @(x) isempty(x)||(isnumeric(x)&&numel(x)==2));
            addParameter(p, 'Axes',         [],             @(x) isempty(x)||isa(x,'matlab.graphics.axis.AbstractAxes'));
            parse(p, varargin{:});
            opts = p.Results;

            % ── Prepare data ───────────────────────────────────────────
            r = obj.resolvePixelRange(opts.pixelRange);
            x = obj.dispTime(obj.timeAxis);
            y = obj.waveAxis(r(1):r(2));
            z = obj.processedData(r(1):r(2), :);

            if ~isempty(opts.xRange)
                xi = x >= opts.xRange(1) & x <= opts.xRange(2);
                x  = x(xi);  z = z(:, xi);
            end
            if ~isempty(opts.yRange)
                yi = y >= opts.yRange(1) & y <= opts.yRange(2);
                y  = y(yi);  z = z(yi, :);
            end

            % ── Resolve axes ───────────────────────────────────────────
            if ~isempty(opts.Axes)
                ax = opts.Axes;
                cla(ax);
            else
                obj.openFigure(opts.figureNum);
                fh = gcf;
                set(fh, 'Units', 'centimeters', ...
                    'Position',  [2 2 opts.figWidthCm opts.figHeightCm], ...
                    'PaperUnits','centimeters', ...
                    'PaperSize', [opts.figWidthCm opts.figHeightCm], ...
                    'Color', [1 1 1]);
                ax = gca;
            end

            % ── Meshgrid ───────────────────────────────────────────────
            [X, Y] = meshgrid(x, y);

            % ── Contour levels ─────────────────────────────────────────
            scalar = max(abs(z(:)));   % ScaleToMax always true here
            pos_levels = scalar * opts.clevels;
            if opts.symmetric
                contour_levels = [-fliplr(pos_levels), pos_levels];
            else
                contour_levels = pos_levels;
            end

            % ── contourf — trap any stray figure MATLAB may create ─────
            figs_before = get(groot, 'Children');
            contourf(ax, X, Y, z, contour_levels, 'LineStyle', 'none');
            figs_after  = get(groot, 'Children');
            stray = setdiff(figs_after, figs_before);
            for k = 1:numel(stray)
                if isprop(stray(k), 'Number') || isa(stray(k), 'matlab.ui.Figure')
                    close(stray(k));
                end
            end

            % ── Overlay contour lines ──────────────────────────────────
            if opts.showLines
                line_levels = opts.customScalar * scalar * opts.lineLevels;
                hold(ax, 'on');
                contour(ax, X, Y, z, line_levels, 'LineColor', 'k', 'LineWidth', opts.lineWidth);
                hold(ax, 'off');
            end

            % ── Colormap ───────────────────────────────────────────────
            if isa(opts.colormap, 'function_handle')
                colormap(ax, opts.colormap());
            else
                colormap(ax, opts.colormap);
            end

            % ── Colorbar ───────────────────────────────────────────────
            cb = colorbar(ax);
            cb.Label.String = opts.cbarLabel;

            % ── CLim ───────────────────────────────────────────────────
            if opts.symmetric
                lim = max(abs(contour_levels));
                clim(ax, [-lim, lim]);
            end

            % ── Axis styling ───────────────────────────────────────────
            set(ax, 'Layer', 'top', 'TickDir', 'out', 'Box', 'on', ...
                'FontSize', opts.fontSize, 'FontName', opts.fontName, 'FontWeight', 'bold', ...
                'Color', [1 1 1], 'XColor', 'black', 'YColor', 'black');
            xlabel(ax, obj.timeLabel(),     'FontSize', opts.fontSize, 'FontName', opts.fontName, 'FontWeight', 'bold');
            ylabel(ax, '\omega (cm^{-1})', 'FontSize', opts.fontSize, 'FontName', opts.fontName, 'FontWeight', 'bold');
            title(ax, obj.plotTitle(), 'Interpreter', 'none', ...
                'FontSize', opts.fontSize, 'FontName', opts.fontName, 'FontWeight', 'bold');
            set(cb, 'FontSize', opts.fontSize, 'FontName', opts.fontName, 'FontWeight', 'bold', 'Color', 'black');
            cb.Label.FontSize   = opts.fontSize;
            cb.Label.FontName   = opts.fontName;
            cb.Label.FontWeight = 'bold';
            cb.Label.Color      = 'black';
        end

        function plotSlices(obj, wavenumbers, varargin)
        % Plot time traces at N wavenumbers on the same axes.
        %
        %   exp.plotSlices([2800 2860 2920])
        %   exp.plotSlices([2800 2860], 'figureNum', 5)
        %   exp.plotSlices([2800 2860], 'Axes', ax)
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'figureNum', [], @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'lineWidth', 2,  @isnumeric);
            addParameter(p, 'fontSize',  16, @isnumeric);
            addParameter(p, 'fontName',  'Aptos Body', @ischar);
            addParameter(p, 'useNorm',   false, @islogical);
            addParameter(p, 'Axes',      [],    @(x) isempty(x)||isa(x,'matlab.graphics.axis.AbstractAxes'));
            parse(p, varargin{:});
            opts = p.Results;

            d = obj.selectData(opts.useNorm);
            t = obj.dispTime(obj.timeAxis);

            ax = obj.openOrUseAxes(opts.Axes, opts.figureNum);
            hold(ax, 'on');
            cmap = lines(numel(wavenumbers));
            lgd  = cell(numel(wavenumbers), 1);
            for i = 1:numel(wavenumbers)
                px     = obj.waveToPixel(wavenumbers(i));
                actual = obj.waveAxis(px);
                plot(ax, t, d(px, :), 'Color', cmap(i,:), 'LineWidth', opts.lineWidth);
                lgd{i} = sprintf('%d cm^{-1}', round(actual));
            end
            yline(ax, 0, '--k', 'LineWidth', 1);
            hold(ax, 'off');
            legend(ax, lgd, 'FontSize', opts.fontSize, 'FontName', opts.fontName);
            xlabel(ax, obj.timeLabel());
            ylabel(ax, '\DeltaA (mOD)');
            title(ax, obj.plotTitle(), 'Interpreter', 'none');
            obj.applyLineStyle(opts.fontSize, opts.fontName, ax);
        end

        function plotTimeSlices(obj, times, varargin)
        % Plot spectra at N time delays. Times are in the current timeUnit.
        %
        %   exp.plotTimeSlices([0.5 5 50])       % if timeUnit='ps'
        %   exp.plotTimeSlices([500 5000 50000])  % if timeUnit='fs'
        %   exp.plotTimeSlices([0.5 5], 'Axes', ax)
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'figureNum',  [], @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'pixelRange', obj.pixelRange, @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'lineWidth',  2,  @isnumeric);
            addParameter(p, 'fontSize',   16, @isnumeric);
            addParameter(p, 'fontName',   'Aptos Body', @ischar);
            addParameter(p, 'useNorm',    false, @islogical);
            addParameter(p, 'Axes',       [],    @(x) isempty(x)||isa(x,'matlab.graphics.axis.AbstractAxes'));
            parse(p, varargin{:});
            opts = p.Results;

            r = obj.resolvePixelRange(opts.pixelRange);
            d = obj.selectData(opts.useNorm);
            w = obj.waveAxis(r(1):r(2));
            t = obj.dispTime(obj.timeAxis);

            ax = obj.openOrUseAxes(opts.Axes, opts.figureNum);
            hold(ax, 'on');
            cmap = lines(numel(times));
            lgd  = cell(numel(times), 1);
            for i = 1:numel(times)
                [~, ti] = min(abs(t - times(i)));
                plot(ax, w, d(r(1):r(2), ti), 'Color', cmap(i,:), 'LineWidth', opts.lineWidth);
                lgd{i}  = sprintf('%g %s', times(i), obj.timeUnit);
            end
            yline(ax, 0, '--k', 'LineWidth', 1);
            hold(ax, 'off');
            legend(ax, lgd, 'Interpreter', 'none', 'FontSize', opts.fontSize, 'FontName', opts.fontName);
            xlabel(ax, '\omega (cm^{-1})');
            ylabel(ax, '\DeltaA (mOD)');
            title(ax, obj.plotTitle(), 'Interpreter', 'none');
            obj.applyLineStyle(opts.fontSize, opts.fontName, ax);
        end

        function plotProjection(obj, varargin)
        % Mean absolute signal across pixelRange vs time — use to find t=0.
        % 'negate' flips the sign so a negative-going signal plots as a decay.
        %
        %   exp.plotProjection()
        %   exp.plotProjection('negate', true, 'xRange', [0 50])  % ps
        %   exp.plotProjection('Axes', ax)
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'figureNum',  [],    @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'pixelRange', obj.pixelRange, @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'color',      'r',   @ischar);
            addParameter(p, 'lineWidth',  2,     @isnumeric);
            addParameter(p, 'fontSize',   16,    @isnumeric);
            addParameter(p, 'fontName',   'Aptos Body', @ischar);
            addParameter(p, 'negate',     false, @islogical);
            addParameter(p, 'xRange',     [],    @(x) isempty(x)||(isnumeric(x)&&numel(x)==2));
            addParameter(p, 'Axes',       [],    @(x) isempty(x)||isa(x,'matlab.graphics.axis.AbstractAxes'));
            parse(p, varargin{:});
            opts = p.Results;

            r   = obj.resolvePixelRange(opts.pixelRange);
            prj = mean(abs(obj.processedData(r(1):r(2), :)), 1);
            t   = obj.dispTime(obj.timeAxis);

            if opts.negate,  prj = -prj; end
            if ~isempty(opts.xRange)
                xi  = t >= opts.xRange(1) & t <= opts.xRange(2);
                t   = t(xi);  prj = prj(xi);
            end

            ax = obj.openOrUseAxes(opts.Axes, opts.figureNum);
            plot(ax, t, prj, 'Color', opts.color, 'LineWidth', opts.lineWidth);
            yline(ax, 0, '--k', 'LineWidth', 1);
            xlabel(ax, obj.timeLabel());
            if opts.negate
                ylabel(ax, 'Mean -|\DeltaA|');
            else
                ylabel(ax, 'Mean |\DeltaA|');
            end
            title(ax, ['Projection — ' obj.plotTitle()], 'Interpreter', 'none');
            obj.applyLineStyle(opts.fontSize, opts.fontName, ax);
        end

        function save(obj, varargin)
        % Save processed data to a timestamped .mat file.
        %
        %   exp.save()
        %   exp.save('dir', '/path/to/output')
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'dir', '', @ischar);
            parse(p, varargin{:});
            opts = p.Results;

            s               = struct();
            s.label         = obj.label;
            s.sampleName    = obj.sampleName;
            s.timeAxis      = obj.timeAxis;
            s.waveAxis      = obj.waveAxis;
            s.pixelRange    = obj.pixelRange;
            s.rawData       = obj.rawData;
            s.processedData = obj.processedData;
            s.isFiltered    = obj.isFiltered;
            if obj.isFiltered, s.filterOpts = obj.filterOpts; end

            timestamp  = datestr(now, 'yyyymmdd_HHMMSS');
            safe_label = matlab.lang.makeValidName(obj.label);
            fname      = sprintf('%s_%s.mat', safe_label, timestamp);
            fpath      = fullfile(opts.dir, fname);

            save(fpath, '-struct', 's');
            fprintf('Saved: %s\n', fpath);
        end

    end

    % ------------------------------------------------------------------ %
    %  Protected helpers — available to subclasses                        %
    % ------------------------------------------------------------------ %
    methods (Access = protected)

        function requireLoaded(obj)
            if ~obj.isLoaded
                error('%s: call load() before using this method.', class(obj));
            end
        end

        function r = activePixelRange(obj)
            if isempty(obj.pixelRange)
                r = [1, size(obj.processedData, 1)];
            else
                r = obj.pixelRange;
            end
        end

        function r = resolvePixelRange(obj, pr)
            if isempty(pr)
                r = obj.activePixelRange();
            else
                r = pr;
            end
        end

        function d = selectData(obj, useNorm)
        % Return processedData; subclasses may override to return dataNorm.
            if nargin < 2 || ~useNorm
                d = obj.processedData;
            else
                d = obj.processedData;  % base fallback; tIRDataset overrides
            end
        end

        function t = dispTime(obj, t_fs)
        % Scale time axis for display according to timeUnit.
            if strcmpi(obj.timeUnit, 'ps')
                t = t_fs / 1000;
            else
                t = t_fs;
            end
        end

        function lbl = timeLabel(obj)
        % Return x-axis label string for the current timeUnit.
            if strcmpi(obj.timeUnit, 'ps')
                lbl = '\tau (ps)';
            else
                lbl = '\tau (fs)';
            end
        end

        function openFigure(~, num)
            if isempty(num)
                figure;
            else
                figure(num);
            end
        end

        function ax = openOrUseAxes(obj, providedAx, figNum)
        % Return providedAx if given; otherwise open/select a figure and return gca.
            if ~isempty(providedAx)
                ax = providedAx;
                cla(ax);
            else
                obj.openFigure(figNum);
                ax = gca;
            end
        end

        function ax = resolveAxes(~, providedAx)
        % Return providedAx if given, otherwise gca.
            if ~isempty(providedAx)
                ax = providedAx;
            else
                ax = gca;
            end
        end

        function applyLineStyle(~, fontSize, fontName, ax)
        % Apply consistent styling to a line-plot axes.
            if nargin < 4 || isempty(ax), ax = gca; end
            set(ax, 'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold', ...
                'TickDir', 'out', 'Layer', 'top', ...
                'Color', [1 1 1], 'XColor', 'black', 'YColor', 'black', 'Box', 'on');
            set(get(ax, 'XLabel'), 'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold');
            set(get(ax, 'YLabel'), 'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold');
            set(get(ax, 'Title'),  'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold');
            if ~isa(ax, 'matlab.ui.control.UIAxes')
                set(gcf, 'Color', [1 1 1]);
            end
        end

        function t = plotTitle(obj)
        % Build plot title: "SampleName — label [filter info]"
            if ~isempty(obj.sampleName)
                t = [obj.sampleName ' — ' obj.label];
            else
                t = obj.label;
            end
            if obj.isFiltered && isfield(obj.filterOpts, 'order')
                t = sprintf('%s  [SG ord=%d win=%d]', t, ...
                    obj.filterOpts.order, obj.filterOpts.window);
            end
        end

    end

end
