#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Requires at least 3 arguments
if (length(args) != 4) {
  stop("Exactly 4 arguments must be supplied:
       1. Plink map file,
       2. Number of SNPs to mask down to,
       3. A file containing chromosome lengths in bp,
       4. Method for snp selection (bpRN, bpEQ, or bpMAF)")
} else if (length(args)==2) {
  # default output file
  args[2] = "out.txt"
}

# Load libraries
library(dplyr)
# For testing
# snps <- read.table("Sable_October_2018_filt.map")
# num_snps <- 10000
# sizes <- read.table("chrom.sort.sizes.txt")
# method <- "lduMAF"

# Read in files from parameters
snps <- read.table(args[1])
num_snps <- as.integer(args[2])
sizes <- read.table(args[3])
method <- as.character(args[4])

# Add column names and compute the number of segments per chromosome
names(sizes) <- c("chrom", "size")
# Add names to map file
names(snps) <- c("chrom", "SNP", "cm", "position")
sizes$proportion <- sizes$size/sum(sizes$size)
sizes$snps_per_chrom <- sizes$proportion * num_snps
sizes$num_segments <- ceiling(sizes$snps_per_chrom) - 1

####################################################################
# Method 1: random
####################################################################
getRandomSNPs <- function(numSNPs) {
  set.seed(1)
  bpRN <- sample(snps$SNP, numSNPs)
  return(bpRN)
}

####################################################################
# Method 2: equidistant in base pairs
####################################################################
# Function to get a specified number of SNPs that are equidistant
getEquidistantSNPs <- function(numSNPs) {
  # Initialize an empty dataframe to contain data on equidistant snps
  closest.snps <- data.frame(matrix(nrow = 0, ncol = 4))
  names(closest.snps) <- c("chromosome", "boundary", 
                           "closest.snp", "closest.position")

  # Iterating over every chromosome
  for (i in 1:nrow(sizes)) {
    boundaries <- round(seq(from = 0, to = sizes[i, "size"], 
		      by = (sizes[i, "size"]/sizes[i, "num_segments"])))

    # Filter down to current chromosome, and reorder SNPs based on position
    snps.chrom <- snps %>% filter(chrom == sizes[i, "chrom"]) %>%
      .[order(.$position), ]
    # Get closest SNP to boundary using MALDIquant::match.closest
    # Can implement binary search but this seems to work for now 
    library(MALDIquant)
    closest <- sapply(boundaries, FUN = function(x) {
      match.closest(x, snps.chrom$position)})
    # Format all information into a dataframe
    closest.snps.chrom <- data.frame("chromosome" = snps.chrom[closest, "chrom"], 
                                     "boundary" = boundaries, 
                                     "closest.snp" = snps.chrom[closest, "SNP"], 
                                     "closest.position" = snps.chrom[closest, "position"])
    # Update the dataframe
    closest.snps <- rbind(closest.snps, closest.snps.chrom)
  }
  print(sum(sizes$snps_per_chrom))
  print(sum(sizes$num_segments))
  return(closest.snps$closest.snp)
}

#####################################################################
# Method 3: equidistant in bp and optimised for MAF
#####################################################################
getSNPsOptimizedForMaf <- function(numSNPs) {
  freqs <- read.table("Sable_October_2018_filt.frq", header = T)
  # Initialize an empty dataframe containing SNPs optimized for 
  # distance and MAF
  optimized.maf <- data.frame(matrix(nrow=0, ncol=2))
  names(optimized.maf) <- c("SNP", "CHR")

  # Map base pair position to frequency table
  freqs$S <- snps$position[match(freqs$SNP, snps$SNP)]
  # And map number of SNPs per segment + chrom length
  freqs$nchr <- sizes$num_segments[match(freqs$CHR, sizes$chrom)]
  freqs$lenchr <- sizes$size[match(freqs$CHR, sizes$chrom)]

  # Calculate d then remove unnecessary columns
  #freqs$d <- freqs$lenchr/31
  print("FREQS") ; print(head(freqs))

  all.snps <- c()
  # Iterate over every chromosome
  for (i in (1:nrow(sizes))) {
    print(paste0("Processing chromosome: ", i))
    snps.chrom <- freqs[freqs$CHR== i, ]
    
    # Divide this chromosome into equal segments based on how many SNPs we want
    num_snps_from_chromosome <- round(sizes[i, "snps_per_chrom"])
    boundary <- unique(snps.chrom$lenchr)/num_snps_from_chromosome
    
    snps.segment <- c() ; segment_num = 0
    for (j in seq(from=0, to=unique(snps.chrom$lenchr), by=boundary)) {
        #print(paste0("Now processing segment #: ", segment_num))
    	segment_num = segment_num + 1

	if (j == 0) {
	    segmented <- snps.chrom %>% filter(S >= j) %>% filter(S < boundary)
	} else {
	    segmented <- snps.chrom %>% filter(S <= j) %>% filter(S >= j - boundary)
	}
        
	# If there are no SNPs in this segment, exit the loop gracefully
        #print(paste0("Total of ", dim(segmented)[1], " SNPs in segment number: ", segment_num))
	if (dim(segmented)[1] == 0) {next}
    
    	segmented$snp_num <- 1:dim(segmented)[1]
	segmented$snp_d <- segmented$lenchr/num_snps_from_chromosome * segmented$snp_num
        segmented$penalty <- abs(segmented$S - segmented$snp_d) * (0.5 - segmented$MAF)
	
        # Get the SNP with the lowest penalty
        # and append it to SNP vector
        snps.segment <- c(snps.segment, segmented[segmented$penalty == min(segmented$penalty), "SNP"])
        }
    all.snps <- c(all.snps, snps.segment)
    }

    # Fill in remaining SNPs with high MAF
    num_snps_still_needed <- num_snps - length(unique(all.snps))
    if (num_snps_still_needed > 0) {
        extra_snps <- freqs %>% filter(!SNP %in% all.snps) %>%
	    arrange(desc(MAF)) %>% pull(SNP)
        extra_snps <- extra_snps[1:num_snps_still_needed]
        all.snps <- c(all.snps, extra_snps)	
   
    }

   return(unique(all.snps))
}

    
######################################################################
# Method 4: equidistant in LD units and optimized for MAF
######################################################################
getSNPsOptimizedForMaf_LD <- function(numSNPs) {
  freqs <- read.table("Sable_October_2018_filt.frq", header = T)
  # Initialize an empty dataframe containing SNPs optimized for 
  # distance and MAF
  optimized.maf <- data.frame(matrix(nrow=0, ncol=2))
  names(optimized.maf) <- c("SNP", "CHR")

  # Map base pair position to frequency table
  freqs$S <- snps$position[match(freqs$SNP, snps$SNP)]
  # And map number of SNPs per segment + chrom length
  freqs$nchr <- sizes$num_segments[match(freqs$CHR, sizes$chrom)]
  freqs$lenchr <- sizes$size[match(freqs$CHR, sizes$chrom)]

  # Calculate d then remove unnecessary columns
  #freqs$d <- freqs$lenchr/31
  print("FREQS") ; print(head(freqs))

  all.snps <- c()
  # Iterate over every chromosome
  for (i in (1:nrow(sizes))) {
    print(paste0("Processing chromosome: ", i))
    snps.chrom <- freqs[freqs$CHR== i, ]
    
    # Divide this chromosome into equal segments based on how many SNPs we want
    num_snps_from_chromosome <- round(sizes[i, "snps_per_chrom"])
    boundary <- unique(snps.chrom$lenchr)/num_snps_from_chromosome
    
    ldmap <- read.table("Sable_October_filt_2018.ldmap", 
			comment.char = "#", header = F)
    names(ldmap) <- c("row", "SNP", "kb", "ldu")

    snps.chrom$ldu <- ldmap$ldu[match(snps.chrom$SNP, ldmap$SNP)]

    snps.segment <- c() ; segment_num = 0
    for (j in seq(from=0, to=unique(snps.chrom$lenchr), by=boundary)) {
        #print(paste0("Now processing segment #: ", segment_num))
    	segment_num = segment_num + 1

	if (j == 0) {
	    segmented <- snps.chrom %>% filter(S >= j) %>% filter(S < boundary)
	} else {
	    segmented <- snps.chrom %>% filter(S <= j) %>% filter(S >= j - boundary)
	}
        
	# If there are no SNPs in this segment, exit the loop gracefully
        #print(paste0("Total of ", dim(segmented)[1], " SNPs in segment number: ", segment_num))
	if (dim(segmented)[1] == 0) {next}
    
    	segmented$snp_num <- 1:dim(segmented)[1]
	segmented$snp_d <- segmented$lenchr/num_snps_from_chromosome * segmented$snp_num/1000000
        segmented$penalty <- abs(segmented$ldu - segmented$snp_d) * (0.5 - segmented$MAF)
	
        # Get the SNP with the lowest penalty and append it to SNP vector
        snps.segment <- c(snps.segment, segmented[segmented$penalty == min(segmented$penalty), "SNP"])
        }
    all.snps <- c(all.snps, snps.segment)
    }

    # Fill in remaining SNPs with high MAF
    num_snps_still_needed <- num_snps - length(unique(all.snps))
    if (num_snps_still_needed > 0) {
        extra_snps <- freqs %>% filter(!SNP %in% all.snps) %>%
	    arrange(desc(MAF)) %>% pull(SNP)
        extra_snps <- extra_snps[1:num_snps_still_needed]
        all.snps <- c(all.snps, extra_snps)	
   
    }

   return(unique(all.snps))
}


######################################################################
# Write the SNPs to mask in a cluster file for Plink
#####################################################################
writeSNPsToMaskToFile <- function(snpSelectionMethod) {
    if (snpSelectionMethod == "bpRN") {
    snpsToKeep <- getRandomSNPs(numSNPs = num_snps)
  } else if (snpSelectionMethod == "bpEQ") {
    snpsToKeep <- getEquidistantSNPs(numSNPs = num_snps)	
  } else if(snpSelectionMethod == "bpMAF") {
    snpsToKeep <- getSNPsOptimizedForMaf(numSNPs = num_snps)
  } else if (snpSelectionMethod == "lduMAF") {
    snpsToKeep <- getSNPsOptimizedForMaf_LD(numSNPs = num_snps)
  }

  toMask <- snps[which(!snps$SNP %in% snpsToKeep), ]$SNP

  snpsToMask <- data.frame(toMask, 1)
  
  write.table(snpsToMask, paste0("snpsToMask_", num_snps, "_", method, ".tsv"),
	      quote = F, row.names = F, sep = "\t", col.names = F)
}

writeSNPsToMaskToFile(method)
