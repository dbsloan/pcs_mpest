# pcs_mpest
Scripts for automating Partitioned Coalescence Support (PCS) using MP-EST

`pcs_mpest.pl`

## Overview: 
This script implements the "partitioned coalescence support" method by automating the process of running [MP-EST](http://faculty.franklin.uga.edu/lliu/mp-est) and parsing output. Partitioned coalescence support for each gene is calculated and reported.

**Citations:**

- [Gatesy et al. 2019. Partitioned coalescence support reveals biases in species-tree methods and detects gene trees that determine phylogenomic conflicts. Molecular Phylogenetics and Evolution. 139: 106539.](https://www.sciencedirect.com/science/article/pii/S1055790318307036) Also available as a [bioRxiv pre-print](https://www.biorxiv.org/content/early/2018/11/04/461699).

- [Gatesy et al. 2017. Resolution of a concatenation/coalescence kerfuffle: partitionedcoalescence support and a robust family-level tree for Mammalia. Cladistics. 33: 295-332.](https://onlinelibrary.wiley.com/doi/full/10.1111/cla.12170) 

## Requirements: 

This automation is implemented with a Perl script that has been designed for a Unix environment (Mac OSX or Linux). It has been tested in Mac OSX 10.11 and Linux CentOS 6, but it should work in most Unix environments.

Perl - The provided Perl script should be called by users (pcs_mpest.pl). Perl is pre-installed in most Mac OSX and Linux distributions.

MP-EST - The Perl script calls [MP-EST](http://faculty.franklin.uga.edu/lliu/mp-est), which must be installed, and the user must provide the full path and file name for the MP-EST executable. The script has been tested with MP-EST v1.5 and v2.0 but would likely work with other versions.


## Running pcs_mpest.pl:
The script can be called from the command line to analyze a set of gene trees with MP-EST. The user must specify the gene trees, the reference species tree, and at least one alternative topology. The user most also provide the content for the control file that is used to run MP-EST (see format in the sample_data: control_core.txt). There are required parameters that are specified at the command line as described below. Sample data and expected output files are provided in the sample_data directory.


Usage: `perl pcs_mpest.pl [arguments] > output_file`

   REQUIRED ARGUMENTS
   
   The optimal species tree must be specified:

         --opt_tree     - file containing optimal species tree topology
   
   
   Alternative species tree(s) must be specified with one of the 
   following options (but not both): 

         --at_file      - a single file containing one or more trees

         --at_dir       - a directory containing one or more files each 
                          containing a single tree 


   Gene trees must be specified with one of the following options (but
   not both): 

         --gt_file      - a single file containing one or more trees

         --gt_dir       - a directory containing one or more files each 
                          containing a single tree 
   
   
   MP-EST executable name (including relative path) must be specified:
   
         --mpest_file   - MP-EST executable file
   
   
   Core content for MP-EST control file must be specified:
   
         --ctl_core      - Core text for control file (see example file)


   EXAMPLE
         
         perl pcs_mpest.pl
            --opt_tree=sample_data/species_tree.tre
            --at_file=sample_data/alt_trees_file.tre
            --gt_file=sample_data/gene_trees_file.tre 
            --mpest_file=mac/mpest
            --ctl_core=sample_data/control_core.txt
            > mpest_sample.txt
