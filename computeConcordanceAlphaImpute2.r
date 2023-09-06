#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Requires exactly 4 arguments
if (length(args) != 4) {
  stop("Need 4 parameters: reference genotypes,
       imputed genotypes, masked genotypes, sample name", call.=FALSE) 
}

start_time <- Sys.time()
library(data.table)

# For testing
setwd("~/projects/imputation/02_AlphaImpute2/num_individuals/")
ref.geno <- fread("../Sable_October_2018_AlphaImpute2.txt", header = F)
imp.geno <- fread("/scratch/20708102/outputs/SI_hair_128_20000_lduMAF_ind100_rep1.txt.genotypes", header = F)
masked.geno <- fread("/scratch/20708102/replicates/SI_hair_128_20000_bpEQ_ind100_rep1.txt", header = F)
sample <- "SI_hair_128"

# Read in all inputs
ref.geno <- fread(args[1], header = F) 
imp.geno <- fread(args[2], header = F)
masked.geno <- fread(args[3], header = F)
sample <- args[4]

# Some processing: first take the masked genotypes and filter for the imputed sample 
masked.geno <- as.numeric(masked.geno[V1 == sample, ])
imp.indices <- which(masked.geno == 9) 				# Indices of genotypes that were imputed
unimp.indices <- which(masked.geno != 9) 			# For summary stats
num.unimputed <- length(which(masked.geno != 9)) 		# Also for summary stats
rm(masked.geno)

# Pairwise SNP statistics: create a vector where unimputed SNPs = 9
# All files will be combined into one and then I will aggregate by iteration
# and compute the accuracy for each SNP within each iteration 
imp.geno.sample <- as.character(imp.geno[V1 == sample, ])				# Get sample of interest
imp.geno.sample[unimp.indices] <- 9						# Label unimputed
#imp.geno.sample[1] <- sub("/scratch/20708102/outputs/", "", "/scratch/20708102/outputs/SI_hair_128_20000_lduMAF_ind100_rep1.genotypes")
imp.geno.sample[1] <- sub("/scratch/20708102/outputs/", "", args[2])
imp.geno.sample[1] <- sub(".genotypes", "", imp.geno.sample[1]) 
fwrite(as.list(imp.geno.sample),  paste0("snpwise_accuracy/", imp.geno.sample[1]))
# Doing the same for reference genotypes, but only needs to be done once
ref.geno.sample <- as.character(ref.geno[ref.geno$V1 == sample])
ref.geno.sample[1] <- imp.geno.sample[1]
#fwrite(ref.pair, paste0("snpwise_accuracy/", ref.pair[1]), col.names = F, sep = ",")

# Filter down both ref and imp genotypes so they each consist of a vector
# Now write this to a one-line file for accuracy calculations later on
imp.geno.sample.imp <- as.numeric(imp.geno.sample[imp.indices])
ref.geno.sample.imp <- as.numeric(ref.geno.sample[imp.indices])
# Find missing data in reference genotypes and remove from reference and imputed
unknowns <- which(ref.geno.sample.imp == 9) 
ref.geno.sample.imp <- ref.geno.sample.imp[-unknowns]
# For imputed genotypes, filter to sample of interest first
imp.geno.sample.imp <- imp.geno.sample.imp[-unknowns]
pear.cor <- cor(ref.geno.sample.imp, imp.geno.sample.imp)				# Calculate R^2 here

# Accuracy method 1: proportion of correctly imputed alleles out of all imputed alleles
full_matches <- length(which(ref.geno.sample.imp == imp.geno.sample.imp)) ; partial_matches <- 0
for (i in 1:length(ref.geno.sample.imp)) {
    if (ref.geno.sample.imp[i] == 0 && imp.geno.sample.imp[i] == 1) 
	    {partial_matches = partial_matches + 0.5}
    if (ref.geno.sample.imp[i] == 1 && imp.geno.sample.imp[i] %in% c(0,2)) 
	    {partial_matches = partial_matches + 0.5}
    if (ref.geno.sample.imp[i] == 2 && imp.geno.sample.imp[i] == 1) 
	    {partial_matches = partial_matches + 0.5}
}

accuracy <- (full_matches + partial_matches)/length(ref.geno.sample.imp)

# Accuracy method 2: correlation between true and imputed genotypic allele counts 
# Reorder to make sure samples are in the same order
ref.geno <- ref.geno[match(imp.geno$V1, ref.geno$V1), ]
# Then subset reference genotypes to imputed SNPs + samples used for imputation
ref.geno.sub <- as.matrix(ref.geno[ref.geno$V1 %in% imp.geno$V1, 
			  imp.indices, with = FALSE])

#unknowns <- which(ref.geno == 9) ;  ref.geno.sub <- ref.geno.sub[-unknowns]
imp.geno.sub <- as.matrix(imp.geno[,imp.indices, with = FALSE])

# Calculate correlation using Huang et al. 2009 formula
cor_vec <- vector(length=length(ref.geno.sample.imp))

for (i in 1:ncol(imp.geno.sub)) {
  cor_vec[i] <- cor(imp.geno.sub[,i], ref.geno.sub[,i])^2
}
cor_vec_all_snps <- imp.geno.sample
cor_vec_all_snps[imp.indices] <- cor_vec
cor_vec_all_snps[unimp.indices] <- 9

# For SNPwise accuracy/correlation calculations, write each iteration
# for each individual to a file, to be aggregated later
#cor_vec_all_snps[1] <- sub("/scratch/20708102/outputs/", "", "/scratch/20708102/outputs/SI_hair_128_20000_lduMAF_ind100_rep1.genotypes")
cor_vec_all_snps[1] <- sub("/scratch/20708102/outputs/", "", args[2])
cor_vec_all_snps[1] <- sub(".genotypes", "", cor_vec_all_snps[1])
options(digits=4) # Reduce # of digits to reduce file size... 
fwrite(as.list(cor_vec_all_snps),  paste0("snpwise_correlation/", cor_vec_all_snps[1]))

# Print results to file
cat(paste0(args[2], ",",
	    length(imp.indices), ",",
	    num.unimputed, ",",
	    accuracy, ",",
	    pear.cor,
	    "\n"))
