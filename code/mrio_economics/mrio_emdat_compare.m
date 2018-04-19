function [glb_direct_risk, glb_indirect_risk, glb_emdat_aed] = mrio_emdat_compare(direct_risk_vector,indirect_risk_vector,climada_mriot,params)
%
% MODULE:
%   climada_advanced
% NAME:
%   mrio_emdat_compare
% PURPOSE:
%   Extracts relative data from emdat to make simple comparison between
%   global (total) risk as estimated by the climada mrio process and emdat
%   data. For now only works for risk measure AED (is additive) and only
%   global total values are compared. 
%
% CALLING SEQUENCE:
%
% EXAMPLE:
%   mrio_emdat_compare(direct_country_risk,indirect_country_risk,climada_mriot,1980,params)
%     -- Compare AED from mrio process and emdat starting in the year 1980 until most current data entry (of either emdat or mrio results).
% INPUTS:
%   to be done  
%   notes: either climada_mriot or mriot_unit, as first is only used to
%   extract latter. Start year optional. If not passed earliest year
%   chosen.
%
% OPTIONAL INPUT PARAMETERS:
%   to be done
% OUTPUTS:
%   to be done
%
% GENERAL NOTES:
%
% POSSIBLE EXTENSIONS TO BE IMPLEMENTED:
%
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180419 initializing basic function; likely to be expanded

global climada_global       %#ok
if ~climada_init_vars,return;end % init/import global variables

if ~exist('direct_risk_vector','var') || ~exist('indirect_risk_vector','var') || ...
        (~exist('climada_mriot','var') && ~exist('mrio_unit','var'))
    errordlg('Please provide the required input arguments.','User input error. Cannot proceed.');
    error('Please provide the required input arguments.')
elseif ~exist('params','var'), params=[];
%elseif ~exist('start_year','var'), start_year=[];    
end

% locate the module's data folder:
module_data_dir=climada_global.data_dir; %#ok

% PARAMETERS

em_data=emdat_read('','','TC',0,0);
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
