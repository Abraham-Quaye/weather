rule fetch_ghcnd_data:
    input:
        "code/zsh/ghcnd_raw_data.sh"
    output:
        expand("data/ghcnd_data/ghcnd{name}", \
        name = ["_all.tar.gz", "-inventory.txt", "-stations.txt"])
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

rule run_project:
    input:
        rules.enumerate_tar_files.output