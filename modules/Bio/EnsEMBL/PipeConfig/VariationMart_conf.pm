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

Bio::EnsEMBL::PipeConfig::VariationMart_conf

=head1 DESCRIPTION

Configuration for running the Variation Mart pipeline, which
constructs a mart database from core and variation databases.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::PipeConfig::VariationMart_conf;

use strict;
use warnings;
use File::Spec::Functions qw(catdir);
use Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf qw( WHEN );
use base ('Bio::EnsEMBL::Hive::PipeConfig::EnsemblGeneric_conf');

sub default_options {
    my ($self) = @_;
    return {
        %{$self->SUPER::default_options},

        pipeline_name            => 'variation_mart_' . $self->o('ensembl_release'),
        drop_mart_db             => 0,
        drop_mart_tables         => 0,
        mtmp_tables_exist        => 0,
        always_skip_genotypes    => [],
        never_skip_genotypes     => [],
        drop_mtmp                => 1,
        drop_mtmp_tv             => 0,
        snp_indep_tables         => [],
        sample_threshold         => 0,
        populate_mart_rc_name    => '4Gb_mem',
        snp_cull_tables          => [],
        snp_cull_columns         => [],
        optimize_tables          => 0,
        population_threshold     => 100,
        species_suffix           => '',
        max_dropdown             => '20000',

        base_dir                 => $self->o('ENV', 'BASE_DIR'),
        biomart_dir              => $self->o('base_dir') . '/ensembl-biomart',
        grch37                   => 0,

        scratch_dir              => catdir('/hps/nobackup/flicek/ensembl', $self->o('ENV', 'USER'), $self->o('pipeline_name')),
        test_dir                 => catdir('/hps/nobackup/flicek/ensembl/production', $self->o('ENV', 'USER'), 'mart_test', $self->o('pipeline_name')),

        previous_mart            => {
            -driver => $self->o('hive_driver'),
            -host   => $self->o('host'),
            -port   => $self->o('port'),
            -user   => $self->o('user'),
            -dbname => undef,
        },

        species                  => [],
        antispecies              => [],
        division                 => [],
        run_all                  => 0,

        copy_species             => [],
        copy_all                 => 0,

        partition_size           => 100000,

        # The following are required for building MTMP tables.
        variation_import_lib     => $self->o('base_dir') .
            '/ensembl-variation/scripts/import',

        variation_feature_script => $self->o('base_dir') .
            '/ensembl-variation/scripts/misc/mart_variation_effect.pl',

        variation_mtmp_script    => $self->o('base_dir') .
            '/ensembl-variation/scripts/misc/create_MTMP_tables.pl',

        # Mart tables are mostly independent in that their construction does not
        # rely on other mart tables. The only execption are the *_feature__main
        # tables, which contain all of the columns in the *_variation__main tables.

        # snp_indep_tables should be defined in an inheriting module

        snp_som_indep_tables     => [
            'snp_som__variation__main',
            'snp_som__population_genotype__dm',
            'snp_som__variation_annotation__dm',
            'snp_som__variation_citation__dm',
            'snp_som__variation_set_variation__dm',
            'snp_som__variation_synonym__dm',
        ],

        snp_dep_tables           => [
            'snp__variation_feature__main',
            'snp__mart_transcript_variation__dm',
            'snp__motif_feature_variation__dm',
            'snp__regulatory_feature_variation__dm',
        ],

        snp_som_dep_tables       => [
            'snp_som__variation_feature__main',
            'snp_som__mart_transcript_variation__dm',
            'snp_som__regulatory_feature_variation__dm',
        ],

        sv_indep_tables          => [
            'structvar__structural_variation__main',
            'structvar__structural_variation_annotation__dm',
            'structvar__supporting_structural_variation__dm',
            'structvar__variation_set_structural_variation__dm',
            'structvar__phenotype__dm',
        ],

        sv_som_indep_tables      => [
            'structvar_som__structural_variation__main',
            'structvar_som__structural_variation_annotation__dm',
            'structvar_som__supporting_structural_variation__dm',
            'structvar_som__variation_set_structural_variation__dm',
            'structvar_som__phenotype__dm',
        ],

        sv_dep_tables            => [
            'structvar__structural_variation_feature__main',
        ],

        sv_som_dep_tables        => [
            'structvar_som__structural_variation_feature__main',
        ],

        # snp_cull_tables should be defined in an inheriting module

        snp_cull_columns         => {
            'snp__mart_transcript_variation__dm' => [ 'polyphen_score_2090', 'sift_score_2090' ],
        },

        snp_som_cull_columns     => {
            'snp_som__mart_transcript_variation__dm' => [ 'pep_allele_string_2090', 'polyphen_prediction_2090', 'polyphen_score_2090', 'sift_prediction_2090', 'sift_score_2090' ],
            'snp_som__variation__main'               => [ 'clinical_significance_2025', 'minor_allele_2025', 'minor_allele_count_2025', 'minor_allele_freq_2025' ],
            'snp_som__variation_feature__main'       => [ 'clinical_significance_2025', 'minor_allele_2025', 'minor_allele_count_2025', 'minor_allele_freq_2025' ],
            'snp_som__variation_annotation__dm'      => [ 'associated_gene_2035', 'associated_variant_risk_allele_2035', 'description_20100', 'external_reference_20100', 'name_20100', 'p_value_2035', 'study_type_20100', 'variation_names_2035' ],
        },

        snp_som_cull_tables      => {
            'snp_som__population_genotype__dm'     => 'name_2019',
            'snp_som__variation_annotation__dm'    => 'name_2021',
            'snp_som__variation_citation__dm'      => 'authors_20137',
            'snp_som__variation_set_variation__dm' => 'name_2077',
            'snp_som__variation_synonym__dm'       => 'name_2030',
        },

        sv_cull_tables           => {
            'structvar__structural_variation_annotation__dm'    => 'name_2019',
            'structvar__supporting_structural_variation__dm',   => 'supporting_structural_variation_id_20116',
            'structvar__variation_set_structural_variation__dm' => 'name_2077',
            'structvar__phenotype__dm'                          => 'phenotype_name',
        },

        sv_som_cull_tables       => {
            'structvar_som__structural_variation_annotation__dm'    => 'name_2019',
            'structvar_som__supporting_structural_variation__dm',   => 'supporting_structural_variation_id_20116',
            'structvar_som__variation_set_structural_variation__dm' => 'name_2077',
            'structvar_som__phenotype__dm'                          => 'phenotype_name',
        },

        tables_dir               => $self->o('biomart_dir') . '/var_mart/tables',

        # The following are required for adding metadata.
        scripts_lib              => $self->o('biomart_dir') . '/scripts',

        generate_names_script    => $self->o('biomart_dir') .
            '/scripts/generate_names.pl',

        generate_meta_script     => $self->o('biomart_dir') .
            '/scripts/generate_meta.pl',

        template_template        => $self->o('biomart_dir') .
            '/scripts/templates/variation_template_template.xml',

        template_sv_template     => $self->o('biomart_dir') .
            '/scripts/templates/structvar_template_template.xml',

        template_som_template    => $self->o('biomart_dir') .
            '/scripts/templates/variation_som_template_template.xml',

        template_sv_som_template => $self->o('biomart_dir') .
            '/scripts/templates/structvar_som_template_template.xml',
    };
}

# Force an automatic loading of the registry in all workers.
sub beekeeper_extra_cmdline_options {
    my $self = shift;
    return "-reg_conf " . $self->o("registry");
}

# Ensures that species output parameter gets propagated implicitly.
sub hive_meta_table {
    my ($self) = @_;

    return {
        %{$self->SUPER::hive_meta_table},
        'hive_use_param_stack' => 1,
    };
}

sub pipeline_create_commands {
    my ($self) = @_;
    return [
        # inheriting database and hive tables' creation
        @{$self->SUPER::pipeline_create_commands},
        'mkdir -p ' . $self->o('test_dir'),
        'mkdir -p ' . $self->o('scratch_dir'),
    ];
}

sub pipeline_analyses {
    my ($self) = @_;

    return [
        {
            -logic_name      => 'InitialiseMartDB',
            -module          => 'Bio::EnsEMBL::VariationMart::InitialiseMartDB',
            -input_ids       => [ {} ],
            -parameters      => {
                mart_db_name => $self->o('mart_db_name'),
                drop_mart_db => $self->o('drop_mart_db'),
            },
            -max_retry_count => 0,
            -flow_into       => {
                '1->A' => [ 'ScheduleSpecies' ],
                'A->1' => [ 'AddMetaData' ],
            }
        },

        {
            -logic_name      => 'ScheduleSpecies',
            -module          => 'Bio::EnsEMBL::Production::Pipeline::Common::SpeciesFactory',
            -parameters      => {
                species     => $self->o('species'),
                antispecies => $self->o('antispecies'),
                division    => $self->o('division'),
                run_all     => $self->o('run_all'),
            },
            -max_retry_count => 0,
            -flow_into       => {
                '4' => 'DropMartTables'
            }
        },

        {
            -logic_name        => 'DropMartTables',
            -module            => 'Bio::EnsEMBL::VariationMart::DropMartTables',
            -parameters        => {
                drop_mart_tables => $self->o('drop_mart_tables'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 5,
            -flow_into         => [ 'CopyOrGenerate' ],
        },

        {
            -logic_name      => 'CopyOrGenerate',
            -module          => 'Bio::EnsEMBL::VariationMart::CopyOrGenerate',
            -parameters      => {
                mtmp_tables_exist     => $self->o('mtmp_tables_exist'),
                copy_species          => $self->o('copy_species'),
                copy_all              => $self->o('copy_all'),
                sample_threshold      => $self->o('sample_threshold'),
                population_threshold  => $self->o('population_threshold'),
                always_skip_genotypes => $self->o('always_skip_genotypes'),
                never_skip_genotypes  => $self->o('never_skip_genotypes'),
                division_name         => $self->o('division_name'),
                species_suffix        => $self->o('species_suffix'),
                ensembl_cvs_root_dir  => $self->o('base_dir')
            },
            -max_retry_count => 0,
            -flow_into       => {
                '3->B' => WHEN('#mtmp_tables_exist# == 0', [ 'CreateMTMPTables' ]), 
                '4'    => [ 'CopyMart' ],
                'B->5' => [ 'GenerateMart' ],
            }
        },

        {
            -logic_name        => 'CreateMTMPTables',
            -module            => 'Bio::EnsEMBL::VariationMart::CreateMTMPTables',
            -parameters        => {
                drop_mtmp                => $self->o('drop_mtmp'),
                drop_mtmp_tv             => $self->o('drop_mtmp_tv'),
                variation_import_lib     => $self->o('variation_import_lib'),
                variation_feature_script => $self->o('variation_feature_script'),
                variation_mtmp_script    => $self->o('variation_mtmp_script'),
                registry                 => $self->o('registry'),
                scratch_dir              => $self->o('scratch_dir'),
            },
            -max_retry_count   => 3,
            -analysis_capacity => 5,
            -can_be_empty      => 1,
            -rc_name           => '16Gb_mem',
        },

        {
            -logic_name        => 'CopyMart',
            -module            => 'Bio::EnsEMBL::VariationMart::CopyMart',
            -parameters        => {
                previous_mart => $self->o('previous_mart'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 5,
            -can_be_empty      => 1,
            -rc_name           => '16Gb_mem',
        },

        {
            -logic_name      => 'GenerateMart',
            -module          => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -parameters      => {},
            -max_retry_count => 0,
            -can_be_empty    => 1,
            -flow_into       => {
                '1->A' => [ 'CreateMartTables' ],
                'A->1' => [ 'CullMartTables' ],
            }
        },

        {
            -logic_name      => 'CreateMartTables',
            -module          => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -parameters      => {},
            -max_retry_count => 0,
            -flow_into       => {
                '1->A' => [ 'CreateIndependentTables' ],
                'A->1' => [ 'AggregatedData' ],
            }
        },

        {
            -logic_name        => 'CreateIndependentTables',
            -module            => 'Bio::EnsEMBL::VariationMart::CreateMartTables',
            -parameters        => {
                snp_tables        => $self->o('snp_indep_tables'),
                snp_som_tables    => $self->o('snp_som_indep_tables'),
                sv_tables         => $self->o('sv_indep_tables'),
                sv_som_tables     => $self->o('sv_som_indep_tables'),
                tables_dir        => $self->o('tables_dir'),
                variation_feature => 0,
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -flow_into         => {
                '1->A' => [ 'PartitionTables' ],
                'A->1' => [ 'CreateMartIndexes' ],
            },
        },

        {
            -logic_name        => 'CreateDependentTables',
            -module            => 'Bio::EnsEMBL::VariationMart::CreateMartTables',
            -parameters        => {
                snp_tables        => $self->o('snp_dep_tables'),
                snp_som_tables    => $self->o('snp_som_dep_tables'),
                sv_tables         => $self->o('sv_dep_tables'),
                sv_som_tables     => $self->o('sv_som_dep_tables'),
                tables_dir        => $self->o('tables_dir'),
                variation_feature => 1,
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -flow_into         => {
                '1->A' => [ 'PartitionTables' ],
                'A->1' => [ 'CreateMartIndexes' ],
            },
        },

        {
            -logic_name        => 'PartitionTables',
            -module            => 'Bio::EnsEMBL::VariationMart::PartitionTables',
            -parameters        => {
                partition_size => $self->o('partition_size'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -flow_into         => [ 'PopulateMart' ],
        },

        {
            -logic_name        => 'PopulateMart',
            -module            => 'Bio::EnsEMBL::VariationMart::PopulateMart',
            -parameters        => {
                tables_dir => $self->o('tables_dir')
            },
            -max_retry_count   => 3,
            -analysis_capacity => 50,
            -rc_name           => $self->o('populate_mart_rc_name'),
        },

        {
            -logic_name        => 'AggregatedData',
            -module            => 'Bio::EnsEMBL::VariationMart::AggregatedData',
            -parameters        => {
                snp_tables     => $self->o('snp_indep_tables'),
                snp_som_tables => $self->o('snp_som_indep_tables'),
                sv_tables      => $self->o('sv_indep_tables'),
                sv_som_tables  => $self->o('sv_som_indep_tables'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -flow_into         => [ 'CreateDependentTables' ],
        },

        # {
        #   -logic_name        => 'OrderColumns',
        #   -module            => 'Bio::EnsEMBL::VariationMart::OrderColumns',
        #   -parameters        => {
        #                         },
        #   -flow_into         => ['CreateMartIndexes'],
        #   -max_retry_count   => 3,
        # },

        {
            -logic_name        => 'CreateMartIndexes',
            -module            => 'Bio::EnsEMBL::VariationMart::CreateMartIndexes',
            -parameters        => {
                tables_dir => $self->o('tables_dir'),
            },
            -max_retry_count   => 2,
            -analysis_capacity => 10,
        },

        {
            -logic_name        => 'CullMartTables',
            -module            => 'Bio::EnsEMBL::VariationMart::CullMartTables',
            -parameters        => {
                snp_cull_tables      => $self->o('snp_cull_tables'),
                snp_cull_columns     => $self->o('snp_cull_columns'),
                snp_som_cull_columns => $self->o('snp_som_cull_columns'),
                snp_som_cull_tables  => $self->o('snp_som_cull_tables'),
                sv_cull_tables       => $self->o('sv_cull_tables'),
                sv_som_cull_tables   => $self->o('sv_som_cull_tables'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
        },

        {
            -logic_name        => 'AddMetaData',
            -module            => 'Bio::EnsEMBL::VariationMart::AddMetaData',
            -parameters        => {
                scripts_lib             => $self->o('scripts_lib'),
                generate_names_script   => $self->o('generate_names_script'),
                generate_meta_script    => $self->o('generate_meta_script'),
                template_template       => $self->o('template_template'),
                max_dropdown            => $self->o('max_dropdown'),
                genomic_features_dbname => $self->o('genomic_features_dbname'),
                division_name           => $self->o('division_name'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -can_be_empty      => 1,
            -flow_into         => [ 'AddSOMMetaData' ],
        },

        {
            -logic_name        => 'AddSOMMetaData',
            -module            => 'Bio::EnsEMBL::VariationMart::AddMetaData',
            -parameters        => {
                scripts_lib             => $self->o('scripts_lib'),
                generate_names_script   => $self->o('generate_names_script'),
                generate_meta_script    => $self->o('generate_meta_script'),
                template_template       => $self->o('template_som_template'),
                dataset_name            => 'snp_som',
                description             => 'variations_som',
                max_dropdown            => $self->o('max_dropdown'),
                genomic_features_dbname => $self->o('genomic_features_dbname'),
                division_name           => $self->o('division_name'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -can_be_empty      => 1,
            -flow_into         => [ 'AddSVMetaData' ],
        },

        {
            -logic_name        => 'AddSVMetaData',
            -module            => 'Bio::EnsEMBL::VariationMart::AddMetaData',
            -parameters        => {
                scripts_lib             => $self->o('scripts_lib'),
                generate_names_script   => $self->o('generate_names_script'),
                generate_meta_script    => $self->o('generate_meta_script'),
                template_template       => $self->o('template_sv_template'),
                dataset_name            => 'structvar',
                description             => 'structural_variations',
                max_dropdown            => $self->o('max_dropdown'),
                genomic_features_dbname => $self->o('genomic_features_dbname'),
                division_name           => $self->o('division_name'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -can_be_empty      => 1,
            -flow_into         => [ 'AddSVSOMMetaData' ],
        },
        {
            -logic_name        => 'AddSVSOMMetaData',
            -module            => 'Bio::EnsEMBL::VariationMart::AddMetaData',
            -parameters        => {
                scripts_lib             => $self->o('scripts_lib'),
                generate_names_script   => $self->o('generate_names_script'),
                generate_meta_script    => $self->o('generate_meta_script'),
                template_template       => $self->o('template_sv_som_template'),
                dataset_name            => 'structvar_som',
                description             => 'structural_variations_som',
                max_dropdown            => $self->o('max_dropdown'),
                genomic_features_dbname => $self->o('genomic_features_dbname'),
                division_name           => $self->o('division_name'),
            },
            -max_retry_count   => 0,
            -analysis_capacity => 10,
            -can_be_empty      => 1,
            -flow_into         => [ 'AnalyzeTables' ],
        },

        {
            -logic_name      => 'AnalyzeTables',
            -module          => 'Bio::EnsEMBL::VariationMart::AnalyzeTables',
            -parameters      => {
                optimize_tables => $self->o('optimize_tables'),
            },
            -max_retry_count => 0,
            -flow_into       => [ 'run_tests' ],
        },
        {
            -logic_name => 'run_tests',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters => {
                cmd         => 'cd #test_dir#;perl #base_dir#/ensembl-biomart/scripts/pre_configuration_mart_healthcheck.pl -newuser #user# -newpass #pass# -newport #port# -newhost #host# -olduser #olduser# -oldport #oldport# -oldhost #oldhost# -new_dbname #mart# -old_dbname #old_mart# -old_rel #old_release# -new_rel #new_release# -empty_column 1 -grch37 #grch37# -mart snp_mart',
                mart        => $self->o('mart_db_name'),
                user        => $self->o('user'),
                pass        => $self->o('pass'),
                host        => $self->o('host'),
                port        => $self->o('port'),
                olduser     => $self->o('olduser'),
                oldhost     => $self->o('oldhost'),
                oldport     => $self->o('oldport'),
                old_mart    => $self->o('old_mart'),
                test_dir    => $self->o('test_dir'),
                old_release => $self->o('old_release'),
                new_release => $self->o('ensembl_release'),
                base_dir    => $self->o('base_dir'),
                grch37      => $self->o('grch37'),
            },
            -flow_into  => [ 'check_tests' ],
        },
        {
            -logic_name => 'check_tests',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters => {
                cmd      => 'EXIT_CODE=0;failed_tests=`find #test_dir#/#old_mart#_#oldhost#_vs_#mart#_#host#.* -type f ! -empty -print`;if [ -n "$failed_tests" ]; then >&2 echo "Some tests have failed please check ${failed_tests}";EXIT_CODE=1;fi;exit $EXIT_CODE',
                mart     => $self->o('mart_db_name'),
                host     => $self->o('host'),
                oldhost  => $self->o('oldhost'),
                old_mart => $self->o('old_mart'),
                test_dir => $self->o('test_dir'),
            },
        }
    ];
}

sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
        %{$self->SUPER::pipeline_wide_parameters},
        'scratch_dir' => $self->o('scratch_dir'),
        'test_dir'    => $self->o('test_dir')
    }
}

sub resource_classes {
    my ($self) = @_;
    return {
        'default'  => { 'LSF' => '-q production' },
        '4Gb_mem'  => { 'LSF' => '-q production -M 4096 -R "rusage[mem=4096]"' },
        '8Gb_mem'  => { 'LSF' => '-q production -M 8192 -R "rusage[mem=8192]"' },
        '16Gb_mem' => { 'LSF' => '-q production -M 16384 -R "rusage[mem=16384]"' },
    }
}


1;
