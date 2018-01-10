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
% Kaspar Tobler, 20180105, added line to obtain aggregated mriot using function climada_aggregate_mriot
% Kaspar Tobler, 20180105, added some notes/questions; see "Note KT".
%
% General note KT: 
%  I think we always need to calculate the direct risk for all countries and all sectors, 
%  regardless of which subset of each a user is interested because only with 
%  this information we can calculate the indirect risk of any such subset(s) 
%  of interest. To get indirect risk of Taiwan Agriculture, we need to 
%  have info on direct risk of ALL contributing sectors/countries which potentially
%  come from all other sectors and all other countries.
%  So before the Leontief calculations, the disaggregation of the direct
%  risk for all countries and the 6 climada sectors onto all countries and
%  all subsectors happens before the Leontief calculation.
%  The prior step gives us direct risk for all subsectors and counries, now
%  in absolute terms (the relative values are multiplied with total sector
%  production of each subsector), on which we then apply the Leontief
%  inverse.
%  This means the leontief function (mrio_risk_calc) always has to
%  transform direct to indirect risk for all sectors/countries.
%  The user's choice of which country/sector subset he/she is interested in
%  comes in only in the last step in what is returned as a result. This is
%  computationally highly inefficient... maybe there is another approach
%  possible... maybe already the disaggregation step could be done only for
%  the countries/sectors of interest and calculating indirect risk
%  (Leontief) based on the various main sector contributions to those...
%  This should change results though versus a first full disaggregation...
%  But using full sector resolution throughout (except for EDS calculation, of
%  course) would make entire aggregation step actually obsolete?? So then
%  the approach to only disaggregate the sectors in the country(-ies) the
%  user is interested in would make more sense.
%

%global climada_global

% read MRIO table
climada_mriot = climada_read_mriot;

% proceed with aggregated numbers / rough sector classification
climada_aggregated_mriot = climada_aggregate_mriot(climada_mriot);

% for sector = 1:climada_mriot(1).climada_aggregated_mriot.no_of_sectors
% Note KT: 
%   Actually, to keep the same structure as the mriot tables, which is
%   always country1-sec1-sec2-secX country2-sec1-sec2-secX etc. it could be
%   better to make the outer loop over the countries? The resulting direct
%   risk array should definitely be filled in the order as denoted in a
%   climada_aggregated_mriot struct, so that we don't lose orientation on
%   which value represents which country/sector combination...

% load centroids and prepare entities for mrio
% Note KT: once separate e   ntity for each climada sector is ready, probably
%   first get [~,hazard] separately as this is the same for every sector
%   and then obtain the 6 entities with the above loop so as to avoid
%   multiple loadings of the hazard. (?)
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

% Note KT: The result of the damage calculation should be a row vector of
% length "no-of-climada-sectors" * "no-of-countries", grouped by country:
% c1 c1 ... c1 c2 c2 ... c2 c3 c3 ... c3
% s1 s2 ... s6 s1 s2 ... s6 s1 s2 ... s6
% Ideally, probably, it will be integrated into a two-field structure, with
% one field containing a simple numeric array with the actual values and the
% other field containing again info on sectors and countries... then again,
% maybe not, since same info also in aggregated mriot
% (memory-inefficient)...

% Note KT: Now disaggregate direct risk on all subsectors for each country based on 
% each subsector's contribution to total industry output of each country.
% Since we used normalized values so far, the weighting is implicity done by
% simple multiplication of the so far obtained mainsector risk with the absolute 
% subsector outputs... Does that make sense? Was that the idea behind the normalization? 

% climada_disaggregate_risk(....)   Not finished building yet.

% Finally, quantifying indirect risk using the Leontief I-O model
% mrio_risk_calc
