function mrio_general_risk_report(IO_YDS, leontief, climada_mriot, aggregated_mriot, report_filename, params) 
% mrio general risk report
% MODULE:
%   advanced
% NAME:
%   mrio_general_risk_report
% PURPOSE:
%   produce a general risk report (country, subsector, peril, direct and indirect damage) 
%   based on the results from mrio_direct_risk_calc and mrio_leontief_calc
%
%   previous call: mrio_direct_risk_calc and mrio_leontief_calc
%   see also: 
%   
% CALLING SEQUENCE:
%  mrio_general_risk_report(IO_YDS, leontief, climada_mriot, aggregated_mriot, report_filename, params);
% EXAMPLE:
%  mrio_general_risk_report(IO_YDS, leontief, climada_mriot, aggregated_mriot, report_filename, params);
% INPUTS:
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
%   params: a structure to pass on parameters, with fields as
%       (run params = mrio_get_params to obtain all default values)
%       verbose: whether we printf progress to stdout (=1, default) or not (=0)
% OUTPUTS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180412, initial (under construction)
% Ediz Herms, ediz.herms@outlook.com, 20180416, first working version: try writing Excel file, otherwise generate .csv report
%

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% Poor man's version to check arguments. 
if ~exist('IO_YDS', 'var'), IO_YDS = struct; end 
if ~exist('leontief','var'), leontief = struct; end
if ~exist('climada_mriot', 'var'), climada_mriot = []; end
if ~exist('aggregated_mriot', 'var'), aggregated_mriot = []; end
if ~exist('report_filename','var'),report_filename = []; end
if ~exist('params','var'), params = struct; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% local folder to write the figures
fig_dir = [climada_global.results_dir filesep 'mrio' filesep datestr(now,1)];
if ~isdir(fig_dir), [fP,fN] = fileparts(fig_dir); mkdir(fP,fN); end % create it
fig_ext = 'png';

% PARAMETERS
%
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(aggregated_mriot), aggregated_mriot = mrio_aggregate_table(climada_mriot); end
% prompt for report_filename if not given
if isempty(report_filename) % local GUI
    report_filename = [climada_global.results_dir filesep 'mrio' filesep datestr(now,1) filesep 'general_risk_report.xls'];
    [filename, pathname] = uiputfile(report_filename, 'Save report as:');
    if isequal(filename,0) || isequal(pathname,0)
        report_filename = ''; % cancel
    else
        report_filename = fullfile(pathname,filename);
    end
end
if ~isfield(params,'verbose'), params.verbose = 1; end

% template entity file, such that we do not need to construct the entity from scratch
report_template_file = [climada_global.results_dir filesep 'mrio' filesep 'mrio_risk_report_template' climada_global.spreadsheet_ext];
%

% prepare header and print format
header_str = 'peril_ID;country_name;country_ISO3;mainsector_name;subsector_name;damage;value;damage/value';
format_str = '%s;%s;%s;%s;%s;%d;%d;%f\n';
%header_str = strrep(header_str,';',climada_global.csv_delimiter);
%format_str = strrep(format_str,';',climada_global.csv_delimiter);

mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = length(mrio_countries_ISO3);

mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);

subsectors = unique(climada_mriot.sectors, 'stable');
n_subsectors = climada_mriot.no_of_sectors;   

[subsector_risk_tb, country_risk_tb] = mrio_get_risk_table(IO_YDS, 'ALL', 'ALL', 0);

% All risks as arrays (not tables) for internal use.
% Keeping it flexible in case future vesions of the tables change order of variables or variable names.
direct_subsector_risk = subsector_risk_tb{:,4}';
indirect_subsector_risk = subsector_risk_tb{:,5}';

direct_country_risk = country_risk_tb{:,3}';
indirect_country_risk = country_risk_tb{:,4}';
total_output = climada_mriot.total_production; % total output per sector per country

if exist(report_template_file,'file') & ispc
    copyfile(report_template_file,report_filename);
elseif ~exist(report_template_file,'file') & ispc
    fprintf('WARNING: report template %s not found, report without formatting\n', report_template_file);
else
    fprintf('WARNING: your operating system does not support writing excel files, proceed writing .csv\n');
end

% try writing Excel file
if climada_global.octave_mode
    STATUS = xlswrite(report_filename,...
        {'peril_ID','country_name','country_ISO3','mainsector_name','subsector_name','damage','value','damage/value'});
    MESSAGE = 'Octave';
else
    [STATUS, MESSAGE] = xlswrite(report_filename,...
        {'peril_ID','country_name','country_ISO3','mainsector_name','subsector_name','damage','value','damage/value'});
end

if ~STATUS || strcmp(MESSAGE.identifier,'MATLAB:xlswrite:NoCOMServer') % xlswrite failed, write .csv instead
    
    [fP,fN] = fileparts(report_filename);
    report_filename = [fP filesep fN '.csv'];
    delete(report_filename);
    
    direct_risk_table = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.climada_sect_name',climada_mriot.sectors',direct_subsector_risk',total_output,(direct_subsector_risk'./total_output), ...
                                'VariableNames',{'country_name','country_ISO3','mainsector_name','subsector_name','damage','value','damage_ratio'});

    indirect_risk_table = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.climada_sect_name',climada_mriot.sectors',indirect_subsector_risk',total_output,(indirect_subsector_risk'./total_output), ...
                                'VariableNames',{'country_name','country_ISO3','mainsector_name','subsector_name','damage','value','damage_ratio'});

    risk_structure_table = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.climada_sect_name',climada_mriot.sectors',leontief.risk_structure, ...
                                'VariableNames',{'country_name','country_ISO3','mainsector_name','subsector_name','damage'});                     

    [fP,fN,fE] = fileparts(report_filename);   
    try
        writetable(risk_structure_table,[fP filesep fN '_risk_structure.csv'])
    catch
       
    end
    writetable(direct_risk_table,[fP filesep fN '_direct_risk.csv'])
    writetable(indirect_risk_table,[fP filesep fN '_indirect_risk.csv'])
    
    if params.verbose, fprintf('report(s) written to %s\n',[fP filesep fN '_XXX.csv']); end

else
    %[STATUS,MESSAGE] = xlswrite(report_filename,excel_data, 1,'A2'); %A2 not to overwrite header
    xlswrite(report_filename,cellstr(climada_mriot.countries'),'direct risk','B2') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso'),'direct risk','C2') 
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name'),'direct risk','D2') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'direct risk','E2') 
    xlswrite(report_filename,direct_subsector_risk','direct risk','F2') 
    xlswrite(report_filename,total_output','direct risk','G2')
    
    xlswrite(report_filename,cellstr(climada_mriot.countries'),'indirect risk','B2') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso'),'indirect risk','C2') 
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name'),'indirect risk','D2') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'indirect risk','E2') 
    xlswrite(report_filename,indirect_subsector_risk','indirect risk','F2') 
    xlswrite(report_filename,total_output','indirect risk','G2')
    
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name),'risk structure','E3') 
    xlswrite(report_filename,cellstr(climada_mriot.climada_sect_name'),'risk structure','A7') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'risk structure','E4') 
    xlswrite(report_filename,cellstr(climada_mriot.sectors'),'risk structure','B7') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso),'risk structure','E5') 
    xlswrite(report_filename,cellstr(climada_mriot.countries_iso'),'risk structure','C7') 
    xlswrite(report_filename,leontief.risk_structure,'risk structure','E7') 
    if params.verbose, fprintf('report written to %s\n',report_filename); end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 1: Stacked bar graph of largest indirect risk carriers (countries)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aggregate components of subsector risk - now per country
indirect_risk_structure_country = zeros(n_mainsectors,n_mrio_countries);
for country_i = 1:n_mrio_countries
    country_ISO3_i = char(mrio_countries_ISO3(country_i));
    sel_country_pos = find(climada_mriot.countries_iso == country_ISO3_i);
    for mainsector_i = 1:n_mainsectors
        mainsector_name_i = char(mainsectors(mainsector_i));
        sel_mainsector_pos = find(climada_mriot.climada_sect_name == mainsector_name_i);
        sel_pos = intersect(sel_mainsector_pos,sel_country_pos);
    
        indirect_risk_structure_country(mainsector_i,country_i) = sum(IO_YDS.indirect.ED(sel_pos));
    end % mainsector_i
end % country_i

[~, sort_index] = sort(nansum(indirect_risk_structure_country,1), 'descend');
indirect_risk_structure_country_temp = [indirect_risk_structure_country(:,sort_index(1:5)) nansum(indirect_risk_structure_country(:,sort_index(6:end)),2)]';

index_sub = {char(mrio_countries_ISO3(sort_index(1)))...
             char(mrio_countries_ISO3(sort_index(2)))...
             char(mrio_countries_ISO3(sort_index(3)))...
             char(mrio_countries_ISO3(sort_index(4)))...
             char(mrio_countries_ISO3(sort_index(5)))...
             'Other'};

legend_sub = {['Agriculture']...
            ['Forestry & Fishing']...
            ['Mining & Quarrying']...
            ['Manufacturing']...
            ['Services']...
            ['Utilities']};

indirect_risk_structure_country = figure;
bar(indirect_risk_structure_country_temp, 0.5, 'stack');
set(gca,'XTickLabel',index_sub);
legend(legend_sub)

% Add title and axis labels
title('Expected annual indirect damage')
xlabel('ISO3')
ylabel('MM$')

saveas(indirect_risk_structure_country,[fig_dir filesep 'indirect_risk_structure'],'jpg')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 2: Stacked bar graph of largest direct risk carriers (countries)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aggregate components of subsector risk - now per country
direct_risk_structure_country = zeros(n_mainsectors,n_mrio_countries);
for country_i = 1:n_mrio_countries
    country_ISO3_i = char(mrio_countries_ISO3(country_i));
    sel_country_pos = find(climada_mriot.countries_iso == country_ISO3_i);
    for mainsector_i = 1:n_mainsectors
        mainsector_name_i = char(mainsectors(mainsector_i));
        sel_mainsector_pos = find(climada_mriot.climada_sect_name == mainsector_name_i);
        sel_pos = intersect(sel_mainsector_pos,sel_country_pos);
    
    direct_risk_structure_country(mainsector_i,country_i) = sum(IO_YDS.direct.ED(sel_pos));
    end % mainsector_i
end % country_i

[~, sort_index] = sort(nansum(direct_risk_structure_country,1), 'descend');
direct_risk_structure_country_temp = [direct_risk_structure_country(:,sort_index(1:5)) nansum(direct_risk_structure_country(:,sort_index(6:end)),2)]';

index_sub = {char(mrio_countries_ISO3(sort_index(1)))...
             char(mrio_countries_ISO3(sort_index(2)))...
             char(mrio_countries_ISO3(sort_index(3)))...
             char(mrio_countries_ISO3(sort_index(4)))...
             char(mrio_countries_ISO3(sort_index(5)))...
             'Other'};

% legend_sub = {[char(mainsectors(1))]...
%             [char(mainsectors(2))]...
%             [char(mainsectors(3))]...
%             [char(mainsectors(4))]...
%             [char(mainsectors(5))]...
%             [char(mainsectors(6))]};

legend_sub = {['Agriculture']...
            ['Forestry & Fishing']...
            ['Mining & Quarrying']...
            ['Manufacturing']...
            ['Services']...
            ['Utilities']};

direct_risk_structure_country = figure;
bar(direct_risk_structure_country_temp, 0.5, 'stack');
set(gca,'XTickLabel',index_sub);
legend(legend_sub)

% Add title and axis labels
title('Expected annual direct damage')
xlabel('ISO3')
ylabel('MM$')

saveas(direct_risk_structure_country,[fig_dir filesep 'direct_risk_structure'],'jpg')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 3: Scatter plot of indirect vs. direct risk ratio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
% p = polyfit(direct_subsector_risk,indirect_subsector_risk,2);
% polyval(p,direct_subsector_risk);
% plot(sort(direct_subsector_risk),sort(polyval(p,direct_subsector_risk)))
% grid on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 4-5: World map of direct and direct risk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% rel_risk = zeros(1,length(total_output));
% for i = 1:length(total_output)
%     if ~isnan(direct_subsector_risk(i)/total_output(i))
%         rel_risk(i) = direct_subsector_risk(i)/total_output(i);
%     end
% end
% rel_country_risk = zeros(1,n_mrio_countries); 
% for mrio_country_i = 1:n_mrio_countries
%     for subsector_j = 1:n_subsectors 
%         rel_country_risk(mrio_country_i) = rel_country_risk(mrio_country_i) + rel_risk((mrio_country_i-1) * n_subsectors+subsector_j);
%     end % subsector_j
% end % mrio_country_i
% 
% ran=range(rel_country_risk); %finding range of data
% min_val=min(rel_country_risk);%finding maximum value of data
% max_val=max(rel_country_risk);%finding minimum value of data
% y=floor(((rel_country_risk-min_val)/ran)*63)+1; 
% col=zeros(20,3);
% p=flipud(colormap('hot'));
% for i=1:length(rel_country_risk)
%   a=y(i);
%   col(i,:)=p(a,:);
%   stem3(i,i,rel_country_risk(i),'Color',col(i,:))
%   hold on
% end
% climada_plot_world_borders
% 
% for mrio_country_i = 1:n_mrio_countries
%         country_ISO3 = char(mrio_countries_ISO3(mrio_country_i)); % extract ISO code
%     if ~strcmp(country_ISO3,'ROW') && ~strcmp(country_ISO3,'RoW')
%         climada_plot_world_borders('',country_ISO3,'','',col(mrio_country_i,:),'')
%         %climada_plot_world_borders('',country_ISO3,'','',[255 (1-rel_country_risk(mrio_country_i)/max(rel_country_risk))*255 (1-rel_country_risk(mrio_country_i)/max(rel_country_risk))*255]/255,'')
%         hold on
%     end
% end

% for mrio_country_i = 1:n_mrio_countries
%         country_ISO3 = char(mrio_countries_ISO3(mrio_country_i)); % extract ISO code
%     if ~strcmp(country_ISO3,'ROW') && ~strcmp(country_ISO3,'RoW')
%         if (direct_country_risk(mrio_country_i) == 0)
%             climada_plot_world_borders('',country_ISO3,'','',[0 max((1-(log10(direct_country_risk(mrio_country_i))/log10(max(direct_country_risk)))^2)*160,0) 0]/255,'')
%         else
%             climada_plot_world_borders('',country_ISO3,'','',[((log10(direct_country_risk(mrio_country_i))/log10(max(direct_country_risk)))^2)*160 max((1-(log10(direct_country_risk(mrio_country_i))/log10(max(direct_country_risk)))^2)*160,0) 0]/255,'')
%         end
%         hold on
%     end


end % mrio_general_risk_report
