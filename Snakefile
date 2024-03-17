rule fetch_ghcnd_data:
    input:
        "code/zsh/ghcnd_raw_data.sh"
    output:
        expand("data/ghcnd_data/ghcnd{name}", \
        name = ["_all.tar.gz", "-inventory.txt"])
    shell:
        "{input}"

rule enumerate_tar_files:
    input:
        "data/ghcnd_data/ghcnd_all.tar.gz"
    output:
        "data/ghcnd_data/tar_files.txt"
    shell:
        """
        echo "file_name" > {output}
        tar tf {input} | grep ".dly" >> {output}
        """

rule subset_split_data:
    input:
        raw = "data/ghcnd_data/ghcnd_all.tar.gz",
        script = "code/zsh/subset_concat_tar.sh"
    output:
        expand("data/processed/temp/x{pre}{suff}.gz", pre = ["a", "b"], \
        suff = list(map(chr, range(97, 123)))),
        expand("data/processed/temp/xc{suff}.gz", \
        suff = list(map(chr, range(97, 119))))
    shell:
        "{input.script}"

rule save_tidy_prcp_data:
    input:
        frags = rules.subset_split_data.output,
        script = "code/r_code/extract_prcp_tidy.R"
    output:
        "data/processed/tidy_prcp_data.tsv.gz"
    shell:
        "{input.script}"

rule save_prcp_geog_metadata:
    input:
        inventory = "data/ghcnd_data/ghcnd-inventory.txt",
        script = "code/r_code/get_geog_metadata.R"
    output:
        "data/processed/prcp_geog_metadata.tsv"
    shell:
        "{input.script}"

rule run_project:
    input:
        rules.enumerate_tar_files.output,
        rules.save_tidy_prcp_data.output,
        rules.save_prcp_geog_metadata.output