<% 
$TD = "TD width='100' height='40' align='center'";
include("externs.inc");

$where = 'bugs.mrn=patients.mrn';

if (isset($md) && $md != 'all') { $where .= (($where) ? ' AND ' : '') . "patients.md='$md'"; }
if (isset($month) && $month != 'all') { $where .= (($where) ? ' AND ' : '') . "patients.month=$month"; }
if (isset($floor) && $floor != 'all') { $where .= (($where) ? ' AND ' : '') . "patients.floor=$floor"; }


if (!isset($md)) { $md = '(all)'; }
if (!isset($month)) { $month = '(all)'; }
if (!isset($floor)) { $floor = '(all)'; }
if (!isset($user)) { $user = 'cleaning'; }

$title = "Antibiogram for" . $abbr2MD[$md] . ", month=$month, floor=$floor";
$error = '';

if ($user == 'pt' || $user == 'nurse' || $user == 'cleaning') {
	$error = "Sorry, you are not authorized to access this information.";
}

if ($where) {
	#$error = "Incorrect Syntax.  Use the following convention (e.g. for md=J Starren (js), Month=1, Floor=3)<BR>sensView.php3?user=$user&md=js&month=1&floor=3";
	$where = "WHERE $where";
}
#else {
	$sql = "SELECT bugs.* FROM bugs,patients $where";
	
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
	$tWidth = " WIDTH='500'";

	$leftfile = $leftstr = $rightfile = $rightstr = '';
	
	$md_i=$abbr2MDindex[$md];
	
	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($md_i > 0) { 
		$leftfile = "sensView.php3?user=$user&md=" . $MD[$md_i-1] . "&floor=$floor&month=$month";
		$leftstr = "MD=" . $abbr2MD[$MD[$md_i-1]];
	}
	if ($md_i < count($MD)-1) {
		$rightfile = "sensView.php3?user=$user&md=" . $MD[$md_i+1] . "&floor=$floor&month=$month";
		$rightstr = "MD=" . $abbr2MD[$MD[$md_i+1]];
	}
	$arrowsMD = makeArrows($tWidth,$leftfile,$leftstr,"MD",$abbr2MD[$md],$rightfile,$rightstr);

	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($month > 1) { 
		$leftfile = "sensView.php3?user=$user&md=$md&floor=$floor&month=" . ($month-1);
		$leftstr = "month=" . ($month-1);
	}
	if ($month < 5) {
		$rightfile = "sensView.php3?user=$user&md=$md&floor=$floor&month=" . ($month+1);
		$rightstr = "month=" . ($month+1);
	}	
	$arrowsMonth = makeArrows($tWidth,$leftfile,$leftstr,"month",$month,$rightfile,$rightstr);	
	
	$leftfile = $leftstr = $rightfile = $rightstr = '';
	if ($floor > 1) { 
		$leftfile = "sensView.php3?user=$user&md=$md&floor=" . ($floor-1) . "&month=$month";
		$leftstr = "floor=" . ($floor-1);
	}
	if ($floor < 10) {
		$rightfile = "sensView.php3?user=$user&md=$md&floor=" . ($floor+1) . "&month=$month";
		$rightstr = "floor=" . ($floor+1);
	}	
	$arrowsFloor = makeArrows($tWidth,$leftfile,$leftstr,"floor",$floor,$rightfile,$rightstr);		
%>
	
<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='0'  WIDTH='500'><TR><TD align='center'><FONT SIZE=5><B>Antibiogram</B><BR></TD></TR></TABLE>
<%=$arrowsMD;%>
<%=$arrowsMonth;%>
<%=$arrowsFloor;%>

<%
	/* Calc sensitivity */
	
	while($row = mysql_fetch_array($result)) {
		reset($DRUG);
		++$denomSens[$row['bug']];
		while (list($key,$drug) = each($DRUG)) {
			$loc = "B" . $row['bug'] . "D$drug";
			if ($row[$drug] == '1') { 
				++$denomSens[$loc];
				++$numerSens[$loc];
			}
			elseif ($row[$drug] == '0') {
				++$denomSens[$loc];
			}
		}
	}
	/* End of CalcByBug */
	
	echo "<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1' WIDTH='500'><TR><$TD>&nbsp;</TD>";
	reset($BUG);
	while (list($key,$bug) = each($BUG)) {
		if ($bug == 'all')
			continue;
		echo "	<$TD><B>" . $abbr2BUG[$bug] . "</B></TD>\n";
	}
	echo "</TR><TD width='100' align='center' valign='top' BGCOLOR='lightblue'><B>#Isolates<B></TD>\n";
	reset($BUG);
	while (list($key,$bug) = each($BUG)) {
		if ($bug == 'all')
			continue;
		echo "	<TD width='100' align='center' valign='top' BGCOLOR='lightblue'><B>" . (($denomSens[$bug]) ? $denomSens[$bug] : '0') . "</B></TD>\n";
	}
	echo "</TR>\n";		
	
	reset($DRUG);
	while (list($key,$drug) = each($DRUG)) {
		if ($drug == 'all')
			continue;
		
		echo "<TR><$TD><B>" . $abbr2DRUG[$drug] . "</B></TD>\n";
		
		reset($BUG);
		while (list($key,$bug) = each($BUG)) {
			if ($bug == 'all')
				continue;
			$loc = "B$bug" . "D$drug";
			
			$numer = $numerSens[$loc];
			$denom = $denomSens[$loc];
			
			if ($denom) {
				$ratio = $numer / $denom;
				$BG = "BGCOLOR='" . rgb(0,$ratio,0) . "'";
				if ($ratio <= .9) {
					$msg = "<FONT COLOR='white'><B>";	# this may be reversed
				}
				else {
					$msg = "<FONT COLOR='black'><B>";
				}
				
				$msg .= sprintf("%3.0f%%<BR>%i</B></FONT>", (100 * $ratio), $denom);
			}
			else {
				$msg = '&nbsp;';
				$BG = '';
			}
			
			echo "<$TD $BG>$msg</TD>\n";
		}
		echo "</TR>\n";
	}
	echo "</TABLE>\n";
	
echo "<P><TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='500'>\n";
echo "<TR><TD align='center' COLSPAN='2'><B>Legend</B></TD></TR>\n";
echo "<TR><TD>%Sensitivity</TD><TD>Higher sensitivities are brighter green</TD></TR>\n";
echo "</TABLE>\n";			

if (isset($result)) { mysql_free_result($result); }
if (isset($db)) { mysql_close($db); }

}	# end else
%>

</BODY>
</HTML>
