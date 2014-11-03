while(<>){
    if ( /let version = ([0-9]*)/ ) {
	my $version = $1 + 1;
	print "let version = $version\n";
    } else {
	print;
    }
}
