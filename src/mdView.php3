<% 
$td = "align='center' valign='top'";
include("externs.inc");

$where = '';

if (isset($md) && $md != 'all') { $where .= (($where) ? ' AND ' : '') . "md='$md'"; }
if (isset($month) && $month != 'all') { $where .= (($where) ? ' AND ' : '') . "month=$month"; }
if (isset($floor) && $floor != 'all') { $where .= (($where) ? ' AND ' : '') . "floor=$floor"; }


if (!isset($md)) { $md = 'all'; }
if (!isset($month)) { $month = 'all'; }
if (!isset($floor)) { $floor = 'all'; }
if (!isset($user)) { $user = 'cleaning'; }

$title = "Patient List for MD=" . $abbr2MD[$md] . ", month=$month, floor=$floor";
$error = '';

if ($user == 'pt' || $user == 'admin' || $user == 'cleaning') {
	$error = "Sorry, you are not authorized to access this information.";
}

if ($where) {
	#$error = "Incorrect Syntax.  Use the following convention (e.g. for md=J Starren (js), Month=1, Floor=3)<BR>mdView.php3?user=$user&md=js&month=1&floor=3";
	$where = "WHERE $where";
}
#else {
	$sql = "SELECT * FROM patients $where ORDER BY month ASC, floor ASC, room ASC, bed ASC";
	
	$db = mysql_connect("localhost", "root");
	
	if (!$db) {
		$error = "Unable to connect to database server";
	}
	else {
		$dbname = "test2";
		if (!mysql_select_db($dbname,$db)) {
			$error = "Unable to connect to database<BR>dbname=$dbname";
		}
		
		else {
			$result = mysql_query($sql);
			if (!$result) {
				$error = "Unable to execute SQL query:<BR>$sql";
			}
		}
	}
#}
%>

<HTML>
<HEAD>
	<TITLE><%=$title %></TITLE>
</HEAD>
<BODY>

<% 
if ($error) {
	echo "<B>$error</B>"; 
} 
else { 
	/* create arrows */
	$tWidth = " WIDTH='400'";

	$leftfile = $leftstr = $rightfile = $rightstr = '';
	
	$md_i=$abbr2MDindex[$md];
	
	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($md_i > 0) { 
		$leftfile = "mdView.php3?user=$user&md=" . $MD[$md_i-1] . "&floor=$floor&month=$month";
		$leftstr = "MD=" . $abbr2MD[$MD[$md_i-1]];
	}
	if ($md_i < count($MD)-1) {
		$rightfile = "mdView.php3?user=$user&md=" . $MD[$md_i+1] . "&floor=$floor&month=$month";
		$rightstr = "MD=" . $abbr2MD[$MD[$md_i+1]];
	}
	$arrowsMD = makeArrows($tWidth,$leftfile,$leftstr,"MD",$abbr2MD[$md],$rightfile,$rightstr);

	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($month > 1) { 
		$leftfile = "mdView.php3?user=$user&md=$md&floor=$floor&month=" . ($month-1);
		$leftstr = "month=" . ($month-1);
	}
	if ($month < 5) {
		$rightfile = "mdView.php3?user=$user&md=$md&floor=$floor&month=" . ($month+1);
		$rightstr = "month=" . ($month+1);
	}	
	$arrowsMonth = makeArrows($tWidth,$leftfile,$leftstr,"month",$month,$rightfile,$rightstr);	
	
	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($floor > 1) { 
		$leftfile = "mdView.php3?user=$user&md=$md&floor=" . ($floor-1) . "&month=$month";
		$leftstr = "floor=" . ($floor-1);
	}
	if ($floor < 10) {
		$rightfile = "mdView.php3?user=$user&md=$md&floor=" . ($floor+1) . "&month=$month";
		$rightstr = "floor=" . ($floor+1);
	}	
	$arrowsFloor = makeArrows($tWidth,$leftfile,$leftstr,"floor",$floor,$rightfile,$rightstr);		
%>
	
<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='0'  WIDTH='400'><TR><TD align='center'><FONT SIZE=5><B>Doctor's List of Patients</B><BR></TD></TR></TABLE>
<%=$arrowsMD;%>
<%=$arrowsMonth;%>
<%=$arrowsFloor;%>
				
<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='400'>
	<TR>
		<TD align='center' valign='top'>Month</TD>
		<TD align='center' valign='top'>MRN</TD>
		<TD align='center' valign='top'>Floor</TD>
		<TD align='center' valign='top'>Room</TD>
		<TD align='center' valign='top'>Bed</TD>
		<%
			if ($user == 'md') {
				echo "<TD align='center' valign='top'><B>Bug:</B> Sensitivity Profile<BR><FONT color='#00dd00'><B>Green</B></FONT>=Sensitive, <FONT color='#aa0000'><B>Red</B></FONT>=Resistant</TD>";
			}
		%>
	</TR>
	
<%
	while($row = mysql_fetch_array($result)) {
		$sql = "SELECT * FROM bugs WHERE mrn=" . $row['mrn'] . " ORDER BY bug";
		$r_profile = mysql_query($sql);
		$profile = '';
		$numer = 10;
		if (!$r_profile) {
			$profile = "Unable to execute query:<BR>$sql";
		}
		elseif (mysql_num_rows($r_profile) == 0) {
			$profile = '&nbsp;';
		}
		else {
			while ($prof = mysql_fetch_array($r_profile)) {
				$profile .= ($profile ? '<BR>' : '') . "<FONT COLOR='black'><B>" . strtoupper($prof['bug']) . "<B>:&nbsp;";
				reset($DRUG);
				while (list($key, $val) = each($DRUG)) {
					if ($val == 'all')
						continue;
					if ($prof[$val] == '1') { 
						$profile .= "&nbsp;<FONT COLOR='#00dd00'>$val</FONT>";
					}
					elseif ($prof[$val] == '0') {
						$profile .= "&nbsp;<FONT COLOR='#aa0000'>$val</FONT>";
					}
					else {
						$profile .= "&nbsp;<FONT COLOR='white'>$val</FONT>";
					}		
				}
				if ($prof['numer'] < $numer)
					$numer = $prof['numer'];
			}
		}
		echo "<TR>\n";
		echo "<TD $td>" . $row['month'] . "</TD>\n";
		echo "<TD $td BGCOLOR='" . $SENS[$numer] . "'><A HREF='patientView.php3?user=$user&mrn=" . $row['mrn'] . "'>" . $row['mrn'] . "</A></TD>\n";
		echo "<TD $td><A HREF='floorView.php3?user=$user&floor=" . $row['floor'] . "&month=" . $row['month'] . "'>" . $row['floor'] . "</A></TD>\n";
		echo "<TD $td>" . $row['room'] . "</TD>\n";
		echo "<TD $td>" . $row['bed'] . "</TD>\n";
		if ($user == 'md') {
			# so nurse sees the color of the patient, but not their list of bugs
			echo "<TD>$profile</TD></TR>";
		}
	}	
	echo "<TR><TD $td COLSPAN='6' BGCOLOR='lightblue'>Total Patients = <B>" . mysql_num_rows($result) . "</B></TD></TR>\n";

%>

</TABLE>

<P><TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='400'>
<TR><TD align='center' COLSPAN='5'><B>Legend</B></TD></TR>
<TR><TD ROWSPAN='2'>Severity</TD><TD  COLSPAN='4'>The cell's color shows how many antibiotics (AB)s can treat the worst bug</TD></TR>
<TR><TD BGCOLOR='<%=$SENS[0];%>'>Resistant to all ABs</TD><TD BGCOLOR='<%=$SENS[1];%>'>Sensitive to 1 AB</TD><TD BGCOLOR='<%=$SENS[2];%>'>Sensitive to 2 ABs</TD><TD BGCOLOR='white'>Sensitive to >2 ABs</TD></TR>
</TABLE>


<%	
} // end else

if (isset($result)) { mysql_free_result($result); }
if (isset($db)) { mysql_close($db); }
%>

</BODY>
</HTML>
