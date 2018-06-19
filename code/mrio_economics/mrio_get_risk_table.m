function [subsector_risk, country_risk] = mrio_get_risk_table(IO_YDS, country_ISO3, sector_name)
% mrio get risk table
% MODULE:
%   advanced
% NAME:
%   mrio_get_risk_table
% PURPOSE:
%   produce a quick&dirty risk table based on the results from
%   mrio_leontief_calc and mrio_direct_risk_calc
%
%   previous call: 
%       mrio_leontief_calc and mrio_direct_risk_calc
%   see also: 
% CALLING SEQUENCE:
% EXAMPLE:
%   country_risk_report_raw(country_risk_calc('Barbados')); % all in one
%
%   country_risk0=country_risk_calc('Switzerland'); % country, admin0 level
%   country_risk1=country_admin1_risk_calc('Switzerland'); % admin1 level
%   country_risk_report([country_risk0 country_risk1]) % report all
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   print_unsorted: =1, show the results in the order they have been calculated
%       =0, show by descending damages (default)
%   plot_DFC: if =1, plot damage frequency curves (DFC) of all EDSs (!) in
%       country_risk, =0 not (default)
%       if =2, plot logarithmic scale both axes
% OUTPUTS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180617, initial (under construction)
%-

subsector_risk = []; % init output
country_risk = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('IO_YDS', 'var'), IO_YDS = struct; end 
if ~exist('country_ISO3','var'), country_ISO3 = []; end
if ~exist('sector_name','var'), sector_name = []; end
if ~exist('mainsector_name','var'), mainsector_name = []; end
if ~exist('subsector_name','var'), subsector_name = []; end
% if ~exist('print_unsorted','var'),print_unsorted = 0; end
% if ~exist('plot_DFC','var'),plot_DFC = 0; end

% PARAMETERS
%
if ~isempty(country_ISO3)
    country_ISO3 = char(country_ISO3); % as to create filenames etc., needs to be char
end
%
if ~isempty(sector_name)
    subsector_name = char(sector_name); % as to create filenames etc., needs to be char
end  
%
if isfield(IO_YDS,'direct')
    mrio_countries_ISO3 = unique(IO_YDS.direct.countries_iso, 'stable');
    mainsectors = unique(IO_YDS.direct.climada_sect_name, 'stable');
    subsectors = unique(IO_YDS.direct.sectors, 'stable');
else
    mrio_countries_ISO3 = unique(IO_YDS.indirect.countries_iso, 'stable');
    mainsectors = unique(IO_YDS.indirect.climada_sect_name, 'stable');
    subsectors = unique(IO_YDS.indirect.sectors, 'stable');  
end
n_mrio_countries = length(mrio_countries_ISO3);
n_mainsectors = length(mainsectors);
n_subsectors = length(subsectors);
%
% prompt country (one or many) - TO DO 
[countries_liststr, countries_sort_index] = sort(mrio_countries_ISO3);
if isempty(country_ISO3)
    % compile list of all mrio countries, then call recursively below
    [selection_country] = listdlg('PromptString','Select countries (or one):',...
        'ListString',countries_liststr);
    selection_country = countries_sort_index(selection_country);
else 
    selection_country = find(mrio_countries_ISO3 == country_ISO3);
end
country_ISO3 = mrio_countries_ISO3(selection_country);
%
% prompt for mainsector name (one or many) - TO DO 
[mainsectors_liststr, mainsectors_sort_index] = sort(mainsectors);
if isempty(mainsector_name)
    % compile list of all mrio countries, then call recursively below
    [selection_mainsector] = listdlg('PromptString','Select subsectors (or one):',...
        'ListString',mainsectors_liststr);
    selection_mainsector = mainsectors_sort_index(selection_mainsector);
else
    selection_mainsector = find(mainsectors == mainsector_name);
end
mainsector_name = mainsectors(selection_mainsector);
%
sel_subsectors = []; % init
for sel_mainsector_i = 1:length(mainsector_name)
    sel_subsectors_i = IO_YDS.direct.aggregation_info.(char(mainsector_name(sel_mainsector_i)));
    sel_subsectors = [sel_subsectors sel_subsectors_i];
end
% prompt for subsector name (one or many) - TO DO 
[subsectors_liststr, subsectors_sort_index] = sort(sel_subsectors);
if isempty(subsector_name)
    % compile list of all mrio countries, then call recursively below
    [selection_subsector] = listdlg('PromptString','Select subsectors (or one):',...
        'ListString',subsectors_liststr);
    selection_subsector = subsectors_sort_index(selection_subsector);
else
    selection_subsector = find(subsectors == subsector_name);
end
subsector_name = subsectors(selection_subsector);

sel_sector_index = find(ismember(IO_YDS.direct.sectors,subsector_name));
sel_country_index = find(ismember(IO_YDS.direct.countries_iso,country_ISO3));
sel_index = intersect(sel_country_index,sel_sector_index);

direct_subsector_risk = IO_YDS.direct.ED;
indirect_subsector_risk = IO_YDS.indirect.ED;

% aggregate indirect risk across all sectors of a country
indirect_country_risk = zeros(1,n_mrio_countries); % init
direct_country_risk = zeros(1,n_mrio_countries); % init
country_value = zeros(1,n_mrio_countries); % init
for mrio_country_i = 1:n_mrio_countries
    for subsector_j = 1:n_subsectors 
        indirect_country_risk(mrio_country_i) = indirect_country_risk(mrio_country_i) + indirect_subsector_risk((mrio_country_i-1) * n_subsectors+subsector_j);
        direct_country_risk(mrio_country_i) = direct_country_risk(mrio_country_i) + direct_subsector_risk((mrio_country_i-1) * n_subsectors+subsector_j);
        country_value(mrio_country_i) = country_value(mrio_country_i) + IO_YDS.direct.Value((mrio_country_i-1) * n_subsectors+subsector_j);
    end % subsector_j
end % mrio_country_i

%%% For better readability, we return final results as tables so that
%%% countries and sectors corresponding to the values are visible on
%%% first sight. Further, a table allows reordering of values, which might come in handy:

subsector_risk = table(IO_YDS.direct.countries',IO_YDS.direct.countries_iso',IO_YDS.direct.sectors',direct_subsector_risk',indirect_subsector_risk',(direct_subsector_risk+indirect_subsector_risk)',((direct_subsector_risk+indirect_subsector_risk)'./IO_YDS.direct.Value'),IO_YDS.direct.Value', ...
                                'VariableNames',{'Country','CountryISO','Subsector','DirectSubsectorRisk','IndirectSubsectorRisk','TotalSubsectorRisk','RiskRatio','Value'});
country_risk = table(unique(IO_YDS.direct.countries','stable'),unique(IO_YDS.direct.countries_iso','stable'),direct_country_risk',indirect_country_risk',(direct_country_risk+indirect_country_risk)',((direct_country_risk+indirect_country_risk)'./country_value'),country_value',...
                                'VariableNames',{'Country','CountryISO','DirectCountryRisk','IndirectCountryRisk','TotalCountryRisk','RiskRatio','Value'});

end % mrio_get_risk_table