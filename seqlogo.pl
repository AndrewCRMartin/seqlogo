#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    seqlogo
#   File:       seqlogo.pl
#   
#   Version:    V1.1
#   Date:       14.06.13
#   Function:   Generate a sequence logo
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2013
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Institute of Structural and Molecular Biology
#               Division of Biosciences
#               University College
#               Gower Street
#               London
#               WC1E 6BT
#   EMail:      andrew@bioinf.org.uk
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#   Generate a sequence logo (in PNM or PostScript format) from a 
#   transfac or MEME format file. 
#
#*************************************************************************
#
#   Usage:
#   ======
#   Change $installDir below or copy seqlogo_ps.tpl to $DATADIR
#
#   See 
#      seqlogo -h 
#   for more usage info
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   11.06.13  Original
#   V1.1   14.06.13  Added calculation and display of mean conservation
#
#*************************************************************************
use strict;

# Change this if necessary
my $installDir = "$ENV{'HOME'}/scripts/seqlogo";

#*************************************************************************
# Help
UsageDie($::h) if(defined($::h));

# Read the Postscript template file
my $templateFile = "";
if(defined($ENV{'DATADIR'}) && -e "$ENV{'DATADIR'}/seqlogo_ps.tpl")
{
    $templateFile = "$ENV{'DATADIR'}/seqlogo_ps.tpl";
}
elsif(-e "$installDir/seqlogo_ps.tpl")
{
    $templateFile = "$installDir/seqlogo_ps.tpl";
}
$templateFile = $::t if(defined($::t));
if($templateFile eq "")
{
    die "You must specify the postscript template file";
}
my $template = ReadFile($templateFile);
my %templateText = ();

# Set the scale for stretching characters
$::scale = 5 if(!defined($::scale));
# Set the font
$templateText{'FONT'} = ((defined($::font))?$::font:"Helvetica");
# Set the font size
$templateText{'FONTSIZE'} = ((defined($::size))?$::size:30);
# Set the x position
$templateText{'XPOS'} = ((defined($::x))?$::x:36);
# Set the y position
$templateText{'YPOS'} = ((defined($::y))?$::y:36);
# Set the baseline thickness
$templateText{'BLWIDTH'} = ((defined($::b))?$::b:7);


# Read the PWM data file in Transfac or MEME format
my @data = ();
if(defined($::meme))
{
    @data = ReadMEME();
}
else
{
    @data = ReadTransfac();
}

# Calculate the height matrix from the conservation 
my @heights = CalcHeightMatrix(@data);

# Convert this to postscript
$templateText{'COMMANDS'} = BuildPostscript($::scale, @heights);

# Insert the postscript into the template
$template = ProcessTemplate($template, %templateText);

if(defined($::png))
{
    my $tfile = "/tmp/seqlogo_$$";
    $tfile .= time . ".ps";
    open(TFILE, ">$tfile") || die "Can't write $tfile";
    print TFILE $template;
    close TFILE;
    `(cd /tmp; pstopnm -dpi=300 $tfile)`;
    my $tfile2 = $tfile;
    $tfile2 =~ s/\.ps/001.ppm/;
    my $png = `(cd /tmp; pnmcrop $tfile2 | pnmscale 0.25 | pnmtopng)`;
    unlink $tfile;
    unlink $tfile2;
    print $png;
}
else
{
    print $template;
}


#*************************************************************************
# Generate the Postscript for drawing the actual logo for insertion into
# the template
#
sub BuildPostscript
{
    my($scale, @heights) = @_;

    my $ndata = scalar(@heights);

    my $ps = "/xp xpos def\n";  # Initialize X position

    for(my $i=0; $i<$ndata; $i++)
    {
        my $line = $heights[$i];
        if(!AllZero($line))
        {
            foreach my $key (reverse sort {$$line{$a} cmp $$line{$b}} keys %$line)
            {
                my $height = $$line{$key} * $scale;
                $height = "0.0000001" if($height == 0);
                $ps .= "($key) $height ";
            }
            $ps .= "xp ypos column\n";
        }
        else
        {
            $ps .= "xp width add /xmax exch def\n";
        }
        $ps .= "xp width add /xp exch def\n";
    }

    if(defined($::DEBUG))
    {
        my $extraPS = <<__EOF;
newpath
xpos ypos moveto
xmax ypos lineto
xmax ymax lineto
xpos ymax lineto
closepath
stroke
__EOF
        $ps .= $extraPS;
    }

    return($ps);
}


#*************************************************************************
# Checks whether all values in a hash reference are zero
sub AllZero
{
    my($line) = @_;

    foreach my $key (keys %$line)
    {
        return(0) if($$line{$key} != 0);
    }
    return(1);
}


#*************************************************************************
# Calculates the matrix of heights for the symbols based on the fraction
# of each symbol multiplied by the entropy-based conservation for the
# column. Data are stored in an array of hashes.
sub CalcHeightMatrix
{
    my(@data) = @_;
    my @heights = ();
    my $ndata = scalar(@data);
    my $meanConservation = 0.0;
    for(my $i=0; $i<$ndata; $i++)
    {
        my $line = $data[$i];
        my ($rseq, $count) = CalcEntropyConservation(%$line);
        $meanConservation += $rseq;

        if(defined($::DEBUG))
        {
            print STDERR "$i $rseq ";
            foreach my $key (keys %$line)
            {
                print STDERR "$key $$line{$key}; ";
            }
            print STDERR "\n";
        }

        foreach my $key (keys %$line)
        {
            $heights[$i]{$key} = $rseq * $$line{$key} / $count;
        }
    }
    if(defined($::v))
    {
        printf STDERR "Mean conservation: %.3f\n", ($meanConservation/$ndata);
    }
    return(@heights);
}


#*************************************************************************
# Calculates the entropy-based conservation for a distribution of symbols. 
# Also returns the number of observations.
sub CalcEntropyConservation
{
    my(%distribution) = @_;
    my $Smax = log2(scalar(keys(%distribution)));
    my $Sobs = 0;
    my $Nobs = 0;
    foreach my $key (keys(%distribution))
    {
        $Sobs += $distribution{$key} * log2($distribution{$key});
        $Nobs += $distribution{$key};
    }
    $Sobs /= $Nobs;
    $Sobs = log2($Nobs) - $Sobs;
    return(($Smax - $Sobs), $Nobs);
}


#*************************************************************************
# Calculates a log to the base 2. If a value of zero is supplied it 
# returns zero rather than infinity
sub log2
{
    my ($val) = @_;

    return(0) if ($val < 0.000000001);
    return(log($val) / log(2));
}


#*************************************************************************
# Prints the array-of-hashes data structure used for storing patterns
# Used for debugging only
sub PrintData
{
    my(@data) = @_;
    my $ndata = scalar(@data);
    for(my $i=0; $i<$ndata; $i++)
    {
        my $line = $data[$i];
        print STDERR "$i ";
        foreach my $key (keys %$line)
        {
            print STDERR "$key $$line{$key}; ";
        }
        print STDERR "\n";
    }
}


#*************************************************************************
# Reads a transfac format file into an array of hashes. The array is the
# positions in the pattern while the key to the hashes is the 4 bases or
# 20 amino acids
sub ReadTransfac
{
    my @data = ();
    my $id = "";
    my $bf = "";
    my @types = ();
    my $ntypes = 0;
    my $count = 0;

    while(<>)
    {
        chomp;
        s/^\s+//;               # Remove leading space
        s/\s+$//;               # Remove trailing space
        if(!/^\#/ && length)    # Not a comment
        {
            if(/^ID\s+(.*)/)    # ID line
            {
                $id = $1;
            }
            elsif(/^BF\s+(.*)/) # BF (species) line
            {
                $bf = $1;
            }
            elsif(/^P0\s*(.*)/) # P0 (fieldnames) line
            {
                @types = split(/\s+/, $1);
                $ntypes = scalar(@types);
            }
            elsif(/^XX/ || /^\/\//) # XX or // line
            {
                last;
            }
            else
            {
                my @fields = split;
                for(my $i=0; $i<$ntypes; $i++)
                {
                    $data[$count]{$types[$i]} = $fields[$i+1];
                }
                $count++;
            }
        }
    }
    return(@data);
}


#*************************************************************************
# Does simple template toolkit style template substitution
# The pattern [%KEY%] or [% KEY %] is substituted by the appropriate value
# with the same key from the supplied hash.
sub ProcessTemplate
{
    my($template, %templateText) = @_;
    foreach my $key (keys %templateText)
    {
        $template =~ s/\[\%\s*$key\s*\%\]/$templateText{$key}/g;
    }
    return($template);
}


#*************************************************************************
# Reads the complete contents of a file into a single variable
sub ReadFile
{
    my($filename) = @_;

    open(FILE, $filename) || die "Can't read $filename";
    my $content = "";
    while(<FILE>)
    {
        $content .= $_;
    }
    close FILE;
    return($content);
}


#*************************************************************************
# Reads a MEME format file into an array of hashes. The array is the
# positions in the pattern while the key to the hashes is the 4 bases or
# 20 amino acids
sub ReadMEME
{
    my @data = ();
    my @types = ();
    my $ntypes = 0;
    my $count = 0;
    my $inData = 0;

    while(<>)
    {
        chomp;
        s/^\s+//;               # Remove leading space
        s/\s+$//;               # Remove trailing space
        if(!/^\#/ && length)    # Not a comment
        {
            if(/^ALPHABET\s*?=\s*?(.*)/)
            {
                my $text = $1;
                $text =~ s/\s//g;
                @types = split(//,$text);
                $ntypes = scalar(@types);
            }
            elsif(/^letter-probability/)
            {
                $inData = 1;
            }
            elsif($inData)
            {
                my @fields = split;
                for(my $i=0; $i<$ntypes; $i++)
                {
                    $data[$count]{$types[$i]} = $fields[$i]; # * 10000;
                }
                $count++;
            }
        }
    }
    return(@data);
}


#*************************************************************************
sub UsageDie
{
    my($help) = @_;
    if($help eq "formats")
    {
        print <<__EOF;

TRANSFAC FORMAT:
================

ID any_old_name_for_motif_1
BF species_name_for_motif_1
P0      A      C      G      T
01      1      2      2      0      S
02      2      1      2      0      R
03      3      0      1      1      A
04      0      5      0      0      C
05      5      0      0      0      A
06      0      0      4      1      G
07      0      1      4      0      G
08      0      0      0      5      T
09      0      0      5      0      G
10      0      1      2      2      K
11      0      2      0      3      Y
12      1      0      3      1      G
XX
//

MEME FORMAT:
============

MEME version 4

ALPHABET=ACGT

Background letter frequencies


A 0.186360 C 0.313640 G 0.313640 T 0.186360


MOTIF   m3
letter-probability matrix: alength=4 w=10
0.1386  0.4242  0.2408  0.1964
0.0005  0.9985  0.0005  0.0005
0.0005  0.4361  0.3865  0.1769
0.0005  0.9985  0.0005  0.0005
0.0005  0.9985  0.0005  0.0005
0.0005  0.0005  0.9985  0.0005
0.0005  0.9985  0.0005  0.0005
0.0005  0.9985  0.0005  0.0005
0.0005  0.4415  0.3432  0.2148
0.0005  0.9985  0.0005  0.0005

__EOF
    }
    else
    {
        print <<__EOF;

seqlogo V1.1 (c) 2013 Dr. Andrew C.R. Martin, UCL

Usage: seqlogo [-png][-meme][-scale=scale][-size=fontsize][-x=x][-y=y][-v]
               [-font=f][-b-baseLineWidth][-t=templateFile][-DEBUG] > output

               -png   Output in PNG format instead of PostScript
               -meme  Read MEME format files instead of Transfac
               -scale Scaling of characters to set size of plot [$::scale]
               -size  Font size [$templateText{'FONTSIZE'}]
               -x     Specify x position of plot (PostScript) [$templateText{'XPOS'}]
               -y     Specify y position of plot (PostScript) [$templateText{'YPOS'}]
               -font  Postscript font [$templateText{'FONT'}]
               -b     Specify thickness of line along the base [$templateText{'BLWIDTH'}]
               -t     Postscript template file [Default: seqlogo_ps.tpl from directory 
                      specified by DATADIR environment variable if defined,
                      otherwise from $installDir]
               -v     Verbose - print mean conservation
               -DEBUG Various debugging information

A simple sequence logo program with minimal external dependencies. This will
generate PostScipt sequence logos on any system having Perl. PNG format requires
programs from the Netpbm package (pstopnm, pnmcrop, pnmscale, pnmtopng) and Ghostscript.
These should be installed on any Linux system.

For help on file formats, type
   seqlogo -h=formats

__EOF
    }

    exit 0;
}
