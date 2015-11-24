function [struct_data, struct_name] = climada_load(struct_file)
% climada
% MODULE:
%   advanced
% NAME:
%   climada_load
% PURPOSE:
%   load any climada struct (entity, EDS, hazard, centroids) and set
%   variable_name yourself with struct_data
% CALLING SEQUENCE:
%   [struct_data, struct_name] = climada_load(struct_file)
% EXAMPLE:
%   [struct_data, struct_name] = climada_entity_load(struct_file)
%   [struct_data, struct_name] = climada_entity_load('demo_today')
% INPUTS:
%   struct_file: the filename (with path, optional) of a previously saved
%       climada structure
%       If no path provided, default path ../data/... is used (and
%       name can be without extension .mat)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   struct_data: a struct, i.e. hazard, entity, EDS, centroids, etc.
%   struct_name: a char that contains the name of the struct, i.e.
%   'hazard', 'entity', etc.
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151124, init from climada_entity_load
%-

% init output
struct_data = []; struct_name = [];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('struct_file','var'),struct_file=[];end

% PARAMETERS

% prompt for struct_file if not given
if isempty(struct_file) % local GUI
    struct_file = [climada_global.data_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(struct_file, 'Select a climada struct to open:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        struct_file = fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE] = fileparts(struct_file);
if isempty(fE),fE = '.mat'; end

% look for a file in the different data folders, find out the struct_name

if isempty(strfind(fP,filesep)) % not an entire path, just one folder
    fN = fullfile(fP,fN); fP = [];
end
    
    
if isempty(fP) 
    struct_file = ''; %init
    
    % centroids
    struct_file_temp = [climada_global.centroids_dir filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
   
    % entity
    struct_file_temp = [climada_global.data_dir filesep 'entities' filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
    
    % EDS or measures_impact
    struct_file_temp = [climada_global.data_dir filesep 'results' filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
    
    % hazard
    struct_file_temp = [climada_global.data_dir filesep 'hazards' filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
else
    % make sure the given file exists
    if ~exist(struct_file,'file'), struct_file = ''; end
end %isempty(fP)

if isempty(struct_file), fprintf('File not found.\n'); return, end

% get information about the variable
vars = whos('-file', struct_file);

% get name of the climada structure as a char
struct_name = vars.name;

% finally load the file 
load(struct_file);

% rename the file to the selected struct_name
eval_str = sprintf('struct_data = %s;',vars.name);
eval(eval_str);
clear(vars.name)


end % climada_load


