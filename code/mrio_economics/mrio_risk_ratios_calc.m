function [total_subsector_risk, total_country_risk] = mrio_risk_ratios_calc(direct_subsector_risk, total_subsector_risk_in,direct_country_risk,total_country_risk_in) 

% MODULE:
%   advanced
% NAME:
%   mrio_risk_ratios_calc
% PURPOSE:
%   Very simple function calculating the ratio of direct to total risk
%   both for subsector and for country risk. Incorporates resulting ratios
%   into the total_subsector_risk and total_country_risk tables as additional variable (column).
%
%   previous call: 
%       mrio_leontief_calc
%   
% CALLING SEQUENCE:
%   [total_subsector_risk, total_country_risk] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);
%   [total_subsector_risk,total_country_risk] = mrio_risk_ratios_calc(direct_subsector_risk, total_subsector_risk,direct_country_risk,total_country_risk); 
% EXAMPLE:
%   [total_subsector_risk,total_country_risk] = mrio_risk_ratios_calc(direct_subsector_risk, total_subsector_risk,direct_country_risk,total_country_risk); 
% INPUTS:
%   direct_subsector_risk: table which contains the direct risk per country
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country iso codes and sector names.
%   total_subsector_risk: as above but for total (i.e. direct+indirect)
%       subsector risk.
%   direct_country_risk: as above but direct risk per country. I.e. table
%       does not have a label variable for sector names.
%   total_country_risk: as above but total risk per country.
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   total_subsector_risk: table as passed in function argument (and as is output
%       from mrio_leontief_calc) but with added variable for the
%       direct-to-total risk ratios. Here for all subsectors.
%   total_country_risk: table as was passed in function argument (and as is output
%       from mrio_leontief_calc) but with added variable for the
%       direct-to-total risk ratios. Here for countries only.
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180129, initialized and finished first working version

% init output
total_subsector_risk=[];
total_country_risk=[];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% Poor man's version to check arguments. For now we don't incorporate any
% user failure catching, i.e. if funtion arguments not provided, error is
% produced.
if ~exist('direct_subsector_risk','var') || ~exist('total_subsector_risk','var') ||...
        ~exist('direct_country_risk','var') || ~exist('total_country_risk','var')
    error('Please provide the required function arguments direct_subsector_risk, subsector_risk, direct_country_risk and country_risk. Withouth these we cannot calculate the risk ratios.')
end

% locate the module's data folder (here  one folder below of the current folder, i.e. in the same level as code folder)

module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data']; %#ok

% PARAMETERS
% All risks as arrays (not tables) for internal use.
% Keeping it flexible in case future vesions of the tables change order of variables or variable names.
for var_i = 1:length(direct_subsector_risk.Properties.VariableNames)
    if isnumeric(direct_subsector_risk{1,var_i})
        direct_subsector_risk = direct_subsector_risk{:,var_i}';
    end
end
for var_i = 1:length(total_subsector_risk_in.Properties.VariableNames)
    if isnumeric(total_subsector_risk_in{1,var_i})
        total_subsector_risk = total_subsector_risk_in{:,var_i}';
    end
end
for var_i = 1:length(direct_country_risk.Properties.VariableNames)
    if isnumeric(direct_country_risk{1,var_i})
        direct_country_risk = direct_country_risk{:,var_i}';
    end
end
for var_i = 1:length(total_country_risk_in.Properties.VariableNames)
    if isnumeric(total_country_risk_in{1,var_i})
        total_country_risk = total_country_risk_in{:,var_i}';
    end
end

% Calculate direct to total risk ratios:

direct_total_ratio_subsector = direct_subsector_risk./total_subsector_risk;
direct_total_ratio_subsector(isnan(direct_total_ratio_subsector)) = 0;

direct_total_ratio_country = direct_country_risk./total_country_risk;
direct_total_ratio_country(isnan(direct_total_ratio_country)) = 0; 

total_subsector_risk_in.DirectToTotalRatio = direct_total_ratio_subsector';
total_subsector_risk = total_subsector_risk_in;

total_country_risk_in.DirectToTotalRatio = direct_total_ratio_country';
total_country_risk = total_country_risk_in;

