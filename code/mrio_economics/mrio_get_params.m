function params = mrio_get_params(mriot_type)
% mrio get params
% MODULE:
%   advanced
% NAME:
%   mrio_get_params
% PURPOSE:
%   Especially for development phase: obtain a paramaters struct which contains
%   default values for all key parameters which are passed as function
%   arguments during the entire standard process following the mrio_master
%   file. Saves time.
% CALLING SEQUENCE:
%   params = mrio_get_params(mriot_type);
% EXAMPLE:
%   params = mrio_get_params;
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   mriot_type: character array specifying name of MRIOT table with which
%       testing person wants to work with. Currently (20180129) either 'wiod' or 'exiobase'.
%       If left empty, WIOD is default.
% OUTPUTS:
%   params: a struct containing several fields, some of which are struct
%       themselves that contain default values of all relevant function
%       parameters used in the mrio_master file. Saves time working through the
%       master file (i.e. the whole standard computation process), especially during development phase.
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180119, initialized and finished first working version.
% Kaspar Tobler, 20180129, added possibility to choose MRIOT type via input argument.
%                          added option to choose whether to calculate full or minimal aggregated mriot.
%                          added option to write final results to excel file.
%

global climada_global
if ~climada_init_vars,return;end % init/import global variables

climada_global.waitbar = 0;

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

if ~exist('mriot_type','var'),mriot_type=[];end

if isempty(mriot_type) || strcmpi(mriot_type,'wiod')
    params.mriot.file_name = [module_data_dir filesep 'mrio' filesep 'WIOT2014_Nov16_ROW.xlsx']; 
    params.mriot.table_flag = 'wiod';   
elseif strcmpi(mriot_type(1:4),'exio')
    params.mriot.file_name = [module_data_dir filesep 'mrio' filesep 'mrIot_version2.2.2.txt'];
    params.mriot.table_flag = 'exiobase';
elseif strcmpi(mriot_type(1:4),'eora')
    params.mriot.file_name = [module_data_dir filesep 'mrio' filesep 'Eora26_2013_bp_T.txt'];
    params.mriot.table_flag = 'eora26';
else
    params.mriot.file_name = [module_data_dir filesep 'mrio' filesep 'WIOT2014_Nov16_ROW.xlsx']; 
    params.mriot.table_flag = 'wiod';   
end

params.centroids_file = 'GLB_NatID_grid_0360as_adv_1'; % the global centroids
params.hazard_file = 'GLB_0360as_TC_hist'; % historic
%params.hazard_file = 'GLB_0360as_TC'; % probabilistic, 10x more events than hist

params.write_xls = 1; % If set to 1 (default) the final results are written to an excel file which can be found in module/data/results
params.full_aggregation = 0; % If set to 0 (default), no full aggregation of mriot table is computed, as the mrio data itself is not required
                             % in the mrio standard procedure. Rather, a minimal version of aggregated_mriot is computed, only containing the labels 
                             % and the aggregation info (i.e. which subsectors belong to which mainsector).
params.verbose = 1; % whether we printf progress to stdout (=1, default) or not (=0)

params.switch_io_approach = 2; % If set to 2 (default), indirect risk is estimated using Ghosh (supply-driven) methodology
        
end % mrio_get_params