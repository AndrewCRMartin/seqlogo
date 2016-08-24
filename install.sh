PREFIX=$HOME
SCRIPTDIR=$PREFIX/scripts
TPLDIR=$SCRIPTDIR/seqlogo
BINDIR=$PREFIX/bin

mkdir -p $SCRIPTDIR
mkdir -p $TPLDIR
cp seqlogo.pl $SCRIPTDIR
cp seqlogo_ps.tpl $TPLDIR

(cd $BINDIR; ln -sf $SCRIPTDIR/seqlogo.pl seqlogo)

