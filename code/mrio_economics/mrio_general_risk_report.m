function mrio_general_risk_report(direct_subsector_risk, indirect_subsector_risk, direct_country_risk, indirect_country_risk, risk_structure, climada_mriot, aggregated_mriot, climada_nan_mriot, report_filename) 
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
%   risk_structure: industry-by-industry table of expected annual damages (in millions
%       of US$) that, for each industry, contains indirect risk implicitly
%       obtained from the different industry.
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
%   aggregated_mriot: an aggregated climada mriot struct as
%       produced by mrio_aggregate_table.
%   climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% OPTIONAL INPUT PARAMETERS:
%   report_filename: the filename of the Excel file the report is written
%       to. Prompted for if not given (if Cancel pressed, write to stdout only)
% OUTPUTS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180412, initial (under construction)
% Ediz Herms, ediz.herms@outlook.com, 20180416, first working version on windows as operating system
%

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% Poor man's version to check arguments. 
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

% local folder to write the figures
fig_dir = [climada_global.results_dir filesep 'mrio ' datestr(now,1) filesep 'general risk report'];
if ~isdir(fig_dir), [fP,fN] = fileparts(fig_dir); mkdir(fP,fN); end % create it
fig_ext = 'png';

% PARAMETERS
%
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(aggregated_mriot), aggregated_mriot = mrio_aggregate_table(climada_mriot); end
% prompt for report_filename if not given
if isempty(report_filename) % local GUI
    report_filename = [climada_global.results_dir filesep 'mrio ' datestr(now,1) filesep 'general risk report' filesep 'general_risk_report.xls'];
    [filename, pathname] = uiputfile(report_filename, 'Save report as:');
    if isequal(filename,0) || isequal(pathname,0)
        report_filename = ''; % cancel
    else
        report_filename = fullfile(pathname,filename);
    end
end

% template entity file, such that we do not need to construct the entity from scratch
report_template_file = [climada_global.results_dir filesep 'mrio' filesep 'mrio_risk_report_template' climada_global.spreadsheet_ext];
%

if exist(report_template_file,'file') & ispc
    copyfile(report_template_file,report_filename);
elseif ~exist(report_template_file,'file') & ispc
    fprintf('WARNING: report template %s not found, report without formatting\n', report_template_file);
else
    fprintf('WARNING: your operating system does not support using excel templates, report without formatting\n');
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

% direct_risk = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.climada_sect_name',climada_mriot.sectors',direct_subsector_risk',total_output,(direct_subsector_risk'./total_output), ...
%                                 'VariableNames',{'country_name','country_ISO3','mainsector_name','subsector_name','EAD','value','loss of TIV'});
%                 
% indirect_risk = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.sectors',indirect_subsector_risk', ...
%                                 'VariableNames',{'Country','CountryISO','Subsector','IndirectSubsectorRisk'});

if ispc % Code to run on Windows platform
    xlswrite(report_filename,cellstr(climada_mriot.countries'),'direct risk','B2') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso'),'direct risk','C2') 
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name'),'direct risk','D2') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'direct risk','E2') 
    xlswrite(report_filename,cellstr(direct_subsector_risk'),'direct risk','F2') 
    xlswrite(report_filename,cellstr(total_output'),'direct risk','G2')
    
    xlswrite(report_filename,cellstr(climada_mriot.countries'),'indirect risk','B2') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso'),'indirect risk','C2') 
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name'),'indirect risk','D2') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'indirect risk','E2') 
    xlswrite(report_filename,cellstr(indirect_subsector_risk'),'indirect risk','F2') 
    xlswrite(report_filename,cellstr(total_output'),'indirect risk','G2')
    
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name),'risk structure','E3') 
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name'),'risk structure','A7') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'risk structure','E4') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'risk structure','B7') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso),'risk structure','E5') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso'),'risk structure','C7') 
    xlswrite(report_filename,cellstr(risk_structure),'risk structure','E7') 
elseif isunix | ismac % Code to run on Linux or Mac platform   
%     [fP,fN,fE] = fileparts(report_filename);   
%     writetable(leontief_inverse,report_filename,'Sheet','risk structure', 'Range', 'A1')
%     writetable(total_subsector_risk,report_filename,'Sheet','subsector risk', 'Range', 'A1')
%     writetable(total_country_risk,report_filename,'Sheet','country risk', 'Range', 'A1')
else
    fprintf('WARNING: Your operating system is not supported with regards to the functionality of creating excel risk reports.\n')
end

try
    winopen(report_filename);
catch
    system(['open ' report_filename]);
end

% aggregate components of subsector risk - now per country
%risk_structure = zeros(1,n_mainsectors*n_mrio_countries);
risk_structure_country = zeros(n_mainsectors,n_mrio_countries);
for country_i = 1:n_mrio_countries
    country_ISO3_i = char(mrio_countries_ISO3(country_i));
    sel_country_pos = find(climada_mriot.countries_iso == country_ISO3_i);
    for mainsector_i = 1:n_mainsectors
        mainsector_name_i = char(mainsectors(mainsector_i));
        sel_mainsector_pos = find(climada_mriot.climada_sect_name == mainsector_name_i);
        sel_pos = intersect(sel_mainsector_pos,sel_country_pos);
    
        risk_structure_country(mainsector_i,country_i) = sum(sum(risk_structure(sel_mainsector_pos,sel_country_pos)));
    end
end

[indirect_country_risk_sorted, sort_index] = sort(indirect_country_risk, 'descend');
risk_structure_country_temp = [risk_structure_country(:,sort_index(1:5)) nansum(risk_structure_country(:,sort_index(6:end)),2)]';

index_sub = categorical({[char(mrio_countries_ISO3(sort_index(1)))]...
             [char(mrio_countries_ISO3(sort_index(2)))]...
             [char(mrio_countries_ISO3(sort_index(3)))]...
             [char(mrio_countries_ISO3(sort_index(4)))]...
             [char(mrio_countries_ISO3(sort_index(5)))]...
             , 'Other'});

legend_sub = {[char(mainsectors(1))]...
            [char(mainsectors(2))]...
            [char(mainsectors(3))]...
            [char(mainsectors(4))]...
            [char(mainsectors(5))]...
            [char(mainsectors(6))]};

bar(index_sub, risk_structure_country_temp, 0.5, 'stack')
legend(legend_sub)

% Add title and axis labels
title('Countries with the largest indirect risk')
xlabel('Country ISO3')
ylabel('Indirect risk')



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
scatter(direct_subsector_risk,indirect_subsector_risk)
xlabel('Direct Subsector Risk')
ylabel('Indirect Subsector Risk')
title('Relation Between Direct & Indirect Risk')
hold on
p = polyfit(direct_subsector_risk,indirect_subsector_risk,2);
polyval(p,direct_subsector_risk);
plot(sort(direct_subsector_risk),sort(polyval(p,direct_subsector_risk)))
grid on

col_row_names = cell(1,n_subsectors*n_mrio_countries);
for subsector_i = 1:n_subsectors*n_mrio_countries
    col_row_name_temp = cellstr([char(climada_mriot.countries_iso(subsector_i)) ' | ' char(climada_mriot.sectors(subsector_i))]);
    if length(col_row_name_temp) > 62
        col_row_names(subsector_i) = matlab.lang.makeValidName(cellstr([char(col_row_name_temp{1}(1:61)) '_']));
    else
        col_row_names(subsector_i) = matlab.lang.makeValidName(col_row_name_temp);
    end
end

% sample = climada_mriot.mrio_data;
% sTable = array2table(sample,climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.climada_sect_name','RowNames,{col_row_names,'Country','CountryISO','Mainsectors'},'VariableNames',{col_row_names,'Country','CountryISO','Mainsectors'});
% 
% test = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.climada_sect_name',climada_mriot.sectors',climada_mriot.mrio_data,...
%                                 'VariableNames',{'Country','CountryISO','Mainsectors','Subsectors','IndirectRisk'});
%                             
% writetable(test) 

end % mrio_general_risk_report
