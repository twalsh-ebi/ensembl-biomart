#!/usr/bin/env perl

=head1 LICENSE

Copyright [2016-2022] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=head1 SYNOPSIS

generate_meta.pl [arguments]

  --user=user                      username for the BioMart database

  --pass=pass                      password for the BioMart database

  --host=host                      server for the BioMart database

  --port=port                      port for the BioMart database

  --dbname=name                      BioMart database name

  --template=file                    template file to load

  --template_name=name               name of the template

  --ds_basename=name                 mart dataset base name

  --max_dropdown=number              number of maximun allowed items in a filter dropdown

  --genomic_features_dbname          genomic_features_mart database name

  --ini_file                         Github link of the ini file containing the xref URLs (DEFAULT.ini).

  --registry                         Give a registry file to load core, variation and regulation databases

  --verbose			     show debug info

  --help                              print help (this message)

=head1 DESCRIPTION

This script is used to populate the metatables of the supplied biomart database

=head1 AUTHOR

Dan Staines

=cut

use warnings;
use strict;
use XML::Simple;
use Data::Dumper;
use Carp;
use File::Slurp;
use Log::Log4perl qw(:easy);

use Bio::EnsEMBL::Utils::CliHelper;
use Bio::EnsEMBL::BioMart::MetaBuilder;
use Bio::EnsEMBL::Registry;

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();

my $optsd = $cli_helper->get_dba_opts();
# add the print option
push( @{$optsd}, "template_name:s" );
push( @{$optsd}, "ds_basename:s" );
push( @{$optsd}, "template:s" );
push( @{$optsd}, "genomic_features_dbname:s" );
push( @{$optsd}, "registry:s" );
push( @{$optsd}, "xref_url_ini_file:s");
push( @{$optsd}, "max_dropdown:i" );
push( @{$optsd}, "scratch_dir:s" );
push( @{$optsd}, "verbose" );

# process the command line with the supplied options plus a help subroutine
my $opts = $cli_helper->process_args( $optsd, \&pod2usage );
$opts->{template_name} ||= 'genes';
$opts->{ds_basename}   ||= '';
$opts->{max_dropdown}  ||= 256;
$opts->{genomic_features_dbname} ||= '';
if ( $opts->{verbose} ) {
  Log::Log4perl->easy_init($DEBUG);
}
else {
  Log::Log4perl->easy_init($INFO);
}
my $logger = get_logger();
$logger->info( "Reading " . $opts->{template_name} . " template XML from " .
               $opts->{template} );
# load in template
my $template = read_file( $opts->{template} );
my $templ = XMLin( $template, KeepRoot => 1, KeyAttr => [] );

$logger->info("Opening connection to mart database");
my ($dba) = @{ $cli_helper->get_dbas_for_opts($opts) };

# load registry
my $registry_loaded='Bio::EnsEMBL::Registry';
if(defined $opts->{registry}) {
  $registry_loaded->load_all($opts->{registry});
} else {
  $registry_loaded->load_registry_from_db(
                                               -host       => $opts->{host},
                                                -user       => $opts->{user},
                                                -pass       => $opts->{pass},
                                                -port       => $opts->{port});
}
# Retrieving different ini files for e! and EG species.
# This is only for the genes marts
if ($opts->{template_name} eq 'genes'){
  if ($dba->dbc()->dbname() =~ 'ensembl' or $dba->dbc()->dbname() =~ 'mouse')
  {
    $opts->{ini_file} ||= 'https://raw.githubusercontent.com/Ensembl/ensembl-webcode/master/conf/ini-files/DEFAULTS.ini';
  }
  else {
    $dba->dbc()->dbname() =~ m/^([a-z0-9]+)_.+/;
    my $division = $1;
    $division = 'vectorbase' if $division eq 'vb';
    $opts->{ini_file} ||= "https://raw.githubusercontent.com/EnsemblGenomes/eg-web-${division}/master/conf/ini-files/DEFAULTS.ini";
  }
}
else
{
  $opts->{ini_file} ||= '';
}

# build
my $builder =
  Bio::EnsEMBL::BioMart::MetaBuilder->new( -DBC    => $dba->dbc(),
                                           -BASENAME => $opts->{ds_basename},
                                           -MAX_DROPDOWN =>  $opts->{max_dropdown} );

$builder->build( $opts->{template_name}, $templ, $opts->{genomic_features_dbname}, $opts->{ini_file}, $registry_loaded, $opts->{scratch_dir} );

