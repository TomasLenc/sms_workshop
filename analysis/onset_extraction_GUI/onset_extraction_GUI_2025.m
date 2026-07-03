function f = onset_extraction_GUI()

%% libraries and parameters

% default parameter values for autodetection
tap_onset_thr = 0.3;
tap_onset_min_iti = 0.080;

%% load and prepare data

data = [];

% data folder (for load and save)
data.data_path = '../data';

% output filename (table where tap onset times will be saved)
data.fname_onsets = 'tap_onsets.csv';

% get a list of tapping files (search for .mat files with aligned
% continuous data - previous preprocessing steps should be already done)
d = dir(fullfile(data.data_path, '*_aligned.mat'));
file_names = {d.name};

if isfile(fullfile(data.data_path, data.fname_onsets))

    data.tap_onsets_table = readtable( ...
        fullfile(data.data_path, data.fname_onsets), ...
        'Delimiter', '\t', ...
        'FileType', 'text');

else

    data.tap_onsets_table = cell2table( ...
        cell(0, 2), ...
        'VariableNames', {'filename', 'onset'});

end

%% GUI

f = figure( ...
    'Color', 'white', ...
    'Position', [107 1505 1675 310]);

f.CloseRequestFcn = @figCloseFun;

fileList = uicontrol( ...
    'Style', 'listbox', ...
    'Units', 'normalized', ...
    'Position', [0 0.3 0.25 0.7], ...
    'String', file_names, ...
    'Callback', @fileListFun);

data.handles.fileList = fileList;

uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'SAVE', ...
    'Units', 'normalized', ...
    'Position', [0.05 0.01 0.05 0.05], ...
    'Callback', @saveButtonFun);

waveMarkerButton = uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'Markers OFF', ...
    'Units', 'normalized', ...
    'Position', [0.105 0.01 0.05 0.05], ...
    'Callback', @waveMarkerButtonFun);

data.handles.waveMarkerButton = waveMarkerButton;
data.showMarkersOnWaveform = false;

% minimum amplitude threshold for autodetection 
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'autodetect', ...
    'Units', 'normalized', ...
    'Position', [0.16 0.01 0.05 0.05], ...
    'Callback', @autodetectButtonFun);

thrEdit = uicontrol( ...
    'Style', 'edit', ...
    'String', num2str(tap_onset_thr), ...
    'Units', 'normalized', ...
    'Position', [0.15 0.10 0.05 0.05], ...
    'Callback', @thrEditFun);

thrEdit.KeyPressFcn = [];
data.handles.thrEdit = thrEdit;

uicontrol( ...
    'Style','text', ...
    'String','Amplitude thr', ...
    'Units','normalized', ...
    'Position',[0.15 0.16 0.05 0.06], ...
    'BackgroundColor','white');

% minimum inter-tap interval for autodetection
minITIEdit = uicontrol( ...
    'Style', 'edit', ...
    'String', num2str(tap_onset_min_iti), ...
    'Units', 'normalized', ...
    'Position', [0.09 0.10 0.05 0.05], ...
    'Callback', @minITIEditFun);

minITIEdit.KeyPressFcn = [];
data.handles.minITIEdit = minITIEdit;

uicontrol( ...
    'Style','text', ...
    'String','minimum ITI', ...
    'Units','normalized', ...
    'Position',[0.09 0.16 0.05 0.06], ...
    'BackgroundColor','white');

% open figure axes
data.handles.ax = axes( ...
    'Parent', f, ...
    'Position', [0.3000 0.1500 0.6900 0.7500]);

data.fileNames = file_names;

guidata(f, data);

fileListFun(fileList, []);

%% CALLBACKS

function fileListFun(hObj, ~)

    data = guidata(f);

    data.currFileIdx = hObj.Value;
    data.currFileName = hObj.String{data.currFileIdx};

    guidata(f, data);

    loadData();
    updatePlot();

end

function loadData()

    data = guidata(f);

    tap = load(fullfile(data.data_path, data.currFileName));

    data.tap_cont = abs(tap.data);
    data.fs = tap.fs;

    row_idx = strcmp( ...
        data.tap_onsets_table.filename, ...
        data.currFileName);

    data.tap_onsets = data.tap_onsets_table.onset(row_idx);

    guidata(f, data);

end

function updatePlot()

    data = guidata(f);

    N = length(data.tap_cont);
    t = (0:N-1) / data.fs;

    cla(data.handles.ax);

    hold(data.handles.ax, 'on');

    data.handles.waveformLine = plot( ...
        data.handles.ax, ...
        t, ...
        data.tap_cont, ...
        'Color', [0.3 0.3 0.3], ...
        'LineWidth', 0.4, ...
        'ButtonDownFcn', @waveformClickFcn);

    guidata(f, data);

    updateWaveformStyle();

    data = guidata(f);

    data.handles.onsetMarkers = plot( ...
        data.handles.ax, ...
        nan, ...
        nan, ...
        'ro', ...
        'ButtonDownFcn', @onsetClickFcn);

    hold(data.handles.ax, 'off');

    xlabel(data.handles.ax, 'Time (s)');

    xlim(data.handles.ax, [0 t(end) + 0.3]);
    ylim(data.handles.ax, [0 1.3]);

    data.handles.ax.YTick = [];

    title( ...
        data.handles.ax, ...
        sprintf('%s', data.currFileName), ...
        'Interpreter', 'none');

    guidata(f, data);

    updateMarkers();

end

function updateMarkers()

    data = guidata(f);

    if isempty(data.tap_onsets)

        set( ...
            data.handles.onsetMarkers, ...
            'XData', [], ...
            'YData', []);

        return

    end

    tap_idx = round(data.tap_onsets * data.fs) + 1;

    tap_idx = max(1, tap_idx);
    tap_idx = min(length(data.tap_cont), tap_idx);

    set( ...
        data.handles.onsetMarkers, ...
        'XData', data.tap_onsets, ...
        'YData', data.tap_cont(tap_idx));

end

function waveformClickFcn(~, ~)

    data = guidata(f);

    cp = get(data.handles.ax, 'CurrentPoint');

    xclick = cp(1, 1);
    yclick = cp(1, 2);

    max_time = length(data.tap_cont) / data.fs;

    if xclick < 0 || xclick > max_time
        return
    end

    [onset_time, ~] = nearestPointOnWaveform(xclick, yclick);

    data.tap_onsets(end + 1) = onset_time;

    % [~, idx] = min(sum(([cp(1,1:2)' - ...
    %     [data.handles.waveformLine.XData; ...
    %      data.handles.waveformLine.YData]).^2, 1));
    %
    % data.tap_onsets(end+1) = ...
    %     data.handles.waveformLine.XData(idx);

    % data.tap_onsets(end+1) = xclick;

    data.tap_onsets = sort(data.tap_onsets);

    guidata(f, data);

    updateOnsetsTable();
    updateMarkers();

end

function onsetClickFcn(~, ~)

    data = guidata(f);

    if isempty(data.tap_onsets)
        return
    end

    cp = get(data.handles.ax, 'CurrentPoint');
    click_time = cp(1, 1);

    [~, idx] = min(abs(data.tap_onsets - click_time));

    data.tap_onsets(idx) = [];

    guidata(f, data);

    updateOnsetsTable();
    updateMarkers();

end

function minITIEditFun(h, eventdata)

    autodetectButtonFun(h, eventdata);

end

function thrEditFun(h, eventdata)

    autodetectButtonFun(h, eventdata);

end

function autodetectButtonFun(~, ~)

    data = guidata(f);

    thr = str2double(data.handles.thrEdit.String);
    minITI = str2double(data.handles.minITIEdit.String);

    % find tap onsets
    tap_indices = find(data.tap_cont > thr) ; 
    asy = [Inf, diff(tap_indices) / data.fs]; 
    tap_indices(asy < minITI) = []; 
    tap_onset_times = tap_indices / data.fs; 
    data.tap_onsets = tap_onset_times; 

    guidata(f, data);

    updateOnsetsTable();
    updatePlot();

end

function waveMarkerButtonFun(~, ~)

    data = guidata(f);

    data.showMarkersOnWaveform = ~data.showMarkersOnWaveform;

    if data.showMarkersOnWaveform
        data.handles.waveMarkerButton.String = 'Markers ON';
    else
        data.handles.waveMarkerButton.String = 'Markers OFF';
    end

    guidata(f, data);

    updateWaveformStyle();

end

function updateWaveformStyle()

    data = guidata(f);

    if ~isfield(data.handles, 'waveformLine') || ...
            ~isgraphics(data.handles.waveformLine)
        return
    end

    if data.showMarkersOnWaveform

        set( ...
            data.handles.waveformLine, ...
            'Marker', '.', ...
            'MarkerSize', 10);

        data.handles.onsetMarkers.MarkerFaceColor = 'r';

    else

        set( ...
            data.handles.waveformLine, ...
            'Marker', 'none');

        if isfield(data.handles, 'onsetMarkers') && isgraphics(data.handles.onsetMarkers)
            data.handles.onsetMarkers.MarkerFaceColor = 'none';
        end

    end

end

function updateOnsetsTable()

    data = guidata(f);

    row_idx = strcmp( ...
        data.tap_onsets_table.filename, ...
        data.currFileName);

    data.tap_onsets_table(row_idx, :) = [];

    for k = 1:length(data.tap_onsets)

        new_row = { ...
            data.currFileName, ...
            data.tap_onsets(k)};

        data.tap_onsets_table = ...
            [data.tap_onsets_table; new_row];

    end

    guidata(f, data);

end

function saveButtonFun(~, ~)

    data = guidata(f);

    fprintf( ...
        '\nwriting table to %s\n', ...
        fullfile(data.data_path, data.fname_onsets));

    writetable( ...
        data.tap_onsets_table, ...
        fullfile(data.data_path, data.fname_onsets), ...
        'Delimiter', '\t', ...
        'FileType', 'text', ...
        'WriteVariableNames', true);

end

function figCloseFun(~, eventdata)

    try

        user_response = closeDlg( ...
            'Title', 'Confirm Close');

    catch

        user_response = questdlg( ...
            'Save changes before closing?', ...
            'Confirm Close', ...
            'Yes', 'No', 'Cancel', 'Yes');

    end

    switch user_response

        case 'Yes'

            saveButtonFun([], eventdata);
            delete(f);

        case 'No'

            delete(f);

        case 'Cancel'

            return

    end

end

function [xproj, yproj] = nearestPointOnWaveform(xclick, yclick)

    data = guidata(f);

    N = length(data.tap_cont);

    x = (0:N-1) / data.fs;
    y = data.tap_cont;

    bestDist2 = inf;
    xproj = NaN;
    yproj = NaN;

    for k = 1:(length(x) - 1)

        P1 = [x(k) y(k)];
        P2 = [x(k + 1) y(k + 1)];

        v = P2 - P1;

        vv = dot(v, v);

        if vv == 0
            continue
        end

        u = dot([xclick yclick] - P1, v) / vv;

        u = max(0, min(1, u));

        proj = P1 + u * v;

        dist2 = sum(([xclick yclick] - proj).^2);

        if dist2 < bestDist2

            bestDist2 = dist2;

            xproj = proj(1);
            yproj = proj(2);

        end

    end

end


end