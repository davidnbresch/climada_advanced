%%%
% config file for run_climada_ed
% for Carbon Delta
%
% CHANGELOG:
% 20170108 Samuel Eberenz eberenz@posteo.eu, init
% 20180906 Samuel Eberenz eberenz@posteo.eu, v1.0: new hazard files, exclude TS (TC only)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% set variables and filenames here:
% set meta info
meta.climada_config_version = 1; % integer 1 2 3 etc
meta.lead = 'EBS'; % abbreviation of responsible person
meta.comment = '201809_v1.0'; % free string

% path and filename of output file (excel sheet)
outputfilename_default = 'ExpectedDamage_';
inputfilename_default = 'all_chunked1_of_31.xlsx'; % entities: file name of locations export from lab
% note: *filename_default is only used if no variable *filename is
% handed over by the wrapper
% note: input file should be located in climada_data/entities/

% filename of vulnerability config file found in ~/climada_node/climada_data/entities
vulnerability_config_fn = '201711_CD_vulnerability_config.xlsx'; % contains basic set up for entity
% filename of damage function parameters:
%df_parameters_fn = sprintf('%s%s%s',climada_global.data_dir,filesep,'calibration_results_all_regions.mat');
df_parameters_fn = sprintf('%s%s%s',climada_global.data_dir,filesep,'TC_region_calibration_04_20181011_CD.xlsx');

% country mapping to calibration region:
country_mapping_fn = sprintf('%s%s%s',climada_global.data_dir,filesep,'NatID_RegID_basins_allcountries_201809.mat');

% set as many hazard files as you wish
hazardDef.fn{1} = 'GLB_0360as_TC_p_dist_decay_v7.mat'; % wind speed (TC) - reference
hazardDef.fn{2} = 'GLB_0360as_TC_p_dist_decay_CC_v7.mat'; % wind speed (TC) - future climate
% hazardDef.fn{3} = 'GLB_0360as_TS_oct.mat'; % storm surge (TS) - reference
% hazardDef.fn{4} = 'GLB_0360as_TS_Knutson2015_all_basins_2033_oct.mat'; % storm surge (TS) - future climate

% set max. encoding distance (depending on resolution, should be larger than sqrt(2*resolution^2), i.e. >15000m for resolution of 10km
climada_global.max_encoding_distance_m=25000; % meters

% set same amount of headers displayed in first row of output file
hazardDef.headers = {'TC_reference'...
                     'TC_future'};
%                      'TS_reference'...
%                      'TS_future'};
                  
% save resulting entity/ EDS to .mat file? (to analyse data with Matlab or octave)   
% (resulting damages  are always saved as xlsx for LAB import)
save_EDS_to_mat = 0;
save_entity_to_mat = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                 
% consistency check             
if length(hazardDef.fn) ~= length(hazardDef.headers)
    error('hazardDef.headers must have same amount of elements as hazardDef.fn!');
end
%%% end
