package AgileRest::Controller::Database;
use Mojo::Base 'Mojolicious::Controller';


sub map {
  my $self = shift;
  my $API = $self->API;
  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  my @tables = $API->get_tables();
  my @maped_tables;
  foreach( @tables )
  {
    my $new_maped_table_id = 0;
    my $already_maped = $API->Select( "SELECT agile_rest_table_id,table_name FROM agile_rest_table WHERE table_name = '".$_."';" );
    if ( defined( $already_maped ) ) {
      $new_maped_table_id = @{ $already_maped }[0]->{agile_rest_table_id};
    }
    else
    {
      my @table_value;
      push @table_value, $_;
      push @table_value, $_;
      $new_maped_table_id = $API->Insert( {
        table => 'agile_rest_table'
        ,columns => 'table_name, grid_name'
        ,placeholders => '?, ?'
        ,primary_key => 'agile_rest_table_id'
        ,values => [@table_value]
      } );
      push @maped_tables, $_;
    }

      my @columns = @{ $API->get_table_schema( $_ )->{columns} };
      my @fkeys = $API->get_table_foreing_keys( $_ );
      foreach my $column_hash ( @columns )
      {
        my $column_exist = $API->Select( "SELECT column_name FROM agile_rest_column WHERE column_name = '".$column_hash->{name}."' AND agile_rest_table_id = '".$new_maped_table_id."';" );
        if ( defined( $column_exist ) ) {

        }
        else
        {
          my @column_values;
          my $found_fkey = 0;
          push @column_values, $new_maped_table_id;
          push @column_values, $column_hash->{name};
          push @column_values, $column_hash->{type};
          push @column_values, $column_hash->{name};
          push @column_values, $API->sqlToDHTMLXsort( $column_hash->{type} );
          push @column_values, $column_hash->{maxlenght};
          push @column_values, $API->sqlToDhxFormType( $column_hash->{type} );
          push @column_values, $API->sqlToDhxFormMask( $column_hash->{type} );

           foreach my $fkey_hash ( @fkeys )
          {
            if( $fkey_hash->{column_name} eq $column_hash->{name} )
            {
              push @column_values, 1;
              push @column_values, $fkey_hash->{foreign_table_name};
              push @column_values, $fkey_hash->{foreign_column_name};
              push @column_values, 'combo';
              $found_fkey = 1;
            }
          }

          if ( $found_fkey == 0) {
            push @column_values, 0;
            push @column_values, '';
            push @column_values, '';
            push @column_values, $API->sqlToDhxGridType( $column_hash->{type} );
          }

          my $new_maped_column_id = $API->Insert( {
            table => 'agile_rest_column'
            ,columns => 'agile_rest_table_id, column_name, column_type, dhtmlx_grid_header, dhtmlx_grid_sorting, dhtmlx_form_length, dhtmlx_form_type, dhtmlx_form_mask, has_fk, foreign_table_name, foreign_column_name, dhtmlx_grid_type'
            ,placeholders => '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?'
            ,primary_key => 'agile_rest_column_id'
            ,values => [@column_values]
          } );
          push @maped_tables, $_;
        }
      }
  }

  $self->expose_default_headers;
  my $response = undef;
  $response = {
          status => 'success',
          response => 'tables maped with sucessful',
          tables => [@maped_tables]
  };
  $self->render(
    json => $response,
    status => 200
  );
}

1;
