# TP_WF_Snakemake

The purpose of this project is to execute the same analysis worflow describe in the HPC project in this github in another way.
Here we use Snakemake to execute the workflow in a Cloud called ifb‑aubi‑oscar with 8 cores, 32 Go of memory and 128 Go of stockage.

**cloud deployment access ssh : ubuntu@193.49.167.105**

**appliance : BioPipes**


The main snakemake file is **Snakefile_WF_withOpenJDK**

To run the entire workflow, the command line is:

> $ snakemake --use-conda --cores all  --snakefile Snakefile_WF_withOpenJDK 

Others snakefiles contain just a specific rule or a part of the workflow. The file Snakemake_WF is an alternative workflow without the DeepTools analysis.

All the files env.yaml and config.yaml are in the config directory.

All the data come from  student22@193.49.167.88 :

Genome:
> /home/users/shared/databanks/bio/ncbi/genomes/Mus_musculus/Mus_musculus_GRCm38.p6/Mus_musculus_2020-7-9/fasta/

Indexes : 
> /home/users/shared/databanks/bio/ncbi/genomes/Mus_musculus/Mus_musculus_GRCm38.p6/Mus_musculus_2020-7-9/bowtie2/

<img src="DAG.png" />

# Snakemake Rules:

Individual steps are almost still the same.

## Unzip fastq files
>rule unzip:

Unzip fastq files

## Initial quality control 
>rule fastqc_init:

Uses fastqc to execute a quick initial quality control of the sequencing results. Takes fastq input by default.

## Trimming 
>rule cutadapt:

Removal of adapters via cutadaptc. If you wish to use this for another analysis with similar workflow, be sure to change the adapter sequences used as needed. Takes fastq input, gives fastq output.

## Post-trimming quality control 
>rule fastqc_post:

Once trimming has been finished, another quality control step is executed, via fastqc once again. Takes fastq input.

## Alignment with reference genome  
>rule bowtie2:

In this step bowtie2 is used to align the sequencing results with the reference genome, then samtools is used for file conversion (sam -> bam) and sorting. Takes bt2 (ref genome index) and fastq (sequencing data) input, gives bam output.

## Exploration via deepTools 
>rule deeptools:

This step produces plots to analyse correlation and coverage for the now aligned sequencing data, through the use of python-coded deepTools. Takes bam input, provides pdf files for plots, and a .tab correlation matrix file.

## Removal of duplicates  
>rule markduplicates:

Picard is used here, specifically the MarkDuplicates tool. It is used with the REMOVE_DUPLICATES option set to true so that the result files have the duplicates removed rather than just marked. Takes bam input, gives bam (data with duplicated removed) and txt (info on duplicates) output.


## Identification of DNA accessibility sites 
>rule macs2:

The MACS2 callpeak tool is used to find the accessibility sites within the aligned sequencing data. Takes bam input, gives narrowPeak, wig, and bed output.
Comparison of DNA accessibility sites between conditions

## Comparison of DNA accessibility sites between conditions
>rule bedtools:

Obtains via bedtools, from MACS2 callpeak results, the unique/common accessibility sites between conditions (T0h and T24h). Takes bed input, gives bed output.


