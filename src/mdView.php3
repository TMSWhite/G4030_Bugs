<% 
/* General include variables */
$td = "align='center' valign='top'";

$drugs = array('gm','ts','e','cax','aug','cp','clin','tim','pitz','ak');
$abbr2MD = array(
	'rb' => 'R Barrows', 
	'jc' => 'J Cimino',
	'gh' => 'G Hripcsak',
	'rj' => 'R Jenders',
	'js' => 'J Starren',
	'all' => 'all'
);
/***/

$where = '';

if (isset($md) && $md != 'all') { $where .= (($where) ? ' AND ' : '') . "md='$md'"; }
if (isset($month) && $month != 'all') { $where .= (($where) ? ' AND ' : '') . "month=$month"; }
if (isset($floor) && $floor != 'all') { $where .= (($where) ? ' AND ' : '') . "floor=$floor"; }

if (!isset($md)) { $md = '(all)'; }
if (!isset($month)) { $month = '(all)'; }
if (!isset($floor)) { $floor = '(all)'; }

$title = "Patient List for MD=" . $abbr2MD[$md] . ", month=$month, floor=$floor";
$error = '';

if (!$where) {
	$error = "Incorrect Syntax.  Use the following convention (e.g. for md=J Starren (js), Month=1, Floor=3)<BR>mdView.php3?md=js&month=1&floor=3";
}
else {
	$sql = "SELECT * FROM patients WHERE $where ORDER BY month ASC, md ASC, floor ASC";
	
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
			else if (mysql_num_rows($result) == 0) {
				$error = "Query produced no results:<BR>$sql";
			}
		}
	}
}
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
%>
	
<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='0'  WIDTH='400'><TR><TD align='center'><FONT SIZE=4>
	<B>Patient List</B><BR>
	MD = <B><%=$abbr2MD[$md];%></B><BR>
	Month = <B><%=$month%></B><BR>
	Floor = <B><%=$floor%></B>
</FONT></TD></TR></TABLE>
				
<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='400'>
	<TR>
		<TD align='center' valign='top'>Month</TD>
		<TD align='center' valign='top'>MRN</TD>
		<TD align='center' valign='top'>Floor</TD>
		<TD align='center' valign='top'>Room</TD>
		<TD align='center' valign='top'>Bed</TD>
		<TD align='center' valign='top'><B>Bug:</B> Sensitivity Profile<BR><FONT color='#00dd00'><B>Green</B></FONT>=Sensitive, <FONT color='#aa0000'><B>Red</B></FONT>=Resistant</TD>
	</TR>
	
<%
	while($row = mysql_fetch_array($result)) {
		echo "<TR>\n";
		echo "<TD $td>" . $row['month'] . "</TD>\n";
		echo "<TD $td><A HREF='patientView.php3?mrn=" . $row['mrn'] . "'>" . $row['mrn'] . "</A></TD>\n";
		echo "<TD $td><A HREF='floorView.php3?floor=" . $row['floor'] . "&month=" . $row['month'] . "'>" . $row['floor'] . "</A></TD>\n";
		echo "<TD $td>" . $row['room'] . "</TD>\n";
		echo "<TD $td>" . $row['bed'] . "</TD>\n";
		echo "<TD>&nbsp;</TD>";
		echo "</TR>";
	}
%>

</TABLE>

<%	
} // end else

if (isset($result)) { mysql_free_result($result); }
if (isset($db)) { mysql_close($db); }
%>

</BODY>
</HTML>
