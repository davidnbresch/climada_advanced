function mrio_general_risk_report(direct_subsector_risk, indirect_subsector_risk, direct_country_risk, indirect_country_risk, climada_mriot, aggregated_mriot, climada_nan_mriot, leontief_inverse, report_filename) 
% mrio general risk report
% MODULE:
%   advanced
% NAME:
%   mrio_general_risk_report
% PURPOSE:
%   produce a report (country, subsector, peril, damage) based on the results from
%   mrio_direct_risk_calc and mrio_leontief_calc
%
%   previous call: mrio_direct_risk_calc and mrio_leontief_calc
%   see also: 
%   
% CALLING SEQUENCE:
%   mrio_general_risk_report(direct_subsector_risk, total_subsector_risk_in, direct_country_risk, total_country_risk);
% EXAMPLE:
%   mrio_general_risk_report(direct_subsector_risk, total_subsector_risk_in, direct_country_risk, total_country_risk);
% INPUTS:
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
% prompt for report_filename if not given
if isempty(report_filename) % local GUI
    report_filename = [climada_global.data_dir filesep 'results' filesep 'mrio_risk_report.xls'];
    [filename, pathname] = uiputfile(report_filename, 'Save report as:');
    if isequal(filename,0) || isequal(pathname,0)
        report_filename = ''; % cancel
    else
        report_filename = fullfile(pathname,filename);
    end
end

% local folder to write the figures
fig_dir = [climada_global.results_dir filesep 'mrio' filesep country_name ' | ' subsector_name ' | ' datestr(now,1)];
if ~isdir(fig_dir), [fP,fN] = fileparts(fig_dir); mkdir(fP,fN); end % create it
fig_ext = 'png';

% template entity file, such that we do not need to construct the entity from scratch
report_template_file = [climada_global.results_dir filesep 'mrio' filesep 'mrio_risk_report_template' climada_global.spreadsheet_ext];
%

if exist(report_template_file,'file')
    copyfile(report_template_file,report_filename);
else
    fprintf('WARNING: report template %s not found, report without formatting\n', report_template_file);
end

mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = length(mrio_countries_ISO3);

mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);

subsectors = unique(climada_mriot.sectors, 'stable');
n_subsectors = climada_mriot.no_of_sectors;   

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
% 
% direct_risk = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.climada_sect_name',climada_mriot.sectors',direct_subsector_risk',total_output,(direct_subsector_risk'./total_output), ...
%                                 'VariableNames',{'country_name','country_ISO3','mainsector_name','subsector_name','EAD','value','loss of TIV'});
%                 
% indirect_risk = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.sectors',indirect_subsector_risk', ...
%                                 'VariableNames',{'Country','CountryISO','Subsector','IndirectSubsectorRisk'});

writetable(climada_mriot.countries_iso,report_filename,'Sheet','risk structure', 'Range', 'D1')
writetable(climada_mriot.countries_iso',report_filename,'Sheet','risk structure', 'Range', 'A4')
writetable(climada_mriot.climada_sect_name,report_filename,'Sheet','risk structure', 'Range', 'D2')
writetable(climada_mriot.climada_sect_name',report_filename,'Sheet','risk structure', 'Range', 'B4')
writetable(climada_mriot.sectors,report_filename,'Sheet','risk structure', 'Range', 'D3')
writetable(climada_mriot.sectors',report_filename,'Sheet','risk structure', 'Range', 'C4')
writetable(leontief_inverse,report_filename,'Sheet','risk structure', 'Range', 'D4')

try
    winopen(report_filename);
catch
    system(['open ' report_filename]);
end

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

end % mrio_general_risk_report
