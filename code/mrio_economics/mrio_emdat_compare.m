function [glb_direct_risk, glb_indirect_risk, glb_emdat_aed] = mrio_emdat_compare(direct_risk_vector, indirect_risk_vector, climada_mriot, params)
% mrio emdat compare
% MODULE:
%   advanced
% NAME:
%	mrio_emdat_compare
% PURPOSE:
%   Extracts relative data from emdat to make simple comparison between
%   global (total) risk as estimated by the climada mrio process and emdat
%   data. For now only works for risk measure AED (is additive) and only
%   global total values are compared. 
% CALLING SEQUENCE:
%   [glb_direct_risk, glb_indirect_risk, glb_emdat_aed] = mrio_emdat_compare(direct_risk_vector, indirect_risk_vector, climada_mriot, params);
% EXAMPLE:
%   mrio_emdat_compare(direct_country_risk, indirect_country_risk, climada_mriot, 1980, params)
%       Compare AED from mrio process and emdat starting in the year 1980 
%       until most current data entry (of either emdat or mrio results).
% INPUTS:
%   direct_risk_vector: a table containing as one variable the direct risk (EAD) per country (aggregated across all subsectors). 
%       Further a variable with correpsonding country names and country ISO codes, respectively.
%   indirect_risk_vector: table with indirect risk (EAD) per country in one variable and "label" 
%       variables containing corresponding country names and country ISO codes.
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
%       NOTE: either climada_mriot or mriot_unit, as first is only used to
%       extract latter. 
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with the fields
%       hazard_file: the filename (and path, optional) of a hazard
%           structure. If no path provided, default path ../data/hazard is used
%           > prompted for if empty
% OUTPUTS:
%   glb_direct_risk: a vector containing the overall value of direct risk 
%       derived from the direct_risk_vector.
%   glb_indirect_risk: a vector containing the overall value of indirect risk 
%       derived from the direct_risk_vector.
%   glb_emdat_aed: global annual expected damages (AEDs) for TCs based on emdat
% GENERAL NOTES:
% POSSIBLE EXTENSIONS TO BE IMPLEMENTED:
% It may be worthwile to implement a start year as input. For now 
% start_year = min(cell2mat({hazard.orig_yearset.yyyy}) is taken.
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180419 initializing basic function; likely to be expanded
%

glb_direct_risk = []; % init output
glb_indirect_risk = []; % init output
glb_emdat_aed = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('direct_risk_vector','var') || ~exist('indirect_risk_vector','var') || ...
        (~exist('climada_mriot','var') && ~exist('mrio_unit','var'))
    errordlg('Please provide the required input arguments.','User input error. Cannot proceed.');
    error('Please provide the required input arguments.')
end
if ~exist('params','var'), params = []; end

% locate the module's data folder:
module_data_dir = climada_global.data_dir; %#ok

% PARAMETERS
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if ~isfield(params,'hazard_file') || isempty(params.hazard_file)
    if (exist(fullfile(climada_global.hazards_dir, 'GLB_0360as_TC_hist.mat'), 'file') == 2) 
        params.hazard_file = 'GLB_0360as_TC_hist.mat';
    else % prompt for hazard filename
        params.hazard_file = [climada_global.hazards_dir];
        [filename, pathname] = uigetfile(params.hazard_file, 'Select hazard file:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            params.hazard_file = fullfile(pathname, filename);
        end
    end
end

em_data = emdat_read('','','TC',0,0);
mrio_unit = climada_mriot.unit;

% Get start year of used hazard:
hazard = climada_hazard_load(params.hazard_file); hazard = climada_hazard_reset_yearset(hazard,0,0);
start_year = min(cell2mat({hazard.orig_yearset.yyyy}));
last_year = max(cell2mat({hazard.orig_yearset.yyyy}));

% DEAL WITH ISSUE THAT YEAR FLEXIBILITY HAS TO GO "IN BOTH DIRECTIONS" LATER

% Adapt emdat units to match mrio data:
% Get pure numeric value of unit:
str_i = strfind(mrio_unit,'usd');
if isempty(str_i), str_i = strfind(mrio_unit,'USD');end

if ~isempty(str_i)
    mrio_unit(str_i:str_i+2) = [];
end
mrio_unit = str2double(mrio_unit);

em_data.damage = em_data.damage/mrio_unit;
glb_direct_risk = sum(direct_risk_vector.DirectCountryRisk);
glb_indirect_risk = sum(indirect_risk_vector.IndirectCountryRisk);

% Get damage of comparable event set from emdat:
selection = (em_data.year >= start_year & em_data.year <= last_year);
emdat_damage_set = em_data.damage(selection)';
emdat_frequencies = em_data.frequency(selection);
% Get global AED for TCs based on emdat:
glb_emdat_aed = emdat_damage_set * emdat_frequencies;

end % mrio_emdat_compare