#!/usr/bin/perl
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


use threads; #using threads for performance
use threads::shared;
#use warnings;
use Text::CSV_XS;
use File::Basename;

use Tk 800.000;

use Tk::Frame;
use Tk::TextUndo;
use Tk::Text;
use Tk::Scrollbar;
use Tk::Menu;
use Tk::Menubutton;
use Tk::Adjuster;
use Tk::DialogBox;





use strict;
use Tk::FileSelect;


my $mw = new MainWindow;
#$mw->geometry('1920x1050');

my $lf = $mw->Frame->pack(-fill => 'x'); # Left Frame;
my $aj = $mw->Adjuster(-widget => $lf, -side => 'left');
my $rf = $mw->Frame->pack(-fill => 'x'); # Right Frame;
my $frame0 = $mw->Frame->pack(-side => "left"); # Left Frame;
my $frame1 = $frame0->Frame->pack(-pady => '50'); # Left Frame;
my $frame2 = $frame0->Frame->pack(-pady => '50'); # Left Frame;



my $txt = $mw-> Scrolled('Text',-width => 80,-scrollbars=>'e') -> pack ();


my $mbar = $mw->Menu( );
my $file = $mbar -> cascade(-label=>"File", -underline=>0, -tearoff => 0);
my $others = $mbar -> cascade(-label =>"Others", -underline=>0, -tearoff => 0);
my $help = $mbar -> cascade(-label =>"Help", -underline=>0, -tearoff => 0);
$file -> command(-label =>"Exit", -underline => 1,
		 -command => sub { exit 0} );
## Others Menu ##
$others -> command(-label =>"LICENCE", -underline => 7,
		   -command => sub { $txt->insert('end',"This program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\n(at your option) any later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n");
		   });


$mw -> configure(-menu => $mbar);


$mw->Label(-text => 'MSSTAT')->pack;



my $Fsref = $mw->FileSelect(-directory => ".");


my @types =( ["CSV files", [qw/.csv/]],
	     ["All files", '*'],
    );



my $lref = "";
my $sref = "";
my $ldir = "";
my @batch :shared;

$rf->Button(-text => 'Save to ',
	    -command => sub{ $sref = $mw->getSaveFile(
				-filetypes =>  \@types ,
				-initialdir => '.',
				);
	    } )-> pack(-side => 'right');

$rf->Button(-text => 'Load',
	    -command => sub{ $lref = $mw->getOpenFile(
				-filetypes =>  \@types ,
				-initialdir => '.',
				);
	    } )-> pack(-side => 'right');

$rf->Button(-text => 'Load Batch',
	    -command => sub{ $ldir = $mw->chooseDirectory(
				 -initialdir => '.',
				 );
			     opendir(DirHandle, $ldir);
			     
			     foreach (readdir(DirHandle)) {
				 if ($_ =~ /.csv$/ ) {
				     push (@batch,$_);
				     $txt->insert('end',  "$_ added to batch\n");
				 }
			     }
			     closedir(DirHandle);
	    } )-> pack(-side => 'right');


my $var_rb;

my $rbutton1 = $lf -> Radiobutton(
    -text => 'da',
    -value => '-Da',
    -variable => \$var_rb
    ) -> pack(-side => 'left');

$rbutton1->select;


my $rbutton2 = $lf -> Radiobutton(
    -text => 'ppm',
    -value => '-ppm',
    -state => 'active',
    -variable => \$var_rb
    ) -> pack(-side => 'left');

$rbutton2->deselect;




$rf->Label(-text => "Enter error value",
		   -foreground => "blue")->pack(-side => "left");

my $error_entry = $rf -> Entry(-text => '1') -> pack(-side => 'left', -padx => '10');


$rf->Label(-text => "Enter nb spectra ",
		   -foreground => "blue")->pack(-side => "left");

my $spectra_entry = $rf -> Entry(-text => '3') -> pack(-side => 'left', -padx => '10');




my $var_from_langage;



$frame1->Label(-text => "FROM",
		   -foreground => "red")->pack();

my $from_l_rbutton1 = $frame1 -> Radiobutton(
    -text => 'US',
    -value => 'US',
    -variable => \$var_from_langage
    ) -> pack(-side => "right");

$from_l_rbutton1->select;


my $from_l_rbutton2 = $frame1 -> Radiobutton(
    -text => 'FR',
    -value => 'FR',
    -state => 'active',
    -variable => \$var_from_langage
    ) -> pack();

#$from_l_rbutton2->deselect();



$frame2->Label(-text => "TO", 
		   -foreground => "red")->pack();


my $var_to_langage;

my $to_l_rbutton1 = $frame2 -> Radiobutton(
    -text => 'US',
    -value => 'US',
    -variable => \$var_to_langage
    ) -> pack(-side => "right");

$to_l_rbutton1->select;


my $to_l_rbutton2 = $frame2 -> Radiobutton(
    -text => 'FR',
    -value => 'FR',
    -state => 'active',
    -variable => \$var_to_langage
    ) -> pack();

$to_l_rbutton2->deselect;





############### END OF GUI CODE ###################





sub extract_tabs  {
    my @T;
    my $i;
    my $j;
    my @args = @_;
    my $nb_lines = shift @args;
    my $from_language  = shift @args;
    my $nb_spectrum  = shift @args;
    my @fic = @args;

    my $csv = Text::CSV_XS->new();

    for ($i=0 ; $i<$nb_lines; $i++)
    {
	if ($from_language eq "FR")
	{
	    $fic[$i] =~ s/,/\./g;
	}
	$fic[$i] =~ s/;/,/g;
    }
    
    
    for($i=0; $i<$nb_lines; $i++)
    {
	$csv->parse ($fic[$i]);

	my @columns = $csv->fields();
	#print "@columns\n"; 
	for ($j=0; $j<$nb_spectrum; $j++)
	{
	    if ( $columns[2*$j] =~/\d+\.?\d*/)
	    {
		$T[$i][$j][0] = $columns[2*$j];
	    }
	    else{
		$T[$i][$j][0] = 9**9**9;	    
	    } 

	    if ( $columns[(2*$j)+1] =~/\d+\.?\d*/){
		$T[$i][$j][1] = $columns[2*$j+1];
	    }
	    else{
		$T[$i][$j][1] = 9**9**9;
	    } 
	    #print   "T -> $T[$i][$j][0]\n";
	    #print  "T -> $T[$i][$j][1]\n";

	}


    }
    return @T;    
}

sub get_min_from_line {
    my @tmp_line = @_;
    my $min = 9**9**9;
    my $id;
    #print "Search min in : @tmp_line\n"; 
    for ($id=0; $id<scalar @tmp_line; $id++)
    {
	if (defined $tmp_line[$id]) {
	    if ( $tmp_line[$id] =~/\d+\.?\d*/)
	    {
		if ($tmp_line[$id] < $min)
		{
		    $min = $tmp_line[$id];
		}
	    }
	}
    }
    #print "MIN: $min\n";
    return $min;
}

sub create_line { 
    my @line;
    foreach (@_){
	push @line , $_;
    }
    return @line
}


sub is_equal
{
    my @args = @_;
    my $to_test = $args[0];
    my $min = $args[1];
    my $error = $args[2];
    my $val_error = $args[3];

    if ($error eq "-ppm") { 
	my $ppm = $val_error;
	return ((defined $to_test) 
		&& (($to_test <= ($min + ($to_test/1000000*$ppm))) 
		    && ($to_test >= ($min - ($to_test/1000000*$ppm))))
		|| ($to_test==9**9**9))
    }
    else 
    {
	if ($error eq "-Da") 
	{ 
	    my $da = $val_error;
	    { 
		return ((defined $to_test) 
			&& ((($to_test <= ($min + $da )))
			    && ($to_test >= ($min - $da )))
			|| ($to_test==9**9**9))
	    }
	}
	else
	{
	    #print "ERROR : you must select an error type\n";

	}
    }
}

sub not_over {
    my @args = @_;
    my $nb_lines = shift @args ;
    my @paf = @args;
    foreach (@paf)
    {
	if ($_!=$nb_lines){
	    return (0==0);
	}
    }
    return (1==0);
}

sub main {
 
    my $file = @_[0];
    my $new_file  = @_[1];
    my $nb_spectrum  = @_[2];
    my $error  = @_[3];    
    my $val_error  = @_[4]; 
    my $from_language  = @_[5]; 
    my $to_language  = @_[6];
    
    
    my @T1;
    my @T2;
    my @T3;
    

    

    open(File, $file);
    open(File2, ">$new_file");
    
    use Math::BigInt;

    my @fic = <File>;
    my $line1 = shift @fic;
    my $line2 = shift @fic;
    my $nb_lines = scalar @fic;


    if (($file eq "")||( $file eq "-help")){
	#print "MS_STAT\n";
	#print "Mathias Bourgoin - 2010\n";
	#print "mathias.bourgoin\@gmail.com\n";
	#print "\nUsage:\n   perl ./ms_stat.pl [path to csv file] [path to new csv file] [nb of spectrums] [error type (-Da/-ppm)] [error value] [from language(FR)] [to language (fr)]\n";
	#print "perl ./ms_stat.pl -help will display this message\n";
	#print "perl ./ms_stat.pl -lic will display the licence\n\n";
	exit;
    }
    if ($file eq"-lic"){
	#print "This program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\n(at your option) any later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n";
	exit;
    }

    #print "-----> before $file\n";
    my @T = extract_tabs ($nb_lines, $from_language, $nb_spectrum, @fic);  

    my @index_in_spectrums;
    my $i=0;
    my $cur_spectrum = 0;
#initialisation of the spectum index table
    for ($cur_spectrum=0; $cur_spectrum<$nb_spectrum; $cur_spectrum++){
	$index_in_spectrums[$cur_spectrum]=0;
    }
    
    #looking for minimum value between non evaluated value in the spectrums
    #for($cul_file_line=0; $cur_file_line<$nb_lines; $cur_file_line++)
    #{
    print File2 "$line1";

    my $to_print="";
    for ($cur_spectrum=0; $cur_spectrum<$nb_spectrum; $cur_spectrum++){
    	$to_print="$to_print Mass";
    	$to_print="$to_print Intensity";
    }
    $to_print="$to_print,  Mavg Iavg Istd Istd(%)";
    $to_print =~ s/^ //g;
    if ($to_language eq "FR")
    {
    	$to_print =~ s/\./,/g;
    	$to_print =~ s/\ /;/g;
    }else{
    	$to_print =~ s/\ /,/g;
    }
    print File2 "$to_print\n";

   while (not_over ($nb_lines, @index_in_spectrums)){
	my @line2 = ();
	for ($cur_spectrum=0; $cur_spectrum<$nb_spectrum; $cur_spectrum++)
	{
	    push @line2, $T[$index_in_spectrums[$cur_spectrum]][$cur_spectrum][0];
	}

	my $min = &get_min_from_line (@line2);

	#creating a line with every value coresponding 
	#to the minimum value previously found
	my @new_line;
	my $nb_good_spectrums=0;
	my $moy_abs=0;
	my $moy_ord=0;
	my $deviation=0;
	my $deviation_percent=0;
	
	for ($cur_spectrum=0; $cur_spectrum<$nb_spectrum; $cur_spectrum++){
	    if (&is_equal ($T[$index_in_spectrums[$cur_spectrum]][$cur_spectrum][0], $min, $error, $val_error))
	    {
		$new_line[2*$cur_spectrum]=$T[$index_in_spectrums[$cur_spectrum]][$cur_spectrum][0];
		$new_line[2*$cur_spectrum+1]=$T[$index_in_spectrums[$cur_spectrum]][$cur_spectrum][1];
		$moy_abs=$moy_abs+$T[$index_in_spectrums[$cur_spectrum]][$cur_spectrum][0];
		$moy_ord=$moy_ord+$T[$index_in_spectrums[$cur_spectrum]][$cur_spectrum][1];
		$index_in_spectrums[$cur_spectrum]++;	
		$nb_good_spectrums++;
	    }
	}
	$moy_abs=$moy_abs/$nb_good_spectrums;
	$moy_ord=$moy_ord/$nb_good_spectrums;
	
	for ($cur_spectrum=0; $cur_spectrum<$nb_spectrum; $cur_spectrum++){
	    if (defined($new_line[2*$cur_spectrum+1])){
		$deviation = $deviation + ($new_line[2*$cur_spectrum+1]-$moy_ord)**2;
	    }
	}

	if (($deviation/$nb_good_spectrums)> 0) {
	    $deviation=sqrt($deviation/$nb_good_spectrums);
	}
	else {
	    $deviation=0;
	}
	if ($nb_good_spectrums > 0){
	    $deviation_percent=0;}
	else{
	    $deviation_percent=$deviation/$moy_ord*100;}
	if ($nb_good_spectrums<2){
	    $deviation="False";
	    $deviation_percent="False";
	    
	}

#	print "$#T\n";
#	print "   $#{$T[i]}\n";
#	print "      $#{$T[i][0]}\n";
	$i++;
	
	$new_line[2*$nb_spectrum+2]=$moy_abs;
	$new_line[2*$nb_spectrum+3]=$moy_ord;
	$new_line[2*$nb_spectrum+4]=$deviation;
	$new_line[2*$nb_spectrum+5]=$deviation_percent;
	my $new_string = "@new_line";
	$new_string =~ s/1\.\#INF//g;
	$new_string =~ s/-1\.\#IND//g;
	if ($to_language eq "FR")
	{
	    $new_string =~ s/\./,/g;
	    $new_string =~ s/\ /;/g;
	}else{
	    $new_string =~ s/,/\./g;
	    $new_string =~ s/\ /,/g;
	}
	print File2 "$new_string\n";
    }   

    close(File);
    close(File2);
    
    
    return 0;
}

#&main ();
#get_min_from_line (@line);



use Time::HiRes;
use Benchmark qw(:hireswallclock);;

$mw->Label(-text => "nb_threads for batch conversion ",
		   -foreground => "blue")->pack(-side => "left");


my $nb_threads = $mw -> Entry(-text => '2',
			      -width => '10'
    ) -> pack(-side => 'left', -padx => '10');

$mw->Button(-text => 'Convert',
	    -background => 'gray',
	    -command => sub{
		my $error_val =  $error_entry->get();
		$txt->insert('end', "MS_Stat Will convert $lref in $sref using $var_rb $error_val from $var_from_langage CSV to $var_to_langage CSV\n");
		my @args = ($lref, $sref, 
		     ($spectra_entry->get()), $var_rb, 
		     ($error_entry->get()), $var_from_langage, 
		     $var_to_langage); 
		my $t0 = Benchmark->new();		
		main @args;
		my $t1 = Benchmark->new();
		my $td = timediff($t1, $t0);
		my $res = timestr($td);
		 $txt->insert('end', "conversion time was : $res\n");
	    } )->pack(-side => 'right', -pady => '10', -padx => '10');

$mw->Button(-text => 'Convert Batch',
	    -background => 'gray',
	    -command => sub{
		my $error_val =  $error_entry->get();
		foreach (@batch) {
		    my $j = 0;
		    my $i;
		    my @mthreads ;
		    my @finished_flags :shared;
		    my $nb_flags = 0;
		    for ($i=0; $i < ($nb_threads->get()); $i++)
		    {
			if (scalar @batch > $j){
			    $sref = basename($batch[$j],  ".csv");
			    $sref = $ldir."/".$sref."_ms_stat.csv";
			    $lref = $ldir."/".$batch[$j] ;
			    my @args = ($lref, $sref, 
					($spectra_entry->get()), $var_rb, 
					($error_entry->get()), $var_from_langage, 
					$var_to_langage); 
			    main @args;
			    $j = $j+1;
			    $nb_flags++;
			}
		    }
		    
		}
		$txt->insert('end', "Batch Conversion Completed\n");
	    } )->pack( -pady => '10', -padx => '10');
    

MainLoop;

