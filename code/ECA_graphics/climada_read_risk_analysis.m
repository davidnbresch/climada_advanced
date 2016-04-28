function ECA_studies = climada_read_risk_analysis(xlsfile, sheet_name)
% climada
% MODULE:
%   ECA_graphics
% NAME:
%   climada_read_risk_analysis
% PURPOSE:
%   read structure ECA_studies with ECA results from all previuous studies
%   (Florida, Gulf Coast, New York, Guyana, Mali, Tanzania, India, China,
%   Samoa, Hull, Bermuda, Cayman Islands, Barbados, Angtigua&Barbuda,
%   Anguilla, St. Lucia, Jamaica and Dominica)
%   includes: 
%   - Waterfall graphic: today, economic growth, climate change, 
%       total climate risk, percentage of all cost-effective measures, residual loss 
%   - adaptation cost curve: name of measures, averted loss, cost-benefit ratio
% CALLING SEQUENCE:
%   ECA_studies = climada_read_risk_analysis(xlsfile, sheet_name)
% EXAMPLE:
%   ECA_studies = climada_read_risk_analysis([],'million_USD')
%   ECA_studies = climada_read_risk_analysis([],'adaptation')
% INPUTS:
%   sheet_name: sheet name of excel sheet to be read
% OPTIONAL INPUT PARAMETERS:
%   xlsfile: file name of xls sheet
% OUTPUTS:
%   structure ECA_studies with ECA results from all previuous studies
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20131024, initial
% Lea Mueller, muellele@gmail.com, 20150107, update
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables
% poor man's version to check arguments
if ~exist('xlsfile','var'),xlsfile=[];end
if ~exist('sheet_name','var'),sheet_name=[];end
ECA_studies = [];

if isempty(sheet_name)
    fprintf('Please specify a sheet name. Unable to proceed. \n ')
    return
end
module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% prompt for xlsfile if not given
if isempty(xlsfile) % local GUI
    xlsfile      = [module_data_dir filesep '*' climada_global.spreadsheet_ext];
    %xlsfile     = [climada_global.data_dir filesep 'entities' filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(xlsfile, 'Select xls file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        xlsfile = fullfile(pathname,filename);
    end
end

ECA_studies = climada_spreadsheet_read('no',xlsfile,sheet_name);

