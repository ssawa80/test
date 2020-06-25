#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use DBI;

our ($dbh, $sthLogInsert, $sthMessageInsert); #, $sth_delete_log, $sth_delete_message);
init_db();

my $i = 0;
if (open(my $file, "< ./out/out"))
{
	while(my $str = <$file>)
	{
		$i++;
		if ($str =~ /^(\d{4}-\d{2}-\d{2}\s\d{2}\:\d{2}\:\d{2})\s(.*?)\s([^ ]+)(\s(.*))?$/)
		{
			my $date = $1;
			my $messageId = $2;
			my $operation = $3;
			my $other = $4;
			LogSave($date, $messageId, $operation, $other, $i);
			if ($i%1000 == 0)
			{
				$dbh->commit();
			}
		}
	}
	close($file);
}
else
{
	print "Error while open file: $!\n";
}

close_db();

sub LogSave
{
	my $date = shift;
	my $messageId = shift;
	my $operation = shift;
	my $str = shift;
	my $recipient = '';
	if ($operation eq '<=')
	{
		if ($str =~ /id=([^ ]+)/)
		{
			my $mailId = $1;
			$sthMessageInsert->execute($date, $mailId, $messageId, "$messageId $operation $str") || die "Error: $!\n";
			return;
		}
	}
	elsif ($str =~ /^\s.*?(<)?([^@ <]+@[^@ >]+?)(>)?(\s|:)/)
	{
		$recipient = $2;
	}
	$sthLogInsert->execute($date, $messageId, "$messageId $operation $str", $recipient) || die "Error: $!\n";
}

sub init_db
{
	$dbh = DBI->connect("DBI:Pg:dbname=postgres;host=host", 
						"user", 
						"password",
						{
					        pg_enable_utf8 => 1,
							AutoCommit => 0
						}
		) || die "Can't connect to db $!";
	my $sql = "
		insert into log (created, int_id, str, address) 
			values (
				to_timestamp(?, 'YYYY-MM-DD hh24:mi:ss')::timestamp without time zone, 
				?, 
				?, 
				?)
		";
	$sthLogInsert = $dbh->prepare($sql);

	$sql = "
		insert into message (created, id, int_id, str)
			values (
				to_timestamp(?, 'YYYY-MM-DD hh24:mi:ss')::timestamp without time zone, 
				?, 
				?, 
				?)
		";
	$sthMessageInsert = $dbh->prepare($sql);

	#$sth_delete_log = $dbh->prepare("delete from log");
	#$sth_delete_message = $dbh->prepare("delete from message");

	#$sth_delete_log->execute();
	#$sth_delete_message->execute();


}

sub close_db
{
	$sthLogInsert->finish();
	$sthMessageInsert->finish();
	#$sth_delete_log->finish();
	#$sth_delete_message->finish();
	$dbh->disconnect();
}