function [subsector_risk, country_risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_subsector_risk, climada_mriot) % uncomment to run as function
% mrio leontief calc
% MODULE:
%   advanced
% NAME:
%   mrio_leontief_calc
% PURPOSE:
%   Derive total risk whereby we are using Leontief I/O model to estimate indirect risk
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
%   next call:  % just to illustrate
%   
% CALLING SEQUENCE:
%   [subsector_risk, country_risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_mainsector_risk, climada_mriot);
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   entity = mrio_entity_prep(climada_mriot); 
%   hazard = climada_hazard_load;
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
%   [subsector_risk, country_risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);
% INPUTS:
%   direct_subsector_risk: row vector which contains the direct risk per country based on the risk measure chosen
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   subsector_risk: risk per subsector/country based on the risk measure chosen
%   country_risk: risk per country based on the risk measure chosen
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
%   climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial
% Kaspar Tobler, 20180105, added a few notes/questions. See "Note KT".
% Kaspar Tobler, 20180105, changed order of matrix multiplication calculation of subsector_risk.
%-

subsector_risk = []; % init output
country_risk = []; % init output
leontief_inverse = []; % init output
climada_nan_mriot = []; % init output 

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('climada_mriot', 'var'), climada_mriot = []; end 
if ~exist('direct_subsector_risk', 'var'), direct_subsector_risk = []; end 

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
% module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data']; 

% PARAMETERS
if isempty(climada_mriot), 
    fprintf('loading centroids %s\n',centroids_file); climada_mriot = mrio_read_table; 
end
if isempty(direct_subsector_risk), direct_mainsector_risk = mrio_direct_risk_calc('', '', climada_mriot, ''); end

climada_nan_mriot = isnan(climada_mriot.mrio_data); % save NaN values to trace affected relationships and values
climada_mriot.mrio_data(isnan(climada_mriot.mrio_data)) = 0; % for calculation purposes we need to replace NaN values with zeroes

n_subsectors = climada_mriot.no_of_sectors;
n_mrio_countries = climada_mriot.no_of_countries;

total_output = nansum(climada_mriot.mrio_data,2); % total output per sector per country (sum up row ignoring NaN-values)
techn_coeffs = []; % init

% technical coefficient matrix
for row_i = 1:n_subsectors*n_mrio_countries
    if ~isnan(climada_mriot.mrio_data(:,row_i)./total_output(row_i))
        techn_coeffs(:,row_i) = climada_mriot.mrio_data(:,row_i)./total_output(row_i); % normalize with total output
    else 
        techn_coeffs(:,row_i) = 0;
    end
end % row_i

% leontief inverse 
leontief_inverse = inv(eye(size(climada_mriot.mrio_data)) - techn_coeffs);

% risk calculation
subsector_risk = direct_subsector_risk * leontief_inverse;

country_risk = zeros(1,n_mrio_countries); % init
for mrio_country_i = 1:n_mrio_countries
    for subsector_i = 1:n_subsectors 
        country_risk(mrio_country_i) = country_risk(mrio_country_i) + subsector_risk((mrio_country_i-1) * n_subsectors+subsector_i);
    end % subsector_i
end % mrio_country_i

end % mrio leontief calc