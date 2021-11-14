# TP_WF_Snakemake

The purpose of this project is to execute the same analysis worflow describe in the HPC project in this github in another way.
Here we use Snakemake to execute the workflow in a Cloud called ifb‑aubi‑oscar with 8 cores, 32 Go of memory and 128 Go of stockage.

cloud deployment access : ubuntu@193.49.167.105
apliance : BioPipes


Individual steps (in order of workflow execution) are the same.
Initial quality control

Uses fastqc to execute a quick initial quality control of the sequencing results. Takes fastq input by default.
Trimming

Removal of adapters via cutadaptc. If you wish to use this for another analysis with similar workflow, be sure to change the adapter sequences used as needed. Takes fastq input, gives fastq output.
Post-trimming quality control

Once trimming has been finished, another quality control step is executed, via fastqc once again. Takes fastq input.
Reference genome indexing (optional)

This step allows for the indexing of the reference genome used for the alignment which follows. Unnecessary if the indexing has already been achieved. bt2 output
Alignment with reference genome

In this step bowtie2 is used to align the sequencing results with the reference genome, then samtools is used for file conversion (sam -> bam) and sorting. Takes bt2 (ref genome index) and fastq (sequencing data) input, gives bam output.
Removal of duplicates

Picard is used here, specifically the MarkDuplicates tool. It is used with the REMOVE_DUPLICATES option set to true so that the result files have the duplicates removed rather than just marked. Takes bam input, gives bam (data with duplicated removed) and txt (info on duplicates) output.
Exploration via deepTools

This step produces plots to analyse correlation and coverage for the now aligned sequencing data, through the use of python-coded deepTools. Takes bam input, provides pdf files for plots, and a .tab correlation matrix file.
GC bias correction (optional)

The MACS2 callpeak tool is used to find the accessibility sites within the aligned sequencing data. Takes bam input, gives narrowPeak, wig, and bed output.
Comparison of DNA accessibility sites between conditions

Obtains via bedtools, from MACS2 callpeak results, the unique/common accessibility sites between conditions (T0h and T24h). Takes bed input, gives bed output.
