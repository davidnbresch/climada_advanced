this folder contains entities that representate the geographical distribution of the six economic main sectors as described in the climada advanced module manual, namely:

*********************************************************
**********Agriculture (GLB_agriculture_XXX.mat)**********
*********************************************************
Source (of the underlying data):
International Food Policy Research Institute (IFPRI),
International Institute for Applied Systems Analysis (IIASA), 
2016, "Global Spatially-Disaggregated Crop Production Statistics Data for 2005 Version 3.2" [Data file], 
http://dx.doi.org/10.7910/DVN/DHXBJX, Harvard Dataverse, V9 (Accessed 26 05 2018)

Download spam2005v3r2_global_val_prod_agg.csv.zip (ZIP archive of aggregated value of production data in CSV format for statistics or database applications)

mrio_generate_agriculture_entity.m was then used to construct a global entity file based on the data mentioned above.

*********************************************************
***Forestry and Fishing (GLB_forestry_fishing_XXX.mat)***
*********************************************************

Source (of the underlying data):
ESA and Université Catholique de Louvain,
2015, "Land Cover Map 2015, Version 2.0" [Data file],
http://maps.elie.ucl.ac.be/CCI/viewer/ (Accessed 26 05 2018)

Download data (red button on the top-right corner) > Climate Research Data Package > Data access > LC Map 2015 (1 netcdf file, zip compression - 2.33Go)

mrio_generate_forestry_entity.m was then used to construct a global entity file based on the data mentioned above.

*********************************************************
********Manufacturing (GLB_manufacturing_XXX.mat)********
*********************************************************

Source (of the underlying data):
Greenhouse gas ? Air pollution Interactions and Synergies (GAINS) model,
International Institute for Applied Systems Analysis (IIASA),
2015, "ECLIPSE V5a global emission fields" [Data file],
http://www.iiasa.ac.at/web/home/research/researchPrograms/air/ECLIPSEv5a.html
(Accessed 26 05 2018)

ECLIPSE V5a global emission fields > ECLIPSE V5a Baseline scenario (CLE) > Download netCDF files of emissions (netcdf4 format)

mrio_generate_manufacturing_entity.m was then used to construct a global entity file based on the data mentioned above.

*********************************************************
***Mining and Quarrying (GLB_mining_quarrying_XXX.mat)***
*********************************************************

Source (of the underlying data):
[1] U.S. Geological Survey,
2005, "Active Mines and Mineral Processing" [Data file],
https://mrdata.usgs.gov/mineplant/ (Accessed 26 05 2018)

Active mines and mineral plants in the US > Download > Download mineplant-csv.zip file

[2] U.S. Geological Survey,
2010, " Mineral operations outside the United States" [Data file],
https://mrdata.usgs.gov/mineral-operations/ (Accessed 26 05 2018)

Mineral operations outside the United States > Download > Download minfac-csv.zip file

mrio_generate_mining_entity.m was then used to construct a global entity file based on the data mentioned above.

*********************************************************
*************Services (GLB_services_XXX.mat)*************
*********************************************************

Source (of the underlying data):
NOAA and US Air Force Weather Agency,
2012, "Version 4 DMSP-OLS Nighttime Lights Time Series" [Data file],
http://ngdc.noaa.gov/eog/dmsp/downloadV4composites.html#AVSLCFC3 (Accessed 26 05 2018)

Version 4 DMSP-OLS Nighttime Lights Time Series > Download 'F182012' .tif file

mrio_generate_services_entity.m was then used to construct a global entity file based on the data mentioned above.

*********************************************************
************Utilities (GLB_utilities_XXX.mat)************
*********************************************************

Source (of the underlying data):
Davis, C. B., Chmieliauskas, A., Dijkema, G. P., and Nikolic, I.,
2014, "ENIPEDIA" [Data file],
http://enipedia.tudelft.nl (Accessed 26 05 2018),

Section Advanced > Download all power plant data

mrio_generate_utilities_entity.m was then used to construct a global entity file based on the data mentioned above.
____________________________________________

The entities were put together as part of the master master theses 'Weather and climate TC risk affecting global businesses' from Ediz Herms and Kaspar Tobler.

Master thesis (May 2018)
'Weather and climate TC risk affecting global businesses'
Ediz Herms, ediz.herms@outlook.com
Kaspar Tobler