#!/usr/bin/env python
# -*- coding: utf-8 -*-

# usage: python snp_comparator.py comma separated list of SNP formatted files
import sys
from collections import Counter

def readfiles(files):
    all_files = []
    for f in files:
        with open(f,"r") as f:
            all_files.append(f.readlines())
    return all_files

def find_SNPs_in_same_position(files):
    comparisons = len(files)-1

    SNPs_same_position = []
    SNPs_same_position_and_file = []

    if len(files)>2:
        #multiple loop
        print "doh"
    else:
        for lines in files[0]:
            for lines2 in files[1]:
                l1 = lines.split("\t")
                l2 = lines2.split("\t")
                if  int(l1[1]) == int(l2[1]):
                    print "success1"
                    SNPs_same_position.append(l1[0])
                    SNPs_same_position.append(l2[0])
                    if l1[0] == l2[0]:
                        print "double success"
                        SNPs_same_position_and_file.append(l1[0])
                        SNPs_same_position_and_file.append(l2[0])
                elif int(l1[1]) > int(l2[1]):
                    break
    return (SNPs_same_position, SNPs_same_position_and_file)



def compare_snps(SNP_files):
    #files = SNP_files.split(",")
    files = SNP_files


    numfiles = len(files)

    if numfiles <= 1:
        sys.stderr.write("snp_comparator requires a minimum of 2 formatted SNP lists with their respective position and file name")
        exit(1)

    snp_lists_files = readfiles(files)

    SNPs_loci, SNPs_loci_filename = find_SNPs_in_same_position(snp_lists_files)


    #SNPSs in total     #total number of snps per tool = len(all_files[0]), len(all_files[1]) ... len(all_files[x])

    SNPs_per_genome = []
    for f in snp_lists_files:

        f = Counter(map(lambda x: x.split("\t")[0], f)) # dict response, should consider this on the count of position as well
        print f
        for a,b in f.items():
            print a,b


    #collections.counter can easily find how many snps occur at one position, however not so relevant in comparison


    #snps per genome

    #snps with same loci



     #total number of snps per tool = len(all_files[0]), len(all_files[1]) ... len(all_files[x])

    #number_of_SNPs_per_genome()

    #number_of_SNPs_in_total()

    #also mention files not present in one of the TOOLs, typically parsnp due to "core-genome"


    # should consider sorting by filename and then position however may be harder to find SNP relation

if __name__ == '__main__':
    print sys.argv
    #galaxy mode:
    #sys.argv[1].split(",")
    compare_snps(sys.argv[1:]) #TODO: change 1: to only 1 when production ready
