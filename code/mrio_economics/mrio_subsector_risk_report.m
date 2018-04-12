function mrio_subsector_risk_report(country_name, subsector_name, direct_subsector_risk, indirect_subsector_risk, direct_country_risk, indirect_country_risk, climada_mriot, aggregated_mriot, climada_nan_mriot, leontief_inverse, report_filename) 
% mrio subsector risk report
% MODULE:
%   advanced
% NAME:
%   mrio_subsector_risk_report
% PURPOSE:
%   produce a report (country, subsector, peril, damage) based on the results from
%   mrio_direct_risk_calc and mrio_leontief_calc
%
%   previous call: mrio_direct_risk_calc and mrio_leontief_calc
%   see also: 
%   
% CALLING SEQUENCE:
%   mrio_subsector_risk_report(country_name, subsector_name, direct_subsector_risk, total_subsector_risk_in, direct_country_risk, total_country_risk);
% EXAMPLE:
%   mrio_subsector_risk_report(country_name, subsector_name, direct_subsector_risk, total_subsector_risk_in, direct_country_risk, total_country_risk);
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
%  direct_country_risk: a table containing as one variable the direct risk per country (aggregated across all subsectors) 
%       based on the risk measure chosen. Further a variable with correpsonding country
%       names and country ISO codes, respectively.
%   subsector_risk: table with indirect risk per subsector/country combination 
%       based on the risk measure chosen in one variable and three "label" variables 
%       containing corresponding country names, country ISO codes and sector names.
%   country_risk: table with indirect risk per country based on the risk measure chosen
%       in one variable and two "label" variables containing corresponding 
%       country names and country ISO codes.
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
%   climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
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
if ~exist('risk_measure','var'), risk_measure = []; end
if ~exist('direct_subsector_risk','var'), direct_subsector_risk = []; end
if ~exist('indirect_subsector_risk','var'), indirect_subsector_risk = []; end
if ~exist('direct_country_risk','var'), direct_country_risk = []; end
if ~exist('indirect_country_risk','var'), indirect_country_risk = []; end
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
country_name = char(mrio_countries_ISO3(selection_country));
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
subsector_name = char(subsectors(selection_subsector));
% prompt for report_filename if not given
if isempty(report_filename) % local GUI
    report_filename = [climada_global.data_dir filesep 'results' filesep 'mrio_risk_report.xls'];
    [filename, pathname] = uiputfile(report_filename, 'Save report as:');
    if isequal(filename,0) || isequal(pathname,0)
        report_filename = ''; % cancel
    else
        report_filename = fullfile(pathname,filename);
    end

% local folder to write the figures
fig_dir = [climada_global.results_dir filesep 'mrio' filesep country_name ' | ' subsector_name ' | ' datestr(now,1)];
if ~isdir(fig_dir), [fP,fN] = fileparts(fig_dir); mkdir(fP,fN); end % create it
fig_ext = 'png';

% All risks as arrays (not tables) for internal use.
% Keeping it flexible in case future vesions of the tables change order of variables or variable names.
for var_i = 1:length(direct_subsector_risk.Properties.VariableNames)
    if isnumeric(direct_subsector_risk{1,var_i})
        direct_subsector_risk = direct_subsector_risk{:,var_i}';
    end
end
for var_i = 1:length(indirect_subsector_risk.Properties.VariableNames)
    if isnumeric(indirect_subsector_risk{1,var_i})
        indirect_subsector_risk = indirect_subsector_risk{:,var_i}';
    end
end
for var_i = 1:length(direct_country_risk.Properties.VariableNames)
    if isnumeric(direct_country_risk{1,var_i})
        direct_country_risk = direct_country_risk{:,var_i}';
    end
end
for var_i = 1:length(indirect_country_risk.Properties.VariableNames)
    if isnumeric(indirect_country_risk{1,var_i})
        indirect_country_risk = indirect_country_risk{:,var_i}';
    end
end

risk_index = (selection_country-1) * n_subsectors + selection_subsector;

total_output = nansum(climada_mriot.mrio_data, 2); % total output per sector per country (sum up row ignoring NaN-values)

% direct intensity vector
direct_intensity_vector = zeros(1,n_subsectors*n_mrio_countries); % init
for cell_i = 1:length(direct_subsector_risk)
    if ~isnan(direct_subsector_risk(cell_i)/total_output(cell_i))
        direct_intensity_vector(cell_i) = direct_subsector_risk(cell_i)/total_output(cell_i);
    end
end % cell_i

% technical coefficient matrix
techn_coeffs = zeros(size(climada_mriot.mrio_data)); % init
for column_i = 1:n_subsectors*n_mrio_countries
    if ~isnan(climada_mriot.mrio_data(:,column_i)./total_output(column_i))
        techn_coeffs(:,column_i) = climada_mriot.mrio_data(:,column_i)./total_output(column_i); % normalize with total output
    else 
        techn_coeffs(:,column_i) = 0;
    end
end % column_i

% components of subsector risk - per subsector
risk_structure_sub = (direct_intensity_vector .* leontief_inverse(:,risk_index)')/sum(direct_intensity_vector .* leontief_inverse(:,risk_index)');

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

risk_structure = figure('position', [250, 0, 750, 500]);
pie(risk_structure_temp, explode)
colormap([1 0 0;      %// red
          .75 .25 0;      %// green
          .5 .5 0;      %// blue
          .25 .75 0;
          0 .75 .25;
          0 .5 .5])
legend(index_sub,'Location','eastoutside','Orientation','vertical')
title(text_title)

saveas(risk_structure,[fig_dir filesep 'risk_structure'],'jpg')

% aggregate components of subsector risk - now per mainsector
%risk_structure = zeros(1,n_mainsectors*n_mrio_countries);
risk_structure = zeros(1,n_mainsectors*n_mrio_countries);
for risk_i = 1:n_mainsectors*n_mrio_countries
    country_ISO3 = char(aggregated_mriot.countries_iso(risk_i));
    mainsector_name = char(aggregated_mriot.sectors(risk_i));
    
    sel_country_pos = find(climada_mriot.countries_iso == country_ISO3);
    sel_mainsector_pos = find(climada_mriot.climada_sect_name == mainsector_name);
    sel_pos = intersect(sel_country_pos, sel_mainsector_pos);
    
    risk_structure(risk_i) = sum(risk_structure_sub(sel_pos));
end

% for mrio_country_i = 1:n_mrio_countries
%     country_ISO3 = char(mrio_countries_ISO3(mrio_country_i)); % extract ISO code
% 
%     sel_country_pos = find(climada_mriot.countries_iso == country_ISO3);
% 
%     for mainsector_j = 1:n_mainsectors
%         mainsector_name = char(mainsectors(mainsector_j));
% 
%         sel_mainsector_pos = find(climada_mriot.climada_sect_name == mainsector_name);
% 
%         sel_pos = intersect(sel_country_pos,sel_mainsector_pos);
% 
%             for subsector_i = 1:length(sel_pos)      
%                 risk_structure((mrio_country_i-1)*n_mainsectors+mainsector_j) = risk_structure((mrio_country_i-1)*n_mainsectors+mainsector_j) + risk_structure_sub(sel_pos(subsector_i));
%             end
%     end   
% end

[risk_structure_sorted, sort_index] = sort(risk_structure, 'descend');
risk_structure_temp = [risk_structure_sorted(1:5) nansum(risk_structure_sorted(6:end))];

index_sub = {[char(aggregated_mriot.countries_iso(sort_index(1))) ' | ' char(aggregated_mriot.sectors(sort_index(1)))]...
             [char(aggregated_mriot.countries_iso(sort_index(2))) ' | ' char(aggregated_mriot.sectors(sort_index(2)))]...
             [char(aggregated_mriot.countries_iso(sort_index(3))) ' | ' char(aggregated_mriot.sectors(sort_index(3)))]...
             [char(aggregated_mriot.countries_iso(sort_index(4))) ' | ' char(aggregated_mriot.sectors(sort_index(4)))]...
             [char(aggregated_mriot.countries_iso(sort_index(5))) ' | ' char(aggregated_mriot.sectors(sort_index(5)))]...
             , 'Other'};

explode = [1 1 1 1 1 0];
text_title = ['(Agg.) Risk Structure of ' char(climada_mriot.sectors(risk_index)) ' in ' char(climada_mriot.countries_iso(risk_index))];

risk_structure_agg = figure('position', [250, 0, 750, 500]);
pie(risk_structure_temp, explode)
colormap([1 0 0;      %// red
          .75 .25 0;      %// green
          .5 .5 0;      %// blue
          .25 .75 0;
          0 .75 .25;
          0 .5 .5])
legend(index_sub,'Location','eastoutside','Orientation','vertical')
title(text_title)

saveas(risk_structure_agg,[fig_dir filesep 'risk_structure_agg'],'jpg')


% 
% [risk_structure_sub_sorted, sort_index] = sort(risk_structure_sub, 'descend');
% risk_structure_sub_temp = [risk_structure_sub_sorted(1:5) sum(risk_structure_sub_sorted(6:end))]
% index_sub = {[char(climada_mriot.countries_iso(sort_index(1))) '|' char(climada_mriot.sectors(sort_index(1)))]...
%              [char(climada_mriot.countries_iso(sort_index(2))) '|' char(climada_mriot.sectors(sort_index(2)))]...
%              [char(climada_mriot.countries_iso(sort_index(3))) '|' char(climada_mriot.sectors(sort_index(3)))]...
%              [char(climada_mriot.countries_iso(sort_index(4))) '|' char(climada_mriot.sectors(sort_index(4)))]...
%              [char(climada_mriot.countries_iso(sort_index(5))) '|' char(climada_mriot.sectors(sort_index(5)))]...
%              , 'Other'}


% 
% 
% for mrio_country_i = 1:n_mrio_countries
%     country_risk_structure(:,mrio_country_i) = risk_structure((mrio_country_i-1)*n_mainsectors+1:mrio_country_i*n_mainsectors);
% end
% 
% country_risk = sum(country_risk_structure,1);
% [country_risk_sorted, sort_index] = sort(country_risk, 'descend');
% 
% explode = [1 1 1 1 1 0];
% text_title = ['Risk Structure of ' char(climada_mriot.sectors(risk_index)) ' in ' char(climada_mriot.countries_iso(risk_index))];
% 
% pie(risk_structure_sub_temp, explode)
% colormap([1 0 0;      %// red
%           .75 .25 0;      %// green
%           .5 .5 0;      %// blue
%           .25 .75 0;
%           0 1 0;
%           0 .75 0.25])
% legend(index_sub,'Location','eastoutside','Orientation','vertical')
% title(text_title)

% 
% 
% 
% 
% % check country name (and obtain ISO3)
% [country_name_chckd,country_ISO3] = climada_country_name(country_name);
% if isempty(country_name_chckd)
%     country_ISO3 = 'XXX'; % be tolerant...
%     fprintf('Warning: Might be an unorthodox country name as input - check results\n')
% else
%     country_name = country_name_chckd;
% end
% country_name_str = strrep(country_name,' ',''); % remove spaces
% 
% 


% 
% for risk_i = 1:6
%     if risk_i <=5
%         country_risk_structure_temp(:,risk_i) = country_risk_structure(:,sort_index(risk_i));
%     else
%         country_risk_structure_temp(:,risk_i) = sum(country_risk_structure(:,6:end),2);
%     end
% end
% 
% bar(mainsectors, country_risk_structure_temp, 0.5, 'stack')
% legend(index_sub,'Location','eastoutside','Orientation','vertical')
% 
% index_sub = {[char(aggregated_mriot.countries_iso(sort_index(1)))]...
%              [char(aggregated_mriot.countries_iso(sort_index(2)))]...
%              [char(aggregated_mriot.countries_iso(sort_index(3)))]...
%              [char(aggregated_mriot.countries_iso(sort_index(4)))]...
%              [char(aggregated_mriot.countries_iso(sort_index(5)))]...
%              , 'Other'}
% 
% % Add title and axis labels
% title('Risk structure')
% xlabel('Mainsectors')
% ylabel('Risk')
% 
% % Add a legend
% legend(mrio_countries_ISO3)
% 



% 
% % components of subsector risk: per country
% % aggregate direct risk across all sectors per country to obtain direct
% % country risk:
% risk_structure_country = zeros(1,n_mrio_countries); % init
% for mrio_country_i = 1:n_mrio_countries
%     for subsector_j = 1:n_subsectors 
%         risk_structure_country(mrio_country_i) = risk_structure_country(mrio_country_i) + risk_structure_sub((mrio_country_i-1) * no_of_subsectors+subsector_j);
%     end % subsector_j
% end % mrio_country_i
% 
% 
% 
% 
% 
% climada_plot_world_borders
% hold on
% 
% scatter(direct_subsector_risk,indirect_subsector_risk)
% xlabel('Direct Subsector Risk')
% ylabel('Indirect Subsector Risk')
% title('Relation Between Direct & Indirect Risk')
% hold on
% p = polyfit(direct_subsector_risk,indirect_subsector_risk,5)
% polyval(p,direct_subsector_risk)
% plot(direct_subsector_risk,polyval(p,direct_subsector_risk))
% grid on

end % mrio_subsector_risk_report
