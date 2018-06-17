function [total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, switch_io_approach) % uncomment to run as function
% mrio leontief calc
% MODULE:
%   advanced
% NAME:
%   mrio_leontief_calc
% PURPOSE:
%   Derive indirect risk from direct risk table whereby we are using Leontief I/O 
%   models to estimate indirect risk. There are three I/O models to choose from, namely
%
%   [1] Standard Input-Output (IO) Model, cf.
%       W. W. Leontief (1944) 
%       Output, employment, consumption, and investment, 
%       The Quarterly Journal of Economics 58 (2) 290?314.
%
%   [2] Ghosh Model, cf.
%       Ghosh, A. (1958)
%       Input-Output Approach in an Allocation System,
%       Economica, New Series, 25, no. 97: 58-64. doi:10.2307/2550694.
%
%   [3] Environmentally Extended Input-Output Analysis (EEIOA), cf.
%       Kitzes, J. (2013)
%       An Introduction to Environmentally-Extended Input-Output Analysis,
%       Resources 2013, 2, 489-503; doi:10.3390/resources2040489
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%   [direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot);
%   next call:  % just to illustrate
%   
% CALLING SEQUENCE:
%   [total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, switch_io_approach);
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   aggregated_mriot = mrio_aggregate_table(climada_mriot);
%   direct_subsector_risk = mrio_direct_risk_calc(climada_mriot, aggregated_mriot);
%   [total_subsector_risk, total_country_risk] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);
% INPUTS:
%   direct_subsector_risk: a table containing as one variable the direct risk (EAD) for each
%       subsector/country combination covered in the original mriot. The
%       order of entries follows the same as in the entire process, i.e.
%       entry mapping is still possible via the climada_mriot.setors and
%       climada_mriot.countries arrays. The table further contins three
%       more variables with the country names, country ISO codes and sector names
%       corresponging to the direct risk values.
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
% OPTIONAL INPUT PARAMETERS:
%   switch_io_approach: specifying what I-O approach is applied in this
%   procedure to estimate indirect risk, can be
%       1: demand-driven standard Input-Output model 
%       2: supply-driven Ghosh model (DEFAULT)
%       3: EEIOA ('environmental accounting')
% OUTPUTS:
%   total_subsector_risk: table with indirect and direct risk (EAD) per subsector/country combination 
%       in one variable and three "label" variables containing corresponding country names, country ISO codes and sector names.
%   total_country_risk: table with indirect and direct risk (EAD) per country
%       in one variable and two "label" variables containing corresponding 
%       country names and country ISO codes.
%   indirect_subsector_risk: table with indirect risk (EAD) per subsector/country combination 
%       in one variable and three "label" variables containing corresponding country names, 
%       country ISO codes and sector names.
%   indirect_country_risk: table with indirect risk (EAD) per country in one variable and two "label" 
%       variables containing corresponding country names and country ISO codes.
%   leontief: a structure with 5 fields. It represents a general climada
%       leontief structure whose basic properties are the same regardless of the
%       provided mriot it is based on. The fields are:
%           risk_structure: industry-by-industry table of expected annual damages (in millions
%               of US$) that, for each industry, contains indirect risk implicitly
%               obtained from the different industry.
%           inverse: the leontief inverse matrix which relates final demand to production
%           coefficients: either the technical coefficient matrix which gives the amount of input that a 
%               given sector must receive from every other sector in order to create one dollar of 
%               output or the allocation coefficient matrix that indicates the allocation of outputs
%               of each sector
%           layers: the first 5 layers and a remainder term that gives the
%               user information on which stage/tier the risk incurs
%           climada_mriot: struct that contains information on the mrio table used
%           climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180115, initial
% Kaspar Tobler, 20180119 implement returned results as tables to improve readability (countries and sectors corresponding to the values are visible on first sight).
% Ediz Herms, ediz.herms@outlook.com, 20180411, set up industry-by-industry risk structure table to track source of indirect risk 
% Ediz Herms, ediz.herms@outlook.com, 20180417, set up general leontief struct that contains rel. info (leontief inverse, risk structure, technical coefficient matrix) 
% Kaspar Tobler, 20180418 change calculations to use the newly implemented total_production array which includes production for final demand.
% Ediz Herms, ediz.herms@outlook.com, 20180511, option to choose between standard IO (demand-driven), Ghosh (supply-driven) and EEIOA ('environmental accounting') methodology
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
if ~exist('switch_io_approach', 'var'), switch_io_approach = []; end 

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(direct_subsector_risk), direct_subsector_risk = mrio_direct_risk_calc('', '', climada_mriot, ''); end
if isfield(switch_io_approach,'switch_io_approach')
    switch_io_approach = switch_io_approach.switch_io_approach;
elseif isempty(switch_io_approach)
    switch_io_approach = 2; 
end

leontief.climada_nan_mriot = isnan(climada_mriot.mrio_data); % save NaN values to trace affected relationships and values
climada_mriot.mrio_data(isnan(climada_mriot.mrio_data)) = 0; % for calculation purposes we need to replace NaN values with zeroes

n_subsectors = climada_mriot.no_of_sectors;
n_mrio_countries = climada_mriot.no_of_countries;

% Direct subsector risk as array (not table) for internal use:
if istable(direct_subsector_risk)
    for var_i = 1:length(direct_subsector_risk.Properties.VariableNames) % Keeping it flexible in case future vesions of table change order of variables or variable names.
        if isnumeric(direct_subsector_risk{1,var_i})
            direct_subsector_risk = direct_subsector_risk{:,var_i}';
            break
        end % isnumeric
    end % var_i
end % istable

% Fill climada leontief struct with basic information from mrio table
leontief.climada_mriot.table_type = climada_mriot.table_type;
leontief.climada_mriot.filename = climada_mriot.filename;

% technical coefficient/allocation matrix
total_output = climada_mriot.total_production;  % total output per sector per country
leontief.coefficients = zeros(size(climada_mriot.mrio_data)); % init
if switch_io_approach ~= 2 % technical coefficient matrix
    for column_i = 1:n_subsectors*n_mrio_countries
        if ~isnan(climada_mriot.mrio_data(:,column_i)./total_output(column_i))
            leontief.coefficients(:,column_i) = climada_mriot.mrio_data(:,column_i)./total_output(column_i); % normalize with total output
        else 
            leontief.coefficients(:,column_i) = 0;
        end % ~isnan
    end % column_i
else % allocation coefficient matrix
    for column_i = 1:n_subsectors*n_mrio_countries
        if ~isnan(climada_mriot.mrio_data(column_i,:)./total_output(column_i))
            leontief.coefficients(column_i,:) = climada_mriot.mrio_data(column_i,:)./total_output(column_i); % normalize with total output
        else 
            leontief.coefficients(column_i,:) = 0;
        end % ~isnan
    end % column_i
end % switch_io_approach

% direct intensity vector
direct_intensity_vector = zeros(1,length(direct_subsector_risk)); % init
for cell_i = 1:length(direct_subsector_risk)
    if ~isnan(direct_subsector_risk(cell_i)/total_output(cell_i))
        direct_intensity_vector(cell_i) = direct_subsector_risk(cell_i)/total_output(cell_i);
    end % ~isnan
end % cell_i

% risk calculation
switch switch_io_approach
    
    case 1 % Standard Input-Output (IO) model, cf. Leontief (1944) [1]
        
        % degraded final demand f .* q (elementwise)
        consumption = climada_mriot.total_production - nansum(climada_mriot.mrio_data,2); 
        degr_consumption = consumption .* direct_intensity_vector';

        % leontief inverse = (I-A)^{-1}
        leontief.inverse = inv(eye(size(climada_mriot.mrio_data)) - leontief.coefficients);
        
        % set up industry-by-industry risk structure table (degraded production L* Deltaf)
        leontief.risk_structure = zeros(size(leontief.inverse));
        for column_i = 1:size(leontief.inverse,1)
           leontief.risk_structure(:,column_i) = (leontief.inverse(column_i,:) .* degr_consumption')';
        end % column_i
        
        % calculate the first 4 layers / tiers and a remainder
        n_layers = 4;
        leontief.layer = zeros(size(leontief.inverse,1),size(leontief.inverse,2),n_layers+1);
        for layer_i = 1:n_layers
            for column_i = 1:size(leontief.inverse,1)
                leontief.layer(:,column_i,layer_i) = (leontief.coefficients(column_i,:) .* degr_consumption')';
            end % column_i
            degr_consumption = sum(leontief.layer(:,:,layer_i),1)';
        end % layer_i
        leontief.layer(:,:,n_layers+1) = leontief.risk_structure - sum(leontief.layer(:,:,1:n_layers),3);

    case 2 % Ghosh Model, cf. Ghosh (1958) [2]
        
        % degraded value added v .* q (elementwise)
        value_added = climada_mriot.total_production - nansum(climada_mriot.mrio_data,1)'; 
        degr_value_added = value_added .* direct_intensity_vector';

        % Ghosh inverse = (I-E)^{-1}
        leontief.inverse = inv(eye(size(climada_mriot.mrio_data)) - leontief.coefficients);
        
        % set up industry-by-industry risk structure table (degraded production Deltav*H)
        leontief.risk_structure = zeros(size(leontief.inverse));
        for column_i = 1:size(leontief.inverse,1)
           leontief.risk_structure(:,column_i) = degr_value_added .* leontief.inverse(:,column_i);
        end % column_i

        % calculate the first 4 layers / tiers and a remainder
        n_layers = 4;
        leontief.layer = zeros(size(leontief.inverse,1),size(leontief.inverse,2),n_layers+1);
        for layer_i = 1:n_layers
            for column_i = 1:size(leontief.inverse,1)
                leontief.layer(:,column_i,layer_i) = degr_value_added .* leontief.coefficients(:,column_i);
            end % column_i
            degr_value_added = sum(leontief.layer(:,:,layer_i),1)';
        end % layer_i
        leontief.layer(:,:,n_layers+1) = leontief.risk_structure - sum(leontief.layer(:,:,1:n_layers),3);

    case 3 % Environmentally Extended Input-Output Analysis (EEIOA), cf. Kitzes (2013) [3]
        
        % leontief inverse 
        leontief.inverse = inv(eye(size(climada_mriot.mrio_data)) - leontief.coefficients);
        
        % set up industry-by-industry risk structure table
        leontief.risk_structure = zeros(size(leontief.inverse));
        for column_i = 1:size(leontief.inverse,1)
            % multiplying the monetary input-output relation by the industry-specific factor requirements q*(1-A)^{-1}*x
            leontief.risk_structure(:,column_i) = (direct_intensity_vector .* leontief.inverse(:,column_i)') .* total_output(column_i);
        end % column_i
        
%         % calculate the first 4 layers / tiers and a remainder
%         n_layers = 4;
%         leontief.layer = zeros(size(leontief.inverse,1),size(leontief.inverse,2),n_layers+1);
%         leontief.layer(:,column_i,1) = ((direct_intensity_vector .* leontief.coefficients(:,column_i)') .* total_output(column_i))';
%         for layer_i = 2:n_layers-1
%             for column_i = 1:size(leontief.inverse,1)
%                 leontief.layer(:,column_i,layer_i) = ((direct_intensity_vector .* leontief.coefficients(:,column_i)') .* sum(leontief.layer(:,:,layer_i-1),1))';
%             end % column_i
%             total_output = sum(leontief.layer(:,:,layer_i),1)';
%         end % layer_i
%         leontief.layer(:,:,n_layers+1) = leontief.risk_structure - sum(leontief.layer(:,:,1:n_layers),3);
    
    otherwise
        
        fprintf('I/0 approach [%i] not implemented yet.\n', switch_io_approach)
        return
        
end % switch_io_approach

% sum up the risk contributions to obtain the indirect subsector risk
indirect_subsector_risk = nansum(leontief.risk_structure,1);

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