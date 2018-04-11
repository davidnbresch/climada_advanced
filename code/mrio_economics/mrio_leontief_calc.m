function [total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, params) % uncomment to run as function
% mrio leontief calc
% MODULE:
%   advanced
% NAME:
%   mrio_leontief_calc
% PURPOSE:
%   Derive total risk whereby we are using Leontief I/O models to estimate
%   indirect risk. There are two I/O models to choose from, namely
%
%   [1] Inoperability Input-Output Model (IIM), cf.
%       Christopher W. Anderson , Joost R. Santos & Yacov Y. Haimes (2007) 
%       A Risk- based Input-Output Methodology for Measuring the Effects of the August 2003 Northeast Blackout, 
%       Economic Systems Research, 19:2, 183-204, DOI: 10.1080/09535310701330233
%
%   [2] Environmentally Extended Input-Output Analysis (EEIOA), cf.
%       Justin Kitzes (2013)
%       An Introduction to Environmentally-Extended Input-Output Analysis,
%       Resources 2013, 2, 489-503; doi:10.3390/resources2040489
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%   [direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, risk_measure);
%   next call:  % just to illustrate
%   
% CALLING SEQUENCE:
%   [subsector_risk, country_risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_subsector_risk, climada_mriot)
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   aggregated_mriot = mrio_aggregate_table(climada_mriot);
%   direct_subsector_risk = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, risk_measure);
%   [subsector_risk, country_risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);
% INPUTS:
%   direct_subsector_risk: table which contains the direct risk per country
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country iso codes and sector names.
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
% OPTIONAL INPUT PARAMETERS:
%   parameters: a structure to pass on parameters, with fields as
%       (run params = mrio_get_params to obtain all default values)
%       switch_io_approach: specifying what I-O approach is applied in this procedure 
%           to estimate indirect risk, IIM (=1, default) or EEIOA (2)
% OUTPUTS:
%   total_subsector_risk: table with indirect and direct risk per subsector/country combination 
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country ISO codes and sector names.
%   total_country_risk: table with indirect and direct risk per country based on the risk measure chosen
%       in one variable and two "label" variables containing corresponding 
%       country names and country ISO codes.
%   indirect_subsector_risk: table with indirect risk per subsector/country combination 
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country ISO codes and sector names.
%   indirect_country_risk: table with indirect risk per country based on the risk measure chosen
%       in one variable and two "label" variables containing corresponding 
%       country names and country ISO codes.
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
%   climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial
% Kaspar Tobler, 20180119 implement returned results as tables to improve readability (countries and sectors corresponding to the values are visible on first sight).
% Ediz Herms, ediz.herms@outlook.com, 20180411, option to choose between IIM and EEIOA methodology
%

indirect_subsector_risk = []; % init output
indirect_country_risk = []; % init output
leontief_inverse = []; % init output
climada_nan_mriot = []; % init output 

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('climada_mriot', 'var'), climada_mriot = []; end 
if ~exist('direct_subsector_risk', 'var'), direct_subsector_risk = []; end 
if ~exist('params','var'), params = struct; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir=[climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(direct_subsector_risk), direct_subsector_risk = mrio_direct_risk_calc('', '', climada_mriot, ''); end
if ~isfield(params,'switch_io_approach'), params.switch_io_approach = 1; end

climada_nan_mriot = isnan(climada_mriot.mrio_data); % save NaN values to trace affected relationships and values
climada_mriot.mrio_data(isnan(climada_mriot.mrio_data)) = 0; % for calculation purposes we need to replace NaN values with zeroes

n_subsectors = climada_mriot.no_of_sectors;
n_mrio_countries = climada_mriot.no_of_countries;

% Direct subsector risk as array (not table) for internal use:
if istable(direct_subsector_risk)
    for var_i = 1:length(direct_subsector_risk.Properties.VariableNames) % Keeping it flexible in case future vesions of table change order of variables or variable names.
        if isnumeric(direct_subsector_risk{1,var_i})
            direct_subsector_risk = direct_subsector_risk{:,var_i}';
        end
    end % var_i
end

% technical coefficient matrix
techn_coeffs = zeros(size(climada_mriot.mrio_data)); % init
total_output = nansum(climada_mriot.mrio_data,2); % total output per sector per country (sum up row ignoring NaN-values)
for column_i = 1:n_subsectors*n_mrio_countries
    if ~isnan(climada_mriot.mrio_data(:,column_i)./total_output(column_i))
        techn_coeffs(:,column_i) = climada_mriot.mrio_data(:,column_i)./total_output(column_i); % normalize with total output
    else 
        techn_coeffs(:,column_i) = 0;
    end
end % column_i

% direct intensity vector
direct_intensity_vector = zeros(1,length(direct_subsector_risk)); % init
for cell_i = 1:length(direct_subsector_risk)
    if ~isnan(direct_subsector_risk(cell_i)/total_output(cell_i))
        direct_intensity_vector(cell_i) = direct_subsector_risk(cell_i)/total_output(cell_i);
    end
end % cell_i

% risk calculation
switch params.switch_io_approach
    
    case 1 % Inoperability Input-Output Model (IIM), cf. Anderson et al., 2007 [1]
        
        inv_total_output = 1./total_output;
        inv_total_output(inv_total_output==Inf) = 0;
        
        % inverse of diagonalized production vector = \hat(x)^{-1}
        inv_diag_total_output = diag(inv_total_output);
        
        % leontief inverse = (I-A^*)^{-1}
        leontief_inverse = inv(eye(size(climada_mriot.mrio_data)) - inv_diag_total_output * techn_coeffs * diag(total_output));
        
        % normalized degraded final demand = (1-A^*)*q 
        degr_final_demand = leontief_inverse * direct_intensity_vector';
        
        % denormalize 
        indirect_subsector_risk = (degr_final_demand .* total_output)';
        
    case 2 % Environmentally Extended Input-Output Analysis (EEIOA), cf. Kitzes (2013) [2]
        
        % leontief inverse 
        leontief_inverse = inv(eye(size(climada_mriot.mrio_data)) - techn_coeffs);
        
        % multiplying the monetary input-output relation by the industry-specific factor requirements
        indirect_subsector_risk = ((direct_intensity_vector * leontief_inverse) .* total_output)';
    
    otherwise % TO DO
        
end % params.switch_io_approach

% aggregate indirect risk across all sectors of a country
indirect_country_risk = zeros(1,n_mrio_countries); % init
direct_country_risk = zeros(1,n_mrio_countries); % init
for mrio_country_i = 1:n_mrio_countries
    for subsector_j = 1:n_subsectors 
        indirect_country_risk(mrio_country_i) = indirect_country_risk(mrio_country_i) + indirect_subsector_risk((mrio_country_i-1) * n_subsectors+subsector_j);
        direct_country_risk(mrio_country_i) = direct_country_risk(mrio_country_i) + direct_subsector_risk((mrio_country_i-1) * n_subsectors+subsector_j);
    end % subsector_j
end % mrio_country_i

%%% For better readability, we return final results as tables so that
%%% countries and sectors corresponding to the values are visible on
%%% first sight. Further, a table allows reordering of values, which might come in handy:

total_subsector_risk = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.sectors',direct_subsector_risk',indirect_subsector_risk',(direct_subsector_risk+indirect_subsector_risk)', ...
                                'VariableNames',{'Country','CountryISO','Subsector','DirectSubsectorRisk','IndirectSubsectorRisk','TotalSubsectorRisk'});
total_country_risk = table(unique(climada_mriot.countries','stable'),unique(climada_mriot.countries_iso','stable'),direct_country_risk',indirect_country_risk',(direct_country_risk+indirect_country_risk)',...
                                'VariableNames',{'Country','CountryISO','DirectCountryRisk','IndirectCountryRisk','TotalCountryRisk'});
                            
indirect_subsector_risk = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.sectors',indirect_subsector_risk', ...
                                'VariableNames',{'Country','CountryISO','Subsector','IndirectSubsectorRisk'});
indirect_country_risk = table(unique(climada_mriot.countries','stable'),unique(climada_mriot.countries_iso','stable'),indirect_country_risk',...
                                'VariableNames',{'Country','CountryISO','IndirectCountryRisk'});

end % mrio leontief calc