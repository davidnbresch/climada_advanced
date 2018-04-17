function [total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, params) % uncomment to run as function
% mrio leontief calc
% MODULE:
%   advanced
% NAME:
%   mrio_leontief_calc
% PURPOSE:
%   Derive indirect risk from direct risk table whereby we are using Leontief I/O 
%   models to estimate indirect risk. There are two I/O models to choose from, namely
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
%   [total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, params);
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   aggregated_mriot = mrio_aggregate_table(climada_mriot);
%   direct_subsector_risk = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, risk_measure);
%   [total_subsector_risk, total_country_risk] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);
% INPUTS:
%   direct_subsector_risk: table which contains the direct risk per country
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country iso codes and sector names.
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
% OPTIONAL INPUT PARAMETERS:
%   params: a structure to pass on parameters, with fields as
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
%   leontief: a structure with 5 fields. It represents a general climada
%       leontief structure whose basic properties are the same regardless of the
%       provided mriot it is based on. The fields are:
%           risk_structure: industry-by-industry table of expected annual damages (in millions
%               of US$) that, for each industry, contains indirect risk implicitly
%               obtained from the different industry.
%           inverse: the leontief inverse matrix which relates final demand to production
%           techn_coeffs: the technical coefficient matrix which gives the amount of input that a 
%               given sector must receive from every other sector in order to create one dollar of output.
%           layers: the first 5 layers and a remainder term that gives the
%               user information on which stage/tier the risk incurs
%           climada_mriot: struct that contains information on the mrio table used
%           climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial
% Kaspar Tobler, 20180119 implement returned results as tables to improve readability (countries and sectors corresponding to the values are visible on first sight).
% Ediz Herms, ediz.herms@outlook.com, 20180411, option to choose between IIM and EEIOA methodology
% Ediz Herms, ediz.herms@outlook.com, 20180411, set up industry-by-industry risk structure table to track source of indirect risk 
% Ediz Herms, ediz.herms@outlook.com, 20180417, set up general leontief struct that contains rel. info (leontief inverse, risk structure, technical coefficient matrix) 
%

total_subsector_risk = []; % init output
total_country_risk = []; % init output
indirect_subsector_risk = []; % init output
indirect_country_risk = []; % init output
leontief = []; % init output

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

leontief.climada_nan_mriot = isnan(climada_mriot.mrio_data); % save NaN values to trace affected relationships and values
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

% Fill climada leontief struct with basic information from mrio table
leontief.climada_mriot.table_type = climada_mriot.table_type;
leontief.climada_mriot.filename = climada_mriot.filename;

% technical coefficient matrix
total_output = nansum(climada_mriot.mrio_data,2); % total output per sector per country (sum up row ignoring NaN-values)
leontief.techn_coeffs = zeros(size(climada_mriot.mrio_data)); % init
for column_i = 1:n_subsectors*n_mrio_countries
    if ~isnan(climada_mriot.mrio_data(:,column_i)./total_output(column_i))
        leontief.techn_coeffs(:,column_i) = climada_mriot.mrio_data(:,column_i)./total_output(column_i); % normalize with total output
    else 
        leontief.techn_coeffs(:,column_i) = 0;
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
        leontief.inverse = inv(eye(size(climada_mriot.mrio_data)) - inv_diag_total_output * leontief.techn_coeffs * diag(total_output));
        
        % normalized degraded final demand = (1-A^*)*q 
        rel_risk_structure = zeros(size(leontief.inverse));
        leontief.risk_structure = zeros(size(leontief.inverse));
        for row_i = 1:size(leontief.inverse,1)
           rel_risk_structure(row_i,:) = (leontief.inverse(row_i,:) .* direct_intensity_vector) .* total_output(row_i);
           leontief.risk_structure(row_i,:) = rel_risk_structure(row_i,:) .* total_output(row_i);
        end % row_i
        degr_final_demand = nansum(rel_risk_structure,2);
        
        % denormalize 
        indirect_subsector_risk = (degr_final_demand .* total_output)';
        
    case 2 % Environmentally Extended Input-Output Analysis (EEIOA), cf. Kitzes (2013) [2]
        
        % leontief inverse 
        leontief.inverse = inv(eye(size(climada_mriot.mrio_data)) - leontief.techn_coeffs);
        
        % set up industry-by-industry risk structure table
        leontief.risk_structure = zeros(size(leontief.inverse));
        for row_i = 1:size(leontief.inverse,1)
            leontief.risk_structure(row_i,:) = (direct_intensity_vector .* leontief.inverse(:,row_i)') .* total_output';
        end % row_i
        
        % multiplying the monetary input-output relation by the industry-specific factor requirements
        indirect_subsector_risk = ((direct_intensity_vector * leontief.inverse) .* total_output)';
    
    otherwise
        fprintf('I/0 approach [%i] not implemented yet.\n', params.switch_io_approach)
        return
end % params.switch_io_approach

% calculate the first 5 layers / tiers and a remainder
n_layers = 5;
leontief.layers = zeros(n_subsectors*n_mrio_countries,5+1);
leontief.layers(:,1) = leontief.techn_coeffs * total_output;
for layer_i = 2:n_layers
    leontief.layers(:,layer_i) = leontief.techn_coeffs * leontief.layers(:,layer_i-1);
end % layer_i
leontief.layers(:,n_layers+1) = indirect_subsector_risk' - sum(leontief.layers(:,1:n_layers-1),2);

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