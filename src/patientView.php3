<HTML>
<BODY>
	
<% 
if (isset($mrn)) { 
	$sql = "SELECT * FROM patients WHERE mrn=$mrn";
	
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
else {
	$error = "Incorrect Syntax.  Use the following convention (e.g. for patient #15)<BR>patientView.php3?mrn=15";
}

if ($error) {
	echo "<B>$error</B>";
} else {
	
$row = mysql_fetch_array($result);

$title = "Patient #$mrn";
$tWidth = " WIDTH='450'";

$td = "width='50' align='center'";

include("externs.inc");

$leftfile = $leftstr = $rightfile = $rightstr = '';
if ($mrn > 0) { 
	$leftfile = "patientView.php3?mrn=" . ($mrn - 1);
	$leftstr = "MRN=" .  ($mrn - 1);
}
if ($mrn < 1000) {
	$rightfile = "patientView.php3?mrn=" . ($mrn + 1);
	$rightstr = "MRN=" .  ($mrn + 1);
}
$arrowsMRN = makeArrows($tWidth,$leftfile,$leftstr,"MRN",$mrn,$rightfile,$rightstr);

%>

<HTML>
<HEAD>
	<TITLE><%=$title %></TITLE>
</HEAD>
<BODY>

<%=$arrowsMRN;%>

<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='450'>
	<TR><TD WIDTH='50'>Patient Name</TD><TD><B>XXXXX YYYYY</B></TR>
	<TR><TD WIDTH='50'>MD</TD><TD><B><%=$abbr2MD[$row['md']];%></B>
	<% echo " (<A HREF='mdView.php3?md=" . $row['md'] . "&month=" . $row['month'] . "&floor=" . $row['floor']. "'>MD's view</A>)</TD></TR>\n";%>
	<TR><TD WIDTH='50'>Where</TD><TD><B>Floor <%=$row['floor'];%>, Room <%=$row['room'];%>, Bed <%=$row['bed'];%></B>
	<% echo " (<A HREF='floorView.php3?md=" . $row['md'] . "&month=" . $row['month'] . "'>Floor-plan view</A>)</TD></TR>\n";%>
	<TR><TD WIDTH='50'>Month</TD><TD><B><%=$row['month'];%></B></TD></TR>
</TABLE>

<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='450'>
<TR>
<% 
	mysql_free_result($result);
	echo "<TD $td>Bug\Drug</TD>\n";
	while (list($key, $val) = each($DRUG)) {
		if ($val == 'all')
			continue;
		echo "<TD $td>$val</TD>";
	}
%>
</TR>

<%
	$result = mysql_query("SELECT * FROM bugs WHERE mrn=$mrn");
	while ($row = mysql_fetch_array($result)) {
		echo "<TR><TD $td><B>" . strtoupper($row['bug']) . "</B></TD>\n";
		reset($DRUG);	// to allow each to work again
		while (list($key, $val) = each($DRUG)) {
			if ($val == 'all')
				continue;
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
	mysql_free_result($result);
%>

<TR>
	<TD BGCOLOR='lightblue' ALIGN='center'><B>Cost</B></TD>
	<TD BGCOLOR='lightblue' COLSPAN='3' ALIGN='center'><B>low</B></TD>
	<TD BGCOLOR='lightblue' COLSPAN='4' ALIGN='center'><B>mid</B></TD>
	<TD BGCOLOR='lightblue' COLSPAN='3' ALIGN='center'><B>high</B></TD>
</TR></TABLE>

<% } // END else 
if (isset($db)) { mysql_close($db); }
%>

</BODY>
</HTML>
