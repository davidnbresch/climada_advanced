%function [,] = mrio_master(country_name,sector_name,risk_measure) % uncomment to run as function
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   master script to run mrio calculation (multi regional I/O table project)
% CALLING SEQUENCE:
%   mrio_master(country_name, sector_name)
% EXAMPLE:
%   mrio_master('Switzerland','Agriculture','100y')
% INPUTS:
%   country_name: name of country (string)
%   sector_name: name of sector (string)
% OPTIONAL INPUT PARAMETERS:
%   risk_measure: risk measure to be applied (string), default is the Annual Average Loss
% OUTPUTS:
%
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial (under construction)
%-

%global climada_global

% read MRIO table
climada_mriot = limada_read_mriot;

% proceed with aggregated numbers / rough sector classification

% for sector = 1:climada_mriot(1).no_of_sectors

% load centroids and prepare entities for mrio
[entity,hazard]=mrio_entity;

% calculation for all countries
for country=unique(entity.assets.NatID)
    sel_pos = ismember(entity.assets.NatID,23);
    entity_sel = entity;
    entity_sel.assets.Value = entity.assets.Value .* sel_pos;  % set values = 0 for all assets outside country i.

    % calculate event damage set
    
    EDS = climada_EDS_calc(entity_sel,hazard,'','',2,'');

    % Calculate Damage exceedence Frequency Curve (DFC)
    DFC = climada_EDS_DFC(EDS);
    
    % convert an event (per occurrence) damage set (EDS) into a year damage set (YDS)
    YDS = climada_EDS2YDS(EDS,hazard);
    
    switch risk_measure
        case 'Annual Average Loss' % expected damage 
            country_risk_direct(country) = YDS.ED;
        case '100y-event' % 
            return_period = 100;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            country_risk_direct(country) = DFC.damage(sel_pos);
        case '50y-event' % 
            return_period = 50;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            country_risk_direct(country) = DFC.damage(sel_pos);
        case '20y-event' % 
            return_period = 20;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            country_risk_direct(country) = DFC.damage(sel_pos);
        case 'worst-case' % 
        otherwise
    end
end

%end

% quantifying indirect risk using the Leontief I-O model
