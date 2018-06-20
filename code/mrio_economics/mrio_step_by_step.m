function mrio_step_by_step(check_figure) % uncomment to run as function
% mrio step by step
% MODULE:
%   advanced
% NAME:
%   mrio_step_by_step
% PURPOSE:
%   show the core mrio key functionality step-by-step. This is just a batch-file 
%   to allow the user to step trough and inspect all individual steps. 
%   See advanced module manual, as this code implements the section 
%   "Step-by-step guide" provided there.
%
%   running it all takes (first time) about 10 minutes (faster on subsequent
%   calls, since the mrio table is loaded rather than re-generated)
%
%   needs modules:
%   climada         https://github.com/davidnbresch/climada
%   country_risk    https://github.com/davidnbresch/climada_module_country_risk
%   isimip          https://github.com/davidnbresch/climada_module_isimip
%   advanced        https://github.com/davidnbresch/climada_module_advanced
%
% CALLING SEQUENCE:
%   mrio_step_by_step(check_figure);
% EXAMPLE:
%   mrio_step_by_step(1);
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   check_figure: set to 1 to visualize figures, by default entities are not plotted (=0)
% OUTPUTS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180614, initial 
%

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% Set max encoding distance to 30km (well enough for our purpose):
climada_global.max_encoding_distance_m = 30000;
         
% poor man's version to check arguments
if ~exist('check_figure', 'var'), check_figure = []; end

%% DEFAULT PARAMETERS
% calculations with default values so that no file dialogs etc. are opened:
params = mrio_get_params; % Can also be used with input arguments 'wiod' or 'exiobase' to choose prefered MRIO table. 
                          % If no argument is passed, default is the WIOD table.
if isempty(check_figure), check_figure = 0; end

%% read MRIO table
fprintf('<strong>Reading MRIO table...</strong>\n');tic;
climada_mriot = mrio_read_table(params.mriot.file_name,params.mriot.table_flag);toc

% aggregated MRIO table
fprintf('<strong>Aggregating MRIO table...</strong>\n');tic;
[aggregated_mriot, climada_mriot] = mrio_aggregate_table(climada_mriot,params.full_aggregation,0);toc
        
%% generate country entities based on global entities provided for set of 
% countries as defined by the mrio table
fprintf('<strong>Generating country entities based on global entity provided and prepare for mrio...</strong>\n');tic;
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
    if check_figure
    	figure; climada_entity_plot(mainsector_entity, 1.5);
    end
end % mainsector_i
toc

%% calculate direct risk for all countries and sectors as specified in mrio table
fprintf('<strong>Calculating direct risk for all countries and sectors as specified in mrio table...</strong>\n');tic;
IO_YDS = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, params);toc

%% finally, quantifying indirect risk using the Leontief I-O model
fprintf('<strong>Quantifying indirect risk using Input-Output methodology...</strong>\n');tic;
[IO_YDS, leontief] = mrio_leontief_calc(IO_YDS, climada_mriot, params);toc

%% Generate simple graphics for subsector x country-combination selected
fprintf('<strong>Generate simple graphics for subsector x country-combination selected...</strong>\n');tic;
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

end % mrio_step_by_step