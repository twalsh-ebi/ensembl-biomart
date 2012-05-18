#!/bin/env perl
#
# $Source$
# $Revision$
# $Date$
# $Author$
#
# Script for splitting datasets from a multi-species mart 

use warnings;
use strict;
use DBI;
use Carp;
use Log::Log4perl qw(:easy);
use List::MoreUtils qw(any);
use Data::Dumper;
use DbiUtils;
use MartUtils;
use Getopt::Long;

Log::Log4perl->easy_init($DEBUG);

my $logger = get_logger();

# db params
my $db_host = 'mysql-cluster-eg-prod-1.ebi.ac.uk';
my $db_port = '4238';
my $db_user = 'ensrw';
my $db_pwd = 'writ3rp1';
my $mart_db;

sub usage {
    print "Usage: $0 [-h <host>] [-port <port>] [-u user <user>] [-p <pwd>] [-mart <mart db>] [-help]\n";
    print "-h <host> Default is $db_host\n";
    print "-port <port> Default is $db_port\n";
    print "-u <host> Default is $db_user\n";
    print "-p <password> Default is top secret unless you know cat\n";
    print "-mart <target mart> Default is $mart_db\n";
    print "-help - this usage\n";
    exit 1;
};

my $options_okay = GetOptions (
    "h=s"=>\$db_host,
    "port=s"=>\$db_port,
    "u=s"=>\$db_user,
    "p=s"=>\$db_pwd,
    "mart=s"=>\$mart_db,
    "help"=>sub {usage()}
    );

if(!$options_okay || !defined $mart_db) {
    usage();
}

my $mart_string = "DBI:mysql:$mart_db:$db_host:$db_port";
my $mart_handle = DBI->connect($mart_string, $db_user, $db_pwd,
	            { RaiseError => 1 }
    ) or croak "Could not connect to $mart_string";

$mart_handle->do("use $mart_db");

# 1. delete from tables in hash 
my %tables_to_tidy;

if($mart_db =~ /_snp_mart/) {
    %tables_to_tidy = (
	'%__mpoly__dm'=>'name_2019',
	'%__variation_set_variation__dm'=>'description_2077',
	'%__variation_annotation__dm'=>'description_2021',
	'%__variation_annotation__dm'=>'name_2033'
    );
} else {
    %tables_to_tidy = (
	'%_transcript_variation__dm'=>'seq_region_id_2026',
	'%_transcript_variation_som__dm'=>'seq_region_id_2026',
	'%__splicing_event__dm'=>'name_1078',
	'%__exp_atlas_%__dm'=>'stable_id_1066',
	'%__exp_est_%__dm'=>'stable_id_1066',
	'%__exp_zfin_%__dm'=>'stable_id_1066',
	'%\_\_go\_%\_\_dm' => 'ontology_id_1006'
	);
}

for my $table_pattern (keys %tables_to_tidy) {
    $logger->info("Finding tables like $table_pattern");
    my $col = $tables_to_tidy{$table_pattern};
    for my $table (query_to_strings($mart_handle,"show tables like '$table_pattern'")) {
	$logger->info("Deleting rows from $table where $col is null");
	eval {
	    $mart_handle->do("DELETE FROM $table WHERE $col IS NULL");
	};
	if($@) {
	    warn "Could not delete from $table:".$@;
	}
    }
}

# 2. find empty tables and drop them
my @tables = query_to_strings($mart_handle,"select table_name from information_schema.tables where table_schema='$mart_db' and TABLE_ROWS=0");
for my $table (@tables) {
    $logger->info("Dropping empty table $table");
    $mart_handle->do("DROP TABLE $table");    
}

# 3. remove TEMP tables and rename tables to lowercase
foreach my $table (get_tables($mart_handle)) {
    if($table =~ /TEMP/) {
	my $sql = "DROP TABLE $table";
	print $sql."\n"; 
	$mart_handle->do($sql);
    } elsif($table =~ m/[A-Z]+/) {
	my $sql = "RENAME TABLE $table TO ".lc($table);
	print $sql."\n"; 
	$mart_handle->do($sql);
    }
}

$mart_handle->disconnect();

$logger->info("Complete");




