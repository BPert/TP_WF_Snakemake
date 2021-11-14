configfile: "config/config.yaml"

rule all:
	input:
		expand("results/fastqc_init/{sample}_fastqc.zip", sample = config["samples"]),
		expand("results/fastqc_init/{sample}_fastqc.html", sample = config["samples"]),
		expand("results/cutadapt/{sample}_1.fastq", sample = config["samplesCut"]),
		expand("results/cutadapt/{sample}_2.fastq", sample = config["samplesCut"]),
		expand("results/fastqc_post/{sample}_fastqc.zip", sample = config["samples"]),
		expand("results/fastqc_post/{sample}_fastqc.html", sample = config["samples"]),
		expand("results/bowtie2/{sample}_trim_mapped_sorted_q2.bam", sample = config["samplesCut"]),
		expand("results/markduplicates/{sample}_lessDup.bam", sample = config["samplesCut"]),
		expand("results/macs2/{sample}_macs2.bed", sample = config["samplesCut"] )
rule unzip:
	input:
		lambda wildcards: config["samples"][wildcards.sample]
	output:
		temp("tmp/{sample}.fastq")
	log: "logs/unzip/{sample}.unzip.log"
	shell:
		"""
		mkdir -p tmp
		gunzip -c {input} > {output}
		"""

rule fastqc_init:
	input:
		"tmp/{sample}.fastq"
	output:
		zip="results/fastqc_init/{sample}_fastqc.zip",
		html="results/fastqc_init/{sample}_fastqc.html"
		
	conda:
		"config/env.yaml"
	benchmark:
		"benchmarks/fastqc_init/{sample}.fastqc.benchmark.txt"
	threads: 8
	log: "logs/fastqc_init/{sample}.fastqc.log"
	shell:
		"""
		mkdir -p results/fastqc_init
		echo " Here we start the fastqc_init analysis (jobid ={jobid}) for {input}"
		fastqc {input} -o "results/fastqc_init" -t {threads}
		"""
	
rule cutadapt:
	input:
		["tmp/{samplesCut}_1.fastq","tmp/{samplesCut}_2.fastq"]

	output:
		fastq1="results/cutadapt/{samplesCut}_1.fastq",
		fastq2="results/cutadapt/{samplesCut}_2.fastq",
		qc="results/cutadapt/{samplesCut}.qc.txt"
#	wildcard_constraints:
#		samplesCut=".*R[123]"
	params:
		adapters="-a CTGTCTCTTATACACATCTCCGAGCCCACGAGAC -A CTGTCTCTTATACACATCTGACGCTGCCGACGA",
		extra="--minimum-length 20 -q 20"
	benchmark:
		"benchmarks/cutadapt/{samplesCut}.cutadapt.benchmark.txt"
	log:
		"logs/cutadapt/{samplesCut}.log"
	threads: 0  #set desired number of threads here - To automatically detect the number of available cores, use -j 0 (or --cores=0). In the wrapper : " -j {snakemake.threads}"
	wrapper:
		"0.79.0/bio/cutadapt/pe"
		

rule fastqc_post:
	input:
		"results/cutadapt/{sample}.fastq"
#		rules.cutadapt.output.fastq1{sample}, rules.cutadapt.output.fastq2{sample}
	output:
		html="results/fastqc_post/{sample}_fastqc.html",
		zip="results/fastqc_post/{sample}_fastqc.zip"
	conda:
		"config/env.yaml"
	benchmark:
		"benchmarks/fastqc_post/{sample}.fastqc.benchmark.txt"
	threads: 8
	log: "logs/fastqc_post/{sample}.fastqc.log"
	shell:
		"""
		mkdir -p results/fastqc_post
		fastqc {input} -o "results/fastqc_post" -t {threads}
		"""

rule bowtie2:
	input:
		fastq1="results/cutadapt/{samplesB}_1.fastq", 
		fastq2="results/cutadapt/{samplesB}_2.fastq"
	output:
		"results/bowtie2/{samplesB}_trim_mapped_sorted_q2.bam"
#	wildcard_constraints:
#		samplesCut=".*R[123]"
	conda:
		"config/envBowtie2.yaml"
	benchmark:
		"benchmarks/bowtie2/{samplesB}_trim_mapped_sorted_q2.benchmark.txt"
	threads: 8 
	log: "logs/bowtie2/{samplesB}_trim_mapped_sorted_q2.log"

	shell:
		"""
		bowtie2  --very-sensitive -p 6 -k 10  -x /home/ubuntu/data/mydatalocal/atacseq/genome \
		-1 {input.fastq1} -2 {input.fastq2} 2>&1 > {log}\
		|  samtools view -q 2 -bS |  samtools sort -o {output} 
		samtools index -b {output}
		"""

#		-1 "results/cutadapt/{samplesB}_1.cutadapt.fastq"  -2 "results/cutadapt/{samplesB}_2.cutadapt.fastq" \
#		|  samtools view -q 2 -bS  -  |  samtools sort - -o {samplesB}_trim_mapped_sorted_q2.bam




rule markduplicates:
	input: #input:  rules.a.output
		"results/bowtie2/{sample}_trim_mapped_sorted_q2.bam"
	output:
		"results/markduplicates/{sample}_lessDup.bam"
#		txt="results/markduplicates/{sample}_lessDup_metrics.txt"
	conda:
		"config/envMarkDuplicates.yaml"
	benchmark:
		"benchmarks/markduplicates/{sample}_lessDup.benchmark.txt"
	threads : 8
	log:
		"logs/markduplicates/{sample}_lessDup.log"
	shell:
		"""
		java -jar /opt/apps/picard-2.18.25/picard.jar MarkDuplicates \
		I={input} \
    	O={output} \
		REMOVE_DUPLICATES=true
		samtools index -b {output}
		"""
#       M="results/markduplicates"

rule macs2:
	input:
		"results/markduplicates/{sample}_lessDup.bam"
	output:
		"results/macs2/{sample}_macs2.bed"
	conda:
		"config/envMacs2.yaml"
	benchmark:
		"benchmarks/macs2/{sample}_macs2.benchmark.txt"
	threads : 8
	log:
		"logs/macs2/{sample}_macs2.log"
	shell:   # revoir le tmpdir... effacer 
		"""
		mkdir -p  results/macs2/tmpdir
		macs2 callpeak -t {input}\
 		-f BAM  \
		-n {output}\
		--outdir results/macs2/\
		--tempdir results/macs2/tmpdir
		"""