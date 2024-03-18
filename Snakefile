rule fetch_ghcnd_data:
    input:
        "code/zsh/ghcnd_raw_data.sh"
    output:
        expand("data/ghcnd_data/ghcnd{name}", \
        name = ["_all.tar.gz", "-inventory.txt"])
    conda:
        "environment.yml"
    shell:
        "{input}"

rule subset_split_data:
    input:
        raw = "data/ghcnd_data/ghcnd_all.tar.gz",
        script = "code/zsh/subset_concat_tar.sh"
    output:
        expand("data/processed/temp/x{pre}{suff}.gz", pre = ["a", "b"], \
        suff = list(map(chr, range(97, 123)))),
        expand("data/processed/temp/xc{suff}.gz", \
        suff = list(map(chr, range(97, 119))))
    conda:
        "environment.yml"
    shell:
        "{input.script}"

rule save_tidy_prcp_data:
    input:
        frags = rules.subset_split_data.output,
        script = "code/r_code/extract_prcp_tidy.R"
    output:
        "data/processed/tidy_prcp_data.tsv.gz"
    conda:
        "environment.yml"
    shell:
        "{input.script}"

rule save_prcp_geog_metadata:
    input:
        inventory = "data/ghcnd_data/ghcnd-inventory.txt",
        script = "code/r_code/get_geog_metadata.R"
    output:
        "data/processed/prcp_geog_metadata.tsv"
    conda:
        "environment.yml"
    shell:
        "{input.script}"

rule merge_plot_prcp_data:
    input:
        script = "code/r_code/plot_region_prcp.R",
        tidy_prcp = rules.save_tidy_prcp_data.output,
        geog_data = rules.save_prcp_geog_metadata.output
    output:
        "plots/prcp_plot.png"
    conda:
        "environment.yml"
    shell:
        "{input.script}"

rule run_project:
    input:
        rules.merge_plot_prcp_data.output