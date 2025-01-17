=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::VariationMart::AggregatedData;

use strict;
use warnings;

use base ('Bio::EnsEMBL::VariationMart::Base');

sub param_defaults {
  return {
    'sv_exists' => 0,
    'sv_som_exists' => 0,
  };
}

sub run {
  my ($self) = @_;
  
  my $mart_table_prefix = $self->param_required('mart_table_prefix');
  my $variation_db = $self->get_DBAdaptor('variation')->dbc()->dbname;
  my $prefix = "";

  foreach my $table ( @{$self->param_required('snp_tables')} ) {
    #if ($table eq 'snp__variation_annotation__dm') {
        # The annotation and citation boolean fields aren't used anywhere, and
        # aren't that useful (since there are phenotype and citation filter).
#    $self->variation_annotation_bool($mart_table_prefix, $mart_dbh, $variation_db, $prefix);
#     }
     if ($table eq 'snp__variation_citation__dm') {
        # The annotation and citation boolean fields aren't used anywhere, and
        # aren't that useful (since there are phenotype and citation filter).
        $self->variation_citation_bool($mart_table_prefix, $variation_db, $prefix);
     } 
     elsif ($table eq 'snp__variation__main') {
        # Variation feature counts aren't currently used, but could be useful
        # in the future, so do them for now.
        $self->variation_feature_count($mart_table_prefix, $variation_db, $prefix);
     }
   }

  if ($self->param_required('species') eq 'homo_sapiens')
  {
    $prefix="_som";
    foreach my $table ( @{$self->param_required('snp_som_tables')} ) {
# NO data for human somatic at the moment
# if ($table eq 'snp_som__variation_annotation__dm') {
        # The annotation and citation boolean fields aren't used anywhere, and
        # aren't that useful (since there are phenotype and citation filter).
#       $self->variation_annotation_bool($mart_table_prefix, $mart_dbh, $variation_db, $prefix);
#     }
     if ($table eq 'snp_som__variation_citation__dm') {
        # The annotation and citation boolean fields aren't used anywhere, and
        # aren't that useful (since there are phenotype and citation filter).
        $self->variation_citation_bool($mart_table_prefix, $variation_db, $prefix);
     }
     elsif ($table eq 'snp_som__variation__main') {
        # Variation feature counts aren't currently used, but could be useful
        # in the future, so do them for now.
        $self->variation_feature_count($mart_table_prefix, $variation_db, $prefix);
     }

    }
    if ($self->param('sv_som_exists') and $self->param_required('species') eq 'homo_sapiens') {
      $self->structural_variation_feature_count($mart_table_prefix, $variation_db, $prefix);
    }
  }

  if ($self->param('sv_exists'))  {
      $prefix="";
      $self->structural_variation_feature_count($mart_table_prefix, $variation_db, $prefix);
  }
  
}

sub variation_annotation_bool {
  my ($self, $mart_table_prefix, $variation_db, $prefix) = @_;
  my $hive_dbc = $self->dbc;
  $hive_dbc->disconnect_if_idle();
  $self->add_column($mart_table_prefix.'_snp'.$prefix.'__variation__main', 'variation_annotation_bool', 'int(11) DEFAULT 0');

  my $update_sql =
    'UPDATE '.
    $mart_table_prefix.'_snp'.$prefix.'__variation__main v_m INNER JOIN '.
    $variation_db.'.MTMP_variation_annotation va ON v_m.variation_id_2025_key = va.variation_id '.
    'SET v_m.variation_annotation_bool = 1;';
  my $mart_dbc = $self->mart_dbc;
  $mart_dbc->sql_helper->execute_update(-SQL=>$update_sql) or $self->throw($mart_dbc->errstr);
  $self->add_index($mart_table_prefix.'_snp'.$prefix.'__variation__main', 'idx_vab', '(variation_annotation_bool)');
  $mart_dbc->disconnect_if_idle();
}

sub variation_citation_bool {
  my ($self, $mart_table_prefix, $variation_db, $prefix) = @_;
  my $hive_dbc = $self->dbc;
  $hive_dbc->disconnect_if_idle();
  
  my $update_sql =
    'UPDATE '.
    $mart_table_prefix.'_snp'.$prefix.'__variation__main v_m INNER JOIN '.
    $variation_db.'.variation_citation vc ON v_m.variation_id_2025_key = vc.variation_id '.
    'SET v_m.variation_citation_bool = 1;';
  my $mart_dbc = $self->mart_dbc;
  $mart_dbc->sql_helper->execute_update(-SQL=>$update_sql) or $self->throw($mart_dbc->errstr);
  $self->add_index($mart_table_prefix.'_snp'.$prefix.'__variation__main', 'idx_vcb', '(variation_citation_bool)');
  $mart_dbc->disconnect_if_idle();
}

sub variation_feature_count {
  my ($self, $mart_table_prefix, $variation_db, $prefix) = @_;
  my $hive_dbc = $self->dbc;
  $hive_dbc->disconnect_if_idle();
  
  my $update_sql =
    'UPDATE '.
    $mart_table_prefix.'_snp'.$prefix.'__variation__main v_m '.
    'SET v_m.variation_feature_count = '.
      '(SELECT COUNT(vf.variation_id) FROM '.$variation_db.'.variation_feature vf '.
      'WHERE v_m.variation_id_2025_key = vf.variation_id);';
  my $mart_dbc = $self->mart_dbc;
  $mart_dbc->sql_helper->execute_update(-SQL=>$update_sql) or $self->throw($mart_dbc->errstr);
  $self->add_index($mart_table_prefix.'_snp'.$prefix.'__variation__main', 'idx_vfc', '(variation_feature_count)');
  $mart_dbc->disconnect_if_idle();
}

sub structural_variation_feature_count {
  my ($self, $mart_table_prefix, $variation_db, $prefix) = @_;
  my $hive_dbc = $self->dbc;
  $hive_dbc->disconnect_if_idle();
  # Patch to make sure the column is created at this
  my $update_sql =
    'UPDATE '.
    $mart_table_prefix.'_structvar'.$prefix.'__structural_variation__main sv_m '.
    'SET sv_m.structural_variation_feature_count = '.
      '(SELECT COUNT(svf.structural_variation_id) FROM '.$variation_db.'.structural_variation_feature svf '.
      'WHERE sv_m.structural_variation_id_2072_key = svf.structural_variation_id);';
  my $mart_dbc = $self->mart_dbc;
  $mart_dbc->sql_helper->execute_update(-SQL=>$update_sql) or $self->throw($mart_dbc->errstr);
  $self->add_index($mart_table_prefix.'_structvar'.$prefix.'__structural_variation__main', 'idx_svfc', '(structural_variation_feature_count)');
  $mart_dbc->disconnect_if_idle();
}

1;
