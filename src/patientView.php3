<HTML>
<BODY>
	
<% 
if (!isset($user)) { $user = 'cleaning'; }


if ($user == 'cleaning' || $user == 'admin') {
	$error = "Sorry, you are not authorized to access this information.";
}

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
	$error = "Incorrect Syntax.  Use the following convention (e.g. for patient #15)<BR>patientView.php3?mrn=15&user=md";
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
	$leftfile = "patientView.php3?user=$user&mrn=" . ($mrn - 1);
	$leftstr = "Patient#" .  ($mrn - 1);
}
if ($mrn < 1000) {
	$rightfile = "patientView.php3?user=$user&mrn=" . ($mrn + 1);
	$rightstr = "Patient#" .  ($mrn + 1);
}
$arrowsMRN = makeArrows($tWidth,$leftfile,$leftstr,"Patient#",$mrn,$rightfile,$rightstr);

$md = $row['md'];
$month = $row['month'];
$floor = $row['floor'];

%>

<HTML>
<HEAD>
	<TITLE><%=$title %></TITLE>
</HEAD>
<BODY>

<% 
	if ($user == 'md') {
		echo $arrowsMRN;
	}
%>

<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='450'>
	<TR><TD WIDTH='50'>MD</TD><TD><B><%=$abbr2MD[$md];%></B>
	<% 
		if ($user == 'md' || $user == 'nurse') {
			echo " (<A HREF='mdView.php3?md=$md&month=$month&floor$floor&user=$user'>MD's Patient List</A>)";
		}
		if ($user == 'md') {
			echo " (<A HREF='sensView.php3?md=$md&floor=$floor&month=$month&user=$user'>Antibiogram</A>)";
		}
	%>
	</TD></TR>
	<TR><TD WIDTH='50'>Where</TD><TD><B>Floor <%=$floor;%>, Room <%=$row['room'];%>, Bed <%=$row['bed'];%></B>
	<%
		if ($user == 'md' || $user == 'nurse') {
			echo " (<A HREF='floorView.php3?md=$md&month=$month&user=$user'>Floor-plan view</A>)";
		}
		elseif ($user == 'pt') {
			# only let patient see their own room geographically
			echo " (<A HREF='floorView.php3?mrn=$mrn&user=$user'>Floor-plan view</A>)";
		}
	%>
	</TD></TR>
	<TR><TD WIDTH='50'>Month</TD><TD><B><%=$month;%></B></TD></TR>
</TABLE>

<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='1'  WIDTH='450'>
<TR>
<% 
	mysql_free_result($result);
	echo "<TD $td>Bug\Drug</TD>\n";
	reset($DRUG);
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
</TR>
</TABLE>

<% } // END else 
if (isset($db)) { mysql_close($db); }
%>

</BODY>
</HTML>
