% climada_tc_play_go
% just call in command window to call climada_tc_play, see all info there

% country_names={'Japan','Taiwan','Australia','Jamaica','Barbados'};
%                 1       2        3           4         5  

clear entity* hazard* total_* EDS* YDS* country* prob* payou* threshold* tol* max* n_countr* silent RoE*
% set maximum cover and attachement globally
total_cover  = 5e9;
total_attach = 1e9;

% Q1
% --
%% group 1
country_cover =[10 0 0 0 0]*5e8;
country_attach=[0 0 0 0 0]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 1 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 1 (prob): RoE = %+2.3f\n',RoE_sum*100);

% group 2
country_cover =[0 0 4 4 2]*5e8;
country_attach=[0 0 0 0 0]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 2 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 2 (prob): RoE = %+2.3f\n',RoE_sum*100);
%%
% group 3
country_cover =[0 0 0 0 10]*5e8;
country_attach=[0 0 0 0 0]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 3 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 3 (prob): RoE = %+2.3f\n',RoE_sum*100);
%%
% group 4
country_cover =[2 2 2 2 2]*5e8;
country_attach=[0 0 0 0 0]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 4 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 4 (prob): RoE = %+2.3f\n',RoE_sum*100);

fprintf('\n')
%%
% Q2
% --
% group 1
country_cover =[10 0 0 0 0]*5e8;
country_attach=[10 0 0 0 0]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 1 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 1 (prob): RoE = %+2.3f\n',RoE_sum*100);

% group 2
country_cover =[0 0 4 4 2]*5e8;
country_attach=[2 2 2 2 2]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 2 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 2 (prob): RoE = %+2.3f\n',RoE_sum*100);

% group 3
country_cover =[0 0 0 0 10]*5e8;
country_attach=[0 0 0 0 10]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 3 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 3 (prob): RoE = %+2.3f\n',RoE_sum*100);

% group 4
country_cover =[2 2 2 2 2]*5e8;
country_attach=[2 2 2 2 2]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 4 (hist): RoE = %+2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 4 (prob): RoE = %+2.3f\n',RoE_sum*100);

%% Q3
% --
fprintf('\n')

% group 1
country_cover =[10 0 0 0 0]*5e8;
country_attach=[2 2 2 2 2]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q3.0 Group 1 (hist): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q3.1 Group 1 (prob): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);

% group 2
country_cover =[0 0 2 4 4]*5e8;
country_attach=[2 2 2 2 2]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q3.0 Group 2 (hist): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q3.1 Group 2 (prob): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);

% group 3
country_cover =[2 2 2 2 2]*5e8;
country_attach=[2 2 2 2 2]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q3.0 Group 3 (hist): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q3.1 Group 3 (prob): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);

% group 4
country_cover =[2 2 2 3 1]*5e8;
country_attach=[3 2 2 2 1]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q3.0 Group 4 (hist): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q3.1 Group 4 (prob): RoE = %+2.3f, max annual payout %2.3g\n',RoE_sum*100,max_annual_payout);

fprintf('\n')

%% Q4: Payout period and free adjustment of "attach"
% --

total_attach = 0; % <-- 0, so that attachement can be set freely
% group 1
country_cover =[10 0 0 0 0]*5e8;
country_attach=[10 0 0 0 0]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q4.0 Group 1 (hist): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q4.1 Group 1 (prob): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)

% group 2
country_cover =[0 0 4 2 4]*5e8;
country_attach=[0 0 4 2 4]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q4.0 Group 2 (hist): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q4.1 Group 2 (prob): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)

% group 3
country_cover =[2 2 2 2 2]*5e8;
country_attach=[5 5 5 5 5]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q4.0 Group 3 (hist): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q4.1 Group 3 (prob): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)

% group 4
country_cover =[2 2 2 2 2]*5e8;
country_attach=[1.5 1.8 2 3 3]*5e8;

country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q4.0 Group 4 (hist): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q4.1 Group 4 (prob): RoE = %+2.3f, max annual payout %2.3g, payout every %i year(s)\n',RoE_sum*100,max_annual_payout,payout_period)

%%

% plot
close all
figure; climada_EDS_DFC(YDS(1:end));
xlim([0 100]),ylim([0 1e9])

figure; climada_EDS_DFC(YDS(1:2));
xlim([0 100]),ylim([0 5e9])

figure; climada_EDS_DFC(YDS(3:end));
xlim([0 100]),ylim([0 5e8])

