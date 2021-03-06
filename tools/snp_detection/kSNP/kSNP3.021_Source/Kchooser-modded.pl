#!/usr/bin/perl
#v3.2

use warnings;
use strict;

=begin
Kchooser determines an optimum value for K then determines at that value of K
the fraction of kmers from the shortest sequence that are present in all of
the genomes.

The input file is a fasta file in which each sequence is on one line

Usage: Kchooser myfile.fasta [unique kmer limit]

By default chooses as the optimum value of K the odd number that is greater than the value
for which >0.99 of the kmers of the median-length sequence are unique.  The user can choose
a lower limit if desired.  See the kSNP documentation for an explanation.  To invoke the option enter
for instance: Kchooser myfile.fasta 0.96.

Output is written to a file named Kchooser.report

This version uses the median length genomes at both steps
=cut

my $infile = $ARGV[0];
my $jellypath = $ARGV[1]."/".$ARGV[2]."/jellyfish";
#print STDERR "PATH:\n";
#print STDERR $ARGV[1];
my @sequences = (); #holds sequence ID in col0, sequence in col1, sequence length in col2
#my $longestSeqIndex = 0;
#my $longSequence = '';
#my $lenLongSequence = 0;
my $lenShortSequence = 0;
my $medI = 0; #index of the median length sequence
my $medSeq = ''; #the median sequence
my $lenMedSeq = 0; #length of the median sequence
my $Kvalue = 0;
my $fractionUniqueMers = 0;
my @kmers = ();
my $finalK = 0;
my $theFastaFile = '';
my $numGenomes = 0;
my $numMers = 0; #the number of kmers in the shortest sequence
my $coreMers = 0;
my $numHits = 0;
my $uniqueMers = 0;
my $theKmer = '';
my $RCkmer = '';
my $coreFraction = 0;
my $beginTime = time;
my $endTime = 0;
my $elapsedTime = 0;
my @args = ();
my $sampleSize = 0;
my $limitFrac;

#if ($ARGV[1]) {$limitFrac = $ARGV[1]} else {$limitFrac = 0.99;}
$limitFrac = 0.99;




#read the input fasta file
readFasta($infile, \@sequences);
#sort @sequences according to line length
@sequences = sort {$a-> [2] <=> $b->[2]} @sequences;
#$longestSeqIndex = $#sequences;
$numGenomes = scalar @sequences;
$endTime = time;
$elapsedTime = $endTime - $beginTime;

#find the median and shortest sequence
#$longSequence = $sequences[$longestSeqIndex][1];
#$lenLongSequence = length $longSequence;
$lenShortSequence = length $sequences[0][1];
$medI = int($numGenomes/2); #the index of the median sequence
$medSeq = $sequences[$medI][1];
$lenMedSeq = length $medSeq;





#write the longest sequence to a temporary fasta file
open (OUTFILE, '>medSeq.fasta') or die "Can't open medseq.fasta for writing. $!";
print OUTFILE "$sequences[$medI][0]\n$sequences[$medI][1]\n";
close OUTFILE;
$theFastaFile = 'medSeq.fasta';
#determine the starting k value so that length sequence/ 4^k is <0.1.
$Kvalue = (log(length $medSeq) - log 0.1) /log 4;
#print "Start value of k is $Kvalue.\n";
$Kvalue = int($Kvalue);
#print "Start integer value of k is $Kvalue.\n";
if (($Kvalue + 1)%2 == 1) {
	$Kvalue = $Kvalue+1;
	}
	else {
		$Kvalue = $Kvalue+2;
		}

 do {
 	@kmers = findUniqueMerFraction($Kvalue, \$fractionUniqueMers, $theFastaFile);
 	$Kvalue = $Kvalue+2;
 	} until $fractionUniqueMers > $limitFrac or $Kvalue > 29;

$finalK = $Kvalue+2;
print "$Kvalue\n";
$endTime = time;
$elapsedTime = $endTime - $beginTime;

@kmers = ();
#now get the  kmers for the shortest sequence
 #write the shortest sequence to a temporary fasta file
open (OUTFILE, '>shortSeq.fasta') or die "Can't open shortSeq.fasta for writing. $!";
print OUTFILE "$sequences[0][0]\n$sequences[0][1]\n";
close OUTFILE;
$theFastaFile = 'shortSeq.fasta';
@kmers = findUniqueMerFraction($Kvalue, \$fractionUniqueMers, $theFastaFile);

$numMers = scalar @kmers;
if($numMers < 1000) {
	$sampleSize = $numMers;
	}
	else {
		$sampleSize = 1000;
		}

for (my $i=0; $i< $sampleSize; $i++) {
	$theKmer = $kmers[$i][0];
	$RCkmer = revcom($theKmer);
	#print "$theKmer\t$kmers[$i][1]\n";
	if ($kmers[$i][1] < 2 ) {
		$uniqueMers++;
		#print "$uniqueMers\n";
		for (my $j=0; $j<$numGenomes; $j++) {
			if ($sequences[$j][1] =~ /$theKmer/ or $sequences[$j][1] =~ /$RCkmer/) {
				$numHits++;
				}
			}
		if ($numHits > $numGenomes-1) {
			$coreMers++;
			$numHits = 0;
			}
		}

	}
$endTime = time;
$elapsedTime = $endTime - $beginTime;
if ($coreMers != 0 && $uniqueMers != 0) {
	$coreFraction = $coreMers/$uniqueMers;
}

$coreFraction = 0;

#remove the leftover files
@args = ('rm', 'output_0');
system(@args) == 0 or die "system @args failed: $!";

@args = ('rm', 'medSeq.fasta');
system(@args) == 0 or die "system @args failed: $!";

@args = ('rm', 'shortSeq.fasta');
system(@args) == 0 or die "system @args failed: $!";

@args = ('rm', 'jellyout.txt');
system(@args) == 0 or die "system @args failed: $!";


$endTime = time;
$elapsedTime = $endTime - $beginTime;

#############################################################################
#Subroutines
#############################################################################
#called by Main
sub readFasta
{
my $infile = $_[0];
my $sequences = $_[1]; #pointer to @sequences
my $line = '';
my @temp = ();
my $id = ''; #the sequence ID
my $lenSeq = '';

open (INFILE, $infile) or die "Can't open $infile for reading. $!";
while ($line = <INFILE>) {
	chomp $line;
	if ($line =~ /^>/) {
		@temp = split / /, $line;
		$id = $temp[0];
		}
		elsif (length $line >0) {
			$lenSeq = length $line;
			push (@$sequences,[$id, $line, $lenSeq]);
			}
	}
close INFILE;
}
#############################################################################
#called by Main
sub findUniqueMerFraction
{
my $Kvalue = $_[0];
my $fractionUniqueMers = $_[1]; #pointer to $fractionUniqueMers
my $theFastaFile = $_[2];
my @args = ();
my @kmers = (); #col0 = ker col1 = number of occurrences
my $numUniqueKmers = 0;

my $numMers = 0;
my $line = '';
my @temp = '';



@args = ($jellypath, 'count', '-C', '-o', 'output', '-s', '10000000', '-t', '3', "$theFastaFile", '-m', "$Kvalue");
system(@args) == 0 or die "system @args failed: $!";

@args = ($jellypath.' dump output_0 -c > jellyout.txt' );
system(@args) == 0 or die "system @args failed: $!";

open (INFILE, 'jellyout.txt') or die "Can't open jellyout.txt for reading. $!";
while ($line = <INFILE>) {
	chomp $line;
	@temp = split / /, $line;
	push( @kmers,[$temp[0], $temp[1]]);
	}
$numMers = scalar @kmers;
for (my $i = 0; $i < $numMers; $i++) {
	if ($kmers[$i][1] == 1) {
		$numUniqueKmers++;
		}
	}
if ($numUniqueKmers != 0 && $numMers) {
	$$fractionUniqueMers = $numUniqueKmers/$numMers;
	}else{
		$$fractionUniqueMers = 0
	}

close INFILE;
return @kmers;
}
#############################################################################
#called by Main
sub revcom
{
my $seq = $_[0];
my $revcom = '';

$revcom = reverse $seq;
$revcom =~ tr/ACGTacgt/TGCAtgca/;
return $revcom;

}
#############################################################################

#############################################################################
