<HTML>
<BODY>
	
<% 
if (isset($mrn)) { 
	$sql = "SELECT * FROM patients WHERE mrn=$mrn";
	$db = mysql_connect("localhost", "root");
	
	if (!$db) {
		$error = "Unable to connect to database";
	}
	else {
		$dbname = "test2";
		mysql_select_db($dbname,$db);

		$result = mysql_query($sql);

		if (!$result) {
			$error = "Unable to connect to database<BR>dbname=$dbname";
		}
		else {
			$row = mysql_fetch_array($result);
			if ($row)
				$error = 0;
			else
				$error = "Query produced no results:<BR>$sql";
		}
	}
}
else {
	$error = "Incorrect Syntax.  Use the following convention (e.g. for patient #15)<BR>patientView.php3?mrn=15";
}

if ($error) {
	echo "<B>$error</B>";
} else {

$title = "Patient #$mrn";

$td = "width='50' align='center'";

$drugs = array('gm','ts','e','cax','aug','cp','clin','tim','pitz','ak');
$abbr2MD = array(
	'rb' => 'R Barrows', 
	'jc' => 'J Cimino',
	'gh' => 'G Hripcsak',
	'rj' => 'R Jenders',
	'js' => 'J Starren',
	'all' => 'all'
);
%>

<HTML>
<HEAD>
	<TITLE><%=$title %></TITLE>
</HEAD>
<BODY>

<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='450'>
	<TR><TD WIDTH='50'>MRN</TD><TD><B><%=$row['mrn'];%></B></TR>
	<TR><TD WIDTH='50'>MD</TD><TD><B><%=$abbr2MD[$row['md']];%></B>
	<% echo " (<A HREF='mdview.php3?md=" . $row['md'] . "&month=" . $row['month'] . "&floor=" . $row['floor']. "'>MD's view</A>)</TD></TR>\n";%>
	<TR><TD WIDTH='50'>Where</TD><TD><B>Floor <%=$row['floor'];%>, Room <%=$row['room'];%>, Bed <%=$row['bed'];%></B>
	<% echo " (<A HREF='floorview.php3?md=" . $row['md'] . "&month=" . $row['month'] . "'>Floor-plan view</A>)</TD></TR>\n";%>
	<TR><TD WIDTH='50'>Month</TD><TD><B><%=$row['month'];%></B></TD></TR>
</TABLE>

<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='450'>
<TR>
<% 
	echo "<TD $td>Bug\Drug</TD>\n";
	while (list($key, $val) = each($drugs)) {
		echo "<TD $td>$val</TD>";
	}
%>
</TR>

<%
	$result = mysql_query("SELECT * FROM bugs WHERE mrn=$mrn");
	while ($row = mysql_fetch_array($result)) {
		echo "<TR><TD $td><B>" . $row['bug'] . "</B></TD>\n";
		reset($drugs);	// to allow each to work again
		while (list($key, $val) = each($drugs)) {
			echo "<TD $td";
			if ($row[$val] == '1') { 
				echo " BGCOLOR='lightgreen'><B>S</B></TD>\n"; 
			}
			elseif ($row[$val] == '0') {
				echo "><B>R</B></TD>\n";
			}
			else {
				echo ">&nbsp;</TD>\n";
			}
		}
		echo "</TR>\n";
	}
%>

<TR>
	<TD BGCOLOR='lightblue' ALIGN='center'><B>Cost</B></TD>
	<TD BGCOLOR='lightblue' COLSPAN='3' ALIGN='center'><B>low</B></TD>
	<TD BGCOLOR='lightblue' COLSPAN='4' ALIGN='center'><B>mid</B></TD>
	<TD BGCOLOR='lightblue' COLSPAN='3' ALIGN='center'><B>high</B></TD>
</TR></TABLE>

<% } // END else 
%>

</BODY>
</HTML>