climada_advanced_mrio_economics
===========================

**Purpose**

This submodule contains a risk assessment method which allows businesses from all industries to analyze their supply chain risk and it further provides valuable insights on societal impacts of natural catastrophes.

This method combines the core climada functionality with multi-regional input-output (MRIO) economics. It is primarily based on output of Input-Output (IO) models. We have made an effort to be compatible with major MRIO tables that are freely available. For full details on the IO models and supported tables, please see the [climada advanced module manual](https://github.com/davidnbresch/climada_advanced/blob/master/docs/climada_advanced.pdf).

The function ***mrio_read_table*** allows to import data from a given MRIO table and put it in a climada mriot structure. ***mrio_aggregate_table*** allows to transform the climada mriot table into an aggregated table that shows values on main sector level. It further can aggregate several different Rest of World (RoW) regions into one. ***mrio_direct_risk_calc*** will run all damage calculations to obtain the direct risk per country and sector. Special attention should be given to the assumed exposure and vulnerability for the different sectors. Last but not least, ***mrio_leontief_calc*** estimates the indirect risk using environmentally extended MRIO analysis techniques. The function ***mrio_step_by_step*** shows the core mrio key functionality step-by-step. Read the [climada advanced module manual](https://github.com/davidnbresch/climada_advanced/blob/master/docs/climada_advanced.pdf) for more details.

The method comes with basic entities for the six mainsectors as described in the manual. For the risk calculations it is assumed that the geographical distribution of the sub-sectors is sufficiently represented by that of the main sectors. However, it allows advanced users to provide additional data on exposure of subsectors for single countries, please proceed as follows:

1. Construct an entity (see either the [climada advanced module manual](https://github.com/davidnbresch/climada_advanced/blob/master/docs/climada_advanced.pdf) or see comments in header section of ***mrio_generate_agriculture_entity***)
2. Move it to  .../climada_data/entity/
4. Give it a reasonable name following the mrio naming system (ISO3_MAINSECTOR_SUBSECTOR) corresponding to the MRIO table you are going to use

This is holds for data on exposure of mainsectors also. In such a case, the name should correspond to the structure ISO3_MAINSECTOR_XXX.

See [climada advanced module manual](https://github.com/davidnbresch/climada_advanced/blob/master/docs/climada_advanced.pdf) for more details.
<br>

**Get to know** ***climada***

* Go to the [wiki](../../../climada/wiki/Home) and read the [introduction](../../../climada/wiki/Home) and find out what _**climada**_ and ECA is. 
* Are you ready to start adapting? This wiki page helps you to [get started!](../../../climada/wiki/Getting-started)  
* Read more on [natural catastrophe modelling](../../../climada/wiki/NatCat-modelling) and look at the GUI that we have prepared for you.
* Read the [core ***climada*** manual (PDF)](../../../climada/docs/climada_manual.pdf?raw=true).

<br>

**Set-up**

In order to grant core climada access to additional modules, create a folder ‘modules’ in the core climada folder and copy/move any additional modules into climada/modules, without 'climada_module_' in the filename.

E.g. if the addition module is named climada_module_MODULE_NAME, we should have

- .../climada the core climada, with sub-folders as
- .../climada/code
- .../climada/data
- .../climada/docs

and then
- .../climada/modules/MODULE_NAME with contents such as 
- .../climada/modules/MODULE_NAME/code
- .../climada/modules/MODULE_NAME/data
- .../climada/modules/MODULE_NAME/docs

this way, climada sources all modules' code upon startup

copyright (c) 2016, David N. Bresch, david.bresch@gmail.com all rights reserved.
