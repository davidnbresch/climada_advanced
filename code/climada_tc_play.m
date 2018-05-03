%function [RoE_sum,country_attach,country_cover,country_premium]=climada_tc_play(country_attach,country_cover,country_premium,prob_switch,silent)
% climada tropical cyclone playful experience
% MODULE:
%   advanced
% NAME:
%   climada_tc_play
% PURPOSE:
%   Playful approach to TC risk in some countries
%
%   Q1.0: how to distribute the country_cover (total 5e9) in order to maximize the
%   return (you get 30% of the expected damage as profit)
%   country_attach=[];country_premium =[];prob_switch=0; 
%   --> compare return on equity (RoE_sum)
%   group with largest RoE wins
%   => learning: put all to the max exposed country
%
%   Q1.1: same, with probabilistic events, prob_switch=1
%   --> compare return on equity (RoE_sum)
%   group with largest RoE wins
%   => learning: probabilistic fills gaps, usually lowers RoE a bit
%
%   Q2.0: in addition, how to distribute a retention (attachement) of 5e9 in
%   order to maximize the profit
%   => lowers RoE, makes not too much sense if only profit maximised
%   Q2.1: same, but probabilistic
%
%   Q3.0: if you would like to avoid paying out more than 2 bn in any year,
%   how would you distribute covers?
%   Q3.1: same, but probabilistic
%   => need to diversify globally, at least in three countries
%
%   Q4: attachement should matter...
%   
%   previous call: none
%   next call: many
% CALLING SEQUENCE:
%   res=climada_template(param1,param2);
% EXAMPLE:
%   climada_template(param1,param2);
% INPUTS:
%   param1:
%       > promted for if not given
%   OPTION param1: a structure with the fields...
%       this way, parameters can be passed on a fields, see below
% OPTIONAL INPUT PARAMETERS:
%   param2: as an example
% OUTPUTS:
%   res: the output, empty if not successful
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160603
% David N. Bresch, david.bresch@gmail.com, 20170212, climada_progress2stdout
% David N. Bresch, david.bresch@gmail.com, 20170313, reverted from erroneous save under another name
%-

RoE_sum=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
country_names={'Japan','Taiwan','Australia','Jamaica','Barbados'};

if ~exist('country_attach', 'var') ,country_attach  =[];end
if ~exist('country_cover',  'var') ,country_cover   =[];end
if ~exist('country_premium','var') ,country_premium =[];end
if ~exist('prob_switch',    'var') ,prob_switch     = 0;end
if ~exist('silent',         'var') ,silent          = 0;end
if ~exist('total_cover',    'var') ,total_cover     = 0;end
if ~exist('total_attach',   'var') ,total_attach    = 0;end

if ~exist('hazard_hist','var'),hazard_hist=climada_hazard_load('GLB_0360as_TC_hist');end
if ~exist('hazard_prob','var'),hazard_prob=climada_hazard_load('GLB_0360as_TC');end

n_countries=length(country_names);

% calculate damage sets for all countries
if ~exist('EDS_hist','var')
    %clear EDS_hist EDS_prob
    for country_i=1:n_countries
        [country_name,country_ISO3]=climada_country_name(country_names{country_i});
        entity_file=[climada_global.entities_dir filesep country_ISO3 '_' country_name '_10x10.mat'];
        if ~exist(entity_file,'file')
            entity=climada_entity_country(country_ISO3);
            entity=climada_assets_encode(entity,hazard_hist);
            save(entity.assets.filename,'entity',climada_global.save_file_version);
        else
            entity=climada_entity_load(entity_file);
            if ~isfield(entity.assets,'centroid_index')
                entity=climada_assets_encode(entity,hazard_hist);
                save(entity.assets.filename,'entity',climada_global.save_file_version);
            end
        end
        
        EDS_hist(country_i)=climada_EDS_calc(entity,hazard_hist);
        EDS_prob(country_i)=climada_EDS_calc(entity,hazard_prob);
    end % country_i
end
    
if prob_switch==1
    EDS=EDS_prob;
else
    EDS=EDS_hist;
end

% covert to annual, makes all interpretation easier
for country_i=1:n_countries
    if prob_switch==1
        YDS(country_i)=climada_EDS2YDS(EDS(country_i),hazard_prob,[],[],1);
    else
        YDS(country_i)=climada_EDS2YDS(EDS(country_i),hazard_hist,[],[],1);
    end
end

if isempty(country_attach),country_attach = zeros(1,n_countries)*1e9;end
if isempty(country_cover),country_cover   = ones(1,n_countries)*1e9;end

% normalize cover and attachement
if total_cover>0, country_cover  = country_cover./sum(country_cover)  *total_cover;end
if total_attach>0 && sum(country_attach)>0,country_attach = country_attach./sum(country_attach)*total_attach;end

if length(country_cover)~=n_countries
    fprintf('cover length incorrect, should be %i\n',n_countries)
    return
end

% calcuate covered damages, hence expected damage in the insured layer
country_damage=country_cover*0; % init
country_damage_set=YDS(country_i).damage*0;
for country_i=1:n_countries
    country_damage_set=country_damage_set+min(max(YDS(country_i).damage-country_attach(country_i),0),country_cover(country_i));
    country_damage(country_i)=YDS(country_i).frequency*min(max(YDS(country_i).damage-country_attach(country_i),0),country_cover(country_i))';
end % country_i

max_annual_damage=max(country_damage_set);
threshold_index=ceil(length(country_damage_set)/10);
country_damage_set=sort(country_damage_set);
tol_annual_damage=country_damage_set(end-threshold_index);


if isempty(country_premium),country_premium=country_damage*1.3;end

% calculate profit per country
country_profit=country_premium-country_damage;

% calculate return on equity total
RoE=country_profit./country_cover;
RoE_sum=sum(country_profit)/sum(country_cover);

if ~silent
    for country_i=1:n_countries
        fprintf('%s, return on equity = %2.3f, premium %2.3g\n',country_names{country_i},RoE(country_i)*100,country_premium(country_i));
    end % country_i
    fprintf('return on equity = %2.2f\n',RoE_sum*100);
end % silent

%end % climada_tc_play