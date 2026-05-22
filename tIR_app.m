function tIR_app()
%TIRER_APP  GUI for tIR pump-probe analysis.

base = fileparts(mfilename('fullpath'));
addpath(base, fullfile(base, 'utils'));

%% ── Colour palette ────────────────────────────────────────────────────────
C_DARK    = [0.10 0.12 0.16];
C_SIDEBAR = [0.13 0.15 0.20];
C_FIELD   = [0.18 0.21 0.28];
C_TEXT    = [0.86 0.90 0.95];
C_MUTED   = [0.92 0.94 0.97];
C_ACCENT  = [0.24 0.68 0.99];
C_RUN     = [0.14 0.58 0.28];

%% ── Figure ────────────────────────────────────────────────────────────────
f = uifigure('Name', 'tIR Analysis', ...
    'Position', [40 60 1400 840], ...
    'Color', C_DARK);

%% ── Outer layout ──────────────────────────────────────────────────────────
outerGL = uigridlayout(f, [2 2], ...
    'RowHeight',     {'1x', 38}, ...
    'ColumnWidth',   {300, '1x'}, ...
    'Padding',       [6 6 6 6], ...
    'RowSpacing',    4, 'ColumnSpacing', 6, ...
    'BackgroundColor', C_DARK);

%% ── LEFT: scrollable config panel ────────────────────────────────────────
cfgPanel = uipanel(outerGL, ...
    'Scrollable', 'on', ...
    'BackgroundColor', C_SIDEBAR, ...
    'BorderType', 'line', ...
    'BorderColor', [0.22 0.26 0.35], ...
    'Title', '');
cfgPanel.Layout.Row = 1; cfgPanel.Layout.Column = 1;

%% ── BOTTOM STATUS BAR ─────────────────────────────────────────────────────
statusPanel = uipanel(outerGL, 'BorderType', 'none', 'BackgroundColor', C_DARK);
statusPanel.Layout.Row = 2; statusPanel.Layout.Column = [1 2];

statusGL = uigridlayout(statusPanel, [1 2], ...
    'ColumnWidth', {20, '1x'}, 'Padding', [10 2 10 2], 'ColumnSpacing', 8, ...
    'BackgroundColor', C_DARK);
ui.statusDot = uilabel(statusGL, 'Text', '●', ...
    'FontColor', C_ACCENT, 'FontSize', 13, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'center', ...
    'BackgroundColor', C_DARK);
ui.statusDot.Layout.Row = 1; ui.statusDot.Layout.Column = 1;
ui.status = uilabel(statusGL, 'Text', 'Starting...', ...
    'FontColor', C_TEXT, 'FontSize', 12, ...
    'WordWrap', 'on', 'VerticalAlignment', 'center', ...
    'HorizontalAlignment', 'left', 'BackgroundColor', C_DARK);
ui.status.Layout.Row = 1; ui.status.Layout.Column = 2;

%% ── Config grid ──────────────────────────────────────────────────────────
cfgGL = uigridlayout(cfgPanel, [25 2], ...
    'ColumnWidth', {96, '1x'}, ...
    'RowHeight', {
        20, 28, 28, 28, ...   %  1- 4  PATHS
         6, ...               %  5     spacer
        20, 28, 28, 28, ...   %  6- 9  DATASET
         6, ...               % 10     spacer
        20, 28, ...           % 11-12  DETECTOR
         6, ...               % 13     spacer
        20, 28, 28, ...       % 14-16  TIME AXIS
         6, ...               % 17     spacer
        20, 28, 28, 28, 28, ...% 18-22 DISPLAY
         6, ...               % 23     spacer
        32, 36  ...           % 24-25  buttons
    }, ...
    'Padding', [8 10 8 10], 'RowSpacing', 3, 'ColumnSpacing', 6, ...
    'BackgroundColor', C_SIDEBAR);

%% ── PATHS ─────────────────────────────────────────────────────────────────
mkHeader(cfgGL, 1, 'PATHS');

mkLabel(cfgGL, 2, 1, 'Data dir');
rowDD = subgrid(cfgGL, 2, 2, {'1x', 26});
ui.dataDir = uieditfield(rowDD, 'text', 'Placeholder', 'path/to/data/', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uibutton(rowDD, 'Text', '…', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, ...
    'ButtonPushedFcn', @(~,~) browseDir(ui.dataDir));

mkLabel(cfgGL, 3, 1, 'Cal file');
calPaths = scanCalFilePaths(base);
calNames  = scanCalFiles(base);
rowCal = subgrid(cfgGL, 3, 2, {'1x', 26});
ui.calFile = uidropdown(rowCal, 'Items', calNames, 'ItemsData', calPaths, ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uibutton(rowCal, 'Text', '…', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, ...
    'ButtonPushedFcn', @(~,~) browseCalFolder(ui));

mkLabel(cfgGL, 4, 1, 'Probe file');
rowPF = subgrid(cfgGL, 4, 2, {'1x', 26});
ui.probeFile = uieditfield(rowPF, 'text', 'Placeholder', 'auto | none', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uibutton(rowPF, 'Text', '…', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, ...
    'ButtonPushedFcn', @(~,~) browseFile(ui.probeFile, '*.txt'));

%% ── DATASET ───────────────────────────────────────────────────────────────
mkHeader(cfgGL, 6, 'DATASET');

mkLabel(cfgGL, 7, 1, 'Root name');
ui.rootName = uieditfield(cfgGL, 'text', 'Placeholder', 'scan_name_Row0', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
ui.rootName.Layout.Row = 7; ui.rootName.Layout.Column = 2;

mkLabel(cfgGL, 8, 1, 'Sample');
ui.sampleName = uieditfield(cfgGL, 'text', 'Placeholder', 'e.g. CdS 400nm', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
ui.sampleName.Layout.Row = 8; ui.sampleName.Layout.Column = 2;

rowPP = subgrid(cfgGL, 9, [1 2], {24,'1x',30,'1x'});
uilabel(rowPP, 'Text', 'nJ',   'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.power = uieditfield(rowPP, 'numeric', 'Value', 50, 'Limits', [0 Inf], ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uilabel(rowPP, 'Text', 'Pol.', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.polarisation = uieditfield(rowPP, 'text', 'Value', 'ZZZZ', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

%% ── DETECTOR ──────────────────────────────────────────────────────────────
mkHeader(cfgGL, 11, 'DETECTOR');

rowDet = subgrid(cfgGL, 12, [1 2], {50,'1x',34,'1x'});
uilabel(rowDet, 'Text', 'Region', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.pixelRegion = uidropdown(rowDet, 'Items', {'top','bottom','all'}, 'Value', 'bottom', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uilabel(rowDet, 'Text', 'N px', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.nPixels = uieditfield(rowDet, 'numeric', 'Value', 32, ...
    'Limits', [1 Inf], 'RoundFractionalValues', 'on', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

%% ── TIME AXIS ─────────────────────────────────────────────────────────────
mkHeader(cfgGL, 14, 'TIME AXIS');

rowTZ = subgrid(cfgGL, 15, [1 2], {44,'1x',34,'1x'});
uilabel(rowTZ, 'Text', 't₀ (fs)', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.timeZero = uieditfield(rowTZ, 'numeric', 'Value', 0, ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uilabel(rowTZ, 'Text', 'Unit', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.timeUnit = uidropdown(rowTZ, 'Items', {'ps','fs'}, 'Value', 'ps', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

rowChk = subgrid(cfgGL, 16, [1 2], {'1x','1x','1x'});
ui.bgSubtract = uicheckbox(rowChk, 'Text', 'BG sub',  'Value', false, 'FontColor', C_TEXT, 'FontSize', 11);
ui.cmAxis     = uicheckbox(rowChk, 'Text', 'cm⁻¹',   'Value', true,  'FontColor', C_TEXT, 'FontSize', 11);
ui.projNegate = uicheckbox(rowChk, 'Text', 'Negate',  'Value', false, 'FontColor', C_TEXT, 'FontSize', 11);

%% ── DISPLAY ───────────────────────────────────────────────────────────────
mkHeader(cfgGL, 18, 'DISPLAY');

rowXR = subgrid(cfgGL, 19, [1 2], {44,'1x',10,'1x'});
uilabel(rowXR, 'Text', 'τ range', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.xRangeMin = uieditfield(rowXR, 'text', 'Value', '', 'Placeholder', 'min', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uilabel(rowXR, 'Text', '–', 'FontColor', C_MUTED, 'FontSize', 11, ...
    'HorizontalAlignment', 'center', 'BackgroundColor', C_SIDEBAR);
ui.xRangeMax = uieditfield(rowXR, 'text', 'Value', '', 'Placeholder', 'max', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

rowYR = subgrid(cfgGL, 20, [1 2], {44,'1x',10,'1x'});
uilabel(rowYR, 'Text', 'ω range', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
ui.yRangeMin = uieditfield(rowYR, 'text', 'Value', '', 'Placeholder', 'min', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
uilabel(rowYR, 'Text', '–', 'FontColor', C_MUTED, 'FontSize', 11, ...
    'HorizontalAlignment', 'center', 'BackgroundColor', C_SIDEBAR);
ui.yRangeMax = uieditfield(rowYR, 'text', 'Value', '', 'Placeholder', 'max', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

mkLabel(cfgGL, 21, 1, 'Slice ω');
ui.sliceWn = uieditfield(cfgGL, 'text', 'Value', '', 'Placeholder', '2800 2850 2900', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
ui.sliceWn.Layout.Row = 21; ui.sliceWn.Layout.Column = 2;

mkLabel(cfgGL, 22, 1, 'Slice τ');
ui.sliceT = uieditfield(cfgGL, 'text', 'Value', '', 'Placeholder', '0 500 2000 (fs)', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
ui.sliceT.Layout.Row = 22; ui.sliceT.Layout.Column = 2;

%% ── BUTTONS ───────────────────────────────────────────────────────────────
rowB1 = subgrid(cfgGL, 24, [1 2], {'1x','1x','1x'});
uibutton(rowB1, 'Text', 'Load Config', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) loadConfig(ui));
uibutton(rowB1, 'Text', 'Save Config', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) saveConfig(ui));
uibutton(rowB1, 'Text', '⚙  Advanced', ...
    'BackgroundColor', [0.14 0.22 0.36], 'FontColor', C_ACCENT, ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(~,~) openAdvancedDialog(f));

rowB2 = subgrid(cfgGL, 25, [1 2], {'1x','1x'});
uibutton(rowB2, 'Text', '▶  RUN', ...
    'BackgroundColor', C_RUN, 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 13, ...
    'ButtonPushedFcn', @(~,~) runAnalysis(ui, f));
uibutton(rowB2, 'Text', 'Export CSV', ...
    'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) exportData(ui, f));

%% ── RIGHT: tabbed plot area ───────────────────────────────────────────────
tg = uitabgroup(outerGL);
tg.Layout.Row = 1; tg.Layout.Column = 2;

TAB_BG = [0.95 0.96 0.98];
tabs.proj    = uitab(tg, 'Title', '① Projection',      'BackgroundColor', TAB_BG);
tabs.raw     = uitab(tg, 'Title', '② Raw',             'BackgroundColor', TAB_BG);
tabs.norm    = uitab(tg, 'Title', '③ Normalised',      'BackgroundColor', TAB_BG);
tabs.slices  = uitab(tg, 'Title', '④ Spectral Slices', 'BackgroundColor', TAB_BG);
tabs.tslices = uitab(tg, 'Title', '⑤ Time Slices',     'BackgroundColor', TAB_BG);

PAD = [0.07 0.09 0.87 0.85];
axes_.proj    = uiaxes(tabs.proj,    'Units', 'normalized', 'Position', PAD);
axes_.raw     = uiaxes(tabs.raw,     'Units', 'normalized', 'Position', PAD);
axes_.slices  = uiaxes(tabs.slices,  'Units', 'normalized', 'Position', PAD);
axes_.tslices = uiaxes(tabs.tslices, 'Units', 'normalized', 'Position', PAD);

% Tab ③ Normalised: contour + wavenumber slider + slice
tab3GL = uigridlayout(tabs.norm, [3 1], ...
    'RowHeight', {'2x', 36, '1x'}, 'Padding', [6 6 6 6], 'RowSpacing', 4, ...
    'BackgroundColor', [0.95 0.96 0.98]);
axes_.norm       = uiaxes(tab3GL); axes_.norm.Layout.Row       = 1;
axes_.normSlider = uislider(tab3GL, 'Orientation', 'horizontal', ...
    'Limits', [2800 3200], 'Value', 3000, ...
    'MajorTicks', [], 'MinorTicks', []);
axes_.normSlider.Layout.Row = 2;
axes_.normSlice  = uiaxes(tab3GL); axes_.normSlice.Layout.Row  = 3;

axes_.proj.ButtonDownFcn = @(~, evt) pickT0fromClick(ui, evt);

%% ── App state ─────────────────────────────────────────────────────────────
f.UserData = struct('ds', [], 'axes', axes_, 'adv', advDefaults());

%% ── Auto-load example_config.m ────────────────────────────────────────────
defaultCfg = fullfile(base, 'example_config.m');
if isfile(defaultCfg)
    try
        cfg = tIRConfig.fromFile(defaultCfg);
        applyConfigToUI(ui, cfg);
        ui.status.Text = 'Default config loaded.  Change parameters you want and press RUN.';
        ui.statusDot.FontColor = [0.22 0.85 0.45];
    catch ME
        ui.status.Text = ['Config load failed: ' ME.message];
        ui.statusDot.FontColor = [0.95 0.30 0.30];
    end
else
    ui.status.Text = 'No example_config.m found — fill fields manually or use Load Config.';
    ui.statusDot.FontColor = [0.99 0.75 0.20];
end

end % ── end tIR_app ──────────────────────────────────────────────────────


%% ═════════════════════════════════════════════════════════════════════════
%  RUN ANALYSIS
%% ═════════════════════════════════════════════════════════════════════════

function runAnalysis(ui, f)
    axes_ = f.UserData.axes;
    adv   = f.UserData.adv;
    setStatus(ui, 'Loading data...');
    try
        cfg = buildConfig(ui);
        % Merge advanced file-column settings into cfg
        cfg.data_idx  = adv.data_idx;
        cfg.stdev_idx = adv.stdev_idx;
        cfg.time_idx  = adv.time_idx;
        cfg.probe_col = adv.probe_col;
        tIRConfig.validate(cfg);

        ds = tIRDataset(cfg);
        ds.load();
        setStatus(ui, 'Normalizing...');
        ds.normalize();
        f.UserData.ds = ds;

        % Resolve colormap (redblue is a local function, not a string MATLAB knows)
        if strcmp(adv.colormap, 'redblue')
            cmap = @redblue;
        else
            cmap = adv.colormap;
        end
        cl = str2num(adv.clevels);    %#ok<ST2NM>
        ll = str2num(adv.lineLevels); %#ok<ST2NM>

        setStatus(ui, 'Plotting projection...');
        ds.plotProjection('Axes', axes_.proj, 'negate', cfg.projection_negate, ...
            'fontSize', adv.fontSize, 'fontName', adv.fontName);

        setStatus(ui, 'Plotting raw contour...');
        ds.plotContour('Axes', axes_.raw, ...
            'xRange', cfg.plot_xRange, 'yRange', cfg.plot_yRange, ...
            'colormap', cmap, 'symmetric', adv.symmetric, ...
            'showLines', adv.showLines, 'lineWidth', adv.lineWidth, ...
            'clevels', cl, 'lineLevels', ll, 'customScalar', adv.customScalar, ...
            'cbarLabel', adv.cbarLabel, 'fontSize', adv.fontSize, 'fontName', adv.fontName);

        if ds.hasProbe
            setStatus(ui, 'Plotting normalised contour...');
            ds.plotContour('useNorm', true, 'Axes', axes_.norm, ...
                'xRange', cfg.plot_xRange, 'yRange', cfg.plot_yRange, ...
                'colormap', cmap, 'symmetric', adv.symmetric, ...
                'showLines', adv.showLines, 'lineWidth', adv.lineWidth, ...
                'clevels', cl, 'lineLevels', ll, 'customScalar', adv.customScalar, ...
                'cbarLabel', adv.cbarLabel, 'fontSize', adv.fontSize, 'fontName', adv.fontName);
            setupNormInteraction(f, ds, axes_, cfg);
        end

        if ~isempty(cfg.slice_wavenumbers)
            setStatus(ui, 'Plotting spectral slices...');
            ds.plotSlices(cfg.slice_wavenumbers, 'Axes', axes_.slices, ...
                'lineWidth', adv.sliceLineWidth, ...
                'fontSize', adv.fontSize, 'fontName', adv.fontName);
            if ~isempty(cfg.plot_xRange), xlim(axes_.slices, cfg.plot_xRange); end
        end

        if ~isempty(cfg.slice_times)
            setStatus(ui, 'Plotting time slices...');
            t_disp = cfg.slice_times;
            if strcmpi(cfg.time_unit, 'ps'), t_disp = t_disp / 1000; end
            ds.plotTimeSlices(t_disp, 'Axes', axes_.tslices, ...
                'lineWidth', adv.sliceLineWidth, ...
                'fontSize', adv.fontSize, 'fontName', adv.fontName);
            if ~isempty(cfg.plot_yRange), xlim(axes_.tslices, cfg.plot_yRange); end
        end

        setStatus(ui, sprintf('Done — %d px × %d time pts  |  probe: %s', ...
            size(ds.rawData,1), size(ds.rawData,2), string(ds.hasProbe)));

    catch ME
        setStatus(ui, ['ERROR: ' ME.message]);
        uialert(f, ME.message, 'Analysis Error');
    end
end


%% ═════════════════════════════════════════════════════════════════════════
%  ADVANCED SETTINGS DIALOG
%% ═════════════════════════════════════════════════════════════════════════

function adv = advDefaults()
    adv.colormap       = 'redblue';
    adv.symmetric      = true;
    adv.showLines      = true;
    adv.lineWidth      = 2.2;
    adv.customScalar   = 1.5;
    adv.clevels        = '0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.85 0.9 0.95 1.0';
    adv.lineLevels     = '-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9';
    adv.cbarLabel      = '\DeltaA (mOD)';
    adv.fontSize       = 16;
    adv.fontName       = 'Aptos Body';
    adv.sliceLineWidth = 2;
    adv.data_idx       = 1;
    adv.stdev_idx      = 2;
    adv.time_idx       = 3;
    adv.probe_col      = 2;
end

function openAdvancedDialog(f)
    % Raise existing dialog instead of opening a second one
    if isfield(f.UserData, 'advDlg') && ...
            ~isempty(f.UserData.advDlg) && isvalid(f.UserData.advDlg)
        figure(f.UserData.advDlg);
        return;
    end

    adv = f.UserData.adv;

    % ── Colours (same as main app) ────────────────────────────────────────
    C_DARK    = [0.10 0.12 0.16];
    C_SIDEBAR = [0.13 0.15 0.20];
    C_FIELD   = [0.18 0.21 0.28];
    C_TEXT    = [0.86 0.90 0.95];
    C_MUTED   = [0.92 0.94 0.97];
    C_RUN     = [0.14 0.58 0.28];

    dlg = uifigure('Name', 'Advanced Settings', ...
        'Position', [200 130 480 590], ...
        'Color', C_DARK, 'Resize', 'off');
    f.UserData.advDlg = dlg;

    gl = uigridlayout(dlg, [17 2], ...
        'ColumnWidth', {110, '1x'}, ...
        'RowHeight', {
            20, 28, 28, 28, 28, 28, 28, ...  %  1-7   CONTOUR PLOT
            10, ...                           %  8     spacer
            20, 28, 28, ...                   %  9-11  ALL PLOTS
            10, ...                           % 12     spacer
            20, 28, 28, ...                   % 13-15  FILE COLUMNS
            10, ...                           % 16     spacer
            36  ...                           % 17     buttons
        }, ...
        'Padding', [14 14 14 14], 'RowSpacing', 5, 'ColumnSpacing', 8, ...
        'BackgroundColor', C_SIDEBAR);

    % ── CONTOUR PLOT ──────────────────────────────────────────────────────
    mkHeader(gl, 1, 'CONTOUR PLOT');

    mkLabel(gl, 2, 1, 'Colormap');
    d.colormap = uidropdown(gl, ...
        'Items', {'redblue','parula','hot','cool','gray','jet'}, ...
        'Value', adv.colormap, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    d.colormap.Layout.Row = 2; d.colormap.Layout.Column = 2;

    rChk = subgrid(gl, 3, [1 2], {'1x','1x'});
    d.symmetric = uicheckbox(rChk, 'Text', 'Symmetric colorbar', ...
        'Value', adv.symmetric, 'FontColor', C_TEXT, 'FontSize', 11);
    d.showLines = uicheckbox(rChk, 'Text', 'Show contour lines', ...
        'Value', adv.showLines, 'FontColor', C_TEXT, 'FontSize', 11);

    rLW = subgrid(gl, 4, [1 2], {80,'1x',100,'1x'});
    uilabel(rLW, 'Text', 'Line width',    'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.lineWidth = uieditfield(rLW, 'numeric', 'Value', adv.lineWidth, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    uilabel(rLW, 'Text', 'Custom scalar', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.customScalar = uieditfield(rLW, 'numeric', 'Value', adv.customScalar, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

    mkLabel(gl, 5, 1, 'Contour levels');
    d.clevels = uieditfield(gl, 'text', 'Value', adv.clevels, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    d.clevels.Layout.Row = 5; d.clevels.Layout.Column = 2;

    mkLabel(gl, 6, 1, 'Line levels');
    d.lineLevels = uieditfield(gl, 'text', 'Value', adv.lineLevels, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    d.lineLevels.Layout.Row = 6; d.lineLevels.Layout.Column = 2;

    mkLabel(gl, 7, 1, 'Colorbar label');
    d.cbarLabel = uieditfield(gl, 'text', 'Value', adv.cbarLabel, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    d.cbarLabel.Layout.Row = 7; d.cbarLabel.Layout.Column = 2;

    % ── ALL PLOTS ─────────────────────────────────────────────────────────
    mkHeader(gl, 9, 'ALL PLOTS');

    rFont = subgrid(gl, 10, [1 2], {68,'1x',80,'1x'});
    uilabel(rFont, 'Text', 'Font size', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.fontSize = uieditfield(rFont, 'numeric', 'Value', adv.fontSize, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    uilabel(rFont, 'Text', 'Font name', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.fontName = uieditfield(rFont, 'text', 'Value', adv.fontName, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

    rSLW = subgrid(gl, 11, [1 2], {100,'1x'});
    uilabel(rSLW, 'Text', 'Slice line width', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.sliceLineWidth = uieditfield(rSLW, 'numeric', 'Value', adv.sliceLineWidth, ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

    % ── FILE COLUMNS ──────────────────────────────────────────────────────
    mkHeader(gl, 13, 'FILE COLUMNS');

    rFC1 = subgrid(gl, 14, [1 2], {68,'1x',72,'1x'});
    uilabel(rFC1, 'Text', 'Data col',  'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.data_idx = uieditfield(rFC1, 'numeric', 'Value', adv.data_idx, ...
        'Limits', [1 Inf], 'RoundFractionalValues', 'on', ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    uilabel(rFC1, 'Text', 'StDev col', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.stdev_idx = uieditfield(rFC1, 'numeric', 'Value', adv.stdev_idx, ...
        'Limits', [1 Inf], 'RoundFractionalValues', 'on', ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

    rFC2 = subgrid(gl, 15, [1 2], {68,'1x',72,'1x'});
    uilabel(rFC2, 'Text', 'Time col',  'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.time_idx = uieditfield(rFC2, 'numeric', 'Value', adv.time_idx, ...
        'Limits', [1 Inf], 'RoundFractionalValues', 'on', ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);
    uilabel(rFC2, 'Text', 'Probe col', 'FontColor', C_MUTED, 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', C_SIDEBAR);
    d.probe_col = uieditfield(rFC2, 'numeric', 'Value', adv.probe_col, ...
        'Limits', [1 Inf], 'RoundFractionalValues', 'on', ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11);

    % ── BUTTONS ───────────────────────────────────────────────────────────
    rBtn = subgrid(gl, 17, [1 2], {'1x','1x','1x'});
    uibutton(rBtn, 'Text', '✓  Apply & Close', ...
        'BackgroundColor', C_RUN, 'FontColor', 'white', ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) applyAdvAndClose(f, dlg, d));
    uibutton(rBtn, 'Text', 'Reset Defaults', ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11, ...
        'ButtonPushedFcn', @(~,~) resetAdvToDefaults(d));
    uibutton(rBtn, 'Text', 'Cancel', ...
        'BackgroundColor', C_FIELD, 'FontColor', C_TEXT, 'FontSize', 11, ...
        'ButtonPushedFcn', @(~,~) close(dlg));
end

function applyAdvAndClose(f, dlg, d)
    adv = f.UserData.adv;
    adv.colormap       = d.colormap.Value;
    adv.symmetric      = d.symmetric.Value;
    adv.showLines      = d.showLines.Value;
    adv.lineWidth      = d.lineWidth.Value;
    adv.customScalar   = d.customScalar.Value;
    adv.clevels        = strtrim(d.clevels.Value);
    adv.lineLevels     = strtrim(d.lineLevels.Value);
    adv.cbarLabel      = d.cbarLabel.Value;
    adv.fontSize       = d.fontSize.Value;
    adv.fontName       = strtrim(d.fontName.Value);
    adv.sliceLineWidth = d.sliceLineWidth.Value;
    adv.data_idx       = d.data_idx.Value;
    adv.stdev_idx      = d.stdev_idx.Value;
    adv.time_idx       = d.time_idx.Value;
    adv.probe_col      = d.probe_col.Value;
    f.UserData.adv = adv;
    close(dlg);
end

function resetAdvToDefaults(d)
    def = advDefaults();
    d.colormap.Value       = def.colormap;
    d.symmetric.Value      = def.symmetric;
    d.showLines.Value      = def.showLines;
    d.lineWidth.Value      = def.lineWidth;
    d.customScalar.Value   = def.customScalar;
    d.clevels.Value        = def.clevels;
    d.lineLevels.Value     = def.lineLevels;
    d.cbarLabel.Value      = def.cbarLabel;
    d.fontSize.Value       = def.fontSize;
    d.fontName.Value       = def.fontName;
    d.sliceLineWidth.Value = def.sliceLineWidth;
    d.data_idx.Value       = def.data_idx;
    d.stdev_idx.Value      = def.stdev_idx;
    d.time_idx.Value       = def.time_idx;
    d.probe_col.Value      = def.probe_col;
end


%% ═════════════════════════════════════════════════════════════════════════
%  CONFIG BUILD / LOAD / SAVE
%% ═════════════════════════════════════════════════════════════════════════

function cfg = buildConfig(ui)
    cfg = tIRConfig.defaults();
    cfg.data_dir          = strtrim(ui.dataDir.Value);
    cfg.cal_file          = ui.calFile.Value;
    cfg.probe_file        = strtrim(ui.probeFile.Value);
    cfg.root_name         = strtrim(ui.rootName.Value);
    cfg.sample_name       = strtrim(ui.sampleName.Value);
    cfg.pump_power_nJ     = ui.power.Value;
    cfg.polarisation      = strtrim(ui.polarisation.Value);
    cfg.pixel_region      = ui.pixelRegion.Value;
    cfg.n_pixels          = ui.nPixels.Value;
    cfg.time_zero         = ui.timeZero.Value;
    cfg.time_unit         = ui.timeUnit.Value;
    cfg.bg_subtract       = ui.bgSubtract.Value;
    cfg.cm_axis           = ui.cmAxis.Value;
    cfg.projection_negate = ui.projNegate.Value;
    xMin = str2double(ui.xRangeMin.Value);
    xMax = str2double(ui.xRangeMax.Value);
    cfg.plot_xRange = condRange(xMin, xMax);
    yMin = str2double(ui.yRangeMin.Value);
    yMax = str2double(ui.yRangeMax.Value);
    cfg.plot_yRange = condRange(yMin, yMax);
    cfg.slice_wavenumbers = str2num(ui.sliceWn.Value); %#ok<ST2NM>
    cfg.slice_times       = str2num(ui.sliceT.Value);  %#ok<ST2NM>
end

function v = condRange(mn, mx)
    if ~isnan(mn) && ~isnan(mx), v = [mn mx]; else, v = []; end
end

function loadConfig(ui)
    [fname, fpath] = uigetfile('*.m', 'Select config file');
    if isequal(fname, 0), return; end
    try
        cfg = tIRConfig.fromFile(fullfile(fpath, fname));
        applyConfigToUI(ui, cfg);
        setStatus(ui, ['Config loaded: ' fname '  — press RUN.']);
    catch ME
        setStatus(ui, ['Load failed: ' ME.message]);
    end
end

function saveConfig(ui)
    [fname, fpath] = uiputfile('*.m', 'Save config as');
    if isequal(fname, 0), return; end
    try
        cfg = buildConfig(ui);
        tIRConfig.toFile(cfg, fullfile(fpath, fname));
        setStatus(ui, ['Config saved: ' fname]);
    catch ME
        setStatus(ui, ['Save failed: ' ME.message]);
    end
end

function applyConfigToUI(ui, cfg)
    if isfield(cfg,'data_dir'),    ui.dataDir.Value   = cfg.data_dir;   end
    if isfield(cfg,'probe_file'),  ui.probeFile.Value = cfg.probe_file; end
    if isfield(cfg,'root_name'),   ui.rootName.Value  = cfg.root_name;  end
    if isfield(cfg,'sample_name'), ui.sampleName.Value= cfg.sample_name;end
    if isfield(cfg,'pump_power_nJ') && ~isnan(cfg.pump_power_nJ)
        ui.power.Value = cfg.pump_power_nJ; end
    if isfield(cfg,'polarisation'), ui.polarisation.Value = cfg.polarisation; end
    if isfield(cfg,'pixel_region') && ismember(cfg.pixel_region, ui.pixelRegion.Items)
        ui.pixelRegion.Value = cfg.pixel_region; end
    if isfield(cfg,'n_pixels'),  ui.nPixels.Value  = cfg.n_pixels;  end
    if isfield(cfg,'time_zero'), ui.timeZero.Value = cfg.time_zero; end
    if isfield(cfg,'time_unit') && ismember(cfg.time_unit, ui.timeUnit.Items)
        ui.timeUnit.Value = cfg.time_unit; end
    if isfield(cfg,'bg_subtract'),       ui.bgSubtract.Value   = cfg.bg_subtract;       end
    if isfield(cfg,'cm_axis'),           ui.cmAxis.Value       = cfg.cm_axis;           end
    if isfield(cfg,'projection_negate'), ui.projNegate.Value   = cfg.projection_negate; end
    if isfield(cfg,'cal_file') && ismember(cfg.cal_file, ui.calFile.ItemsData)
        ui.calFile.Value = cfg.cal_file; end
    if isfield(cfg,'plot_xRange') && numel(cfg.plot_xRange)==2
        ui.xRangeMin.Value = num2str(cfg.plot_xRange(1));
        ui.xRangeMax.Value = num2str(cfg.plot_xRange(2)); end
    if isfield(cfg,'plot_yRange') && numel(cfg.plot_yRange)==2
        ui.yRangeMin.Value = num2str(cfg.plot_yRange(1));
        ui.yRangeMax.Value = num2str(cfg.plot_yRange(2)); end
    if isfield(cfg,'slice_wavenumbers') && ~isempty(cfg.slice_wavenumbers)
        ui.sliceWn.Value = num2str(cfg.slice_wavenumbers); end
    if isfield(cfg,'slice_times') && ~isempty(cfg.slice_times)
        ui.sliceT.Value = num2str(cfg.slice_times); end
end


%% ═════════════════════════════════════════════════════════════════════════
%  EXPORT / T0 CLICK PICK
%% ═════════════════════════════════════════════════════════════════════════

function exportData(ui, f)
    ds = f.UserData.ds;
    if isempty(ds)
        uialert(f, 'Run analysis first.', 'No Data'); return;
    end
    try
        ds.export('csv');
        setStatus(ui, 'Exported CSV to data directory.');
    catch ME
        uialert(f, ME.message, 'Export Error');
    end
end

function pickT0fromClick(ui, evt)
    t_clicked = evt.IntersectionPoint(1);
    if strcmpi(ui.timeUnit.Value, 'ps')
        t0_fs = t_clicked * 1000;
    else
        t0_fs = t_clicked;
    end
    ui.timeZero.Value = t0_fs;
    setStatus(ui, sprintf('t0 set to %.1f fs — press RUN to re-plot.', t0_fs));
end


%% ═════════════════════════════════════════════════════════════════════════
%  NORMALISED CONTOUR INTERACTIVE LINE
%% ═════════════════════════════════════════════════════════════════════════

function setupNormInteraction(f, ds, axes_, cfg)
    wmin = min(ds.waveAxis);
    wmax = max(ds.waveAxis);
    wn0  = round(mean([wmin wmax]));

    sl = axes_.normSlider;
    sl.Limits = [wmin wmax];
    sl.Value  = wn0;

    % Pre-compute data once — avoids repeated selectDataPublic calls on drag
    t = ds.timeAxis;
    if strcmpi(cfg.time_unit, 'ps'), t = t / 1000; end
    d   = ds.selectDataPublic(true);
    px0 = ds.waveToPixel(wn0);

    f.UserData.normDs        = ds;
    f.UserData.normAxContour = axes_.norm;
    f.UserData.normAxSlice   = axes_.normSlice;
    f.UserData.normSlider    = sl;
    f.UserData.normCfg       = cfg;
    f.UserData.normData      = d;
    f.UserData.normT         = t;

    % Draw yline on contour once
    f.UserData.normLine = yline(axes_.norm, wn0, 'w-', 'LineWidth', 2.5);

    % Build slice axes once — style it here, never touch it again on drag
    axS = axes_.normSlice;
    cla(axS);
    hLine = plot(axS, t, d(px0, :), 'Color', [0.85 0.15 0.15], 'LineWidth', 2);
    hold(axS, 'on');
    yline(axS, 0, '--k', 'LineWidth', 1);
    hold(axS, 'off');
    if ~isempty(cfg.plot_xRange), xlim(axS, cfg.plot_xRange); end
    if strcmpi(cfg.time_unit, 'ps'), xlabel(axS, '\tau (ps)');
    else,                            xlabel(axS, '\tau (fs)'); end
    ylabel(axS, '\DeltaA (norm.)');
    title(axS, sprintf('\\omega = %.0f cm^{-1}', ds.waveAxis(px0)), 'Interpreter', 'tex');
    set(axS, 'FontSize', 12, 'FontName', 'Aptos Body', 'FontWeight', 'bold', ...
        'TickDir', 'out', 'Box', 'on', 'Color', [1 1 1], 'XColor', 'k', 'YColor', 'k');
    f.UserData.normSliceLine = hLine;

    % Both callbacks do the same lightweight update
    sl.ValueChangingFcn = @(~,evt) normSliderUpdate(f, evt.Value);
    sl.ValueChangedFcn  = @(~,~)  normSliderUpdate(f, sl.Value);
end

function normSliderUpdate(f, wn)
    % Move yline
    if ~isempty(f.UserData.normLine) && isvalid(f.UserData.normLine)
        f.UserData.normLine.Value = wn;
    end
    % Update slice: just swap YData — no cla, no replot, no styling
    ds        = f.UserData.normDs;
    px        = ds.waveToPixel(wn);
    actual_wn = ds.waveAxis(px);
    f.UserData.normSliceLine.YData = f.UserData.normData(px, :);
    title(f.UserData.normAxSlice, ...
        sprintf('\\omega = %.0f cm^{-1}', actual_wn), 'Interpreter', 'tex');
end


%% ═════════════════════════════════════════════════════════════════════════
%  HELPERS
%% ═════════════════════════════════════════════════════════════════════════

function setStatus(ui, msg)
    if contains(msg, 'ERROR') || contains(msg, 'failed') || contains(msg, 'Error')
        dot = [0.95 0.32 0.32];
    elseif contains(msg, 'Done') || contains(msg, 'loaded') || ...
           contains(msg, 'saved') || contains(msg, 'Exported')
        dot = [0.22 0.85 0.45];
    else
        dot = [0.99 0.75 0.20];
    end
    ui.statusDot.FontColor = dot;
    ui.status.Text = msg;
    drawnow;
end

function browseCalFolder(ui)
    d = uigetdir('', 'Select calibration folder');
    if isequal(d, 0), return; end
    hits = dir(fullfile(d, '*.txt'));
    if isempty(hits)
        uialert(ancestor(ui.calFile, 'figure'), ...
            'No .txt files found in that folder.', 'No calibration files');
        return;
    end
    names = {hits.name};
    paths = fullfile(d, names);
    ui.calFile.Items     = names;
    ui.calFile.ItemsData = paths;
    ui.calFile.Value     = paths{1};
end

function browseDir(field)
    d = uigetdir('', 'Select data directory');
    if ~isequal(d, 0), field.Value = [d filesep]; end
end

function browseFile(field, filter)
    [fn, fp] = uigetfile(filter, 'Select file');
    if ~isequal(fn, 0), field.Value = fullfile(fp, fn); end
end

function items = scanCalFiles(base)
    hits = dir(fullfile(base, 'cailbration', '*.txt'));
    if isempty(hits), items = {'(no cal files found)'};
    else,             items = {hits.name}; end
end

function paths = scanCalFilePaths(base)
    hits = dir(fullfile(base, 'cailbration', '*.txt'));
    if isempty(hits), paths = {''};
    else,             paths = fullfile(base, 'cailbration', {hits.name}); end
end

function gl = subgrid(parent, row, colSpan, widths)
    gl = uigridlayout(parent, [1, numel(widths)], ...
        'ColumnWidth', widths, 'Padding', [0 0 0 0], ...
        'RowSpacing', 0, 'ColumnSpacing', 4, ...
        'BackgroundColor', [0.13 0.15 0.20]);
    gl.Layout.Row    = row;
    gl.Layout.Column = colSpan;
end

function mkHeader(gl, row, txt)
    lbl = uilabel(gl, 'Text', upper(txt), ...
        'FontWeight', 'bold', 'FontSize', 10, ...
        'FontColor', [0.24 0.68 0.99], ...
        'BackgroundColor', [0.13 0.15 0.20], ...
        'VerticalAlignment', 'bottom');
    lbl.Layout.Row = row; lbl.Layout.Column = [1 2];
end

function mkLabel(gl, row, col, txt)
    lbl = uilabel(gl, 'Text', txt, ...
        'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', ...
        'FontColor', [0.92 0.94 0.97], ...
        'BackgroundColor', [0.13 0.15 0.20]);
    lbl.Layout.Row = row; lbl.Layout.Column = col;
end
