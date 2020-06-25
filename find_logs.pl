#!C:\Perl64\bin\perl.exe 
use strict;
use warnings;
use DBI;
use utf8;
use CGI;
use HTML::Entities;

our ($dbh, $sthLogSearch);
my $q = CGI->new();
my $search_email = '';
if ( $q->param()) { 
    $search_email = $q->param('search_email');
}

	print "Content-type:text/html\n\n";

	print  <<EOF;
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
		<title>Find logs</title>
		<script>
		
		</script>
	</head>
	<body topmargin="0" leftmargin="0">
		<table>
			<tr>
				<td valign=top>
					<form action="find_logs.pl" method=post>
						<table border=0>
							<tr>
								<td>
									Введите адрес получателя
								</td>
								<td>
									<input type="text" name="search_email" value="$search_email">
								</td>
							</tr>
							<tr>
								<td colspan=2>
									<input type="submit" value="Поиск">
								</td>
							</tr>
						</table>
					</form>
				</td>
			</tr>
EOF

if ($search_email ne '')
{
    print "<tr><td valign=top><table border=1 style=\"border-collapse: collapse;>\"";
    print "<tr><th valign=top>№</th><th valign=top>timestamp</th><th valign=top>log message</th></tr>";

    init_db();
    $sthLogSearch->execute($search_email);
    my $idx = 0;
    while(my ($t, $str) = $sthLogSearch->fetchrow_array())
    {
        $idx++;
        if ($idx > 100)
        {
            last;
        }
        $str = encode_entities($str);
        #escape_html($str);
        print "<tr><td>$idx</td><td>$t</td><td>$str</td></tr>";
    }
    if ($idx == 0)
    {
        print "<tr><td colspan=3><b>По вашему запросу ничего не найдено</b></td></tr>";
    }
    else
    {
        if ($idx <=100)
        {
            print "<tr><td colspan=3><b>Итого: $idx</b></td></tr>";
        }
        else
        {
            print "<tr><td colspan=3><b>Найдено более 100 записей, но выведены только первые 100 записей</b></td></tr>";
        }
    }
    print "</table></td></tr>";
    close_db();
}

print <<EOF;
	</table>

</body>
</html>
EOF

sub init_db
{
	$dbh = DBI->connect("DBI:Pg:dbname=postgres;host=host", 
						"user", 
						"password",
						{
					        pg_enable_utf8 => 1}
		) || die "Can't connect to db $!";
	my $sql = "
            with t as (
                select 
                                created, str, int_id
                            from
                                log
                            where 
                                address = ?
            )
            , t1 as (
                select created, str, int_id from t
                union all select created, str, int_id from message where int_id in (select int_id from t)
            )
            select created, str from t1 order by int_id, created
		";
	$sthLogSearch = $dbh->prepare($sql);
}

sub close_db
{
	$sthLogSearch->finish();
	$dbh->disconnect();
}