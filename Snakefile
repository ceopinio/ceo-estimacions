from os.path import join

# Load the configuration
configfile: 'config/config.yaml'

SRC_FOLDER = config["SRC_FOLDER"]
DTA_FOLDER = config["DTA_FOLDER"]
RAW_DTA_FOLDER = config["RAW_DTA_FOLDER"]
MDL_FOLDER = config["MDL_FOLDER"]
RAW_DTA_FILE = "Microdades anonimitzades 1031.sav"

models=["model-partychoice", "model-abstention"]
exts=["RDS", "xgb"]


## Rules
rule all:
    input:
        expand(join(MDL_FOLDER, "{models}.{exts}"),
               models=models,
               exts=exts),
        join(RAW_DTA_FOLDER, RAW_DTA_FILE),
        join(DTA_FOLDER, "weight.RDS"),
        join(DTA_FOLDER, "predicted-partychoice.RDS"),
        join(DTA_FOLDER, "predicted-voting.RDS"),
        join(DTA_FOLDER, "thr-predicted-voting.RDS"),
        join(DTA_FOLDER, "individual-behavior.RDS"),
        join(DTA_FOLDER, "estimated-vote-share.RDS"),
        join(DTA_FOLDER, "vote-share-district.RDS"),
        join(DTA_FOLDER, "seats-simulation.RDS"),
        join(DTA_FOLDER, "seats.RDS"),

        
## Delete everything for re-runs
rule clean:
    shell: f"find {DTA_FOLDER} -maxdepth 1 -type f -delete && find {MDL_FOLDER} -maxdepth 1 -type f -delete"


rule data_cleaning:
    input:
        dta=join(RAW_DTA_FOLDER, RAW_DTA_FILE),
        cmd=join(SRC_FOLDER, "data-cleaning.R")
    output: join(DTA_FOLDER, "clean-bop.RDS")
    shell:
        "Rscript {input.cmd}"

rule past_behavior:
    input:
        join(RAW_DTA_FOLDER, "results-2021.csv"),
        join(RAW_DTA_FOLDER, "llengua.csv"),        
        join(DTA_FOLDER, "clean-bop.RDS"),
        cmd=join(SRC_FOLDER, "past-behavior.R")
    output:
        join(DTA_FOLDER, "weight.RDS"),
        join(DTA_FOLDER, "predicted-recall.RDS"),        
        join(MDL_FOLDER, "model-recall.RDS"),
        join(MDL_FOLDER, "model-recall.xgb")
    shell:
        "Rscript {input.cmd}"
            
rule expected_behavior:
    input:
        dta=join(DTA_FOLDER, "clean-bop.RDS"),
        cmd=join(SRC_FOLDER, "expected-behavior.R")
    output:
        expand(join(MDL_FOLDER, "{models}.{exts}"),
               models=models,
               exts=exts),
        join(DTA_FOLDER, "predicted-partychoice.RDS"),        
        join(DTA_FOLDER, "predicted-voting.RDS"),
        join(DTA_FOLDER, "thr-predicted-voting.RDS")
        
    shell:
        "Rscript {input.cmd}"

rule vote_shares:
    input:
        join(DTA_FOLDER, "clean-bop.RDS"),
        join(DTA_FOLDER, "weight.RDS"),
        join(DTA_FOLDER, "predicted-partychoice.RDS"),
        join(DTA_FOLDER, "predicted-voting.RDS"),
        join(DTA_FOLDER, "thr-predicted-voting.RDS"),
        cmd=join(SRC_FOLDER, "vote-shares.R")
    output:
        join(DTA_FOLDER, "individual-behavior.RDS"),
        join(DTA_FOLDER, "estimated-vote-share.RDS")
    shell:
        "Rscript {input.cmd}"

rule district_shares:
    input:
        join(RAW_DTA_FOLDER, "results-2021.csv"),
        join(DTA_FOLDER, "clean-bop.RDS"),        
        join(DTA_FOLDER, "individual-behavior.RDS"),
        cmd=join(SRC_FOLDER, "district-shares.R")        
    output:
        join(DTA_FOLDER, "vote-share-district.RDS")
    shell:
        "Rscript {input.cmd}"

rule seat_estimates:
    input:
        join(DTA_FOLDER, "vote-share-district.RDS"),
        cmd=join(SRC_FOLDER, "seat-estimates.R")
    output:
        join(DTA_FOLDER, "seats-simulation.RDS"),
        join(DTA_FOLDER, "seats.RDS")
    shell:
        "Rscript {input.cmd}"
    
