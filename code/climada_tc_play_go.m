% climada_tc_play_go
% just call in command window to call climada_tc_play, see all further info there
%
%
%
% country_names={'Japan','Taiwan','Australia','Jamaica','Barbados'};
%                 1       2        3           4         5  
%
%  CALLING SEQUENCE
%   This script calls climada_tc_play several times. hazard and entities
%   are defined there
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% clear entity* hazard* total_* EDS* YDS* country* prob* payou* threshold* tol* max* n_countr* silent RoE*
% set maximum cover and attachment globally

plot_switch = 0; % Show plots of damage per return period and country
global_prob_switch = 1;

total_cover  = 5e9;
total_attach = 1e9;

fprintf('\n \n ~~~ climada TC play ~~~\n \n');

if climada_global.octave_mode
    warning('No probabilistic hazard set for Octave (takes too long)');
end
% Q1
% --
%% group 1
country_cover =[10 0 0 0 0]*5e8; % distribute a total of 10 points (total= USD 5bn)

    country_attach=[0 0 0 0 0]*5e8; % leaf at zero for Q1 (no retention)
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('\n--> Q1.0 Group 1 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q1.1 Group 1 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end

% group 2
country_cover =[0 0 4 4 2]*5e8;

    country_attach=[0 0 0 0 0]*5e8;
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q1.0 Group 2 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q1.1 Group 2 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end
    
% group 3
country_cover =[0 0 0 0 10]*5e8;

    country_attach=[0 0 0 0 0]*5e8;
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q1.0 Group 3 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q1.1 Group 3 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end
%%
% group 4
country_cover =[2 2 2 2 2]*5e8;

    country_attach=[0 0 0 0 0]*5e8;
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q1.0 Group 4 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q1.1 Group 4 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end
    fprintf('\n')
%%
% Q2
% --
% group 1
country_cover =[10 0 0 0 0]*5e8; % distribute a total of 10 points (total= USD 5bn)
country_attach=[10 0 0 0 0]*1e8; % distribute a total of 10 points (total= USD 1bn)

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q2.0 Group 1 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q2.1 Group 1 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end

% group 2
country_cover =[0 0 4 4 2]*5e8;
country_attach=[0 0 5 4 1]*1e8;

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q2.0 Group 2 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q2.1 Group 2 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end
% group 3
country_cover =[0 0 0 0 10]*5e8;
country_attach=[0 0 0 0 10]*1e8;

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q2.0 Group 3 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q2.1 Group 3 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end

% group 4
country_cover =[2 2 2 2 2]*5e8;
country_attach=[2 2 2 2 2]*1e8;

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q2.0 Group 4 (hist): RoE = %+2.3f%%\n',RoE_sum*100);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q2.1 Group 4 (prob): RoE = %+2.3f%%\n',RoE_sum*100);
    end
    fprintf('\n')

%% Q3
% --

% group 1
country_cover =[10 0 0 0 0]*5e8; % distribute a total of 10 points (total= USD 5bn)

    country_attach=[2 2 2 2 2]*1e8;  % do not change attachement point for Q3 (USD 0.2bn for each country)
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q3.0 Group 1 (hist): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q3.1 Group 1 (prob): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
% group 2
country_cover =[0 0 2 4 4]*5e8;

    country_attach=[2 2 2 2 2]*1e8;
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q3.0 Group 2 (hist): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q3.1 Group 2 (prob): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
% group 3
country_cover =[2 2 2 2 2]*5e8;

    country_attach=[2 2 2 2 2]*1e8;
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q3.0 Group 3 (hist): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q3.1 Group 3 (prob): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
% group 4
country_cover =[.5 .5 4 4 1]*5e8;

    country_attach=[2 2 2 2 2]*1e8;
    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q3.0 Group 4 (hist): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q3.1 Group 4 (prob): RoE = %+2.3f%%, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
    fprintf('\n')

%% Q4: Payout period and free adjustment of "attach"
% --

total_attach = 0; % <-- if set to 0, attachment can be choosen freely, otherwise it is always normalized to the value of total_attach, i.e. 1e9 USD.

% group 1
country_cover =[10 0 0 0 0]*5e8;
country_attach=[5 0 0 0 0]*1e8;

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q4.0 Group 1 (hist): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);  
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q4.1 Group 1 (prob): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
% group 2
country_cover =[0 0 4 2 4]*5e8;
country_attach=[0 0 4 2 4]*1e8;

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q4.0 Group 2 (hist): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q4.1 Group 2 (prob): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
% group 3
country_cover =[2 2 2 2 2]*5e8;
country_attach=[5 5 5 5 5]*1e8;

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q4.0 Group 3 (hist): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q4.1 Group 3 (prob): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
% group 4
country_cover =[2 2 2 2 2]*5e8;
country_attach=[1.5 1.8 2 3 3]*1e8;

    country_premium=[];
    prob_switch=0;silent=1;climada_tc_play
    fprintf('--> Q4.0 Group 4 (hist): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    if ~climada_global.octave_mode && global_prob_switch
    prob_switch=1;silent=1;climada_tc_play
    fprintf('--> Q4.1 Group 4 (prob): RoE = %+2.3f%%, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)
    fprintf('                  actual RoE = %+2.3f%% (dependant on max annual payout)\n',RoE_sum*100*total_cover/max_annual_payout);
    end
%%

% plot
if plot_switch
    close all
    figure('InnerPosition',[10 10 700 450]);
    climada_EDS_DFC(YDS(1:end));
    xlim([0 100]),ylim([0 1e9])
    legend('Location','NorthEast')
    title('Damage exceedence Frequency Curve (DFC)');

    figure('InnerPosition',[10 10 700 450]); 
    climada_EDS_DFC(YDS(1:2));
    xlim([0 100]),ylim([0 5e9])
    title('Damage exceedence Frequency Curve (DFC)');

    figure('InnerPosition',[10 10 700 450]);
    climada_EDS_DFC(YDS(3:end));
    xlim([0 100]),ylim([0 5e8])
    title('Damage exceedence Frequency Curve (DFC)');
end

