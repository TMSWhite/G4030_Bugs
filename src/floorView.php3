<% 
$TD = "TD width='30' height='30' align='center' valign='top'";
include("externs.inc");

$where = '';

if (isset($md) && $md != 'all') { $where .= (($where) ? ' AND ' : '') . "patients.md='$md'"; }
if (isset($month) && $month != 'all') { $where .= (($where) ? ' AND ' : '') . "patients.month=$month"; }
if (isset($bug) && $bug != 'all') { $where .= (($where) ? ' AND ' : '') . "bugs.bug='$bug'"; }
if (isset($floor) && $floor != 'all') { $where .= (($where) ? ' AND ' : '') . "patients.floor=$floor"; }


if (!isset($md)) { $md = 'all'; }
if (!isset($month)) { $month = 'all'; }
if (!isset($bug)) { $bug = 'all'; }
if (!isset($floor)) { $floor = 'all'; }

$title = "Floor View of MRNs, Bugs, and Severity for" . $abbr2MD[$md] . ", month=$month, bug=$bug";
$error = '';

if ($where) {
	#$error = "Incorrect Syntax.  Use the following convention (e.g. for md=J Starren (js), Month=1, Floor=3)<BR>floorView.php3?md=js&month=1&bug=3";
	$where = "WHERE $where";
}
#else {
	$bug_sql = "SELECT DISTINCT bugs.numer, bugs.bug, patients.* FROM patients LEFT JOIN bugs ON patients.mrn=bugs.mrn $where";
	$pt_sql = "SELECT DISTINCT patients.mrn, patients.floor, patients.room, patients.bed FROM patients LEFT JOIN bugs ON patients.mrn=bugs.mrn $where";

	$db = mysql_connect("localhost", "root");
	
	if (!$db) {
		$error = "Unable to con!=ct to database server";
	}
	else {
		$dbname = "test2";
		if (!mysql_select_db($dbname,$db)) {
			$error = "Unable to con!=ct to database<BR>dbname=$dbname";
		}
		
		else {
			$bug_result = mysql_query($bug_sql);
			if (!$bug_result) {
				$error = "Unable to execute SQL query:<BR>$bug_sql";
			}
			$pt_result = mysql_query($pt_sql);
			if (!$bug_result) {
				$error .= "<BR>Unable to execute SQL query:<BR>$bug_sql";
			}			
		}
	}
#}
%>

<HTML>
<HEAD>
	<TITLE><%=$title;%></TITLE>
</HEAD>
<BODY>

<% 
#echo "<P><B>" . mysql_num_rows($bug_result) . "<BR>$bug_sql</B>";

if ($error) {
	echo "<B>$error</B>"; 
} 
else { 
	/* create arrows */
	$tWidth = " WIDTH='700'";

	$leftfile = $leftstr = $rightfile = $rightstr = '';
	
	$md_i=$abbr2MDindex[$md];
	$bug_i= $abbr2BUGindex[$bug];
	
	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($md_i > 0) { 
		$leftfile = "floorView.php3?md=" . $MD[$md_i-1] . "&bug=$bug&month=$month&floor=$floor";
		$leftstr = "MD=" . $abbr2MD[$MD[$md_i-1]];
	}
	if ($md_i < count($MD)-1) {
		$rightfile = "floorView.php3?md=" . $MD[$md_i+1] . "&bug=$bug&month=$month&floor=$floor";
		$rightstr = "MD=" . $abbr2MD[$MD[$md_i+1]];
	}
	$arrowsMD = makeArrows($tWidth,$leftfile,$leftstr,"MD",$abbr2MD[$md],$rightfile,$rightstr);

	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($month > 1) { 
		$leftfile = "floorView.php3?md=$md&bug=$bug&floor=$floor&month=" . ($month-1);
		$leftstr = "month=" . ($month-1);
	}
	if ($month < 5) {
		$rightfile = "floorView.php3?md=$md&bug=$bug&floor=$floor&month=" . ($month+1);
		$rightstr = "month=" . ($month+1);
	}	
	$arrowsMonth = makeArrows($tWidth,$leftfile,$leftstr,"month",$month,$rightfile,$rightstr);	
	
	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($bug_i > 0) { 
		$leftfile = "floorView.php3?md=$md&bug=" . $BUG[$bug_i-1] . "&month=$month&floor=$floor";
		$leftstr = "bug=" . $BUG[$bug_i-1];
	}
	if ($bug_i < count($BUG)-1) {
		$rightfile = "floorView.php3?md=$md&bug=" . $BUG[$bug_i+1]  . "&month=$month&floor=$floor";
		$rightstr = "bug=" . $BUG[$bug_i+1];
	}	
	$arrowsBug = makeArrows($tWidth,$leftfile,$leftstr,"bug",$bug,$rightfile,$rightstr);	
	
	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($floor > 0) { 
		$leftfile = "floorView.php3?md=$md&bug=$bug&month=$month&floor=" . ($floor-1);
		$leftstr = "floor=" . ($floor-1);
	}
	if ($floor < 10) {
		$rightfile = "floorView.php3?md=$md&bug=$bug&month=$month&floor=" . ($floor+1);
		$rightstr = "floor=" . ($floor+1);
	}	
	$arrowsFloor = makeArrows($tWidth,$leftfile,$leftstr,"floor",$floor,$rightfile,$rightstr);			
	
	$title = "Hospital-Wide View of Patients, Bugs, and Severity";
%>
	
<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='0'  <%=$tWidth;%>><TR><TD align='center'><FONT SIZE=5><B><%=$title;%></B><BR></TD></TR></TABLE>
<%=$arrowsMD;%>
<%=$arrowsMonth;%>
<%=$arrowsBug;%>
<%=$arrowsFloor;%>

<%
	/* Calc # patients, # floors, and sensitivity */
	reset($FLOOR);
	while (list($key,$floor) = each($FLOOR)) {
		reset($ROOM);
		while (list($key,$room) = each($ROOM)) {
			reset($BED);
			while (list($key,$bed) = each($BED)) {
				$loc = "F$floor" . "R$room" . "B$bed";
				$minSens[$loc] = 10;	# so that can get minimum value
			}
		}
	}
	
	while($row = mysql_fetch_array($bug_result)) {
		$loc = 'F' . $row['floor'] . 'R' . $row['room'] . 'B' . $row['bed'];
		
		if ($month != 'all') {
			$Mrn[$loc] = $row['mrn'];
			if (isset($row['bug'])) {
				$bugList[$loc] .= (($bugList[$loc]) ? ',' : '') . $row['bug'];
			}
		}
			
		if (isset($row['bug'])) {
			++$tBug[$loc];
			if ($row['numer'] < $minSens[$loc]) {
				$minSens[$loc] = $row['numer'];
			}
		}
	}
	
	if ($pt_result) {
		while($row = mysql_fetch_array($pt_result)) {
			$loc = 'F' . $row['floor'] . 'R' . $row['room'] . 'B' . $row['bed'];
			
			++$tPt[$loc];
		}
	}
	
	reset($FLOOR);
	while (list($key,$floor) = each($FLOOR)) {
		reset($ROOM);
		$floc = "F$floor" . "Rall" . "Ball";
		while (list($key,$room) = each($ROOM)) {
			$rloc = "F$floor" . "R$room" . "Ball";
			reset($BED);
			while (list($key,$bed) = each($BED)) {
				$frb = "F$floor" . "R$room" . "B$bed";
				$tPt[$rloc] += $tPt[$frb];
				$tBug[$rloc] += $tBug[$frb];
				
				$arb = "Fall" . "R$room" . "Ball";
				$tPt[$arb] += $tPt[$frb];
				$tBug[$arb] += $tBug[$frb];
			}
			$tPt[$floc] += $tPt[$rloc];
			$tBug[$floc] += $tBug[$rloc];
		}
		$tPt['FallRallBall'] += $tPt[$floc];
		$tBug['FallRallBall'] += $tBug[$floc];
	}			
	/* End of CalcByLoc */
	
	echo "<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'>\n";
	
	/** START Room descriptors **/
	echo "<TR><TD COLSPAN='2' ALIGN='center'><B>ROOM</B></TD>\n";
	for ($room=1;$room<=10;++$room) {
		echo "	<TD COLSPAN='2' ALIGN='center'><B>$room</B></TD>\n";
	}
	echo "<TD ROWSPAN='2' ALIGN='center' BGCOLOR='lightblue'><B>Totals</B><BR><I>Pts<BR>Bugs</I></TD></TR>\n";
	
	echo "<TR><TD COLSPAN='2' ALIGN='center'><B>BED</B></TD>\n";
	for ($room=1;$room<=10;++$room) {
		for ($bed=1;$bed<=2;++$bed) {
			$val = ($bed==1) ? 'a' : 'b';
			echo "	<TD ALIGN='center'><B>$val</B></TD>\n";
		}
	}
	echo "</TR>\n";

	/** END Room descriptors **/
	
	for ($floor=10;$floor>=1;--$floor) {
		echo "	<TR>\n";
		
		if ($floor == 10) {
			echo "		<TD ROWSPAN='10' ALIGN='center'><B>F<BR>L<BR>O<BR>O<BR>R</B></TD>\n";
		}
		
		echo "		<TD ALIGN='center'><B>$floor</B></TD>\n";
		
		for ($room=1;$room<=10;++$room) {
			for ($bed=1;$bed<=2;++$bed) {
				$loc = "F$floor" . "R$room" . "B$bed";
				
				#color code based upon sensitivity
				#the lower the value for $minSens, the more resistant - worst bug of bunch
				$min = $minSens[$loc];
				$tpts = $tPt[$loc];
				
				$msg = '';
				$BG='';

				if (isset($tPt[$loc])) {
					$ratioCol = $SENS[$min];
					$msg .= "<BR>$min";
					if ($ratioCol) {
						$BG = "BGCOLOR='$ratioCol'";
					}
				}
				
				if ($month != 'all') {
					$buglist = $bugList[$loc];
					$mrn = $Mrn[$loc];
					if (isset($Mrn[$loc])) {
						$msg = "<A HREF='patientView.php3?mrn=$mrn.'>$mrn</A>";
					}

					if ($buglist) {
						$msg .= "<BR>$buglist";
					}
				}
				else {
					$tbugs = $tBug[$loc];	
					if (isset($tPt[$loc])) {
						$msg = "$tpts<BR>$tbugs";
					}
				}
				
				if (!$msg) {
					$msg = '&nbsp;';
				}
				echo "		<$TD $BG>$msg</TD>\n";
				
			}
		}
		# print row summary
		$msg = $tPt["F$floor" .'RallBall'] . '<BR>' . $tBug["F$floor" . 'RallBall'];
		if (!$msg) { $msg = '&nbsp;'; }
		echo "		<$TD BGCOLOR='lightblue'>$msg</TD>\n";
		echo "	</TR>\n";
	}
	
	
	echo "	<TR><TD ALIGN='center' COLSPAN='2' BGCOLOR='lightblue'><B>Totals</B><BR><I>Pts/Bugs</I></TD>\n";
	for ($room=1;$room<=10;++$room) {
		$msg = $tPt["FallR$room" . 'Ball'] . '<BR>' . $tBug["FallR$room" . 'Ball'];
		if (!$msg) { $msg = '&nbsp;'; }
		echo "<TD ALIGN='center' COLSPAN='2' BGCOLOR='lightblue'>$msg</TD>\n";
	}
	$msg = $tPt['FallRallBall'] . '<BR>' . $tBug['FallRallBall'];
	if (!$msg) { $msg = '&nbsp;'; }
	echo "	<$TD BGCOLOR='lightblue'>$msg</TD>\n</TR>\n";	
	echo "</TABLE>\n";		

	

if (isset($bug_result)) { mysql_free_result($bug_result); }
if (isset($bug_result)) { mysql_free_result($pt_result); }
if (isset($db)) { mysql_close($db); }

}	# end else
%>

<P><TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1' <%=$tWidth;%>>
<TR><TD align='center' COLSPAN='5'><B>Legend</B></TD></TR>

<% if ($month == 'all') { %>

<TR><TD># Patients</TD><TD COLSPAN='4'>The top number of each cell</TD></TR>
<TR><TD># Bugs</TD><TD COLSPAN='4'>The bottom number of each cell</TD></TR>

<% } else { %>

<TR><TD>MRN</TD><TD COLSPAN='4'>The hyperlinked number at the top of each cell</TD></TR>
<TR><TD>Bugs</TD><TD  COLSPAN='4'>The comma separated list of abbreviations at the bottom of each cell</TD></TR>

<% } %>

<TR><TD ROWSPAN='2'>Severity</TD><TD  COLSPAN='4'>The cell's color shows how many antibiotics (AB)s can treat the worst bug</TD></TR>
<TR><TD BGCOLOR='<%=$SENS[0];%>'>Resistant to all ABs</TD><TD BGCOLOR='<%=$SENS[1];%>'>Sensitive to 1 AB</TD><TD BGCOLOR='<%=$SENS[2];%>'>Sensitive to 2 ABs</TD><TD BGCOLOR='white'>Sensitive to >2 ABs</TD></TR>
</TABLE>

</BODY>
</HTML>
