% climada_tc_play_go
% just call in command window to call climada_tc_play, see all info there

% set maximum cover and attachement globally
total_cover  = 5e9;
total_attach = 5e9;

% Q1
% --
% group 1
country_attach=[0 0 0 0 0]*1e9;
country_cover =[5 0 0 0 0]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 1 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 1 (prob): RoE = %2.3f\n',RoE_sum*100);

% group 2
country_attach=[0 0 0 0 0]*1e9;
country_cover =[0 0 2 2 1]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 2 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 2 (prob): RoE = %2.3f\n',RoE_sum*100);

% group 3
country_attach=[0 0 0 0 0]*1e9;
country_cover =[0 0 0 0 5]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 3 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 3 (prob): RoE = %2.3f\n',RoE_sum*100);

% group 4
country_attach=[0 0 0 0 0]*1e9;
country_cover =[1 1 1 1 1]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q1.0 Group 4 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q1.1 Group 4 (prob): RoE = %2.3f\n',RoE_sum*100);

fprintf('\n')

% Q2
% --
% group 1
country_attach=[5 0 0 0 0]*1e9;
country_cover =[5 0 0 0 0]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 1 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 1 (prob): RoE = %2.3f\n',RoE_sum*100);

% group 2
country_attach=[0 0 1 1 1]*1e9;
country_cover =[0 0 2 2 1]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 2 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 2 (prob): RoE = %2.3f\n',RoE_sum*100);

% group 3
country_attach=[0 0 0 0 5]*1e9;
country_cover =[0 0 0 0 5]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 3 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 3 (prob): RoE = %2.3f\n',RoE_sum*100);

% group 4
country_attach=[1 1 1 1 1]*1e9;
country_cover =[1 1 1 1 1]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q2.0 Group 4 (hist): RoE = %2.3f\n',RoE_sum*100);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q2.1 Group 4 (prob): RoE = %2.3f\n',RoE_sum*100);

% Q3
% --
fprintf('\n')

% group 1
country_attach=[5 0 0 0 0]*1e9;
country_cover =[5 0 0 0 0]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q3.0 Group 1 (hist): RoE = %2.3f, max annual damage %2.3g\n',RoE_sum*100,max_annual_damage);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q3.1 Group 1 (prob): RoE = %2.3f, max annual damage %2.3g\n',RoE_sum*100,max_annual_damage);

% group 4
country_attach=[1 1 1 1 1]*1e9;
country_cover =[1 1 1 1 1]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q3.0 Group 4 (hist): RoE = %2.3f, max annual damage %2.3g\n',RoE_sum*100,max_annual_damage);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q3.1 Group 4 (prob): RoE = %2.3f, max annual damage %2.3g\n',RoE_sum*100,max_annual_damage);

% group 5
country_attach=[1 1 1 1 1]*1e9;
country_cover =[1 1 1 3 2]*1e9;
country_premium=[];
prob_switch=0;silent=1;climada_tc_play
fprintf('--> Q3.0 Group 4 (hist): RoE = %2.3f, max annual damage %2.3g\n',RoE_sum*100,max_annual_damage);
prob_switch=1;silent=1;climada_tc_play
fprintf('--> Q3.1 Group 4 (prob): RoE = %2.3f, max annual damage %2.3g\n',RoE_sum*100,max_annual_damage);


% total_attach = 0;
% 
% disp('set attach freely:')
% 
% % group 1
% country_attach=[.1 0 0 0 0]*1e9;
% country_cover =[5 0 0 0 0]*1e9;
% country_premium=[];
% prob_switch=0;silent=1;climada_tc_play
% fprintf('--> Q3.1 Group 1 (hist): RoE = %2.3f\n',RoE_sum*100);
% prob_switch=1;silent=1;climada_tc_play
% fprintf('--> Q3.2 Group 1 (prob): RoE = %2.3f\n',RoE_sum*100);
% 
% % group 4
% country_attach=[1 .5 .2 .1 .01]*1e9;
% country_cover =[1 1 1 1 1]*1e9;
% country_premium=[];
% prob_switch=0;silent=1;climada_tc_play
% fprintf('--> Q3.1 Group 4 (hist): RoE = %2.3f\n',RoE_sum*100);
% prob_switch=1;silent=1;climada_tc_play
% fprintf('--> Q3.2 Group 4 (prob): RoE = %2.3f\n',RoE_sum*100);