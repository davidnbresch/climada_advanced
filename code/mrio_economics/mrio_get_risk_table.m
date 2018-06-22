function [subsector_risk_tb, country_risk_tb] = mrio_get_risk_table(IO_YDS, country_ISO3, sector_name, year_yyyy)
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
%   [subsector_risk_tb, country_risk_tb] = mrio_get_risk_table(IO_YDS, country_ISO3, sector_name, year_yyyy)
% EXAMPLE:
%   [subsector_risk_tb, country_risk_tb] = mrio_get_risk_table(IO_YDS, 'DEU', 'Forestry and logging', 0) 
%   [subsector_risk_tb, country_risk_tb] = mrio_get_risk_table(IO_YDS, 'TWN', 'agriculture', 'ALL') 
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
%   country_ISO3: the country ISO3 code
%   sector_name: either the sub-sector name or main sector name
%   year_yyyy: 
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   subsector_risk_tb: table with indirect and direct risk per
%       subsector/country combination (and year)
%   country_risk_tb: table with indirect and direct risk per country
%       (and year)
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180620, initial (first working version)
%-

subsector_risk_tb = []; % init output
country_risk_tb = []; % init output

global climada_global
if ~climada_init_vars, return; end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('IO_YDS', 'var'), IO_YDS = struct; end 
if ~exist('country_ISO3','var'), country_ISO3 = []; end
if ~exist('sector_name','var'), sector_name = []; end
if ~exist('mainsector_name','var'), mainsector_name = []; end
if ~exist('subsector_name','var'), subsector_name = []; end
if ~exist('year_yyyy','var'), year_yyyy = []; end

% PARAMETERS
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

if ~isempty(sector_name)
    if find(ismember(mainsectors, sector_name))
        mainsector_name = mainsectors(find(ismember(mainsectors, sector_name)));
    else find(ismember(subsectors, sector_name))
        subsector_name = mainsectors(find(ismember(mainsectors, sector_name)));

        sel_index = ismember(unique(IO_YDS.direct.sectors), subsector_name)==1;
        mainsector_name = IO_YDS.direct.climada_sect_name(sel_index(1));
    end
end

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

sel_country_index = find(ismember(IO_YDS.direct.countries_iso,country_ISO3));

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
    selection_subsector = find(ismember(subsectors,subsector_name));
end
subsector_name = subsectors(selection_subsector);

sel_sector_index = find(ismember(IO_YDS.direct.sectors,subsector_name));

sel_mrio_index = intersect(sel_country_index,sel_sector_index);

% distinction by cases
if find(ismember(IO_YDS.direct.yyyy,year_yyyy)) % year damage of a specific year is shown (yyyy) e.g. 1950
    
    sel_year_index = find(ismember(IO_YDS.direct.yyyy',year_yyyy));
    
    direct_damage_sel = IO_YDS.direct.damage(sel_year_index,sel_mrio_index);
    indirect_damage_sel = IO_YDS.indirect.damage(sel_year_index,sel_mrio_index);
    
    sz_damage_sel_temp = size(direct_damage_sel);
    direct_damage_sel_re = reshape(direct_damage_sel,1,sz_damage_sel_temp(1)*sz_damage_sel_temp(2));
    indirect_damage_sel_re = reshape(indirect_damage_sel,1,sz_damage_sel_temp(1)*sz_damage_sel_temp(2));
    
    lb_sectors = []; lb_countries = []; 
    lb_countries_iso = []; lb_year = [];
    value_sel = [];
    for index_i = 1:length(sel_mrio_index)
        lb_sectors = [lb_sectors repmat(IO_YDS.direct.sectors(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
        lb_countries = [lb_countries repmat(IO_YDS.direct.countries(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
        lb_countries_iso = [lb_countries_iso repmat(IO_YDS.direct.countries_iso(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
        lb_year = [lb_year repmat(year_yyyy,1,sz_damage_sel_temp(1))];
        
        value_sel = [value_sel repmat(IO_YDS.direct.Value(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
    end
    
elseif ischar(year_yyyy) % 'All' year damages are shown
    
    direct_damage_sel = IO_YDS.direct.damage(:,sel_mrio_index);
    indirect_damage_sel = IO_YDS.indirect.damage(:,sel_mrio_index);
    
    sz_damage_sel_temp = size(direct_damage_sel);
    direct_damage_sel_re = reshape(direct_damage_sel,1,sz_damage_sel_temp(1)*sz_damage_sel_temp(2));
    indirect_damage_sel_re = reshape(indirect_damage_sel,1,sz_damage_sel_temp(1)*sz_damage_sel_temp(2));
    
    lb_sectors = []; lb_countries = []; 
    lb_countries_iso = []; lb_year = [];
    value_sel = [];
    for index_i = 1:length(sel_mrio_index)
        lb_sectors = [lb_sectors repmat(IO_YDS.direct.sectors(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
        lb_countries = [lb_countries repmat(IO_YDS.direct.countries(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
        lb_countries_iso = [lb_countries_iso repmat(IO_YDS.direct.countries_iso(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
        lb_year = [lb_year IO_YDS.direct.yyyy'];
        
        value_sel = [value_sel repmat(IO_YDS.direct.Value(sel_mrio_index(index_i)),1,sz_damage_sel_temp(1))];
    end
    
% elseif year_yyyy < 0 % i-th biggest year damage is shown, e.g. for year_yyyy = -2, the largest year damage is shown
    
else % expected annual damage is shown (year_yyyy == 0)

    direct_damage_sel_re = IO_YDS.direct.ED(sel_mrio_index);
    indirect_damage_sel_re = IO_YDS.indirect.ED(sel_mrio_index);
    
    lb_sectors = IO_YDS.direct.sectors(sel_mrio_index);
    lb_countries = IO_YDS.direct.countries(sel_mrio_index);
    lb_countries_iso = IO_YDS.direct.countries_iso(sel_mrio_index);
    lb_year = repmat('_',1,length(sel_mrio_index));

    value_sel = IO_YDS.direct.Value(sel_mrio_index);

end

subsectors_sel = unique(lb_sectors,'stable'); n_subsectors_sel = length(subsectors_sel);
mrio_countries_ISO3_sel = unique(lb_countries_iso,'stable'); n_mrio_countries_ISO3_sel = length(mrio_countries_ISO3_sel);
mrio_countries_sel = unique(lb_countries,'stable');

% aggregate risk across all sectors of a country
if ~(year_yyyy == 0)
    
    indirect_country_risk = zeros(1,n_mrio_countries_ISO3_sel*sz_damage_sel_temp(1)); % init
    direct_country_risk = zeros(1,n_mrio_countries_ISO3_sel*sz_damage_sel_temp(1)); % init
    country_value = zeros(1,n_mrio_countries_ISO3_sel*sz_damage_sel_temp(1)); % init
    
    for mrio_country_ISO3_temp_i = 1:n_mrio_countries_ISO3_sel
        country_ISO3_i = mrio_countries_ISO3_sel(mrio_country_ISO3_temp_i);
        sel_country_index = find(ismember(mrio_countries_ISO3_sel,country_ISO3_i));
        for year_i = 1:sz_damage_sel_temp(1)
            indirect_country_risk(year_i+sz_damage_sel_temp(1)*(mrio_country_ISO3_temp_i-1)) = sum(indirect_damage_sel(year_i,sel_country_index));
            direct_country_risk(year_i+sz_damage_sel_temp(1)*(mrio_country_ISO3_temp_i-1)) = sum(direct_damage_sel(year_i,sel_country_index));
            country_value(year_i+sz_damage_sel_temp(1)*(mrio_country_ISO3_temp_i-1)) = sum(value_sel(sel_country_index));
        end % year_i
    end % mrio_country_ISO3_temp_i

    lb_country_year = repmat(IO_YDS.direct.yyyy',1,n_mrio_countries_ISO3_sel);

    lb_countries_temp = []; lb_countries_iso_temp = [];
    for mrio_country_ISO3_temp_i = 1:n_mrio_countries_ISO3_sel
        lb_countries_temp = [lb_countries_temp repmat(mrio_countries_sel(mrio_country_ISO3_temp_i),1,sz_damage_sel_temp(1))];
        lb_countries_iso_temp = [lb_countries_iso_temp repmat(mrio_countries_ISO3_sel(mrio_country_ISO3_temp_i),1,sz_damage_sel_temp(1))];
    end % mrio_country_ISO3_temp_i
    
else

    indirect_country_risk = zeros(1,n_mrio_countries_ISO3_sel); % init
    direct_country_risk = zeros(1,n_mrio_countries_ISO3_sel); % init
    country_value = zeros(1,n_mrio_countries_ISO3_sel); % init
    
    for mrio_country_ISO3_temp_i = 1:n_mrio_countries_ISO3_sel
        country_ISO3_i = mrio_countries_ISO3_sel(mrio_country_ISO3_temp_i);
        sel_country_index = find(ismember(IO_YDS.direct.countries_iso,country_ISO3_i));
        indirect_country_risk(mrio_country_ISO3_temp_i) = sum(indirect_damage_sel_re(sel_country_index));
        direct_country_risk(mrio_country_ISO3_temp_i) = sum(direct_damage_sel_re(sel_country_index));
        country_value(mrio_country_ISO3_temp_i) = sum(value_sel(sel_country_index));
    end % mrio_country_i
    
    lb_countries_temp = unique(lb_countries,'stable');
    lb_countries_iso_temp = unique(lb_countries_iso,'stable');
    
end

%%% For better readability, we return final results as tables so that
%%% countries and sectors corresponding to the values are visible on
%%% first sight. Further, a table allows reordering of values, which might come in handy:

if ~(year_yyyy == 0)
    
    subsector_risk_tb = table(lb_countries',lb_countries_iso',lb_sectors',lb_year',direct_damage_sel_re',indirect_damage_sel_re',(direct_damage_sel_re+indirect_damage_sel_re)',((direct_damage_sel_re+direct_damage_sel_re)'./value_sel'),value_sel', ...
                                        'VariableNames',{'Country','CountryISO','Subsector','Year','DirectSubsectorRisk','IndirectSubsectorRisk','TotalSubsectorRisk','RiskRatio','Value'});                        
    country_risk_tb = table(lb_countries_temp',lb_countries_iso_temp',lb_country_year',direct_country_risk',indirect_country_risk',(direct_country_risk+indirect_country_risk)',((direct_country_risk+indirect_country_risk)'./country_value'),country_value',...
                                        'VariableNames',{'Country','CountryISO','Year','DirectCountryRisk','IndirectCountryRisk','TotalCountryRisk','RiskRatio','Value'});  
else
    
    subsector_risk_tb = table(lb_countries',lb_countries_iso',lb_sectors',direct_damage_sel_re',indirect_damage_sel_re',(direct_damage_sel_re+indirect_damage_sel_re)',((direct_damage_sel_re+direct_damage_sel_re)'./value_sel'),value_sel', ...
                                        'VariableNames',{'Country','CountryISO','Subsector','DirectSubsectorRisk','IndirectSubsectorRisk','TotalSubsectorRisk','RiskRatio','Value'});
    country_risk_tb = table(lb_countries_temp',lb_countries_iso_temp',direct_country_risk',indirect_country_risk',(direct_country_risk+indirect_country_risk)',((direct_country_risk+indirect_country_risk)'./country_value'),country_value',...
                                        'VariableNames',{'Country','CountryISO','DirectCountryRisk','IndirectCountryRisk','TotalCountryRisk','RiskRatio','Value'}); 
end

end % mrio_get_risk_table