function mainsector_ids = mrio_mainsector_mapping(mainsector_names)

% MODULE:
%   climada_advanced
% NAME:
%   mrio_mainsector_mapping
% PURPOSE:
%   Helper function. Used e.g. by mrio_read_table.
%   Maps an input array of mainsector names to mainsector IDs.
%   
%   previous call:
% 
% CALLING SEQUENCE:
%  
% EXAMPLE:
%   climada_sect_id = mrio_mainsector_mapping(climada_sect_name) 
%
% INPUTS:
%   A cell or categorical array containing mainsector names.
%
% OPTIONAL INPUT PARAMETERS:
%
% OUTPUTS:
%   mainsector_ids: 
%       an array containing mainsector IDs, where each array element
%       corresponds to the element at the same position in the provided array of names.
%   
% GENERAL NOTES:
%
% POSSIBLE EXTENSIONS TO BE IMPLEMENTED:
%
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180216 initializing function
% Kaspar Tobler, 20180301 changed principle of ID mapping from alphabetical
%   to following the order of appearance of the mainsectors in the full mrio table.

mainsector_ids=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('mainsector_names','var')
    error('No input argument provided. Function requires an input cell or categorical array containing sector names.')
end 

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
% account for different directory structures
% if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
%     module_data_dir=[climada_global.modules_dir filesep 'advanced' filesep 'data'];
% else
%     module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
% end

% PARAMETERS
% First create mapping table (based on order of appearance in full mrio
% table), which is then used in the second part to map an ID to the full provided
% array...
unique_names = unique(mainsector_names,'stable')'; 
mapping_table = table(unique_names,[1:6]','VariableNames',{'name','ID'});    %#ok 

% Perform actual mapping:
mainsector_ids = zeros(1,length(mainsector_names));
for name_i = 1:length(mainsector_names)
    mainsector_ids(name_i) = mapping_table.ID(mapping_table.name == mainsector_names(name_i));
end






