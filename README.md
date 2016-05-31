# climada_advanced
additional features (mainly for core climada)

additional/doc for documentation.

In order to grant core climada access to additional modules, create a folder ‘climada_modules’ on the same level your core climada folder resides and copy/move any additional modules into climada_modules. You might shorten the module filename(s), i.e. without 'advanced' instead of 'climada_module_advanced' as a folder name.

E.g. if the addition module is named climada_module_MODULE_NAME, we should have

.../climada the core climada, with sub-folders as
.../climada/code
.../climada/data
.../climada/docs

and then

.../climada_modules/MODULE_NAME with sub-folders as
.../climada_modules/MODULE_NAME/code
.../climada_modules/MODULE_NAME/data
.../climada_modules/MODULE_NAME/docs

this way, climada sources all modules' code upon startup. See climada/docs/climada_manual.pdf to get started

copyright (c) 2016, David N. Bresch, david.bresch@gmail.com all rights reserved.
