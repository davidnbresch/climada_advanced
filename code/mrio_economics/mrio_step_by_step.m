% mrio_step_by_step
% mrio step by step
% MODULE:
%   advanced
% NAME:
%   mrio_step_by_step
% PURPOSE:
%   show the core mrio key functionality step-by-step. Not a function,
%   just a batch-file to allow the user to step trough and inspect all
%   individual steps. See advanced module manual, as this code implements the
%   section "Step-by-step guide" provided there.
%
%   running it all takes (first time) about 5 minutes (faster on subsequent
%   calls, since the mrio table is loaded rather than re-generated)
%
%   needs modules:
%   climada         https://github.com/davidnbresch/climada
%   country_risk    https://github.com/davidnbresch/climada_module_country_risk
%   isimip          https://github.com/davidnbresch/climada_module_isimip
%   advanced        https://github.com/davidnbresch/climada_module_advanced
%
% CALLING SEQUENCE:
%   mrio_step_by_step
% EXAMPLE:
%   mrio_step_by_step
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   direct_subsector_risk: a table containing as one variable the direct risk (EAD) for each
%       subsector/country combination covered in the original mriot. The
%       order of entries follows the same as in the entire process, i.e.
%       entry mapping is still possible via the climada_mriot.setors and
%       climada_mriot.countries arrays. The table further contins three
%       more variables with the country names, country ISO codes and sector names
%       corresponging to the direct risk values.
%   direct_country_risk: a table containing as one variable the direct risk (EAD) per country (aggregated across all subsectors). 
%       Further a variable with correpsonding country names and country ISO codes, respectively.
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
% Ediz Herms, ediz.herms@outlook.com, 20180614, initial 
%

% import/setup global variables
% global climada_global
% if ~climada_init_vars,return;end

% Set max encoding distance to 30km (well enough for our purpose):
climada_global.max_encoding_distance_m = 30000;
         
% poor man's version to check arguments
%if ~exist('country_name', 'var'), country_name = []; end
%if ~exist('subsector_name', 'var'), sector_name = []; end
%if ~exist('silent_mode','var'), silent_mode = 0; end

% DEFAULT PARAMETERS; useful in development phase to go through all
% calculations with default values so that no file dialogs etc. are opened:
params = mrio_get_params; % Can also be used with input arguments 'wiod' or 'exiobase' to choose prefered MRIO table. 
                          % If no argument is passed, default is the WIOD table.

% read MRIO table
fprintf('Reading MRIO table...\n');tic;
climada_mriot = mrio_read_table(params.mriot.file_name,params.mriot.table_flag);toc

% aggregated MRIO table
fprintf('Aggregating MRIO table...\n');tic;
[aggregated_mriot, climada_mriot] = mrio_aggregate_table(climada_mriot,params.full_aggregation,0);toc
        
% generate country entities based on global entities provided for set of 
% countries as defined by the mrio table
fprintf('Generating country entities based on global entity provided and prepare for mrio...\n');tic;
mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);
for mainsector_i = 1:n_mainsectors
    mainsector_name = char(mainsectors(mainsector_i));
    mainsector_entity_file = ['GLB_' mainsector_name '_XXX.mat'];
    if ~(exist(fullfile(climada_global.entities_dir, ['USA_' mainsector_name '_XXX.mat']), 'file') == 2) 
        % load (global) mainsector entity
        if (exist(fullfile(climada_global.entities_dir, ['GLB_' mainsector_name '_XXX.mat']), 'file') == 2) 
            mainsector_entity = climada_entity_load(mainsector_entity_file);
            mrio_entity_country(mainsector_entity, climada_mriot, '', '', '', params);
        else 
            disp('Please provide global main sector entities.')
            return
        end  
    else
        mainsector_entity = climada_entity_load(mainsector_entity_file);
    end 
    figure; climada_entity_plot(mainsector_entity,1.5);
end % mainsector_i
toc

% calculate direct risk for all countries and sectors as specified in mrio table
fprintf('Calculating direct risk for all countries and sectors as specified in mrio table...\n');tic;
[direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, params);toc

% finally, quantifying indirect risk using the Leontief I-O model
fprintf('Quantifying indirect risk using Input-Output methodology...\n');tic;
[total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, params);toc

% produce simple graphics based on subsector x country-combination selected
fprintf('produce simple graphics based on subsector x country-combination selected...\n');tic;
mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = length(mrio_countries_ISO3);

mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);

subsectors = unique(climada_mriot.sectors, 'stable');
n_subsectors = climada_mriot.no_of_sectors;  

if ~exist('country_name','var'), country_name = []; end
% prompt country (one or many) - TO DO 
[countries_liststr, countries_sort_index] = sort(mrio_countries_ISO3);
if isempty(country_name)
    % compile list of all mrio countries, then call recursively below
    [selection_country] = listdlg('PromptString','Select countries (or one):',...
        'ListString',countries_liststr);
    selection_country = countries_sort_index(selection_country);
else 
    selection_country = find(mrio_countries_ISO3 == country_name);
end
country_name = char(mrio_countries_ISO3(selection_country));

if ~exist('subsector_name','var'), subsector_name = []; end
% prompt for subsector name (one or many) - TO DO 
[subsectors_liststr, subsectors_sort_index] = sort(subsectors);
if isempty(subsector_name)
    % compile list of all mrio countries, then call recursively below
    [selection_subsector] = listdlg('PromptString','Select subsectors (or one):',...
        'ListString',subsectors_liststr);
    selection_subsector = subsectors_sort_index(selection_subsector);
else
    selection_subsector = find(subsectors == subsector_name);
end
subsector_name = char(subsectors(selection_subsector));

mrio_subsector_risk_report(country_name, subsector_name, direct_subsector_risk, indirect_subsector_risk, direct_country_risk, indirect_country_risk, leontief, climada_mriot, aggregated_mriot, 'mrio_step_by_step');
toc

% end % mrio_step_by_step