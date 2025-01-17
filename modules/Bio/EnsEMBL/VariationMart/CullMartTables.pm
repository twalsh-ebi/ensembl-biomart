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

package Bio::EnsEMBL::VariationMart::CullMartTables;

use strict;
use warnings;

use base ('Bio::EnsEMBL::VariationMart::Base');

sub run {
  my ($self) = @_;
  
  my %snp_cull_tables = %{$self->param_required('snp_cull_tables')};
  my %snp_cull_columns = %{$self->param_required('snp_cull_columns')};
  
  foreach my $table (keys %snp_cull_tables) {
    $self->cull_table($table, $snp_cull_tables{$table});
  }

  foreach my $table (keys %snp_cull_columns) {
    foreach my $column (@{$snp_cull_columns{$table}})
    {
      $self->cull_column($table, $column);
    }
  }

  if ($self->param_required('species') eq 'homo_sapiens'){
    my %snp_som_cull_tables = %{$self->param_required('snp_som_cull_tables')};
    foreach my $table (keys %snp_som_cull_tables) {
      $self->cull_table($table, $snp_som_cull_tables{$table});
    }
    my %snp_som_cull_columns = %{$self->param_required('snp_som_cull_columns')};
    foreach my $table (keys %snp_som_cull_columns) {
      foreach my $column (@{$snp_som_cull_columns{$table}})
      {
        $self->cull_column($table, $column);
      }
    }
  }

  
  if ($self->param('sv_exists')) {
    my %sv_cull_tables = %{$self->param_required('sv_cull_tables')};
    foreach my $table (keys %sv_cull_tables) {
      $self->cull_table($table, $sv_cull_tables{$table});
    }
  }

  if ($self->param('sv_som_exists') and $self->param_required('species') eq 'homo_sapiens') {
    my %sv_som_cull_tables = %{$self->param_required('sv_som_cull_tables')};
    foreach my $table (keys %sv_som_cull_tables) {
      $self->cull_table($table, $sv_som_cull_tables{$table});
    }
  }

}

sub cull_table {
  my ($self, $table, $column) = @_;
  
  my $hive_dbc = $self->dbc;
  $hive_dbc->disconnect_if_idle();
  my $mart_dbc = $self->mart_dbc;
  my $mart_table_prefix = $self->param_required('mart_table_prefix');
  my $mart_table = "$mart_table_prefix\_$table";
  
  my $tables_sql = "SHOW TABLES LIKE '$mart_table';";
  my $tables = $mart_dbc->sql_helper->execute(-SQL=>$tables_sql);

  if (@$tables) {  
    my $count_sql = "SELECT COUNT(*) FROM $mart_table WHERE $column IS NOT NULL";
    my ($rows) = $mart_dbc->sql_helper->execute_simple(-SQL=>$count_sql)->[0];
    
    if ($rows == 0) {
      my $drop_sql = "DROP TABLE $mart_table";
      $mart_dbc->sql_helper->execute_update(-SQL=>$drop_sql);
    }
  }
  $mart_dbc->disconnect_if_idle();
}

sub cull_column {
  my ($self, $table, $column) = @_;

  my $hive_dbc = $self->dbc;
  $hive_dbc->disconnect_if_idle();
  my $mart_dbc = $self->mart_dbc;
  my $mart_table_prefix = $self->param_required('mart_table_prefix');
  my $mart_table = "$mart_table_prefix\_$table";

  my $tables_sql = "SHOW TABLES LIKE '$mart_table';";
  my $tables = $mart_dbc->sql_helper->execute(-SQL=>$tables_sql);

  if (@$tables) {
    my $count_sql = "SELECT COUNT(*) FROM $mart_table WHERE $column IS NOT NULL";
    my ($rows) = $mart_dbc->sql_helper->execute_simple(-SQL=>$count_sql)->[0];
    
    if ($rows == 0) {
      my $drop_sql = "ALTER TABLE $mart_table DROP COLUMN $column";
      $mart_dbc->sql_helper->execute_update(-SQL=>$drop_sql);
    }
  }
  $mart_dbc->disconnect_if_idle();
}

1;
