function params = mrio_get_params
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   Especially for development phase: obtain a paramaters struct which contains
%   default values for all key parameters which are passed as function
%   arguments during the entire standard process following the mrio_master
%   file. Saves time.
% CALLING SEQUENCE:
% EXAMPLE:
%   params = mrio_get_params;
% INPUTS:
%   None.
% OPTIONAL INPUT PARAMETERS:
%   None.
% OUTPUTS:
%   params: a struct containing several fields, some of which are struct
%   themselves that contain default values of all relevant function
%   parameters used in the mrio_master file. Saves time working through the
%   master file (i.e. the whole standard computation process), especially during development phase.
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180119, initialized and finished first working version.

global climada_global
if ~climada_init_vars,return;end % init/import global variables

climada_global.waitbar = 0;
params.mriot.file_name = 'WIOT2014_Nov16_ROW.xlsx';
params.mriot.table_flag = 'wiod';
params.centroids_file = 'GLB_NatID_grid_0360as_adv_1'; % the global centroids
params.entity_file.agri = 'GLB_0360as_ismip_2018'; % the global Agriculture (agri) entity
params.entity_file.for = 'GLB_0360as_ismip_2018'; % the global Forestry and Fishing (for) entity
params.entity_file.min = 'GLB_0360as_ismip_2018'; % the global Mining and Quarrying (min) entity
params.entity_file.manu = 'GLB_0360as_ismip_2018'; % the global Manufacturing (manu) entity
params.entity_file.serv = 'GLB_0360as_ismip_2018'; % the global Services (serv) entity
params.entity_file.utilities = 'GLB_0360as_ismip_2018'; % the global Electricity, Gas and Water supply (utilities) entity
params.hazard_file = 'GLB_0360as_TC_hist'; % historic
% params.hazard_file='GLB_0360as_TC'; % probabilistic, 10x more events than hist
