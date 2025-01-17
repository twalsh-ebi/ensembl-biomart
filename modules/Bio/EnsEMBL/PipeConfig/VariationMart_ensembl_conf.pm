=head1 LICENSE

Copyright [1999-2022] EMBL-European Bioinformatics Institute
and Wellcome Trust Sanger Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=pod

=head1 NAME

Bio::EnsEMBL::PipeConfig::VariationMart_ensembl_conf

=head1 DESCRIPTION

Configuration for running the Variation Mart pipeline, which
constructs a mart database from core and variation databases.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::PipeConfig::VariationMart_ensembl_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::PipeConfig::VariationMart_conf');

sub default_options {
    my ($self) = @_;
    return {
        %{$self->SUPER::default_options},

        division_name           => 'vertebrates',
        mart_db_name            => 'snp_mart_' . $self->o('ensembl_release'),
        drop_mtmp               => 1,
        drop_mtmp_tv            => 0,
        sample_threshold        => 0,
        population_threshold    => 500,
        optimize_tables         => 1,
        populate_mart_rc_name   => '8Gb_mem',
        genomic_features_dbname => 'genomic_features_mart_' . $self->o('ensembl_release'),

        # Most mart table configuration is in VariationMart_conf, but e! and EG
        # differ in the absence/presence of the poly__dm table.
        snp_indep_tables        => [
            'snp__variation__main',
            'snp__population_genotype__dm',
            'snp__variation_annotation__dm',
            'snp__variation_citation__dm',
            'snp__variation_set_variation__dm',
            'snp__variation_synonym__dm',
        ],

        snp_cull_tables         => {
            'snp__population_genotype__dm'     => 'name_2019',
            'snp__variation_annotation__dm'    => 'name_2021',
            'snp__variation_citation__dm'      => 'authors_20137',
            'snp__variation_set_variation__dm' => 'name_2077',
            'snp__variation_synonym__dm'       => 'name_2030',
        },
    };
}

1;
