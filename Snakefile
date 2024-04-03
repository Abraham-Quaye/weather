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
        expand("data/processed/temp/x{pre}{suff}.gz",
        pre = list(map(chr, range(97, 105))), \
        suff = list(map(chr, range(97, 123)))),
        expand("data/processed/temp/xi{suff}.gz", \
        suff = list(map(chr, range(97, 100))))
    conda:
        "environment.yml"
    shell:
        "{input.script}"

rule save_tidy_element_data:
    input:
        frags = rules.subset_split_data.output,
        script = "code/r_code/extract_element_tidy.R"
    output:
        "data/processed/tidy_prcp_data.tsv.gz",
        "data/processed/tidy_tmax_data.tsv.gz"
    conda:
        "environment.yml"
    shell:
        "{input.script}"

rule save_element_geog_metadata:
    input:
        inventory = "data/ghcnd_data/ghcnd-inventory.txt",
        script = "code/r_code/get_geog_metadata.R"
    output:
        "data/processed/geog_metadata.tsv.gz"
    conda:
        "environment.yml"
    shell:
        "{input.script}"

rule merge_plot_element_data:
    input:
        script = "code/r_code/plot_region_element.R",
        tidy_prcp = rules.save_tidy_element_data.output,
        geog_data = rules.save_element_geog_metadata.output,
        raw_data = rules.fetch_ghcnd_data.output,
        split_files = rules.subset_split_data.output
    output:
        "plots/prcp_plot.png",
        "plots/tmax_plot.png"
    conda:
        "environment.yml"
    shell:
        """
        {input.script}
        echo removing data files
        rm {input.raw_data}
        rm {input.split_files}
        rm {input.tidy_prcp}
        rm {input.geog_data}
        """

rule run_project:
    input:
        rules.merge_plot_element_data.output