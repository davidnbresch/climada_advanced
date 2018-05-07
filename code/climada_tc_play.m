%function [RoE_sum,country_attach,country_cover,country_premium]=climada_tc_play(country_attach,country_cover,country_premium,prob_switch,silent)
% climada tropical cyclone playful experience
% MODULE:
%   advanced
% NAME:
%   climada_tc_play
% PURPOSE:
%
%  Usually called from climada_tc_play_go
%
% 
% Play around with TC damage for different countries, compare the effect of attachment point (retention) and diversification for an insurance point-of-view. 
% 
%  ~~~ Questions (to be implemented in climada_tc_play_go) ~~~
% 
% Q1.0 How to distribute the cover to the five countries (total cover USD 5 bn)
% in order to maximize the return on equity (you get 30% of the expected damage as profit).
% Note: Cover vector is normalized to sum up to USD 5 bn (5e9). No attachment point is set in this question.
% Set: country_attach=[];country_premium =[];prob_switch=0; 
% --> compare return on equity (RoE_sum)
% group with largest RoE wins
% => learning: put all to the max exposed country
% 
% Q1.1: same, with probabilistic events, prob_switch=1
% --> compare return on equity (RoE_sum)
% group with largest RoE wins
% => learning: probabilistic fills gaps, usually lowers RoE a bit
% 
% Q2.0: In addition, how to distribute a retention (attachment) of USD 1 bn (1e9) in
% order to maximize the profit?
% => learning: lowers RoE, makes not too much sense if only profit maximized
% 
% Q2.1: same, but probabilistic
% 
% Q3.0: If you would like to avoid paying out more than 2 bn USD in any year,
% how would you distribute covers over the 5 countirs? Use a fixed retention of USD 0.2 bn per country
% => learning: need to diversify globally, at least in three countries
% 
% Q3.1: same, but probabilistic
% 
% Q4.0: If you would like to reduce the payout frequency to once in ten years, 
% how would you choose retention and cover per country? Set attachment and cover freely.
% Find a good trade-off between high RoE, low max. payout for payout period >= 10.
% => learning: attachment matters to increase payout period and optimize your risks
% 
% Q4.1: same, but probabilistic
% 

%   
%   previous call: none
%   next call: many
% CALLING SEQUENCE:
%   [RoE_sum,country_attach,country_cover,country_premium]=climada_tc_play(country_attach,country_cover,country_premium,prob_switch,silent)
% EXAMPLE:
%   climada_tc_play
% INPUTS:
%   currently run as a batch, no parameters passed, see code
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20180503 init
% Samuel Eberenz, eberenz@posteo.eu, 20180503, add payout_period + Q4
% David N. Bresch, david.bresch@gmail.com, 20180505, octave compatibility (half way)
% Samuel Eberenz, eberenz@posteo.eu, 20180507, tested for octave, scaling down damagefunctions for JPN, TWN, finalized questions and settings in climada_tc_play_go
%-

RoE_sum=[]; % init output
max_annual_payout = [];
tol_annual_damage = [];
payout_period=[]; 

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


if climada_global.octave_mode
    
    % special preparation for Octave
    if ~exist('hazard_hist','var')
        hazard_hist = climada_hazard_load('GLB_0360as_TC_hist_OCT');
        hazard_hist = climada_hazard_reset_yearset(hazard_hist,1,1);
        hazard_prob=[];
    end
    
    prob_switch=0; % no probabilistic for Octave (takes too long)
    
else
    
    if ~exist('hazard_hist','var')
        hazard_hist = climada_hazard_load('GLB_0360as_TC_hist');
        hazard_hist = climada_hazard_reset_yearset(hazard_hist,1,1);
    end
    if ~exist('hazard_prob','var')
        hazard_prob = climada_hazard_load('GLB_0360as_TC');
        hazard_prob = climada_hazard_reset_yearset(hazard_prob,1,1);
    end
    
end

n_countries=length(country_names);

% calculate damage sets for all countries
if ~exist('YDS_hist','var') %to force: clear YDS_hist YDS_prob
    for country_i=1:n_countries
        [country_name,country_ISO3]=climada_country_name(country_names{country_i});
        entity_file=[climada_global.entities_dir filesep country_ISO3 '_' country_name '_10x10.mat'];
        if ~exist(entity_file,'file')
            entity=climada_entity_country(country_ISO3);
            entity=climada_assets_encode(entity,hazard_hist);
            %save(entity.assets.filename,'entity',climada_global.save_file_version);
        else
            entity=climada_entity_load(entity_file);
            if ~isfield(entity.assets,'centroid_index')
                entity=climada_assets_encode(entity,hazard_hist);
                %save(entity.assets.filename,'entity',climada_global.save_file_version);
            end
        end
        
        if ~climada_global.octave_mode, save(entity_file,'entity','-v6'); end % save as -v6 for later use in Octave

        if isequal(country_ISO3,'JPN'),entity.damagefunctions.MDD=entity.damagefunctions.MDD*0.1;end
        if isequal(country_ISO3,'TWN'),entity.damagefunctions.MDD=entity.damagefunctions.MDD*0.1;end   
        
        EDS_hist(country_i)=climada_EDS_calc(entity,hazard_hist);
        YDS_hist(country_i)=climada_EDS2YDS(EDS_hist(country_i),hazard_hist,[],[],1);
        YDS_hist(country_i).annotation_name = country_names{country_i};
        
        if ~climada_global.octave_mode
            EDS_prob(country_i)=climada_EDS_calc(entity,hazard_prob); % prob calc only in MATLAB
            YDS_prob(country_i)=climada_EDS2YDS(EDS_prob(country_i),hazard_prob,[],[],1);
            YDS_prob(country_i).annotation_name = country_names{country_i};
        end
                
    end % country_i

end % ~exist('EDS_hist','var')
    
YDS=YDS_hist; % default is historic perspective
if prob_switch==1,YDS=YDS_prob;end



if isempty(country_attach),country_attach = zeros(1,n_countries)*1e9;end
if isempty(country_cover),country_cover   = ones(1,n_countries)*1e9;end

% normalize cover and attachment (no normalization if total_... = 0)
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

max_annual_payout=max(country_damage_set);
threshold_index=floor(length(country_damage_set)/10);
country_damage_set=sort(country_damage_set);
tol_annual_damage=country_damage_set(end-threshold_index);
if length(find(country_damage_set>0))>0
    payout_period = floor(length(find(country_damage_set==0))/(length(find(country_damage_set>0)))+1);
else
    payout_period=Inf;
end

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