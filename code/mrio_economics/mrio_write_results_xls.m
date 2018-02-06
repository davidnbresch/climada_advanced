function mrio_write_results_xls(direct_subsector_risk,direct_country_risk,total_subsector_risk,total_country_risk)
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
%   mrio_write_results_xls(direct_subsector_risk,direct_country_risk,total_subsector_risk,total_country_risk)
% INPUTS:
%   
% OPTIONAL INPUT PARAMETERS:
%   None.
% OUTPUTS:
%   Matlab internally none. Creates and writes to an excel file in folder module/data/results
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180119, initialized and finished first working version. Formally not yet in best-practice form.

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

% First direct, indirect, total and ratios of SUBSECTOR risk in one sheet:
xlswrite(target_file,total_subsector_risk.Properties.VariableNames,'SubsectorRisk'); % Write column headers
xlswrite(target_file,cellstr(total_subsector_risk{:,1:3}),'SubsectorRisk','A2') % Write country names, ISO3 codes and sector names. 
xlswrite(target_file,round(total_subsector_risk{:,4:end},4),'SubsectorRisk','D2') % Write DIRECT, INDIRECT, TOTAL RISK AND RISK RATIOS 

xlswrite(target_file,{'Values are rounded to four post-decimalpoint digits.'},'SubsectorRisk','I1');

% Now write direct, indirect, total and ratios of COUNTRY risk in another sheet:
% First direct, indirect, total and ratios of SUBSECTOR risk in one sheet:
xlswrite(target_file,total_country_risk.Properties.VariableNames,'CountryRisk'); % Write column headers
xlswrite(target_file,cellstr(total_country_risk{:,1:2}),'CountryRisk','A2') % Write country names and ISO3 codes (here no sectors)
xlswrite(target_file,round(total_country_risk{:,3:end},4),'CountryRisk','C2') % Write DIRECT, INDIRECT, TOTAL RISK AND RISK RATIOS

xlswrite(target_file,{'Values are rounded to four post-decimalpoint digits.'},'CountryRisk','I1');


