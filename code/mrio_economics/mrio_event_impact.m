function [total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief_inverse, climada_nan_mriot] = mrio_event_impact(country_name, subsector_name, climada_mriot, params) % uncomment to run as function
% mrio event impact
% MODULE:
%   advanced
% NAME:
%   mrio_event_impact
% PURPOSE:
%   Derive total risk resulting from an event in a pre-defined country and sector 
%   whereby we are using Leontief I/O model to estimate indirect risk
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
%   country_name: the country name, either full (like 'Puerto Rico')
%       or ISO3 (like 'PRI'). See climada_country_name for names/ISO3
%   subsector_name: the subsector name, see e.g. mrio_read_table
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
% OPTIONAL INPUT PARAMETERS:
%   params: a struct containing several fields, one of them specifying what
%       I-O approach is applied in this procedure to estimate indirect risk
% OUTPUTS:
%   subsector_risk: table with indirect risk per subsector/country combination 
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country ISO codes and sector names.
%   country_risk: table with indirect risk per country based on the risk measure chosen
%       in one variable and two "label" variables containing corresponding 
%       country names and country ISO codes.
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
%   climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180403, initial

indirect_subsector_risk = []; % init output
indirect_country_risk = []; % init output
leontief_inverse = []; % init output
climada_nan_mriot = []; % init output 

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('country_name','var'), country_name = []; end
if ~exist('subsector_name','var'), subsector_name = []; end
if ~exist('climada_mriot', 'var'), climada_mriot = []; end 
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
if isempty(country_name)
    country_name = [];
else
    country_name = char(country_name); % as to create filenames etc., needs to be char
end
%
if isempty(subsector_name)
    subsector_name = [];
else
    subsector_name = char(subsector_name); % as to create filenames etc., needs to be char
end
if ~isfield(params,'switch_io_approach'), params.switch_io_approach = 1; end

mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = length(mrio_countries_ISO3);

% prompt country (one or many)
[countries_liststr, countries_sort_index] = sort(mrio_countries_ISO3);
if isempty(country_name)
    % compile list of all mrio countries, then call recursively below
    [selection_country] = listdlg('PromptString','Select countries (or one):',...
        'ListString',countries_liststr);
    selection_country = countries_sort_index(selection_country);
else 
    selection_country = find(mrio_countries_ISO3 == country_name);
end

mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);

subsectors = unique(climada_mriot.sectors, 'stable');
n_subsectors = climada_mriot.no_of_sectors;    

% prompt for subsector name (one or many)
[subsectors_liststr, subsectors_sort_index] = sort(subsectors);
if isempty(subsector_name)
    % compile list of all mrio countries, then call recursively below
    [selection_subsector] = listdlg('PromptString','Select subsectors (or one):',...
        'ListString',subsectors_liststr);
    selection_subsector = subsectors_sort_index(selection_subsector);
else
    selection_subsector = find(subsectors == subsector_name);
end

prompt = {'Enter (relative) disaster impact:'};
title = 'Input';
dims = [1 35];
definput = {'0.5'};
answer = inputdlg(prompt,title,dims,definput);

direct_subsector_risk = zeros(1,n_subsectors*n_mrio_countries);  

% feed (relative) disaster impact into our direct subsector risk vector
direct_subsector_risk((selection_country-1)*n_subsectors+selection_subsector) = str2double(answer);

% Derive indirect risk using Leontief I/O model
[total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, params);

end % mrio event calc