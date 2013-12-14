#!/usr/bin/perl -w

# create a directory tree
sub create($$){
    my ($base,$max) = @_;
    my $s = "(:)";
    for(my $i=1;$i<=$max;$i++){
        for(my $j=1;$j<=$max;$j++){
            for(my $k=1;$k<=$max;$k++){
                for(my $l=1;$l<=$max;$l++){
                    my $m = "$base/${base}dir$i/${base}dir${i}_${j}/${base}dir${i}_${j}_${k}";
                    #print `mkdir -p $m && cp file.jpg $m/file${base}_${i}_${j}_${k}_${l}.jpg`;
                    $s = "$s && mkdir -p $m && cp file.jpg $m/file${base}_${i}_${j}_${k}_${l}.jpg";
                }
            }
        }
    }
 #   print $s;
 print `$s`;
}

sub check($$){
    my ($r,$hash) = @_;
    $r =~ s/Elapsed time .*begining/<time>/g;
    my $hex = sha1_hex($r);
    if ($hex eq $hash) {
        print "[OK]\n"; }
    else {print "[FAILED!]\n$hex\n";
    }
}

`rm -rf r1 r1_copy r2 r3 r4 tmp`;

use Digest::SHA qw(sha1_hex); 

print "Single basic run";
&create("r1",3);
$r = `cd r1 ; time (../../index > /dev/null) ; ls -Rs | tee ../test1.txt`;
&check($r,"72509c08a2e68d9a50804cf5a3294c6fbad06432");
$r = `cd r1 ; ../../index -n > /dev/null ; ls -Rs`;
&check($r,"72509c08a2e68d9a50804cf5a3294c6fbad06432");

`mkdir -p tmp/ref1; cp -rp r1/ tmp/ref1/`;
print "Single basic run with relative path : r1";
`rm -rf r1`;
&create("r1",3);
$r = `time (../index r1 > /dev/null); diff -r r1 tmp/ref1/r1 | tee test1rel.txt`;
&check($r,"da39a3ee5e6b4b0d3255bfef95601890afd80709");
$r = `(../index -n r1 > /dev/null); diff -r r1 tmp/ref1/r1 | tee test1rel.txt`;
&check($r,"da39a3ee5e6b4b0d3255bfef95601890afd80709");

print "Single basic run with relative path : ./r1";
`rm -rf r1`;
&create("r1",3);
$r = `time (../index ./r1 > /dev/null); diff -r r1 tmp/ref1/r1 |tee test1rel2.txt`;
&check($r,"da39a3ee5e6b4b0d3255bfef95601890afd80709");
$r = `time (../index -n ./r1 > /dev/null); diff -r r1 tmp/ref1/r1 |tee test1rel2.txt`;
&check($r,"da39a3ee5e6b4b0d3255bfef95601890afd80709");

print "Single basic run with absolute path path: ";
`rm -rf r1`;
&create("r1",3);
my $pwd = `pwd`; print "$pwd/r1";
$r = `time (../index \`pwd\`/r1 > ../test1abs.txt); diff -r r1 tmp/ref1/r1`;
&check($r,"da39a3ee5e6b4b0d3255bfef95601890afd80709");
$r = `time (../index -n \`pwd\`/r1 > ../test1abs.txt); diff -r r1 tmp/ref1/r1`;
&check($r,"da39a3ee5e6b4b0d3255bfef95601890afd80709");

print "Check that running 2 times on the same dir, nothing change, except list ";
`cp -rp r1/ r1_copy/`; 
`cd r1_copy/; time ../../index -n`;
$r = `diff -r r1_copy r1 | tee test2a.txt`;
&check($r, "da39a3ee5e6b4b0d3255bfef95601890afd80709");
`cd r1_copy/; time ../../index`;
$r = `diff -r r1_copy r1 | tee test2b.txt`;
&check($r, "04088a404ecd140258b1cfc1ccb1fe766cda93a7");

print "Complete recopy checking\n";
`mkdir r2; cp -rp r1/list/* r2/ ; cd r2/; time ../../index`;
#list is different in the second case, the 2nd path is added, that why list is excuded in the diff
$r = `diff -r -x list r1 r2 | tee test3.txt`; 
&check($r, "da39a3ee5e6b4b0d3255bfef95601890afd80709");

print "Add external index into a list, nothing bad should happen, no copy";
&create("r2",3);
`cd r2 ; ../../index`;
`cp -rp r1/list r2/list/r1`;
`cd r2 ; ../../index -n; export OCAMLPARAM=b; time ../../index --trace`;
$r = `ls -R r2/ | tee test4.txt`;
&check($r, "f20c0acc7adcf3eddec0c49448109dab1af01e36");

print "Check the behavior of copy, and tentative of copy\n";
&create("r3",3);
&create("r4",3);
`cd r3 ; ../../index;`;
`cd r4 ; ../../index;`;
`mkdir -p r2/r3; cp -rp r3/list/* r2/r3`;
`mkdir -p r2/r4; cp -rp r4/list/* r2/r4`;
`rm -rf r3`;
`cd r2 ; ../../index -n ;time ../../index | tee ../test5.txt`;
$r = `ls -R r2`;
&check($r, "9bcfd016fb8304973a0f09db5c9604fc16607281");
