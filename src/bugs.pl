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

my %abbr2BUG = (
	'ab', 'Acinetobacter&nbsp;B.<BR>(ab)',
	'pa', 'Pseudomonas&nbsp;A.<BR>(pa)',
	'sa', 'Staph&nbsp;Aureus<BR>(sa)',
	'sm', 'Serratia&nbsp;Marc.<BR>(sm)',
	'all', 'Average',
);

my %abbr2DRUG = (
	'gm',	'Gentamicin&nbsp;(gm)',
	'ts', 'Bactrim&nbsp;(ts)',
	'tim', 'Timentin&nbsp;(tim)',
	'pitz', 'Zosyn&nbsp;(pitz)',
	'cax', 'Ceftriaxone&nbsp;(cax)',
	'ak', 'Amikacin&nbsp;(ak)',
	'cp', 'Ciprofloxacin&nbsp;(cip)',
	'aug', 'Augmentin&nbsp;(aug)',
	'e', 'Erythromycin&nbsp;(e)',
	'clin', 'Clindamycin&nbsp;(clin)',
	'all', 'Average',
);

my ($TD,$TITLE,$floor,$room,$bed,$bgcolor,$color,$mrn,$bug,$drug,$filename);
my (@MD,@DRUG,@BUG,@MONTH,@FLOOR,@ROOM);
my (%Bugs,%tBug,%Mrn,%minSens,%MIN_SENS,%tSens,%denomSens,%tPt);
my ($gMd,$gBug,$gMonth,$gFloor);

my $TABLE = "TABLE CELLPADDING='0' CELLSPACING='0'";


@MD = ('all','rb','jc','gh','rj','js');
@DRUG = ('gm','ts','e','cax','aug','cp','clin','tim','pitz','ak','all');	# drugs in ascending order from cheapest to most expensive
@BUG = ('ab','pa','sa','sm','all');
@MONTH = ('all','1','2','3','4','5');
@FLOOR = ('all','1','2','3','4','5','6','7','8','9','10');
@ROOM = ('all','1','2','3','4','5','6','7','8','9','10');

my ($numer,$denom,$ratio);
my ($mrn,$month,$floor,$room,$bed,$md,@rest);
my ($bug,$profile,$prefix,$sens,$resis,@micro,@args,@prof,$bugs,$profStr);
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
#&test;
#&printByLoc;
#&printByPt;
#&printByMD;
#&printByBug;
&patientDB;

sub title {
	my $arg = shift;
	my $bold = shift;
	
	return "<FONT SIZE='4'>$arg</FONT>"	if ($bold eq '0');
	return "<FONT SIZE=4><B>$arg</B></FONT>";
}

sub parseSource {
	open (SRC,"bugs.src") or die "unable to open bugs.src";
	
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
					$profStr = "$bug:";
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
						$profStr .= $sens0;
					}
#					$ratio = $numer / $denom;
#					foreach (@micro) {
#						print BYDRUG $prefix, $_, $numer, "\n";
#					}
					
					push @profiles, ( $bugs, { ('bug',$bug,'numer',$numer,'denom',$denom,'profStr',$profStr,@prof) } );
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
}

sub test {
	open (BYDRUG, ">bydrug.txt") or die "unable to open bydrug.txt";
	print BYDRUG "mrn,month,floor,room,bed,md,bugs,bug,sens,denom,ts,tim,pitz,cax,gm,ak,cp,e,clin,aug,profile\n";
	
	my %b;
	
	foreach (@patients) {
		my %p = %{ $_ };
		my %profs = %{ $p{'profiles'} };
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			%b = %{ $profs{$i} };
			print BYDRUG "$p{'mrn'},$p{'month'},$p{'floor'},$p{'room'},$p{'bed'},$p{'md'},$p{'bugs'}";
			print BYDRUG ",$b{'bug'},$b{'numer'},$b{'denom'},$b{'ts'},$b{'tim'},$b{'pitz'},$b{'cax'},$b{'gm'},$b{'ak'},$b{'cp'},$b{'e'},$b{'clin'},$b{'aug'},$b{'profStr'}\n";
		}
		if ($p{'bugs'} == 0) {
			print BYDRUG "$p{'mrn'},$p{'month'},$p{'floor'},$p{'room'},$p{'bed'},$p{'md'},$p{'bugs'}";
			print BYDRUG ",,,,,,,,,,,,,,\n";
		}
	}
	
	close BYDRUG;
}

sub patientDB {
	open (PTDB, ">patientDB.txt") or die "unable to open patientDB.txt";
	open (BUGDB, ">bugDB.txt") or die "unable to open bugDB.txt";
	
	print PTDB "CREATE TABLE patients (\n";
	print PTDB "	id int DEFAULT '0' NOT NULL auto_increment,\n";
	print PTDB "	mrn int, month tinyint, floor tinyint, room tinyint, bed tinyint,\n";
	print PTDB "	md varchar(2), bugs tinyint,\n";
	print PTDB "	PRIMARY KEY (id),\n";
	print PTDB "	UNIQUE id (id));\n";
	
	print BUGDB "CREATE TABLE bugs (\n";
	print BUGDB "	id int DEFAULT '0' NOT NULL auto_increment, mrn int,\n";
	
	print BUGDB "	ak tinyint,\n";
	print BUGDB "	aug tinyint,\n";
	print BUGDB "	bug varchar(2),\n";
	print BUGDB "	cax tinyint,\n";
	print BUGDB "	clin tinyint,\n";
	print BUGDB "	cp tinyint,\n";
	print BUGDB "	denom int,\n";
	print BUGDB "	e tinyint,\n";
	print BUGDB "	gm tinyint,\n";
	print BUGDB "	numer int,\n";
	print BUGDB "	pitz tinyint,\n";
	print BUGDB "	profStr varchar(15),\n";
	print BUGDB "	tim tinyint,\n";
	print BUGDB "	ts tinyint,\n";
	
	print BUGDB "	PRIMARY KEY (id),\n";
	print BUGDB "	UNIQUE id (id));\n";

	my %b;
	my $bugcount=0;
	my $ptcount=0;
	
	foreach (@patients) {
		my %p = %{ $_ };
		my %profs = %{ $p{'profiles'} };
		++$ptcount;
		print PTDB "INSERT INTO patients VALUES('$ptcount','$p{'mrn'}','$p{'month'}','$p{'floor'}','$p{'room'}','$p{'bed'}','$p{'md'}','$p{'bugs'}');\n";
		
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			%b = %{ $profs{$i} };
			
			++$bugcount;
			print BUGDB "INSERT INTO bugs VALUES('$bugcount','$p{'mrn'}'";
			
			foreach my $key (sort(keys(%b))) {
				my $val = $b{$key};
				if ($val eq '0' || $val) {
					print BUGDB ",'$val'";
				}
				else {
					print BUGDB ",NULL";
				}
			}
			print BUGDB ");\n";
		}
	}
	
	close PTDB;
	close BUGDB;
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
	my $tWidth = "WIDTH='700'";
	my $msg;
	
	for (my $cMd=0;$cMd<=$#MD;++$cMd) {
		$gMd = $MD[$cMd];
		for (my $cBug=0;$cBug<=$#BUG;++$cBug) {
			$gBug = $BUG[$cBug];
			for (my $cMonth=0;$cMonth<=$#MONTH;++$cMonth) {
				$gMonth = $MONTH[$cMonth];

				$filename = "../html/loc_$gMd\_$gBug\_$gMonth.htm";
				open (OUT, ">$filename") or die "unable to open $filename";
				
				&preamble;
				
				if ($gMonth eq 'all') {
					$msg = "Number and Severity of Infections by Location";
				}
				else {
					$msg = "Patient MRN, Bugs, and Severity by Location";
				}
				
				print OUT qq|<$TABLE BORDER='0' $tWidth><TR><TD align='center'>| . &title($msg) . qq|</TD></TR></TABLE>\n|;
							
				
				my ($leftfile,$leftstr,$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "loc_$MD[$cMd-1]_$gBug\_$gMonth.htm"	if ($cMd > 0);
				$leftstr = "MD=$abbr2MD{$MD[$cMd-1]}"	if ($cMd > 0);
				$rightfile = "loc_$MD[$cMd+1]_$gBug\_$gMonth.htm"	if ($cMd < $#MD);
				$rightstr = "MD=$abbr2MD{$MD[$cMd+1]}"	if ($cMd < $#MD);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,"MD",$abbr2MD{$gMd},$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "loc_$gMd\_$gBug\_$MONTH[$cMonth-1].htm"	if ($cMonth > 0);
				$leftstr = "month=$MONTH[$cMonth-1]"	if ($cMonth > 0);
				$rightfile = "loc_$gMd\_$gBug\_$MONTH[$cMonth+1].htm"	if ($cMonth < $#MONTH);
				$rightstr = "month=$MONTH[$cMonth+1]"	if ($cMonth < $#MONTH);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,"month",$gMonth,$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "loc_$gMd\_$BUG[$cBug-1]_$gMonth.htm"	if ($cBug > 0);
				$leftstr = "bug=$BUG[$cBug-1]"	if ($cBug > 0);
				$rightfile = "loc_$gMd\_$BUG[$cBug+1]_$gMonth.htm"	if ($cBug < $#BUG);
				$rightstr = "bug=$BUG[$cBug+1]"	if ($cBug < $#BUG);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,"bug",$gBug,$rightfile,$rightstr);						
				
				
				print OUT qq|<$TABLE BORDER='1'>\n|;
				
				&calcByLoc;
				
				&printByLocTableBody;
				&printByLocTableEnd;
				
				
				# print legend
				
				print OUT qq|<P><$TABLE BORDER='1' $tWidth>\n|;
				print OUT qq|<TR><TD align='center' COLSPAN='5'><B>Legend</B></TD></TR>\n|;
				
				if ($gMonth eq 'all') {
					print OUT qq|<TR><TD># Patients</TD><TD COLSPAN='4'>The top number of each cell</TD></TR>\n|;
					print OUT qq|<TR><TD># Bugs</TD><TD COLSPAN='4'>The bottom number of each cell</TD></TR>\n|;
				}
				else {
					print OUT qq|<TR><TD>MRN</TD><TD COLSPAN='4'>The hyperlinked number at the top of each cell</TD></TR>\n|;
					print OUT qq|<TR><TD>Bugs</TD><TD  COLSPAN='4'>The comma separated list of abbreviations at the bottom of each cell</TD></TR>\n|;
				}
				
				print OUT qq|<TR><TD ROWSPAN='2'>Severity</TD><TD  COLSPAN='4'>The cell's color shows how many antibiotics (AB)s can treat the worst bug</TD></TR>\n|;
				print OUT qq|<TR><TD BGCOLOR='red'>Resistant to all ABs</TD><TD BGCOLOR='orange'>Sensitive to 1 AB</TD><TD BGCOLOR='yellow'>Sensitive to 2 ABs</TD><TD BGCOLOR='white'>Sensitive to >2 ABs</TD></TR>\n|;
				print OUT qq|<TR><TD BGCOLOR='lightblue'>Totals</TD><TD COLSPAN='4'>Total #Patients is the top number; Total #Bugs is the bottom number</TD>\n|;
				print OUT qq|</TABLE>\n|;					
				
				
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

		$filename = "../html/pt$p{'mrn'}.htm";
		open (OUT, ">$filename") or die "unable to open $filename";
		
		&preamble;
		
		my ($leftfile,$leftstr,$rightfile,$rightstr);
		my $leftnum = $count-1;
		my $rightnum = $count+1;
		$leftstr = "MRN=$leftnum"	if ($count > 0);
		$leftfile = "pt$leftnum.htm"	if ($count > 0);
		$rightstr = "MRN=$rightnum"	if ($count < $#patients);
		$rightfile = "pt$rightnum.htm"	if ($count < $#patients);
				
		my $arrows = &makeArrows($tWidth,$leftfile,$leftstr,"Patient MRN",$p{'mrn'},$rightfile,$rightstr);

		print OUT $arrows;
		
		print OUT qq|<$TABLE BORDER='1' $tWidth>\n|;
		print OUT qq|	<TR><TD WIDTH='50'>MD</TD><TD><B>$abbr2MD{$p{'md'}}</B> (<A HREF='md_$p{'md'}_$p{'month'}.htm'>MD's view</A>)</TD></TR>\n|;
		print OUT qq|	<TR><TD WIDTH='50'>Where</TD><TD><B>Floor $p{'floor'}, Room $p{'room'}, Bed $p{'bed'}</B> (<A HREF='loc_$p{'md'}_all_$p{'month'}.htm'>Floor-plan view</A>)</TD></TR>\n|;
		print OUT qq|	<TR><TD WIDTH='50'>Month</TD><TD><B>$p{'month'}</B></TD></TR>\n|;
		print OUT qq|</TABLE>\n|;
			
		print OUT qq|<$TABLE BORDER='1' $tWidth>\n|;
		print OUT qq|<TR><TD $TD>Bug\\Drug</TD>|;
		
		foreach my $drug (@DRUG) {
			next	if ($drug eq 'all');
			print OUT qq|<TD $TD>$drug</TD>|;
		}
		print OUT qq|</TR>\n|;
		
		my %profs = %{ $p{'profiles'} };
		my ($sens,$label,$BG);
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			my %b = %{ $profs{$i} };
			
			print OUT "<TR><TD $TD><B>" . uc($b{'bug'}) . "</B></TD>";
			
			foreach my $drug (@DRUG) {
				next if ($drug eq 'all');
				$sens = $b{$drug};
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
		
		print OUT qq|<TR>\n|;
		print OUT qq|	<TD BGCOLOR='lightblue' ALIGN='center'><B>Cost</B></TD>\n|;
		print OUT qq|	<TD BGCOLOR='lightblue' COLSPAN='3' ALIGN='center'><B>low</B></TD>\n|;
		print OUT qq|	<TD BGCOLOR='lightblue' COLSPAN='4' ALIGN='center'><B>mid</B></TD>\n|;
		print OUT qq|	<TD BGCOLOR='lightblue' COLSPAN='3' ALIGN='center'><B>high</B></TD>\n|;
		print OUT qq|</TR></TABLE>\n|;
		
		&epilogue;		
		
		close (OUT);
	}
}

sub makeArrows {
	my ($width,$prefile,$prestr,$midtopic,$midstr,$postfile,$poststr,$msg);
	($width,$prefile,$prestr,$midtopic,$midstr,$postfile,$poststr) = @_;
	
	$msg = qq|<$TABLE BORDER='0' $width><TR>|	.
			qq|<TD width='25%' align='left'><A HREF='$prefile'>$prestr</A></TD>| .
			qq|<TD width='25%' align='right'>| . &title("$midtopic = ",0) . qq|</TD>| .
			qq|<TD width='25%' align='left'>| . &title($midstr) . qq|</TD>| .
			qq|<TD width='25%' align='right'><A HREF='$postfile'>$poststr</A></TD></TR></TABLE>\n|;
	return $msg;
}


sub printByMD {
	my $TD = "TD align='center' valign='top'";
	my $msg;
	my $tWidth = " WIDTH='400'";
	my ($leftfile,$leftstr,$rightfile,$rightstr);
	my ($arrowsMD,$arrowsMonth);
	
	for (my $md=0;$md<=$#MD;++$md) {
		$gMd = $MD[$md];
		for (my $month=0;$month<=$#MONTH;++$month) {
			$gMonth = $MONTH[$month];	
		
			$filename = "../html/md_$gMd\_$gMonth.htm";
			open (OUT, ">$filename") or die "unable to open $filename";
			
			&preamble;
			
			print OUT qq|<$TABLE BORDER='0' $tWidth><TR><TD align='center'>| . &title('Patient List') . qq|</TD></TR></TABLE>\n|;

			$leftfile = $leftstr = $rightfile = $rightstr = '';
			$leftfile = "md_$MD[$md-1]_$gMonth.htm"	if ($md > 0);
			$leftstr = "MD=$abbr2MD{$MD[$md-1]}"	if ($md > 0);
			$rightfile = "md_$MD[$md+1]_$gMonth.htm"	if ($md < $#MD);
			$rightstr = "MD=$abbr2MD{$MD[$md+1]}"	if ($md < $#MD);
			$arrowsMD = &makeArrows($tWidth,$leftfile,$leftstr,"MD",$abbr2MD{$gMd},$rightfile,$rightstr);

			$leftfile = $leftstr = $rightfile = $rightstr = '';
			$leftfile = "md_$gMd\_$MONTH[$month-1].htm"	if ($month > 0);
			$leftstr = "month=$MONTH[$month-1]"	if ($month > 0);
			$rightfile = "md_$gMd\_$MONTH[$month+1].htm"	if ($month < $#MONTH);
			$rightstr = "month=$MONTH[$month+1]"	if ($month < $#MONTH);			
			$arrowsMonth = &makeArrows($tWidth,$leftfile,$leftstr,"month",$MONTH[$gMonth],$rightfile,$rightstr);
			
			print OUT $arrowsMD;
			print OUT $arrowsMonth;
			
			print OUT qq|<$TABLE BORDER='1' $tWidth>\n|;
			print OUT qq|	<TR><$TD>Month</TD><$TD>MRN</TD><$TD>Floor</TD><$TD>Room</TD><$TD>Bed</TD><$TD><B>Bug:</B> Sensitivity Profile<BR><FONT color='#00dd00'><B>Green</B></FONT>=Sensitive, <FONT color='#aa0000'><B>Red</B></FONT>=Resistant</TD></TR>|;
			
			if ($gMd eq 'all') {
				print OUT qq|<TR><$TD COLSPAN='6'>The list of all patients for <B>all</B> MDs is too long - please select a single MD</TD></TR>\n|;
				print OUT qq|</TABLE>\n|;
				&epilogue;
				close(OUT);
				next;
			}
			
			my $count = 0;
			
			foreach (@patients) {
				my %p = %{ $_ };
				
				next unless ($p{'md'} eq $gMd || $gMd eq 'all');
				next unless ($p{'month'} eq $gMonth || $gMonth eq 'all');
				
				$msg = '';
				++$count;
				my %profs = %{ $p{'profiles'} };
			
				if ($p{'bugs'} == 0) {
					$msg = '&nbsp;';
				}
				
				my $min = 10;
				
				for (my $i=1;$i<=$p{'bugs'};++$i) {
					my %b = %{ $profs{$i} };
					
					if ($i > 1) {
						$msg .= '<BR>';
					}
					$msg .= uc($b{'bug'}) . qq|:&nbsp;|;
					
					foreach my $drug (@DRUG) {
						next if ($drug eq 'all');
						$sens = $b{$drug};
						if ($sens eq '0') {
							$msg .= qq|&nbsp;<FONT COLOR='#aa0000'>$drug</FONT>|;
						}
						elsif ($sens eq '1') {
							$msg .= qq|&nbsp;<FONT COLOR='#00dd00'>$drug</FONT>|;
						}
						else {
							$msg .= qq|&nbsp;<FONT COLOR='white'>$drug</FONT>|;
						}
					}
					$min = $b{'numer'}	if ($b{'numer'} < $min);
				}
				
				print OUT qq|<TR><$TD>$p{'month'}</TD>\n|;
				print OUT qq|	<$TD BGCOLOR='| . $SENSITIVITY_COLS[$min] . qq|'><A HREF='pt$p{'mrn'}.htm'>$p{'mrn'}</A></TD>\n|;
				print OUT qq|	<$TD><A HREF='loc_$gMd\_all_$p{'month'}.htm'>$p{'floor'}</A></TD><$TD>$p{'room'}</TD><$TD>$p{'bed'}</TD>|;
				print OUT qq|<TD><FONT FACE='Arial'><B>|;
				
				print OUT $msg;
								
				print OUT qq|</B></FONT></TD></TR>\n|;
			}
			print OUT qq|<TR><$TD COLSPAN='6' BGCOLOR='lightblue'>Total Patients = <B>$count</B></TD></TR>\n|;
			print OUT qq|</TABLE>\n|;
			print OUT $arrowsMD;
			print OUT $arrowsMonth;	
				
			&epilogue;		
			close (OUT);
		}
	}
}

sub printByBug {
	my $tWidth = "WIDTH='550'";
	my $msg;
	
	for (my $cMd=0;$cMd<=$#MD;++$cMd) {
		$gMd = $MD[$cMd];
		for (my $cFloor=0;$cFloor<=$#FLOOR;++$cFloor) {
			$gFloor = $FLOOR[$cFloor];
			for (my $cMonth=0;$cMonth<=$#MONTH;++$cMonth) {
				$gMonth = $MONTH[$cMonth];

				$filename = "../html/sens_$gMd\_$gFloor\_$gMonth.htm";
				open (OUT, ">$filename") or die "unable to open $filename";
				
				&preamble;
				
				$msg = "Antibiotic Sensitivity of Bugs<BR>";
				
				print OUT qq|<$TABLE BORDER='0' $tWidth><TR><TD align='center'>| . &title($msg) . qq|</TD></TR></TABLE>\n|;
							
				
				my ($leftfile,$leftstr,$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "sens_$MD[$cMd-1]_$gFloor\_$gMonth.htm"	if ($cMd > 0);
				$leftstr = "MD=$abbr2MD{$MD[$cMd-1]}"	if ($cMd > 0);
				$rightfile = "sens_$MD[$cMd+1]_$gFloor\_$gMonth.htm"	if ($cMd < $#MD);
				$rightstr = "MD=$abbr2MD{$MD[$cMd+1]}"	if ($cMd < $#MD);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,"MD",$abbr2MD{$gMd},$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "sens_$gMd\_$gFloor\_$MONTH[$cMonth-1].htm"	if ($cMonth > 0);
				$leftstr = "month=$MONTH[$cMonth-1]"	if ($cMonth > 0);
				$rightfile = "sens_$gMd\_$gFloor\_$MONTH[$cMonth+1].htm"	if ($cMonth < $#MONTH);
				$rightstr = "month=$MONTH[$cMonth+1]"	if ($cMonth < $#MONTH);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,"month",$gMonth,$rightfile,$rightstr);
				
				$leftfile = $leftstr = $rightfile = $rightstr = '';
				$leftfile = "sens_$gMd\_$FLOOR[$cFloor-1]_$gMonth.htm"	if ($cFloor > 0);
				$leftstr = "floor=$FLOOR[$cFloor-1]"	if ($cFloor > 0);
				$rightfile = "sens_$gMd\_$FLOOR[$cFloor+1]_$gMonth.htm"	if ($cFloor < $#FLOOR);
				$rightstr = "floor=$FLOOR[$cFloor+1]"	if ($cFloor < $#FLOOR);				
				print OUT &makeArrows($tWidth,$leftfile,$leftstr,"floor",$gFloor,$rightfile,$rightstr);						
				
				&calcByBug;
				
				print OUT qq|<$TABLE BORDER='1'>\n|;
				
				&printByBugTableBody;
				
				print OUT qq|</TABLE>\n|;
				
				#Legend
				print OUT qq|<P><$TABLE BORDER='1' $tWidth>\n|;
				print OUT qq|<TR><TD align='center' COLSPAN='2'><B>Legend</B></TD></TR>\n|;
				print OUT qq|<TR><TD>%Sensitivity</TD><TD>The top number of each cell.  Higher sensitivities are brighter green</TD></TR>\n|;
				print OUT qq|<TR><TD>#Samples Tested</TD><TD>The bottom number of each cell</TD></TR>\n|;
				print OUT qq|</TABLE>\n|;						
				
				&epilogue;				
				
				close (OUT);
			}
		}
	}
}

sub calcByLoc {
	my $allFallR = "FallRallBall";

	%Mrn = ();
	%tBug = ();
	%Bugs = ();
	%minSens = %MIN_SENS;	# reset to maximal value
	%tPt = ();
	
	foreach (@patients) {
		my %p = %{ $_ };
		my (%b,$loc);
		next unless ($gMonth eq 'all' || $p{'month'} eq $gMonth);
		next unless ($gMd eq 'all' || $p{'md'} eq $gMd);
		
		$loc = "F$p{'floor'}R$p{'room'}B$p{'bed'}";
		$Mrn{$loc} = $p{'mrn'};
		
		my %profs = %{ $p{'profiles'} };
		
		my $min = $minSens{$loc};
		my $total=0;
		my $denom=0;
		my $bugs = '';
		
		
		my $allF = "FallR$p{'room'}Ball";
		my $allR = "F$p{'floor'}RallBall";
		
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			%b = %{ $profs{$i} };
			
			next unless ($gBug eq 'all' || $b{'bug'} eq $gBug);
			
			$bugs .= ($bugs ? ',' : '') . $b{'bug'};
			
			++$tBug{$loc};
			++$tBug{$allF};
			++$tBug{$allR};
			++$tBug{$allFallR};
			
			$min = $b{'numer'}	if ($b{'numer'} < $min);
			$total += $b{'numer'};
			$denom += $b{'denom'};
		}
		
		if ($denom > 0 || $gBug eq 'all') {
			$Bugs{$loc} = $bugs;
			
			#only increase patient count if there are infections, or all bugs
			++$tPt{$loc};
			++$tPt{$allF};
			++$tPt{$allR};
			++$tPt{$allFallR};

			$minSens{$loc} = $min;
		}
	}	
}

sub calcByBug {
	my $BDall = "BallDall";
	
	%tSens = ();
	%denomSens = ();
	
	foreach (@patients) {
		my %p = %{ $_ };
		
		next unless ($gMonth eq 'all' || $p{'month'} eq $gMonth);
		next unless ($gMd eq 'all' || $p{'md'} eq $gMd);
		next unless ($gFloor eq 'all' || $p{'floor'} eq $gFloor);
		
		my %profs = %{ $p{'profiles'} };
		
		for (my $i=1;$i<=$p{'bugs'};++$i) {
			my %b = %{ $profs{$i} };
			
			my $Ball = "B$b{'bug'}Dall";
			
			foreach my $drug (@DRUG) {
				my $loc = "B$b{'bug'}D$drug";
				my $Dall = "BallD$drug";
				
				if ($b{$drug} ne '') {	# then was tested
					++$denomSens{$loc};
					++$denomSens{$Ball};
					++$denomSens{$BDall};	
					++$denomSens{$Dall};
									
					if ($b{$drug} eq '1') {	# then was sensitive to this drug
						++$tSens{$loc};
						++$tSens{$Ball};
						++$tSens{$BDall};
						++$tSens{$Dall};
					}
				}
			}
		}
	}
}

sub printByBugTableBody {
	my $TD = "TD width='40' height='40' align='center' valign='top'";
	my ($msg,$loc,$numer,$denom,$ratio,$BG);
	
	print OUT qq|<TR><$TD>&nbsp;</TD>\n|;
	
	foreach my $bug (@BUG) {
		next if ($bug eq 'all');
		
		print OUT qq|	<$TD><B>$abbr2BUG{$bug}</B></TD>\n|;
	}
	
	print OUT qq|</TR>\n|;
	
	foreach my $drug (@DRUG) {
		next if ($drug eq 'all');
		
		print OUT qq|<TR><$TD><B>$abbr2DRUG{$drug}</B></TD>\n|;
		
		foreach my $bug (@BUG) {
			next if ($bug eq 'all');
			$loc = "B$bug\D$drug";
			
			$numer = $tSens{$loc};
			$denom = $denomSens{$loc};
			
			if ($denom) {
				$ratio = $numer / $denom;
				$BG = "BGCOLOR='" . &rgb(0,$ratio,0) . "'";
				if ($ratio <= .7) {
					$msg = "<FONT COLOR='white'><B>";	# this may be reversed
				}
				else {
					$msg = "<FONT COLOR='black'><B>";
				}
				
				$msg .= sprintf("%3.0f%", 100 * $ratio) . "<BR>$denom</B></FONT>";
			}
			else {
				$msg = '&nbsp;';
				$BG = '';
			}
			
			print OUT qq|	<$TD $BG>$msg</TD>\n|;
		}
		
		print OUT qq|</TR>\n|;
	}
}


sub printByLocTableBody {
	my $TD = "TD width='30' height='30' align='center' valign='top'";
	my $msg;
	
	for ($floor=10;$floor>=1;--$floor) {
		print OUT qq|	<TR>\n|;
		
		if ($floor == 10) {
			print OUT qq|		<TD ROWSPAN='10'><B>F<BR>L<BR>O<BR>O<BR>R</B></TD>\n|;
		}
		
		print OUT qq|		<TD ALIGN='center'><B>$floor</B></TD>\n|;
		
		for ($room=1;$room<=10;++$room) {
			for ($bed=1;$bed<=2;++$bed) {
				my $loc = "F$floor\R$room\B$bed";
				my ($BG,$ratio,$ratioStr,$ratioCol,$bug,$min,$tPt,$tBug);
				
				#color code based upon sensitivity
				#the lower the value for $minSens, the more resistant - worst bug of bunch
				$min = $minSens{$loc};
				$tPt = $tPt{$loc};
				$tBug = $tBug{$loc};
				$mrn = $Mrn{$loc};
				
				$msg = '';

				if ($tBug) {
					$ratioCol = $SENSITIVITY_COLS[$min];
					$msg .= "<BR>$min";
					$BG = "BGCOLOR='$ratioCol'"	if ($ratioCol);
				}
								
				if ($gMonth ne 'all') {
					$msg = "<A href='pt$mrn.htm'>$mrn</A>"	if ($tPt);

					if ($tBug) {
						$msg .= "<BR>$Bugs{$loc}";
					}
				}
				else {
					if ($tPt) {
						$msg = "$tPt<BR>$tBug";
					}
				}
				
				$msg = '&nbsp;'	unless $msg;
				print OUT qq|		<$TD $BG>$msg</TD>\n|;
				
			}
		}
		# print row summary
		$msg = qq|$tPt{"F$floor\RallBall"}<BR>$tBug{"F$floor\RallBall"}|;
		$msg = '&nbsp;'	unless $msg;
		print OUT qq|		<$TD BGCOLOR='lightblue'>$msg</TD>\n|;
		print OUT qq|	</TR>\n|;
	}
	print OUT qq|	<TR><$TD COLSPAN='2' BGCOLOR='lightblue'><B>Pts<BR>Bugs</B></TD>\n|;
	for ($room=1;$room<=10;++$room) {
		$msg = qq|$tPt{"FallR$room\Ball"}<BR>$tBug{"FallR$room\Ball"}|;
		$msg = '&nbsp;'	unless $msg;		
		print OUT qq|	<$TD COLSPAN='2' BGCOLOR='lightblue'>$msg</TD>\n|;
	}
	$msg = qq|$tPt{'FallRallBall'}<BR>$tBug{'FallRallBall'}|;
	$msg = '&nbsp;'	unless $msg;	
	print OUT qq|	<$TD BGCOLOR='lightblue'>$msg</TD>\n</TR>\n|;
}

sub rgb {
	# expects rgb as percents
	my ($r,$g,$b,$ans);
	$r = shift;
	$g = shift;
	$b = shift;
	
	$ans = sprintf('#%02x%02x%02x', (($r * 255) % 256), (($g * 255) % 256), (($b * 255) % 256));
	
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
	print OUT qq|</BODY>\n|;
	print OUT qq|</HTML>\n|;
}

sub printByLocTableEnd {
	print OUT qq|	<TR>\n|;
	print OUT qq|		<TD ROWSPAN='3' COLSPAN='2'>&nbsp;</TD>\n|;
	
	for ($room=1;$room<=10;++$room) {
		for ($bed=1;$bed<=2;++$bed) {
			my $val = ($bed==1) ? 'a' : 'b';
			print OUT qq|		<TD ALIGN='center'><B>$val</B></TD>\n|;
		}
	}
	print OUT qq|	<TD ROWSPAN='3' BGCOLOR='lightblue' ALIGN='center'><B>Pts<BR>Bugs</B></TD>\n|;
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


