seqlogo V1.2
------------

A simple sequence logo program in Perl 

This is a simple sequence logo program with minimal external
dependencies.  It will generate PostScipt sequence logos on any system
having Perl. PNG format requires programs from the Netpbm package
(pstopnm, pnmcrop, pnmscale, pnmtopng) and Ghostscript.  These should
be installed on any Linux system.

Input is a Transfac or MEME format matrix file.

Installation is simply a matter of running the ./install.sh
script. This will place the script in ~/scripts and will create a
symbolic link in your ~/bin directory. The template file in
~/scripts/seqlogo

Alternatively, change the $installDir variable to point to the
directory where this is unpacked and put the file seqlogo_ps.tpl in a
directory pointed to by the environment variable DATADIR.

Then type
   seqlogo -h
for help.

