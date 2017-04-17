#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw (min);
use Getopt::Long;

our $opt_tree;
our $at_file;
our $at_dir;
our $gt_file;
our $gt_dir;
our $mpest_file;
our $ctl_core;

my $usage = 
"\nUsage: perl $0 [arguments] > output_file
   
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
   
   		 --mpest_file  - MP-EST executable file


   Core content for MP-EST control file must be specified:
   
    		 --ctl_core    - Core text for control file (see example file)
  
   
   EXAMPLE
         perl $0 --opt_tree=sample_data/species_tree.tre
         	  --at_file=sample_data/alt_trees_file.tre --gt_file=sample_data/gene_trees_file.tre  
           	--mpest_file=mac/mpest --ctl_core=sample_data/control_core.txt > mpest_sample.txt
\n\n";

GetOptions(
    'opt_tree=s'  => \$opt_tree,
    'at_file=s'  => \$at_file,
    'at_dir=s'  => \$at_dir,
    'gt_file=s'  => \$gt_file,
    'gt_dir=s'  => \$gt_dir,
    'mpest_file=s'  => \$mpest_file,
    'ctl_core=s'  => \$ctl_core,
);

#Checked that required command line arguments were provided
$mpest_file or die ("\nERROR: Must specify MP-est executable file with --mpest_file\n\n$usage");
$ctl_core or die ("\nERROR: Must provide file containing core text for MP-EST control file with --ctl_core\n\n$usage");
$opt_tree or die ("\nERROR: Must specify optimal species tree with --opt_tree\n\n$usage");
$at_file or $at_dir or die ("\nERROR: Must specify alternative tree(s) with either --at_file or --at_dir\n\n$usage");
$gt_file or $gt_dir or die ("\nERROR: Must specify gene trees with either --gt_file or --gt_dir\n\n$usage");
$at_file and $at_dir and die ("\nERROR: --at_file and --at_dir cannot both be used at the same time\n\n$usage");
$gt_file and $gt_dir and die ("\nERROR: --gt_file and --gt_dir cannot both be used at the same time\n\n$usage");
if ($at_file){
	-d $at_file and die ("\nERROR: the --at_file option was used but $at_file is a directory. You may want to use --at_dir instead.\n\n$usage");
}else{
	-d $at_dir or die ("\nERROR: the --at_dir option was used but $at_dir is NOT a directory. You may want to use --at_file instead.\n\n$usage");
}
if ($gt_file){
	-d $gt_file and die ("\nERROR: the --gt_file option was used but $gt_file is a directory. You may want to use --gt_dir instead.\n\n$usage");
}else{
	-d $gt_dir or die ("\nERROR: the --gt_dir option was used but $gt_dir is NOT a directory. You may want to use --gt_file instead.\n\n$usage");
}

#Define random number that will be used in saving temp file names to avoid clashing if multiple runs are done in parallel.
my $randnum = int(rand(10000));

#extract and save optimal species tree and file name
my @species_trees;
my @st_names;
push (@species_trees, file_to_string($opt_tree));
push (@st_names, $opt_tree);

#extract and save gene trees and file names
my @gene_trees;
my @gene_names;
if ($gt_file){ #if a single file with multiple trees was provided, extract each line
	my $FH_GT = open_file($gt_file);
	while (my $line = <$FH_GT>){
		$line =~ /^\s*$/ and next;
		chomp $line;
		push (@gene_trees, $line);
	}
	close $FH_GT;
}else{ #if a directory with multiple tree files, extract the tree from each and save file name
	substr ($gt_dir, -1) eq '/' or $gt_dir .= '/';
	my @files = get_file_names ($gt_dir);
	foreach my $name (@files){
		push (@gene_trees, file_to_string($gt_dir.$name));
		push (@gene_names, $name);
	}
}

#extract and save alternative species trees and file names. Append to array containing optimal tree
if ($at_file){ #if a single file with multiple trees was provided, extract each line
	my $FH_AT = open_file($at_file);
	while (my $line = <$FH_AT>){
		$line =~ /^\s*$/ and next;
		chomp $line;
		push (@species_trees, $line);
	}
	close $FH_AT;
}else{ #if a directory with multiple tree files, extract the tree from each and save file name
	substr ($at_dir, -1) eq '/' or $at_dir .= '/';
	my @files = get_file_names ($at_dir);
	foreach my $name (@files){
		push (@species_trees, file_to_string($at_dir.$name));
		push (@st_names, $name);
	}
}

#save contents of the provided core text for control file to a string.
my $core = file_to_string($ctl_core);
chomp $core;


#Print STDERR describing the run, including whether directories or single files were provided
my $at_source;
if ($at_file){$at_source = $at_file;}else{$at_source = $at_dir;}
my $gt_source;
if ($gt_file){$gt_source = $gt_file;}else{$gt_source = $gt_dir;}

print STDERR "\n\n". (localtime) ."\nRunning PCS using MP-EST: $mpest_file\n\n";
print STDERR "--Optimal tree specified as: $opt_tree\n";
print STDERR "--", scalar(@species_trees) -1, " alternative species trees in $at_source\n";
print STDERR "--",scalar(@gene_trees), " gene trees in $gt_source\n\n";


#Print header row of main output file. Include alt species tree file names if the at_dir option was used.
my @split_name = split (/\//, $st_names[0]);
print "Gene\tOptimalTree: $split_name[-1]";
for (my $i = 1; $i < scalar (@species_trees); ++$i){
	print "\tAltTree$i";
	$st_names[$i] and print ": $st_names[$i]";
}
for (my $i = 1; $i < scalar (@species_trees); ++$i){
	print "\tAltTree$i\_Difference";
	$st_names[$i] and print ": $st_names[$i]";
}
print "\tPCS\tSupported Tree\n";


#For each gene tree, calculate pseudo likelihood scores with MP-EST by running the gene tree file against each possible species tree (optimal and alternatives).
my $gene_count = 0;
my @scores_sum;
my @PCSs_sum;

foreach my $tree (@gene_trees){
	++$gene_count;
	print STDERR "Analyzing gene tree $gene_count\n";

	#write file that contains a single gene tree
	my $FH = open_output (".$randnum\_TEMP_GENE_TREE_INPUT");
	print $FH "$tree";
	close $FH;

	#loop over all species trees, calling MP-EST each time. 
	#Compare each  score for alt species trees back to the optimal tree to calculate PCS.
	my @scores;
	my @PCSs;	
	for (my $i = 0; $i < scalar @species_trees; ++$i){
		
		#generate an MP-EST Control file by combining 1) the name of the temp gene tree file, 2) the core control file text, and 3) the species tree
		my $FH2 = open_output (".$randnum\_TEMP_CONTROL_FILE");
		print $FH2 ".$randnum\_TEMP_GENE_TREE_INPUT\n$core\n$species_trees[$i]";
		close $FH2;

		$scores[$i] = call_mpest("$mpest_file .$randnum\_TEMP_CONTROL_FILE");
		$scores_sum[$i] += $scores[$i];
		$PCSs[$i] = $scores[0] - $scores[$i];
		$PCSs_sum[$i] += $PCSs[$i];
	}
	
	#delete temp files
	unlink ".$randnum\_TEMP_GENE_TREE_INPUT";
	unlink ".$randnum\_TEMP_CONTROL_FILE";
	
	#remove PCS calcs for optimal tree itself (which are 0 by definition)
	shift @PCSs;
	
	#report the minimum PCS value among the altenrnative trees. 
	#If it is negative (or zero), determine which alt tree was better supported than (or tied with) the optimal tree.
	my $min_PCS = min (@PCSs);
	my $tree_num = 0;
	if ($min_PCS <= 0){
		my $index = 0;
		$tree_num = "";
		foreach (@PCSs){
			++$index;
			if ($_ == $min_PCS){
				if ($tree_num){
					$tree_num .= ",$index";
				}elsif ($min_PCS == 0){
					$tree_num = "0,$index";
				}else{
					$tree_num = $index;
				}
			}
		}
	}
	
	#print output line for each gene
	print "Gene $gene_count";
	@gene_names and print ": $gene_names[$gene_count -1]";
	foreach (@scores){print "\t$_";}
	foreach (@PCSs){print "\t$_";}
	print "\t$min_PCS\t$tree_num\n";	
}

#remove PCS summation calcs for optimal tree itself (0 by definition)
shift @PCSs_sum;

#print summation line
print "SUM";
foreach (@scores_sum){print "\t$_";}
foreach (@PCSs_sum){print "\t$_";}
print "\n";

print STDERR "\n" . (localtime) . "\nRun Completed\n\n";


###define subroutines###

#call MP-EST. Parse out and return pseudo likelihood score from output
sub call_mpest{
	
	use strict;
	use warnings;
	
	my $bash_line = shift @_;


	system ("$bash_line > .$randnum\_MPEST_TEMP_OUT 2>&1");
	my @mpest_out = file_to_array(".$randnum\_MPEST_TEMP_OUT");
	chomp $mpest_out[-1];
	$mpest_out[-1] =~ /^\-[\d\.]+$/ or die ("\nERROR: Could not parse likelihood score from the file .$randnum\_MPEST_TEMP_OUT, which was generated with the following system call:\n\n$bash_line > .$randnum\_MPEST_TEMP_OUT\n\n");
	
	unlink ".$randnum\_MPEST_TEMP_OUT";
	
	return $mpest_out[-1];

}

#additional subroutines for reading/writing files
sub get_file_names {
	use strict;
	use warnings;

    my ($directory) = @_;
    my @files = (  );
    my @filedata =(  );
    	

    # Open the directory
    unless(opendir(DIRECTORY, $directory)) {
        print "Cannot open directory $directory!\n";
        exit;
    }
    
    # Read the directory, ignoring special entries starting with "."
    @files = grep (!/^\./, readdir(DIRECTORY));
    
    closedir(DIRECTORY);
    
    return (@files);
   
}

sub file_to_string {
	use strict;
	use warnings;

    my($filename) = @_;

    my $filedata;

    unless( open(GET_FILE_DATA, $filename) ) {
        print STDERR "Cannot open file \"$filename\"\n\n";
        exit;
    }
    
    while (<GET_FILE_DATA>){
    	$filedata .= $_;
    }
    
    close GET_FILE_DATA;

    return $filedata;
}

sub file_to_array {
	use strict;
	use warnings;

    my($filename) = @_;

    my @filedata = (  );

    unless( open(GET_FILE_DATA, $filename) ) {
        print STDERR "Cannot open file \"$filename\"\n\n";
        exit;
    }

    @filedata = <GET_FILE_DATA>;

    close GET_FILE_DATA;

    return @filedata;
}


sub open_file {
	use strict;
	use warnings;

    my($filename) = @_;
    my $fh;

    unless(open($fh, $filename)) {
        print "Cannot open file $filename\n";
        exit;
    }
    return $fh;
}

sub open_output {
	use strict;
	use warnings;

    my($filename) = @_;
    my $fh_output;

    unless(open($fh_output, ">$filename")) {
        print "Cannot open file $filename\n";
        exit;
    }
    return $fh_output;
}
