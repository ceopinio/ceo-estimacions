from os.path import join


# Load the configuration
configfile: 'config/config.yaml'

SRC_FOLDER = config["SRC_FOLDER"]
DTA_FOLDER = config["DTA_FOLDER"]
RAW_DTA_FOLDER = config["RAW_DTA_FOLDER"]

models=["fit-partychoice", "fit-abstention"]
exts=["RDS", "model"]

## Rules
rule all:
    input:
        expand(join(DTA_FOLDER, "{models}.{exts}"),
               models=models,
               exts=exts),
        join(DTA_FOLDER, "bop-recall-weights.RDS")
        
## Delete everything for re-runs
rule clean:
    shell: f"find {DTA_FOLDER} -maxdepth 1 -type f -delete"

           
rule data_cleaning:
    input:
        cmd=join(SRC_FOLDER, "data-cleaning.R"),
        dta=join(RAW_DTA_FOLDER, "BOP221.dta")
    output: join(DTA_FOLDER, "BOP221.RDS")
    shell:
        "Rscript {input.cmd}"

rule past_behavior:
    input:
        cmd=join(SRC_FOLDER, "past-behavior.R"),
        dta=join(DTA_FOLDER, "BOP221.RDS")
    output: join(DTA_FOLDER, "bop-recall-weights.RDS")
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
