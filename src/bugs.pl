# Tom White
# reads from bugs.src, writes to stdout

use strict;

my $empty = ",,,,,\n";

my %MD2abbr = (
	'R Barrows', 'rb',
	'J Cimino', 'jc',
	'G Hripcsak', 'gh',
	'R Jenders', 'rj',
	'J Starren', 'js',
	'all', 'all',
);
my %abbr2MD = (
	'rb', 'R Barrows', 
	'jc', 'J Cimino',
	'gh', 'G Hripcsak',
	'rj', 'R Jenders',
	'js', 'J Starren',
	'all', 'all',
	
);

my ($TD,$TITLE,$floor,$room,$bed,$bgcolor,$color,$mrn,$bug,$drug,$filename,$single);
my (@MD,@DRUG,@BUG,@MONTH,@FLOOR,@ROOM,@BED);
my (%Bugs,%tBug,%Mrn,%Drug,%minSens,%MIN_SENS);
my ($gMd,$gBug,$gMonth);

my $TABLE = "TABLE CELLPADDING='0' CELLSPACING='0'";


@MD = ('all','rb','jc','gh','rj','js');
@DRUG = ('all','gm','ts','e','cax','aug','cp','clin','tim','pitz','ak');	# drugs in ascending order from cheapest to most expensive
@BUG = ('all','pa','sa','sm','ab');
@MONTH = ('all','1','2','3','4','5');
@FLOOR = ('all','1','2','3','4','5','6','7','8','9','10');
@ROOM = ('all','1','2','3','4','5','6','7','8','9','10');
@BED = ('all','1','2');

my ($numer,$denom,$ratio);
my ($mrn,$month,$floor,$room,$bed,$md,@rest);
my ($bug,$profile,$prefix,$sens,$resis,@micro,@args,@prof,$bugs);
my ($drug,$sens0);
my (@profiles,@patients);
my ($ts,$tim,$pitz,$cax,$gm,$ak,$cp,$aug,$e,$clin);

#set MIN_SENS = some max value
for (my $floor=1;$floor<=10;++$floor) {
	for (my $room=1;$room<=10;++$room) {
		for (my $bed=1;$bed<=2;++$bed) {
			my $loc = "F$floor\R$room\B$bed";
			$MIN_SENS{$loc} = 10;	# a max value
		}
	}
}
my @SENSITIVITY_COLS = ('red','orange','yellow','white','white','white','white','white','white','white','white');

&parseSource;
&test;
&printByLoc;
&printByPt;
&printByMD;


sub parseSource {
	open (SRC,"bugs.src") or die "unable to open bugs.src";
	open (BYDRUG, ">bydrug.txt") or die "unable to open bydrug.txt";
	
	#print BYDRUG "mrn,month,floor,room,bed,md,bug,drug,sens,resis\n";
	while (<SRC>) {
		chomp;
		($mrn,$month,$floor,$room,$bed,$md,@rest) = split(/,/);
		$md = $MD2abbr{$md};
		$prefix = "$mrn,$month,$floor,$room,$bed,$md";
		
		@profiles = ();
		
		$bugs = 0;
		
		if (@rest) {
			while (@rest) {
				$bug = lc(shift(@rest));
				$profile = lc(shift(@rest));
#				@micro = ();
				$numer = $denom = 0;
				@prof = ();
				++$bugs;
				
				if ($profile) {
					@args = split(/[: ]/,$profile);
					while(@args) {
						$drug = shift(@args);
						$drug = 'ts' if ($drug eq 't/s');
						$sens0 = shift(@args);
						++$numer if ($sens0 eq 's');
						++$denom if ($sens0 ne '-');
						$sens = ($sens0 eq '-') ? '' : (($sens0 eq 's') ? 1 : 0);
						$resis = ($sens0 eq '-') ? '' : (($sens0 eq 's') ? 0 : 1);
#						push @micro, ",$bug,$drug,$sens,$resis,";
						push @prof, ($drug, $sens);
					}
#					$ratio = $numer / $denom;
#					foreach (@micro) {
#						print BYDRUG $prefix, $_, $numer, "\n";
#					}
					
					push @profiles, ( $bugs, { ('bug',$bug,'numer',$numer,'denom',$denom,@prof) } );
				}
				else {
#					print BYDRUG $prefix, $empty;
				}
			}
		}
		else {
#			print BYDRUG $prefix, $empty;
		}
		
		push @patients, &parsePatient;
	}
	
	close SRC;
	close BYDRUG;	
}

sub test {
	open (BYDRUG, ">bydrug.txt") or die "unable to open bydrug.txt";
	print BYDRUG "mrn,month,floor,room,bed,md,bugs,bug,sens,denom,ts,tim,pitz,cax,gm,ak,cp,e,clin,aug\n";
	
	my %b;
	
	foreach (@patients) {
		my %p = %{ $_ };
		my %profs = %{ $p{'profiles'} };
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			%b = %{ $profs{$i} };
			print BYDRUG "$p{'mrn'},$p{'month'},$p{'floor'},$p{'room'},$p{'bed'},$p{'md'},$p{'bugs'}";
			print BYDRUG ",$b{'bug'},$b{'numer'},$b{'denom'},$b{'ts'},$b{'tim'},$b{'pitz'},$b{'cax'},$b{'gm'},$b{'ak'},$b{'cp'},$b{'e'},$b{'clin'},$b{'aug'}\n";
		}
		if ($p{'bugs'} == 0) {
			print BYDRUG "$p{'mrn'},$p{'month'},$p{'floor'},$p{'room'},$p{'bed'},$p{'md'},$p{'bugs'}";
			print BYDRUG ",,,,,,,,,,,,,\n";
		}
	}
	
	close BYDRUG;
}

sub parsePatient {
	return {
		mrn => $mrn,
		month => $month,
		floor => $floor,
		room => $room,
		bed => $bed,
		md => $md,
		bugs => $bugs,
		profiles => { @profiles },
	};
}

sub printByLoc {
	my $tWidth = "WIDTH='750'";
	my $msg;
	
	for (my $cMd=0;$cMd<=$#MD;++$cMd) {
		$gMd = $MD[$cMd];
		for (my $cBug=0;$cBug<=$#BUG;++$cBug) {
			$gBug = $BUG[$cBug];
			for (my $cMonth=0;$cMonth<=$#MONTH;++$cMonth) {
				$gMonth = $MONTH[$cMonth];

				$filename = "../bugs/loc_$gMd\_$gBug\_$gMonth.htm";
				open (OUT, ">$filename") or die "unable to open $filename";
				
				&preamble;
				
				if ($gMonth eq 'all') {
					$msg = "<B>Number and Severity of Infections by Location</B><BR>";
				}
				else {
					$msg = "<B>Patient MRN, Bugs, and Severity by Location</B><BR>";
				}
				if ($gMd eq 'all') {
					$msg .= "All MDs, "
				}
				else {
					$msg .= "MD=<B>$abbr2MD{$gMd}</B>, ";
				}
				if ($gMonth eq 'all') {
					$msg .= "All Months, ";
				}
				else {
					$msg .= "Month=<B>$gMonth</B>, ";
				}
				if ($gBug eq 'all') {
					$msg .= "All Bugs";
				}
				else {
					$msg .= "Bug=<B>$gBug</B>";
				}
				
				print OUT qq|<$TABLE BORDER='0' $tWidth><TR><TD align='center'>$msg</TD></TR></TABLE>\n|;
							
				
				my ($leftfile,$leftstr,$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "loc_$MD[$cMd-1]_$gBug\_$gMonth.htm"	if ($cMd > 0);
				$leftstr = "MD=$abbr2MD{$MD[$cMd-1]}"	if ($cMd > 0);
				$rightfile = "loc_$MD[$cMd+1]_$gBug\_$gMonth.htm"	if ($cMd < $#MD);
				$rightstr = "MD=$abbr2MD{$MD[$cMd+1]}"	if ($cMd < $#MD);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "loc_$gMd\_$gBug\_$MONTH[$cMonth-1].htm"	if ($cMonth > 0);
				$leftstr = "month=$MONTH[$cMonth-1]"	if ($cMonth > 0);
				$rightfile = "loc_$gMd\_$gBug\_$MONTH[$cMonth+1].htm"	if ($cMonth < $#MONTH);
				$rightstr = "month=$MONTH[$cMonth+1]"	if ($cMonth < $#MONTH);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "loc_$gMd\_$BUG[$cBug-1]_$gMonth.htm"	if ($cBug > 0);
				$leftstr = "bug=$BUG[$cBug-1]"	if ($cBug > 0);
				$rightfile = "loc_$gMd\_$BUG[$cBug+1]_$gMonth.htm"	if ($cBug < $#BUG);
				$rightstr = "bug=$BUG[$cBug+1]"	if ($cBug < $#BUG);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,$rightfile,$rightstr);						
				
				
				print OUT qq|<$TABLE BORDER='1'>\n|;
				
				$single = !($gMonth eq 'all');
				%Mrn = ();
				%Drug = ();
				%tBug = ();
				%Bugs = ();
				%minSens = %MIN_SENS;	# reset to maximal value
				&calcSingle	if $single;
				&calcMultiple;
				&locTableBody;
				&locTableEnd;
				
				
				# print legend
				
				if ($gMonth eq 'all') {
					print OUT qq|<P><$TABLE BORDER='1' $tWidth>\n|;
					print OUT qq|<TR><TD align='center' COLSPAN='5'><B>Legend</B></TD></TR>\n|;
					print OUT qq|<TR><TD>Number of infections</TD><TD COLSPAN='4'>The number and background color of each cell:  The lighter the grey, the more infections in that room</TD></TR>\n|;
					print OUT qq|<TR><TD ROWSPAN='2'>Severity</TD><TD  COLSPAN='4'>The color of the number in each cell shows how many antibiotics (AB)s can treat the infection:</TD></TR>\n|;
					print OUT qq|<TR><TD BGCOLOR='black'><FONT size='4' color='red'><B>Resistant to all ABs</B></FONT></TD>\n|;
					print OUT qq|<TD BGCOLOR='black'><FONT size='4' color='orange'><B>Sensitive to 1 AB</B></FONT></TD>\n|;
					print OUT qq|<TD BGCOLOR='black'><FONT size='4' color='yellow'><B>Sensitive to 2 ABs</B></FONT></TD>\n|;
					print OUT qq|<TD BGCOLOR='black'><FONT size='4' color='white'><B>Sensitive to >2 ABs</B></FONT></TD></TR>\n|;
					print OUT qq|</TABLE>\n|;
				}
				else {
					print OUT qq|<P><$TABLE BORDER='1' $tWidth>\n|;
					print OUT qq|<TR><TD align='center' COLSPAN='5'><B>Legend</B></TD></TR>\n|;
					print OUT qq|<TR><TD>MRN</TD><TD COLSPAN='4'>The hyperlinked number at the top of each cell</TD></TR>\n|;
					print OUT qq|<TR><TD>Bugs</TD><TD  COLSPAN='4'>The comma separated list of abbreviations at the bottom of each cell</TD></TR>\n|;
					print OUT qq|<TR><TD ROWSPAN='2'>Severity</TD><TD  COLSPAN='4'>The cell's color shows how many antibiotics (AB)s can treat the infection</TD></TR>\n|;
					print OUT qq|<TR><TD BGCOLOR='red'>Resistant to all ABs</TD><TD BGCOLOR='orange'>Sensitive to 1 AB</TD><TD BGCOLOR='yellow'>Sensitive to 2 ABs</TD><TD BGCOLOR='white'>Sensitive to >2 ABs</TD></TR>\n|;
					print OUT qq|</TABLE>\n|;					
				}
				
				

				
				&epilogue;				
				
				close (OUT);
			}
		}
	}
}

sub printByPt {
	my $TD = " width='50' align='center'";
	my $tWidth = " WIDTH='450'";
	
	for (my $count=0;$count<=$#patients;++$count) {
		my %p = %{ $patients[$count] };
		my (%b,$loc);

		$filename = "../bugs/pt$p{'mrn'}.htm";
		open (OUT, ">$filename") or die "unable to open $filename";
		
		&preamble;
		
		my ($leftfile,$leftstr,$rightfile,$rightstr);
		$leftstr = $count-1	if ($count > 0);
		$leftfile = "pt$leftstr.htm"	if ($count > 0);
		$rightstr = $count+1	if ($count < $#patients);
		$rightfile = "pt$rightstr.htm"	if ($count < $#patients);
				
		my $arrows = &makeArrows($tWidth,$leftfile,$leftstr,$rightfile,$rightstr);

		print OUT qq|<$TABLE BORDER='0' $tWidth><TR><TD align='center'>Patient <B>$p{'mrn'}</B></TD></TR></TABLE>\n|;
		
		print OUT $arrows;
		
		print OUT qq|<$TABLE BORDER='1' $tWidth>\n|;
		print OUT qq|	<TR><TD WIDTH='50'>MD</TD><TD><B><A HREF='md_$p{'md'}.htm'>$abbr2MD{$p{'md'}}</A></B></TD></TR>\n|;
		print OUT qq|	<TR><TD WIDTH='50'>Where</TD><TD><B>Floor $p{'floor'}, Room $p{'room'}, Bed $p{'bed'}</B></TD></TR>\n|;
		print OUT qq|	<TR><TD WIDTH='50'>Month</TD><TD><B><A HREF='loc_$p{'md'}_all_$p{'month'}.htm'>$p{'month'}</A></B></TD></TR>\n|;
		print OUT qq|</TABLE>\n|;
			
		print OUT qq|<$TABLE BORDER='1' $tWidth>\n|;
		print OUT qq|<TR><TD $TD>Bug</TD>|;
		
		foreach (@DRUG) {
			next	if ($_ eq 'all');
			print OUT qq|<TD $TD>$_</TD>|;
		}
		print OUT qq|</TR>\n|;
		
		my %profs = %{ $p{'profiles'} };
		my ($sens,$label,$BG);
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			my %b = %{ $profs{$i} };
			
			print OUT "<TR><TD $TD><B>" . uc($b{'bug'}) . "</B></TD>";
			
			foreach (@DRUG) {
				next if ($_ eq 'all');
				$sens = $b{$_};
				if ($sens eq '0') {
					$label = 'R';
					$BG = '';
				}
				elsif ($sens eq '1') {
					$label = 'S';
					$BG = " BGCOLOR='lightgreen'";
				}
				else {
					$label = '&nbsp';
					$BG =  '';
				}
				
				print OUT qq|<TD $TD $BG><B>$label</B></TD>|;
			}
			print OUT qq|</TR>\n|;
		}
				
		print OUT qq|</TABLE>\n|;
		
		&epilogue;		
		
		close (OUT);
	}
}

sub makeArrows {
	my ($width,$prefile,$prestr,$postfile,$poststr,$msg);
	($width,$prefile,$prestr,$postfile,$poststr) = @_;
	
	$msg = qq|<$TABLE BORDER='0' $width><TR><TD align='left'><A HREF='$prefile'>$prestr</A></TD><TD align='right'><A HREF='$postfile'>$poststr</A></TD></TR></TABLE>\n|;
	return $msg;
}


sub printByMD {
	my $TD = "TD align='center' valign='top'";
	my $msg;
	my $tWidth = " WIDTH='400'";
	
	for (my $count=0;$count<=$#MD;++$count) {
		
		next if ($MD[$count] eq 'all');
		$gMd = $MD[$count];
		
		$filename = "../bugs/md_$gMd.htm";
		open (OUT, ">$filename") or die "unable to open $filename";
		
		&preamble;
		
		my ($leftfile,$leftstr,$rightfile,$rightstr);
		$leftfile = "md_$MD[$count-1].htm"	if ($count > 1);
		$leftstr = $abbr2MD{$MD[$count-1]}	if ($count > 1);
		$rightfile = "md_$MD[$count+1].htm"	if ($count < $#MD);
		$rightstr = $abbr2MD{$MD[$count+1]}	if ($count < $#MD);
		
	
		print OUT qq|<$TABLE BORDER='0' $tWidth><TR><TD align='center'>All Patients for <B>$abbr2MD{$gMd}</B></TD></TR></TABLE>\n|;
		
		my $arrows = &makeArrows($tWidth,$leftfile,$leftstr,$rightfile,$rightstr);
		
		print OUT $arrows;
		print OUT qq|<$TABLE BORDER='1' $tWidth>\n|;
		print OUT qq|	<TR><$TD>Month</TD><$TD>MRN</TD><$TD>Floor</TD><$TD>Room</TD><$TD>Bed</TD><$TD><B>Bug:</B> Sensitivity Profile<BR><FONT color='#00dd00'><B>Green</B></FONT>=Sensitive, <FONT color='#aa0000'><B>Red</B></FONT>=Resistant</TD></TR>|;
		
		foreach (@patients) {
			my %p = %{ $_ };
			
			next unless ($p{'md'} eq $gMd);
			
			print OUT qq|	<TR><$TD><A HREF='loc_$gMd\_all_$p{'month'}.htm'>$p{'month'}</A></TD><$TD><A HREF='pt$p{'mrn'}.htm'>$p{'mrn'}</A></TD><$TD>$p{'floor'}</TD><$TD>$p{'room'}</TD><$TD>$p{'bed'}</TD>|;

			my %profs = %{ $p{'profiles'} };
			
			print OUT qq|<TD><FONT FACE='Arial'><B>|;
			
			if ($p{'bugs'} == 0) {
				print OUT '&nbsp;';
			}
			
			for (my $i=1;$i<=$p{'bugs'};++$i) {
				my %b = %{ $profs{$i} };
				
				if ($i > 1) {
					print OUT '<BR>';
				}
				$msg = uc($b{'bug'});
				print OUT qq|$msg:&nbsp;|;
				
				foreach (@DRUG) {
					next if ($_ eq 'all');
					$sens = $b{$_};
					if ($sens eq '0') {
						print OUT qq|&nbsp;<FONT COLOR='#aa0000'>$_</FONT>|;
					}
					elsif ($sens eq '1') {
#						$msg = uc($_);
						$msg = $_;
						print OUT qq|&nbsp;<FONT COLOR='#00dd00'>$msg</FONT>|;
					}
					else {
						print OUT qq|&nbsp;<FONT COLOR='#dddddd'>$_</FONT>|;
					}
				}
			}
			print OUT qq|</B></FONT></TD></TR>\n|;
		}
		print OUT qq|</TABLE>\n|;
		print OUT $arrows;
	
		&epilogue;		
		close (OUT);	
	}
}



sub calcSingle {
	foreach (@patients) {
		my %p = %{ $_ };
		my (%b,$loc,$drugs);
		next unless ($gMonth eq 'all' || $p{'month'} eq $gMonth);
		next unless ($gMd eq 'all' || $p{'md'} eq $gMd);
		
		$loc = "F$p{'floor'}R$p{'room'}B$p{'bed'}";
		
		$Mrn{$loc} = ($p{'mrn'} + 1);	# so that can check for nulls (same as 0, which is valid mrn)
		
		my %profs = %{ $p{'profiles'} };
#		my %rx = ();
		my $bugs = '';
		
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			%b = %{ $profs{$i} };
			
			next unless ($gBug eq 'all' || $b{'bug'} eq $gBug);
			
			$bugs .= ($bugs ? ',' : '') . $b{'bug'};
		}
		
		$Bugs{$loc} = $bugs;
#		$Drug{$loc} = $drugs;
	}		
}


sub calcMultiple {
	foreach (@patients) {
		my %p = %{ $_ };
		my (%b,$loc);
#		print BYDRUG "$p{'mrn'},$p{'month'},$p{'floor'},$p{'room'},$p{'bed'},$p{'md'},$p{'bugs'}";
		next unless ($gMonth eq 'all' || $p{'month'} eq $gMonth);
		next unless ($gMd eq 'all' || $p{'md'} eq $gMd);
		
		$loc = "F$p{'floor'}R$p{'room'}B$p{'bed'}";
		
		my %profs = %{ $p{'profiles'} };
		
		my $min = $minSens{$loc};
		
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			%b = %{ $profs{$i} };
			
			next unless ($gBug eq 'all' || $b{'bug'} eq $gBug);
			
			++$tBug{$loc};
			$min = $b{'numer'}	if ($b{'numer'} < $min);
		}
		$minSens{$loc} = $min;
	}	
}



sub locTableBody {
	my $TD = "TD width='35' height='35' align='center' valign='top'";
	
	for ($floor=10;$floor>=1;--$floor) {
		print OUT qq|	<TR>\n|;
		
		if ($floor == 10) {
			print OUT qq|		<TD ROWSPAN='10'><B>F<BR>L<BR>O<BR>O<BR>R</B></TD>\n|;
		}
		
		print OUT qq|		<TD ALIGN='center'><B>$floor</B></TD>\n|;
		
		for ($room=1;$room<=10;++$room) {
			for ($bed=1;$bed<=2;++$bed) {
				my $loc = "F$floor\R$room\B$bed";
				my $msg;
				my ($BG,$COL);
				my ($ratio,$ratioStr,$ratioCol,$bug,$min,$total);
				
				#color code based upon sensitivity
				#the lower the value for $minSens, the more resistant - worst bug of bunch
				$min = $minSens{$loc};
				$total = $tBug{$loc};
				$mrn = $Mrn{$loc} - 1;
				
				if ($total) {
					$ratioCol = $SENSITIVITY_COLS[$min];
					$msg .= "<BR>$min";
					$BG = "BGCOLOR='$ratioCol'"	if ($ratioCol);
				}
				
				if ($single) {
					$msg = "<A href='pt$mrn.htm'>$mrn</A>"	if ($Mrn{$loc});

					if ($total) {
						$msg .= "<BR>$Bugs{$loc}";
					}
				}
				else {
					if ($total) {
						$msg = "<FONT SIZE='4' COLOR='$ratioCol'><B>$total</B></FONT>";
						$ratioCol = &rgb($total/12,$total/12,$total/12);
						$BG = "BGCOLOR='$ratioCol'";
					}
				}
				
				$msg = '&nbsp;'	unless $msg;
				print OUT qq|		<$TD $BG><FONT $COL>$msg</FONT></TD>\n|;
				
			}
		}
		print OUT qq|	</TR>\n|;
	}
}

sub rgb {
	# expects rgb as percents
	my ($r,$g,$b,$ans);
	$r = shift;
	$g = shift;
	$b = shift;
	
	$ans = sprintf '#%02x%02x%02x', (($r * 255) % 256), (($g * 255) % 256), (($b * 255) % 256);
	
	return $ans;
}
	

sub preamble {
	print OUT qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">\n|;
	print OUT qq|<HTML>\n|;
	print OUT qq|<HEAD>\n|;
	print OUT qq|	<META HTTP-EQUIV="Content-Type" CONTENT="text/html;CHARSET=iso-8859-1">\n|;
	print OUT qq|	<TITLE>$TITLE</TITLE>\n|;
	print OUT qq|</HEAD>\n|;
	print OUT qq|<BODY>\n|;	
}

sub epilogue {
	print OUT qq|</TABLE>\n|;
	print OUT qq|</BODY>\n|;
	print OUT qq|</HTML>\n|;
}

sub locTableEnd {
	print OUT qq|	<TR>\n|;
	print OUT qq|		<TD ROWSPAN='3' COLSPAN='2'>&nbsp;</TD>\n|;
	
	for ($room=1;$room<=10;++$room) {
		for ($bed=1;$bed<=2;++$bed) {
			my $val = ($bed==1) ? 'a' : 'b';
			print OUT qq|		<TD ALIGN='center'><B>$val</B></TD>\n|;
		}
	}
	print OUT qq|	</TR>\n|;
	for ($room=1;$room<=10;++$room) {
		print OUT qq|		<TD COLSPAN='2' ALIGN='center'><B>$room</B></TD>\n|;
	}
	print OUT qq|	</TR>\n|;
	print OUT qq|	<TR>\n|;
	print OUT qq|		<TD COLSPAN='20' ALIGN='center'><B>ROOM/BED</B></TD>\n|;
	print OUT qq|	</TR>\n|;
	print OUT qq|</TABLE>\n|;
}


