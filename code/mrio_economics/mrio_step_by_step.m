function [subsector_risk_tb, country_risk_tb, IO_YDS, leontief] = mrio_step_by_step(check_figure) % uncomment to run as function
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
%   needs additional data: TCE-DAT hazard
%   https://polybox.ethz.ch/index.php/s/FwetsXlLeXLJPnD (Accessed 26 07 2018)
%   Download > Store in climada_global.hazards_dir (./climada_data/hazards)
%
%   Reference [Data file]:
%   Geiger, T., Frieler, K., & Bresch, D. N. (2018). 
%   A global historical data set of tropical cyclone exposure (TCE-DAT). 
%   Earth System Science Data, 10(1), 185?194. doi:10.5194/essd-10-185-2018
%
% CALLING SEQUENCE:
%   mrio_step_by_step(check_figure);
% EXAMPLE:
%   mrio_step_by_step(1);
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   check_figure: set to 1 to visualize figures, by default entities are not plotted (=0)
% OUTPUTS:
%   subsector_risk_tb: a table containing as one variable the direct risk
%       subsector/country combination selected. The table further contins three
%       more variables with the country names, country ISO codes and sector names
%       corresponging to the direct risk values.
%   country_risk_tb: a table containing as one variable the direct risk per country 
%       (aggregated across all subsectors selected). Further a variable with corresponding 
%       country names and country ISO codes, respectively.
%   IO_YDS, the Input-Output year damage set, a struct with the fields:
%       direct, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       indirect, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       hazard: itself a structure, with:
%           filename: the filename of the hazard event set
%           comment: a free comment
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

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% Set max encoding distance to 30km (well enough for our purpose):
climada_global.max_encoding_distance_m = 30000;
         
% poor man's version to check arguments
if ~exist('check_figure', 'var'), check_figure = []; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

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
        else 
            mainsector_entity = climada_entity_load(fullfile([module_data_dir filesep 'entities'], mainsector_entity_file));
        end  
        mrio_entity_country(mainsector_entity, climada_mriot, '', '', '', params);
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

%% return final results as tables
fprintf('<strong>Return final results (annual expected damage per sector and country) as tables...</strong>\n');tic;
[subsector_risk_tb, country_risk_tb] = mrio_get_risk_table(IO_YDS, 'ALL', 'ALL', 0); toc

head(subsector_risk_tb)
head(country_risk_tb)

%% Generate simple graphics for subsector x country-combination selected
fprintf('<strong>Generate simple graphics for subsector x country-combination selected...</strong>\n');tic;
mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
subsectors = unique(climada_mriot.sectors, 'stable'); 

country_name = []; % init
% prompt country name 
[countries_liststr, countries_sort_index] = sort(mrio_countries_ISO3);
if isempty(country_name)
    [selection_country] = listdlg('PromptString','Select country:',...
        'SelectionMode','single','ListString',countries_liststr);
    selection_country = countries_sort_index(selection_country);
else 
    selection_country = find(mrio_countries_ISO3 == country_name);
end
country_name = char(mrio_countries_ISO3(selection_country));

subsector_name = []; % init
% prompt for subsector name
[subsectors_liststr, subsectors_sort_index] = sort(subsectors);
if isempty(subsector_name)
    [selection_subsector] = listdlg('PromptString','Select subsector:',...
        'SelectionMode','single','ListString',subsectors_liststr);
    selection_subsector = subsectors_sort_index(selection_subsector);
else
    selection_subsector = find(subsectors == subsector_name);
end
subsector_name = char(subsectors(selection_subsector));

mrio_subsector_risk_report(IO_YDS, leontief, climada_mriot, aggregated_mriot, country_name, subsector_name);
toc

%% Generate general risk report 
fprintf('<strong>Generate general risk report...</strong>\n');tic;
mrio_general_risk_report(IO_YDS, leontief, climada_mriot, aggregated_mriot, '', params);toc

end % mrio_step_by_step