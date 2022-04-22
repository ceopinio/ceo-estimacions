# Load the configuration
configfile: 'config/config.yaml'

from os.path import join


SRC_FOLDER = config["SRC_FOLDER"]
DTA_FOLDER = config["DTA_FOLDER"]
RAW_DTA_FOLDER = config["RAW_DTA_FOLDER"]

models=["fit_partychoice", "fit_abstention"]
exts=["RDS", "model"]

## RULES
rule all:
    input:
        expand(join(DTA_FOLDER, "{models}.{exts}"),
               models=models,
               exts=exts)
    
rule data_cleaning:
    input:
        cmd=join(SRC_FOLDER, "data-cleaning.R"),
        dta=join(RAW_DTA_FOLDER, "BOP221.dta")
    output: join(DTA_FOLDER, "BOP221.RDS")
    shell:
        "Rscript {input.cmd}"
        
rule expected_behavior:
    input:
        cmd=join(SRC_FOLDER, "expected-behavior.R"),
        dta=join(DTA_FOLDER, "BOP221.RDS")
    output:
        expand(join(DTA_FOLDER, "{models}.{exts}"),
               models=models,
               exts=exts)
    shell:
        "Rscript {input.cmd}"
