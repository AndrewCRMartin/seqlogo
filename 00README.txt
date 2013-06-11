seqlogo V1.0 
------------

This is a simple sequence logo program with minimal external
dependencies.  It will generate PostScipt sequence logos on any system
having Perl. PNG format requires programs from the Netpbm package
(pstopnm, pnmcrop, pnmscale, pnmtopng) and Ghostscript.  These should
be installed on any Linux system.

Input is a Transfac or MEME format matrix file.

Installation is simply a matter of either editing the Perl script to
change the $installDir variable to point to the directory where this
is unpacked or putting the file seqlogo_ps.tpl in a directory pointed
to by the environment variable DATADIR.

Once you've done that, create a symbolic link from the Perl script to
somewhere in your path.

Then type
   seqlogo -h
for help.

