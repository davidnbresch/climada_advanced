function mrio_subsector_risk_report(country_name, subsector_name, direct_subsector_risk, indirect_subsector_risk, direct_country_risk, indirect_country_risk, leontief, climada_mriot, aggregated_mriot, report_filename) 
% mrio subsector risk report
% MODULE:
%   advanced
% NAME:
%   mrio_subsector_risk_report
% PURPOSE:
%   produce a subsector specific risk report (country, subsector, peril, 
%   indirect and direct damage) based on the results from mrio_direct_risk_calc 
%   and mrio_leontief_calc
%
%   previous call: mrio_direct_risk_calc and mrio_leontief_calc
%   see also: 
%   
% CALLING SEQUENCE:
%   mrio_subsector_risk_report(country_name, subsector_name, direct_subsector_risk, indirect_subsector_risk, direct_country_risk, indirect_country_risk, leontief, climada_mriot, aggregated_mriot);
% EXAMPLE:
%   climada_mriot = mrio_read_table
%   aggregated_mriot = mrio_aggregate_table(climada_mriot);
%   [direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot);
%   [total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);
%   mrio_subsector_risk_report(country_name, subsector_name, direct_subsector_risk, indirect_subsector_risk, direct_country_risk, indirect_country_risk, leontief, climada_mriot, aggregated_mriot);
% INPUTS:
%   country_name: the country name, either full (like 'Puerto Rico')
%       or ISO3 (like 'PRI'). See climada_country_name for names/ISO3
%   subsector_name: the subsector name, see e.g. mrio_read_table
%   direct_subsector_risk: a table containing as one variable the direct risk for each
%       subsector/country combination covered in the original mriot. The
%       order of entries follows the same as in the entire process, i.e.
%       entry mapping is still possible via the climada_mriot.setors and
%       climada_mriot.countries arrays. The table further contins three
%       more variables with the country names, country ISO codes and sector names
%       corresponging to the direct risk values.
%   direct_country_risk: a table containing as one variable the direct risk per country (aggregated across all subsectors) 
%       based on the risk measure chosen. Further a variable with correpsonding country
%       names and country ISO codes, respectively.
%   subsector_risk: table with indirect risk per subsector/country combination 
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country ISO codes and sector names.
%   country_risk: table with indirect risk per country based on the risk measure chosen
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
%           climada_mriot: struct that contains information on the mrio table used
%           climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
%   aggregated_mriot: an aggregated climada mriot struct as
%       produced by mrio_aggregate_table.
% OPTIONAL INPUT PARAMETERS:
%   report_filename: the filename of the Excel file the report is written
%       to. Prompted for if not given (if Cancel pressed, write to stdout only)
% OUTPUTS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180412, initial (under construction)
%

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% Poor man's version to check arguments. 
if ~exist('country_name','var'), country_name = []; end
if ~exist('subsector_name','var'), subsector_name = []; end
if ~exist('direct_subsector_risk','var'), direct_subsector_risk = []; end
if ~exist('indirect_subsector_risk','var'), indirect_subsector_risk = []; end
if ~exist('direct_country_risk','var'), direct_country_risk = []; end
if ~exist('indirect_country_risk','var'), indirect_country_risk = []; end
if ~exist('risk_structure','var'), risk_structure = []; end
if ~exist('climada_mriot', 'var'), climada_mriot = []; end
if ~exist('aggregated_mriot', 'var'), aggregated_mriot = []; end
if ~exist('climada_nan_mriot','var'), climada_nan_mriot = []; end
if ~exist('report_filename','var'),report_filename = []; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
%
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(aggregated_mriot), aggregated_mriot = mrio_aggregate_table(climada_mriot); end
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
%
mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = length(mrio_countries_ISO3);
%
mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);
%
subsectors = unique(climada_mriot.sectors, 'stable');
n_subsectors = climada_mriot.no_of_sectors;    
%
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
%
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
%
% prompt for report_filename if not given
if isempty(report_filename) % local GUI
    report_filename = [climada_global.data_dir filesep 'results' filesep 'mrio' filesep datestr(now,1) filesep 'subesctor_risk_report.xls'];
    [filename, pathname] = uiputfile(report_filename, 'Save report as:');
    if isequal(filename,0) || isequal(pathname,0)
        report_filename = ''; % cancel
    else
        report_filename = fullfile(pathname,filename);
    end
end

% local folder to write the figures
fig_dir = [climada_global.results_dir filesep 'mrio' filesep datestr(now,1) filesep country_name '_' subsector_name];
if ~isdir(fig_dir), [fP,fN] = fileparts(fig_dir); mkdir(fP,fN); end % create it
fig_ext = 'png';

% All risks as arrays (not tables) for internal use.
% Keeping it flexible in case future vesions of the tables change order of variables or variable names.
if istable(direct_subsector_risk)
    for var_i = 1:length(direct_subsector_risk.Properties.VariableNames)
            if isnumeric(direct_subsector_risk{1,var_i})
                direct_subsector_risk = direct_subsector_risk{:,var_i}';
            end
    end % var_i
end
if istable(indirect_subsector_risk)
    for var_i = 1:length(indirect_subsector_risk.Properties.VariableNames)
        if isnumeric(indirect_subsector_risk{1,var_i})
            indirect_subsector_risk = indirect_subsector_risk{:,var_i}';
        end
    end % var_i
end
if istable(direct_country_risk)
    for var_i = 1:length(direct_country_risk.Properties.VariableNames)
        if isnumeric(direct_country_risk{1,var_i})
            direct_country_risk = direct_country_risk{:,var_i}';
        end
    end % var_i
end
if istable(indirect_country_risk)
    for var_i = 1:length(indirect_country_risk.Properties.VariableNames)
        if isnumeric(indirect_country_risk{1,var_i})
            indirect_country_risk = indirect_country_risk{:,var_i}';
        end
    end % var_i
end

risk_index = (selection_country-1) * n_subsectors + selection_subsector;

total_output = climada_mriot.total_production; % total output per sector per country

% direct intensity vector
direct_intensity_vector = zeros(1,n_subsectors*n_mrio_countries); % init
for cell_i = 1:length(direct_subsector_risk)
    if ~isnan(direct_subsector_risk(cell_i)/total_output(cell_i))
        direct_intensity_vector(cell_i) = direct_subsector_risk(cell_i)/total_output(cell_i);
    end
end % cell_i

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 1: pier chart of contributions (subsector level) to our subsector risk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% components of subsector risk - per subsector
risk_structure_sub = (leontief.risk_structure(:,risk_index)/sum(leontief.risk_structure(:,risk_index)))';

[risk_structure_sorted, sort_index] = sort(risk_structure_sub, 'descend');
risk_structure_temp = [risk_structure_sorted(1:5) nansum(risk_structure_sorted(6:end))];

index_sub = {[char(climada_mriot.countries_iso(sort_index(1))) ' | ' char(climada_mriot.sectors(sort_index(1)))]...
             [char(climada_mriot.countries_iso(sort_index(2))) ' | ' char(climada_mriot.sectors(sort_index(2)))]...
             [char(climada_mriot.countries_iso(sort_index(3))) ' | ' char(climada_mriot.sectors(sort_index(3)))]...
             [char(climada_mriot.countries_iso(sort_index(4))) ' | ' char(climada_mriot.sectors(sort_index(4)))]...
             [char(climada_mriot.countries_iso(sort_index(5))) ' | ' char(climada_mriot.sectors(sort_index(5)))]...
             , 'Other'};

explode = [1 1 1 1 1 0];
text_title = ['Risk Structure of ' char(climada_mriot.sectors(risk_index)) ' in ' char(climada_mriot.countries_iso(risk_index))];

risk_structure_main = figure('position', [250, 0, 750, 500]);
pie(risk_structure_temp, explode)
colormap([1 0 0;      %// red
          .75 .25 0;      %// green
          .5 .5 0;      %// blue
          .25 .75 0;
          0 .75 .25;
          0 .5 .5])
legend(index_sub,'Location','eastoutside','Orientation','vertical')
title(text_title)

saveas(risk_structure_main,[fig_dir filesep 'risk_structure'],'jpg')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 2: pier chart of contributions (mainsector level) to our subsector risk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aggregate components of subsector risk - now per mainsector
%risk_structure = zeros(1,n_mainsectors*n_mrio_countries);
risk_structure_main = zeros(1,n_mainsectors*n_mrio_countries);
for risk_i = 1:n_mainsectors*n_mrio_countries
    country_ISO3 = char(aggregated_mriot.countries_iso(risk_i));
    mainsector_name = char(aggregated_mriot.sectors(risk_i));
    
    sel_country_pos = find(climada_mriot.countries_iso == country_ISO3);
    sel_mainsector_pos = find(climada_mriot.climada_sect_name == mainsector_name);
    sel_pos = intersect(sel_country_pos, sel_mainsector_pos);
    
    risk_structure_main(risk_i) = sum(risk_structure_sub(sel_pos));
end

[risk_structure_sorted, sort_index] = sort(risk_structure_main, 'descend');
risk_structure_temp = [risk_structure_sorted(1:5) nansum(risk_structure_sorted(6:end))];

index_sub = {[char(aggregated_mriot.countries_iso(sort_index(1))) ' | ' char(aggregated_mriot.sectors(sort_index(1)))]...
             [char(aggregated_mriot.countries_iso(sort_index(2))) ' | ' char(aggregated_mriot.sectors(sort_index(2)))]...
             [char(aggregated_mriot.countries_iso(sort_index(3))) ' | ' char(aggregated_mriot.sectors(sort_index(3)))]...
             [char(aggregated_mriot.countries_iso(sort_index(4))) ' | ' char(aggregated_mriot.sectors(sort_index(4)))]...
             [char(aggregated_mriot.countries_iso(sort_index(5))) ' | ' char(aggregated_mriot.sectors(sort_index(5)))]...
             , 'Other'};

explode = [1 1 1 1 1 0];
text_title = ['Risk Structure of ' char(climada_mriot.sectors(risk_index)) ' in ' char(climada_mriot.countries_iso(risk_index))];

risk_structure_main = figure('position', [250, 0, 750, 500]);
pie(risk_structure_temp, explode)
colormap([1 0 0;      %// red
          .75 .25 0;      %// green
          .5 .5 0;      %// blue
          .25 .75 0;
          0 .75 .25;
          0 .5 .5])
legend(index_sub,'Location','eastoutside','Orientation','vertical')
title(text_title)

saveas(risk_structure_main,[fig_dir filesep 'risk_structure_main'],'jpg')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 3: pier chart of contributions (country level) to our subsector risk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aggregate components of subsector risk - now per country
%risk_structure = zeros(1,n_mainsectors*n_mrio_countries);
risk_structure_country = zeros(1,n_mrio_countries);
for country_i = 1:n_mrio_countries
    country_ISO3_i = char(mrio_countries_ISO3(country_i));
    
    sel_pos = find(climada_mriot.countries_iso == country_ISO3_i);
    
    risk_structure_country(country_i) = sum(risk_structure_sub(sel_pos));
end

[risk_structure_sorted, sort_index] = sort(risk_structure_country, 'descend');
risk_structure_temp = [risk_structure_sorted(1:5) nansum(risk_structure_sorted(6:end))];

index_sub = {[char(mrio_countries_ISO3(sort_index(1)))]...
             [char(mrio_countries_ISO3(sort_index(2)))]...
             [char(mrio_countries_ISO3(sort_index(3)))]...
             [char(mrio_countries_ISO3(sort_index(4)))]...
             [char(mrio_countries_ISO3(sort_index(5)))]...
             , 'Other'};

explode = [1 1 1 1 1 0];
text_title = ['Risk Structure of ' char(climada_mriot.sectors(risk_index)) ' in ' char(climada_mriot.countries_iso(risk_index))];

risk_structure_country = figure('position', [250, 0, 750, 500]);
pie(risk_structure_temp, explode)
colormap([1 0 0;      %// red
          .75 .25 0;      %// green
          .5 .5 0;      %// blue
          .25 .75 0;
          0 .75 .25;
          0 .5 .5])
legend(index_sub,'Location','eastoutside','Orientation','vertical')
title(text_title)

saveas(risk_structure_country,[fig_dir filesep 'risk_structure_country'],'jpg')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 3: Sankey diagram of contributions (mainsector level) to our subsector risk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% input_sub = leontief.risk_structure(:,risk_index);
% output_sub = leontief.risk_structure(risk_index,:);
% 
% for country_i = 1:n_mrio_countries
%     country_ISO3_i = char(mrio_countries_ISO3(country_i));
%     
%     sel_pos = find(climada_mriot.countries_iso == country_ISO3_i);
% 
%     input_sub_agg(country_i) = sum(input_sub(sel_pos));
%     output_sub_agg(country_i) = sum(output_sub(sel_pos));
% end
% 
% [input_sub_agg_sorted, input_sort_index] = sort(input_sub_agg, 'descend');
% input_sub_temp = [input_sub_agg_sorted(1:5) nansum(input_sub_agg_sorted(6:end))];
% 
% input_index_sub = cellstr({[char(mrio_countries_ISO3(input_sort_index(1)))]...
%              [char(mrio_countries_ISO3(input_sort_index(2)))]...
%              [char(mrio_countries_ISO3(input_sort_index(3)))]...
%              [char(mrio_countries_ISO3(input_sort_index(4)))]...
%              [char(mrio_countries_ISO3(input_sort_index(5)))]...
%              , 'Other'});
% 
% [output_sub_agg_sorted, output_sort_index] = sort(output_sub_agg, 'descend');
% output_sub_temp = [output_sub_agg_sorted(1:5) nansum(output_sub_agg_sorted(6:end))];
% 
% output_index_sub = cellstr({[char(mrio_countries_ISO3(output_sort_index(1)))]...
%              [char(mrio_countries_ISO3(output_sort_index(2)))]...
%              [char(mrio_countries_ISO3(output_sort_index(3)))]...
%              [char(mrio_countries_ISO3(output_sort_index(4)))]...
%              [char(mrio_countries_ISO3(output_sort_index(5)))]...
%              , 'Other'});
% 
% %labels=[imports_list(:,1) ;  exports_list(:,1) ; 'Switzerland domestic & RoW'];
% unit = '%'; sep = [1];
% labels=[input_index_sub ;  output_index_sub];
% drawSankey(input_sub_temp', output_sub_temp', unit, labels);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 4: Stacked bar graph of the different production layers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % only consider total subsector output of the subsector specified
% total_output_sub = zeros(size(total_output));
% total_output_sub(risk_index) = total_output(risk_index);
% 
% indirect_country_risk_sub = leontief.inverse * total_output_sub;
% 
% % calculate the first 5 layers / tiers and a remainder
% n_layers = 5;
% leontief_layers = zeros(n_subsectors*n_mrio_countries,5+1);
% leontief_layers(:,1) = leontief.techn_coeffs * total_output_sub;
% for layer_i = 2:n_layers
%     leontief_layers(:,layer_i) = leontief.techn_coeffs * leontief_layers(:,layer_i-1);
% end % layer_i
% leontief_layers(:,n_layers+1) = indirect_country_risk_sub - sum(leontief_layers(:,1:n_layers-1),2); % TO DO
% 
% % aggregate components of production layers - per country
% leontief_layer_agg = zeros(n_mrio_countries,size(leontief_layers,2));
% for country_i = 1:n_mrio_countries
%     country_ISO3_i = char(mrio_countries_ISO3(country_i));
%     sel_pos = find(climada_mriot.countries_iso == country_ISO3_i); 
%     
%     leontief_layer_agg(country_i,:) = sum(leontief_layers(sel_pos,:),1);
% end
% 
% index_sub = categorical({['layer_1']...
%              ['layer_2']...
%              ['layer_3']...
%              ['layer_4']...
%              ['layer_5']...
%              ['layer_6_n']});
% 
% legend_sub = {[char(mrio_countries_ISO3)]};
% 
% barh(leontief_layer_agg', 0.5, 'stack');
% legend(legend_sub)
% 
% % Add title and axis labels
% title('production layers')
% xlabel('')
% ylabel('')
% 
% saveas(risk_structure,[fig_dir filesep 'risk_structure'],'jpg')

end % mrio_subsector_risk_report
