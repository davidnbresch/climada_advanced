climada_advanced_mrio_economics
===========================

**Purpose**

This submodule contains a risk assessment method which allows businesses from all industries to analyze their supply chain risk and it further provides valuable insights on societal impacts of natural catastrophes.

This method combines the core climada functionality with multi-regional input-output (MRIO) economics. It is primarily based on output of MRIO models. We have made an effort to be compatible with major MRIO tables that are freely available. For full details on the MRIO models and table details, please see the [original databases (link to come)]().

The function ***mrio_read_table*** allows to import data from a given MRIO table and put it in a climada mriot structure. ***mrio_direct_risk_calc*** will run all damage calculations to obtain the direct risk per country and sector. Special attention should be given to the assumed exposure and vulnerability for the different sectors. Last but not least, ***mrio_leontief_calc*** estimates the indirect risk using environmentally extended MRIO analysis techniques. The core function is ***mrio_master***, which does it all in one go. Read the [mrio economics manual (link to come)]() for more details.

The method will (NOT yet) allow advanced users to provide additional data on exposure of main sectors for single countries, please proceed as follows:

1. Download the file
2. Move it to  .../advanced/data/
3. Use e.g. ***climada_shaperead*** to read in the data
4. Convert the shapefile into an entity using ***mrio_shapes2entity***
4. Rename it to <span style="color:red">ISO3</span>_<span style="color:red">MAINSECTOR</span>_2018

See [mrio economics manual (link to come)]() for more details.
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
