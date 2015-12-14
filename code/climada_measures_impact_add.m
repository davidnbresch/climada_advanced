function measures_impact = climada_measures_impact_add(measures_impact,EDS,entity)
% climada_measures_impact_add
% MODULE:
%   advanced
% NAME:
%   climada_measures_impact_add
% PURPOSE:
%   Add control EDS to existing measures_impact so that the before
%   'control' run is the asset change run (i.e. urban planning)
% CALLING SEQUENCE:
%   measures_impact = climada_measures_impact_add(measures_impact,EDS,entity)
% EXAMPLE:
%   measures_impact = climada_measures_impact_add(measures_impact,EDS,entity)
% INPUTS:
%   measures_impact: a climada measures_impact structure where we want to
%       add a new control run from EDS.
%       with fields .EDS,
%       .ED, .benefit, .scenario, .peril
%       > promted for if not given
%   EDS: a climada EDS structure that contains the control run that will be
%       added to measures_impact.
%       with field .refence_year,
%       .ED, .ED_at_centroid, .peril
%       > promted for if not given
%   entity: special case for Barisal to copy asset characteristics
%       (.Category, .Caterogy_name, .Category_ID)
% OPTIONAL INPUT PARAMETERS:
%   param2: as an example
% OUTPUTS:
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151207, init
%-

% measures_impact = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures_impact','var'), measures_impact = []; end
if ~exist('EDS','var'), EDS = []; end
if ~exist('entity','var'), entity = []; end

% locate the module's (or this code's) data folder (usually  afolder
% 'parallel' to the code folder, i.e. in the same level as code folder)
% module_data_dir = [fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS

% prompt for measures_impact if not given
[measures_impact, struct_name] = climada_load(measures_impact,'measures_impact');

% prompt for EDS if not given
[EDS, struct_name] = climada_load(EDS,'EDS');
% EDS = climada_EDS_load(EDS);

% ---------BARISAL SPECIALS-------
region_names = {'BCC' 'BCC' 'BCC' 'BCC' 'BCC'} ;
% region_names = {'BCC FL monsoon' 'BCC FL monsoon' 'BCC FL cyclone' 'BCC FL cyclone' 'BCC TC'} ;
peril_ID_barisal = {'FL monsoon' 'FL monsoon duration' 'FL cyclone' 'FL cyclone duration' 'TC'};
% --------------------------------

n_scenarios = numel(measures_impact);
    
for scenario_i = 1:n_scenarios
    n_measures = numel(measures_impact(scenario_i).measures.name);

    % ---------BARISAL SPECIALS-------
    EDS(scenario_i).Value_unit = climada_global.Value_unit;
    
%     % init
%     measures_impact(scenario_i).scenario.name = '';
%     measures_impact(scenario_i).scenario.name_simple = '';
%     measures_impact(scenario_i).scenario.assets_year = '';
%     measures_impact(scenario_i).scenario.region = '';
%     measures_impact(scenario_i).scenario.hazard_year = '';
%     measures_impact(scenario_i).scenario.hazard_scenario = '';
% 
%     % add scenario description for barisal 
%     region = region_names{scenario_i};
%     measures_impact(scenario_i).scenario.region = region;
%     measures_impact(scenario_i).scenario.assets_year = measures_impact(scenario_i).EDS(1).reference_year;
%     measures_impact(scenario_i).scenario.hazard_year = measures_impact(scenario_i).EDS(1).reference_year;
%     
%     assets_year = measures_impact(scenario_i).scenario.assets_year;
%     hazard_year = measures_impact(scenario_i).scenario.hazard_year;
%     region = measures_impact(scenario_i).scenario.region;
%     
%     hazard_scenario = 'moderate change';%hazard_scenario = 'extreme change';
%     if assets_year == 2014, hazard_scenario = 'no change'; end
%     measures_impact(scenario_i).scenario.hazard_scenario = hazard_scenario;
%     name = sprintf('Assets %d, Hazard %d %s, %s',assets_year, hazard_year, hazard_scenario, region);
%     
%     % a simpler scenario name
%     % either today or climate change
%     if assets_year == hazard_year
%         name_simple = sprintf('%d, %s, %s',hazard_year,hazard_scenario,region);
%     end
%     % only economic growth
%     if assets_year>hazard_year
%         name_simple = sprintf('%d, Economic growth, %s',assets_year,region);
%     end
%           
%     if hazard_year>assets_year
%         name_simple = sprintf('%d, %s, no growth, %s',hazard_year,hazard_scenario,region);
%     end
%     measures_impact(scenario_i).scenario.name = name;
%     measures_impact(scenario_i).scenario.name_simple = name_simple;
    
    % check that we add the correct EDS to measures_impact
    if strcmp(measures_impact(scenario_i).peril_ID, EDS(scenario_i).peril_ID)
        if measures_impact(scenario_i).scenario.hazard_year == EDS(scenario_i).reference_year
            
            fprintf('Add baseline run (no measure) to measures_impact (%s), \n \t rename "control" to asset location and damfun change\n',...
                measures_impact(scenario_i).scenario.name)
      
            % add EDS and other fields to measures_impact
            measures_impact(scenario_i).EDS(n_measures+2) = EDS(scenario_i);
            measures_impact(scenario_i).EDS(n_measures+1).annotation_name = 'asset location and damfun change';
            measures_impact(scenario_i).EDS(end).annotation_name = 'control';
            measures_impact(scenario_i).risk_transfer(end+1) = measures_impact(scenario_i).risk_transfer(end);
            measures_impact(scenario_i).ED(end+1) = EDS(scenario_i).ED;
            measures_impact(scenario_i).benefit(end+1) = 0;
            measures_impact(scenario_i).cb_ratio(end+1) = 0;
            measures_impact(scenario_i).ED_benefit(end+1) = 0;
            measures_impact(scenario_i).ED_risk_transfer(end+1) = 0;
            measures_impact(scenario_i).ED_cb_ratio(end+1) = 0;
            
%             % ---------BARISAL SPECIALS-------
%             % rename measures, so that they can be combined
%             if strcmp(measures_impact(scenario_i).peril_ID,'FL')
%                 measures_impact(scenario_i).measures.name{2} = 'final package';
%                 measures_impact(scenario_i).EDS(2).annotation_name = measures_impact(scenario_i).measures.name{2};
%             else
%                 measures_impact(scenario_i).measures.name{1} = 'final package';
%                 measures_impact(scenario_i).EDS(1).annotation_name = measures_impact(scenario_i).measures.name{1};
%             end
%             % ---------------------------------
            measures_impact(scenario_i).measures.name{end+1} = 'asset change (values, location, damfun)';
            measures_impact(scenario_i).EDS(end-1).annotation_name = measures_impact(scenario_i).measures.name{end};
            measures_impact(scenario_i).measures.cost(end+1) = 1;
            
            
            % overwrite peril_ID for barisal (FL monsoon, FL monsoon duration, etc)
            measures_impact(scenario_i).peril_ID = peril_ID_barisal{scenario_i};
        end
    end
    
    % ---------BARISAL SPECIALS-------
    % change Value_unit to BDT, add asset Categories
    n_measures = numel(measures_impact(scenario_i).measures.name);
    for m_i = 1:n_measures+1
        measures_impact(scenario_i).EDS(m_i).Value_unit = climada_global.Value_unit;
        measures_impact(scenario_i).EDS(m_i).assets.Category = entity.assets.Category;
        measures_impact(scenario_i).EDS(m_i).assets.Category_name = entity.assets.Category_name;
        measures_impact(scenario_i).EDS(m_i).assets.Category_ID = entity.assets.Category_ID;
    end
    % ----------------------------    
    
end %scenario_i

return
