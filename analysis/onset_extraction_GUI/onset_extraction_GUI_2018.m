function f = onset_extraction_GUI()
% This function load wav tapping audio files and lets the user define tap
% onsets using GUI. The onsets are saved to a csv file. 

% default threshold above which taps are going to be detected
tap_onset_thr = 0.3; 
tap_onset_min_iti = 0.080; 

%% load and prepare data

data = []; 

% data folder
data.data_path = '../data';  
     
% output filename 
data.fname_onsets = 'tap_onsets.csv'; 

% get a list of tapping files (search for .mat files with aligned
% continuous data - previous preprocessing steps should be already done)
d = dir(fullfile(data.data_path, '*_aligned.mat')); 
file_names = {d.name}; 

% try loading table with tap onsets 
if isfile(fullfile(data.data_path, data.fname_onsets))
    data.tap_onsets_table = readtable(fullfile(data.data_path, data.fname_onsets),...
            'Delimiter','\t','FileType','text'); 
else
    % otherwise make new one 
    data.tap_onsets_table = cell2table(cell(0,2), ...
        'VariableNames',{'filename','onset'}); 
end

%%  

f = figure('color','white',...
    'position',[107 1505 1675 310]); 

f.CloseRequestFcn = {@figCloseFun,f}; 

% list of files 
fileList = uicontrol('Style', 'listbox', 'Units', 'normalized', ...
                     'Position', [0, 0.3, 0.25, 0.7], ...
                     'string',file_names,'Callback',@fileListfFun); 
data.handles.fileList = fileList; 

% autodetect button 
autodetectButton = uicontrol('Style','PushButton','String','autodetect',... 
                        'Units', 'normalized', ...
                        'Position', [0.15, 0.01, 0.05, 0.05], ...
                        'CallBack', @autodetectButtonFun);

                    
% threshold edit 
thrEdit = uicontrol('Style','edit','String',num2str(tap_onset_thr),... 
                        'Units', 'normalized', ...
                        'Position', [0.15, 0.1, 0.05, 0.05], ...
                        'CallBack', @thrEditFun);
data.handles.thrEdit = thrEdit; 


% minITI edit 
minITIEdit = uicontrol('Style','edit','String',num2str(tap_onset_min_iti),... 
                        'Units', 'normalized', ...
                        'Position', [0.09, 0.1, 0.05, 0.05], ...
                        'CallBack', @minITIEditFun);
data.handles.minITIEdit = minITIEdit; 


% save button 
saveButton = uicontrol('Style','PushButton','String','SAVE',... 
                        'Units', 'normalized', ...
                        'Position', [0.05, 0.01, 0.05, 0.05], ...
                        'CallBack', @saveButtonFun);

% plot axes 
data.handles.ax = axes(f,'Position',[0.3, 0.1, 0.7, 0.8]); 


% datacursor 
data.handles.dcm_obj = datacursormode(f);
data.handles.dcm_obj.UpdateFcn = @cursorFun; 
%     % set cursor initial position 
%     dcurs = createDatatip(data.handles.dcm_obj,h);
%     dcurs.Position = [data.tsv{data.currFileIdx,2}, 0]; 
%     dcurs.UpdateFcn = @cursorFun; 
%     datacursormode on;
%     data.handles.dcurs = dcurs; 

%% 

% save uidata 
data.fileNames = file_names; 
set(0,'userdata',data);

fileListfFun(data.handles.fileList,[])
loadData(); 
updatePlot(); 



                    
function fileListfFun(hObj,~)
    data = get(0,'userdata'); 
    data.currFileIdx = hObj.Value; 
    data.currFileName = hObj.String{data.currFileIdx}; 
    set(0,'userdata',data);
    % load new data 
    loadData(); 
    % update plot 
    updatePlot(); 
    

function loadData() 
    data = get(0,'userdata'); 
    tap = load(fullfile(data.data_path, data.currFileName)); 
    data.tap_cont = abs(tap.data); 
    data.fs = tap.fs; 
    row_idx = find(strcmp(data.tap_onsets_table.filename, data.currFileName)); 
    data.tap_onsets = data.tap_onsets_table.onset(row_idx); 
    set(0,'userdata',data);

    
function h = updatePlot()
    data = get(0,'userdata'); 
    % load data
    N = length(data.tap_cont); 
    t = [0:N-1]/data.fs; 
    % plot 
    cla(data.handles.ax); 
    h = plot(data.handles.ax, t, data.tap_cont, 'color',[.3,.3,.3],'linew',0.4);
    hold on 
    tap_onsets_idx = round(data.tap_onsets*data.fs)+1; 
    plot(data.handles.ax, data.tap_onsets, data.tap_cont(tap_onsets_idx), 'ro'); 
    
    set(0,'userdata',data);


function txt = cursorFun(~, event_obj)
    data = get(0,'userdata'); 
    % points are red 
    idx = get(event_obj, 'DataIndex'); 
    pos = get(event_obj, 'Position'); 
    
    if all(event_obj.Target.Color==[1,0,0])
        % delete tap onset  
        data.tap_onsets(idx) = []; 
        txt = {'rm tap'};
    else
        % clicked on line, create new tap onset 
        if size(data.tap_onsets,1)>size(data.tap_onsets,2)
            data.tap_onsets = [data.tap_onsets; idx/data.fs]; 
        else
            data.tap_onsets = [data.tap_onsets, idx/data.fs]; 
        end
        txt = {'add tap'};
    end
    % save idx data 
    set(0,'userdata',data);
    updateOnsetsTable()
    warning('off')
    updatePlot()

    
function minITIEditFun(h, eventdata)
    autodetectButtonFun(h, eventdata)
    
function thrEditFun(h, eventdata)
    autodetectButtonFun(h, eventdata)

    
function autodetectButtonFun(h, eventdata)
    data = get(0,'userdata'); 
    thr = str2num(data.handles.thrEdit.String); 
    minITI = str2num(data.handles.minITIEdit.String); 

    % find tap onsets
    tap_indices = find(data.tap_cont > thr) ; 
    asy = [Inf, diff(tap_indices) / data.fs]; 
    tap_indices(asy < minITI) = []; 
    tap_onset_times = tap_indices / data.fs; 
    data.tap_onsets = tap_onset_times; 

    set(0,'userdata',data);
    updateOnsetsTable()
    updatePlot()
    

function updateOnsetsTable()
    data = get(0,'userdata'); 
    % remove old tap onsets 
    row_idx = find(strcmp(data.tap_onsets_table.filename, data.currFileName)); 
    data.tap_onsets_table(row_idx,:) = []; 
    % insert new tap onsets 
    for i=1:length(data.tap_onsets)
        % {'filename','trial','rhythm','onset'}); 
        new_row = {data.currFileName, ...
                    data.tap_onsets(i)}; 
        
        data.tap_onsets_table = [data.tap_onsets_table; new_row];                                           
    end
    set(0,'userdata',data);

    
function saveButtonFun(h, eventdata)
    data = get(0,'userdata'); 
    fprintf('\nwriting table to %s\n',fullfile(data.data_path, data.fname_onsets)); 
    
    writetable(data.tap_onsets_table, ...
            fullfile(data.data_path, data.fname_onsets), ...
            'Delimiter','\t','FileType','text',...
            'WriteVariableNames',true); 
       
    

        
function figCloseFun(hObject, eventdata, f)
    data = get(0,'userdata'); 
    user_response = closeDlg('Title','Confirm Close');
    switch user_response
        case 'No'
            delete(f) % Hint: delete(hObject) closes the figure
        case 'Yes'
            saveButtonFun(f, eventdata); 
            delete(f) 
        case 'Cancel'
            % take no action
    end   