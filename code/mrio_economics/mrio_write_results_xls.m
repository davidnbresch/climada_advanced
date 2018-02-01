function mrio_write_results_xls(direct_subsector_risk,direct_country_risk,subsector_risk,country_risk)
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   Writing the four key results into an xls sheet. For now, in minimal
%   version mainly for development phase (facilitating testing and
%   comparing of results).
% CALLING SEQUENCE:
% EXAMPLE:
%   mrio_write_results_xls
% INPUTS:
%   None.
% OPTIONAL INPUT PARAMETERS:
%   None.
% OUTPUTS:
%   Matlab internally none. Creates and writes to an excel file in folder module/data/results
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180119, initialized and finished first working version.

global climada_global
if ~climada_init_vars,return;end % init/import global variables
% Get module data directory:
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir=[climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% Supress xlswrite specific matlab warning message (creates new worksheet):
warning('off','MATLAB:xlswrite:AddSheet')

target_dir  = [module_data_dir filesep 'results'];
target_file = [target_dir filesep 'mrio_final_results.xlsx'];

% First direct and total SUBSECTOR risk in one sheet:
xlswrite(target_file,direct_subsector_risk.Properties.VariableNames,'SubsectorRisk'); % Write columns headers Countries, ISO3, Sectors and direct risk  
xlswrite(target_file,cellstr(direct_subsector_risk{:,1:3}),'SubsectorRisk','A2') % Write country names, ISO3 codes and sector names. 
xlswrite(target_file,round(direct_subsector_risk{:,4},4),'SubsectorRisk','D2') % Write DIRECT risk values
xlswrite(target_file,subsector_risk.Properties.VariableNames(4:5),'SubsectorRisk','E1') % Write column header total risk and risk ratios
xlswrite(target_file,round(subsector_risk{:,4},2),'SubsectorRisk','E2') % Write TOTAL risk values
xlswrite(target_file,round(subsector_risk{:,5},4),'SubsectorRisk','F2') % Write direct to toal risk ratios

xlswrite(target_file,{'Direct risk and ratio values rounded to four, total risk values to two post-decimalpoint digits'},'SubsectorRisk','I1');

% Now write direct and total COUNTRY risk in another sheet:
xlswrite(target_file,direct_country_risk.Properties.VariableNames,'CountryRisk'); % Write column headers Countries, ISO3 and direct risk 
xlswrite(target_file,cellstr(direct_country_risk{:,1:2}),'CountryRisk','A2') % Write country names and ISO3 codes 
xlswrite(target_file,round(direct_country_risk{:,3},4),'CountryRisk','C2') % Write DIRECT risk values
xlswrite(target_file,country_risk.Properties.VariableNames(3:4),'CountryRisk','D1') % Write column header total risk and risk ratios
xlswrite(target_file,round(country_risk{:,3},2),'CountryRisk','D2') % Write TOTAL risk values
xlswrite(target_file,round(country_risk{:,4},4),'CountryRisk','E2') % Write TOTAL risk values

xlswrite(target_file,{'Direct risk and ratio values rounded to four, total risk values to two post-decimalpoint digits'},'CountryRisk','I1');


