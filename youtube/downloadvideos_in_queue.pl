#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

Log::Log4perl::init('log.conf');
Log::Log4perl::init_and_watch('log.conf',10);
my $logger = Log::Log4perl->get_logger('downloadvideo');
$logger->info("---------------------------------------------------------------------");
$logger->info("start executing download_videos_in_queue.pl ...");
$logger->info("---------------------------------------------------------------------");

my ($dbh, $sth);
&db_init();

my ($url_list, $filename_list, $state_list) = &read_file_to_array();
my @url = @$url_list;
my @filename = @$filename_list;
my @state = @$state_list;

foreach my $i (0 .. $#url) {
	&videos_enqueue($url[$i], $filename[$i], $state[$i]);
}

($url_list, $filename_list) = &get_videos_in_queue();
@url = @$url_list;
@filename = @$filename_list;

foreach my $i (0 .. $#url) {
	&download_file_by_url($url[$i]);
}

$logger->info("---------------------------------------------------------------------");
$logger->info("finish executing download_videos_in_queue.pl ...");
$logger->info("---------------------------------------------------------------------");

#------------------------------------------------------------------------------------#
#                    following are sub routine definitions                           #
#------------------------------------------------------------------------------------#

sub db_init() {
	my $dbname = 'youtube';
	my $dbuser = 'root';
	my $dbpass = '';
	$dbh = DBI -> connect("DBI:mysql:$dbname", $dbuser, $dbpass, {RaiseError => 0, ShowErrorStatement => 1});
	$sth = $dbh -> prepare('set names utf8');
	$sth -> execute();
}



sub read_file_to_array() {
	open (FH, 'queue.ini');
	my @lines=<FH>;
	close FH;

	my (
		@url,
		@filename,
		@state, #0 - pending, #1 - downloading, #2 - finished
	);

	foreach my $url (@lines) {
		chomp($url);
		my $filename = &get_filename_from_url($url);
		my $state = 0;
		push @url, $url;
		push @filename, $filename;
		push @state, $state;
	}
	return (\@url, \@filename, \@state);
}

sub videos_enqueue() {
	if (isexist_url($_[0])) {
		return;
	}
	$sth = $dbh -> prepare(qq{
		INSERT INTO `videolist` (
		`url`,
		`filename`,
		`state`,
		`queue_datetime`
		) VALUES (
		"$_[0]",
		"$_[1]",
		"$_[2]",
		NOW()
		)
		});
	$sth -> execute();
	$logger->info("insert record - url: $_[0], filename: $_[1]\n");
}

sub update_video_state() {
	if ($_[1] eq 1) {
		$sth = $dbh -> prepare(qq{
			UPDATE `videolist` 
			SET `state`="$_[1]",
			`start_datetime`=NOW()
			WHERE `url`="$_[0]"
			});
	} else {
		$sth = $dbh -> prepare(qq{
			UPDATE `videolist` 
			SET `state`="$_[1]",
			`finish_datetime`=NOW()
			WHERE `url`="$_[0]"
			});

	}
	$sth -> execute();
	$logger->info("update video $_[0] to state $_[1]");
}

sub get_videos_in_queue() {
#state: 0 - init, 1 - start download, 2 - finished
	$sth = $dbh -> prepare(qq{
		SELECT url, filename
		FROM videolist
		WHERE state < 2
		ORDER BY videoId
		});

	$sth -> execute();
	my (@url, @filename);

	while (my @row = $sth -> fetchrow_array()) {
		push @url, $row[0];
		push @filename, $row[1];
	}

	return (\@url, \@filename);
}

sub isexist_url() {
	$sth = $dbh -> prepare(qq{
		SELECT url
		FROM videolist
		ORDER BY videoId
		});

	$sth -> execute();
	my @url;

	while (my @row = $sth -> fetchrow_array()) {
		push @url, $row[0];
	}

	my $temp = grep {$_ eq $_[0]} @url;
	if ($temp eq '0') {
		return 0;
	} else {
		return 1;
	}
}

sub download_file_by_url() {
	my $url = $_[0];
	my $filename = &get_filename_from_url;
	my $state = 1;
	$logger->info("=====================================================================");
	&update_video_state($url, $state);
	$logger->info("start downloading file - url: $url, filename: $filename");
	my $download = `/usr/local/bin/youtube-dl -f best  -o "/opt/youtube/$filename" $url`;
	$logger->info("result of download - url: $url, filename: $filename");
	$logger->info("$download");
	$logger->info("=====================================================================");
	$state = 2;
	&update_video_state($url, $state);
}

sub get_filename_from_url() {
	my $u = $_[0];
	my $f = `/usr/local/bin/youtube-dl --get-filename $u`;
	chomp($f);
	return $f;
}

$dbh->disconnect();

