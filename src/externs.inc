<%

$SENS = array('#FF66FF','#FF9900','yellow','white','white','white','white','white','white','white','white');

$MD2abbr = array(
	'R Barrows' => 'rb',
	'J Cimino' => 'jc',
	'G Hripcsak' => 'gh',
	'R Jenders' => 'rj',
	'J Starren' => 'js',
	'all' => 'all'
);
$abbr2MD = array(
	'rb' => 'R Barrows', 
	'jc' => 'J Cimino',
	'gh' => 'G Hripcsak',
	'rj' => 'R Jenders',
	'js' => 'J Starren',
	'all' => 'all'
);

$abbr2index = array(
	'rb' => '0', 
	'jc' => '1',
	'gh' => '2',
	'rj' => '3',
	'js' => '4',
	'all' => '5'
);

$abbr2BUG = array(
	'ab' => 'Acinetobacter&nbsp;B.<BR>(ab)',
	'pa' => 'Pseudomonas&nbsp;A.<BR>(pa)',
	'sa' => 'Staph&nbsp;Aureus<BR>(sa)',
	'sm' => 'Serratia&nbsp;Marc.<BR>(sm)',
	'all' => 'Average'
);

$abbr2DRUG = array(
	'gm' => 'Gentamicin&nbsp;(gm)',
	'ts' => 'Bactrim&nbsp;(ts)',
	'tim' => 'Timentin&nbsp;(tim)',
	'pitz' => 'Zosyn&nbsp;(pitz)',
	'cax' => 'Ceftriaxone&nbsp;(cax)',
	'ak' => 'Amikacin&nbsp;(ak)',
	'cp' => 'Ciprofloxacin&nbsp;(cip)',
	'aug' => 'Augmentin&nbsp;(aug)',
	'e' => 'Erythromycin&nbsp;(e)',
	'clin' => 'Clindamycin&nbsp;(clin)',
	'all' => 'Average'
);

$MD = array('rb','jc','gh','rj','js','all');
$DRUG = array('gm','ts','e','cax','aug','cp','clin','tim','pitz','ak','all');	
$BUG = array('ab','pa','sa','sm','all');
$MONTH = array('all','1','2','3','4','5');
$FLOOR = array('all','1','2','3','4','5','6','7','8','9','10');
$ROOM = array('all','1','2','3','4','5','6','7','8','9','10');


function makeArrows ($width,$prefile,$prestr,$midtopic,$midstr,$postfile,$poststr) {
	$msg = "<TABLE CELLPADDING='0' CELLSPACING='0' BORDER='0' $width><TR>" .
			"<TD width='25%' align='left'><A HREF='$prefile'>$prestr</A></TD>" .
			"<TD width='25%' align='right'>" . title("$midtopic = ",0) . "</TD>" .
			"<TD width='25%' align='left'>" . title($midstr) . "</TD>" .
			"<TD width='25%' align='right'><A HREF='$postfile'>$poststr</A></TD></TR></TABLE>\n";
	return $msg;
}

function title ($arg, $bold='1') {
	if ($bold == '0')
		return "<FONT SIZE='4'>$arg</FONT>";
	else
		return "<FONT SIZE=4><B>$arg</B></FONT>";
}

function rgb ($r,$g,$b) {
	# expects rgb as percents
	
	return sprintf('#%02x%02x%02x', (($r * 255) % 256), (($g * 255) % 256), (($b * 255) % 256));
}
%>
