#!/bin/env perl
# Copyright [2009-2022] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# $Source$
# $Revision$
# $Date$
# $Author$
#
# Script to populate homology dimension tables for partitioned marts from a set of SQL templates

use warnings;
use strict;
use DBI;
use Data::Dumper;
use Carp;
use Log::Log4perl qw(:easy);
use FindBin;
use lib "$FindBin::Bin/../modules";
use DbiUtils qw(get_string);
use MartUtils qw(get_dataset_names get_species_name_for_dataset get_sql_name_for_dataset);
use Cwd;
use File::Copy;
use Getopt::Long;

Log::Log4perl->easy_init($DEBUG);

my $logger = get_logger();

my $template_dir = "$FindBin::Bin/templates";

# db params

my $db_host = 'mysql-cluster-eg-prod-1.ebi.ac.uk';
my $db_port = '4238';
my $db_user = 'ensrw';
my $db_pwd = 'writ3rp1';
my $mart_db = 'metazoa_mart_4';
my $compara_db ='ensembl_compara_metazoa_4_56';
sub usage {
    print "Usage: $0 [-h <host>] [-P <port>] [-u user <user>] [-p <pwd>] [-src_mart <src>] [-target_mart <targ>]\n";
    print "-h <host> Default is $db_host\n";
    print "-P <port> Default is $db_port\n";
    print "-u <host> Default is $db_user\n";
    print "-p <password> Default is top secret unless you know cat\n";
    print "-mart <mart_db> Default is $mart_db\n";
    print "-compara <compara_db> Default is $compara_db\n";
    exit 1;
};

my $options_okay = GetOptions (
    "h=s"=>\$db_host,
    "P=s"=>\$db_port,
    "u=s"=>\$db_user,
    "p=s"=>\$db_pwd,
    "mart=s"=>\$mart_db,
    "compara=s"=>\$compara_db,
    "help"=>sub {usage()}
    );

if(!$options_okay) {
    usage();
}

my %statement_cache = ();
my $mart_string = "DBI:mysql:$mart_db:$db_host:$db_port";
my $mart_handle = DBI->connect($mart_string, $db_user, $db_pwd,
			       { RaiseError => 1 }
    ) or croak "Could not connect to $mart_string";

sub get_species_sets {
    my ($sth,$dataset,$dataset2) = @_;
    $dataset=$dataset || '';
#   print "dataset $dataset2\n";
    my @species_sets = ();
    $sth->execute($dataset,$dataset2,$dataset,$dataset2);
    while(my @data = $sth->fetchrow_array()) {
	my $tld = $data[3];
#	print "Answer=".Dumper(@data);
#	if(!$tld) {
#	    $tld= $data[3];
#}
	push(@species_sets,{id=>$data[0],name=>$data[1], tld=>$tld});       
    }    
    @species_sets;
}

sub write_species {
    my ($dataset, $species_id, $species_name, $speciesTld, $sql_file_name) = @_;
    my $ds = $dataset.'_gene';
    open my $sql_file, '<', $sql_file_name or croak "Could not open SQL file $sql_file_name for reading";
    print "Writing species $dataset $species_id $species_name $speciesTld\n";
    my $indexN = 0;
    while (my $sql = <$sql_file>) {
	chomp($sql);
	if($sql ne q{} && !($sql =~ m/^#/)) {
	    my $indexName = 'I_'.$species_id.'_'.++$indexN;
	    $sql =~ s/;$//;
	    $sql =~ s/%srcSchema%/$compara_db/g;
	    $sql =~ s/%martSchema%/$mart_db/g;
	    $sql =~ s/%dataSet%/$ds/g;
	    $sql =~ s/%speciesTld%/$speciesTld/g;
	    $sql =~ s/%method_link_species_set_id%/$species_id/g;
	    $sql =~ s/%indexName%/$indexName/;
	    #print "Executing $sql\n";
	    my $sth = $statement_cache{$sql};
	    if(!$sth) {
		$sth = $mart_handle->prepare($sql);
		$statement_cache{$sql} = $sth;
	    }
	    $sth->execute();
	}
    }
    close($sql_file);
}

my $species_homolog_sql = qq{
select ms.method_link_species_set_id, g.name, CONCAT(CONCAT(n.src_dataset,'_'),n.species_id), n.name from $compara_db.species_set s
join $compara_db.method_link_species_set ms using (species_set_id)
join $compara_db.method_link m using (method_link_id)
join $compara_db.genome_db g using (genome_db_id)
join $mart_db.dataset_names n on (n.sql_name=g.name or n.species_name=g.name)
where
s.species_set_id in (
select distinct (ss.species_set_id) from
       $compara_db.species_set ss
join $compara_db.genome_db gg
     using (genome_db_id)
where (gg.name=? or gg.name=?)
AND gg.assembly_default=1
)
AND g.name<>? AND g.name<>?
AND g.assembly_default=1
AND m.type='ENSEMBL_ORTHOLOGUES'
};
print $species_homolog_sql;

my $species_paralog_sql = qq{
select ms.method_link_species_set_id, g.name, CONCAT(CONCAT(n.src_dataset,'_'),n.species_id) from $compara_db.species_set s
join $compara_db.method_link_species_set ms using (species_set_id)
join $compara_db.method_link m using (method_link_id)
join $compara_db.genome_db g using (genome_db_id)
join $mart_db.dataset_names n on (n.sql_name=g.name or n.species_name=g.name)
where
s.species_set_id in (
select distinct (ss.species_set_id) from
       $compara_db.species_set ss
join $compara_db.genome_db gg
     using (genome_db_id)
where (gg.name=? or gg.name=?)
AND gg.assembly_default=1
)
AND (g.name=? OR g.name=?) AND m.type='ENSEMBL_PARALOGUES'
AND g.assembly_default=1
and ms.method_link_species_set_id in 
(select method_link_species_set_id  from $compara_db.homology where description='within_species_paralog')
};
print $species_paralog_sql;

my $species_homolog_sth = $mart_handle->prepare($species_homolog_sql);
my $species_paralog_sth = $mart_handle->prepare($species_paralog_sql);
my $homolog_sql = "$template_dir/update_homo.sql.tmp";
my $paralog_sql = "$template_dir/update_para.sql.tmp";

my $get_species_id_sth = $mart_handle->prepare('select species_id from dataset_names where name=?');
my $get_species_clade_sth = $mart_handle->prepare('select src_dataset from dataset_names where name=?');

# iterate over each dataset
#my @datasets = grep{m/d.*eg/}get_dataset_names($mart_handle);
my @datasets = get_dataset_names($mart_handle);
for my $dataset (@datasets) {
    my $ds_name_sql = get_sql_name_for_dataset($mart_handle,$dataset);
    my $ds_name_full = get_species_name_for_dataset($mart_handle,$dataset);
    $logger->info("Processing $dataset for $ds_name_full/$ds_name_sql");
    # work out species name from $dataset
    # get list of method_link_species_set_id/name pairs for homolog partners
#print "$species_homolog_sql $ds_name_sql $ds_name_full\n";
    for my $species_set (get_species_sets($species_homolog_sth,$ds_name_sql,$ds_name_full)) {
	$logger->info('Processing homologs for '.$species_set->{name}.' as '.$species_set->{tld});
	write_species($dataset, $species_set->{id}, $species_set->{name}, $species_set->{tld}, $homolog_sql);
    }
    # get paralogs
    my $id = get_string($get_species_id_sth,$dataset);
    my $clade = get_string($get_species_clade_sth,$dataset);
    $logger->info("Processing paralogs for $dataset with $ds_name_sql ,$ds_name_full\n");
    my $method_link_species_id = get_string($species_paralog_sth,$ds_name_sql,$ds_name_full,$ds_name_sql,$ds_name_full);
    if($method_link_species_id && $id) {
	$logger->info("Writing paralogs for $dataset with id $dataset");
	write_species($dataset, $method_link_species_id, $dataset, $dataset, $paralog_sql);
	$logger->info("Completed writing paralogs for $dataset with id $dataset");
    }
}
$logger->info("Completed processing");
$species_homolog_sth->finish() or carp "Could not close statement handle";
$species_paralog_sth->finish() or carp "Could not close statement handle";
$get_species_id_sth->finish() or carp "Could not close statement handle";
$get_species_clade_sth->finish() or carp "Could not close statement handle";
$mart_handle->disconnect() or carp "Could not close handle to $mart_string";

