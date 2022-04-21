workdir: "./src"
         
rule expected_behavior:
    input:
        "../dta/raw-dta/BOP221.dta"
    output:
        "../dta/fit_partychoice.model",
        "../dta/fit_partychoice.RDS",
        "../dta/fit_abstention.model",
        "../dta/fit_abstention.RDS"
    shell:
        "Rscript 02_expected-behavior.R"
