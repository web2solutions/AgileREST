package AgileRest::Controller::Database;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use Tie::IxHash;

sub map {
  my $self = shift;
  my $API = $self->API;
  #my $access_granted_message = $API->check_authorization( $self );
  #if ( $access_granted_message ne 'granted' )
  #{
  #  return $self->unauthorized( $access_granted_message );
  #}

  my $dbh = $API->dbh;

  my $logger = $self->logger;
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

    $logger->debug( $already_maped );
    $logger->debug( $new_maped_table_id );
    $logger->debug( $_ );
    $logger->debug( $self->dumper( @fkeys ) );

    foreach my $column_hash ( @columns )
    {
        my $column_exist = $API->Select( "SELECT name FROM agile_rest_column WHERE name = '".$column_hash->{name}."' AND agile_rest_table_id = '".$new_maped_table_id."';" );
        if ( defined( $column_exist ) ) { }
        else
        {

            my $found_fkey = 0;
            my @column_values;
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
                if( $fkey_hash->{name} eq $column_hash->{name} )
                {
                    push @column_values, 1;
                    push @column_values, $fkey_hash->{foreign_table_name};
                    push @column_values, $fkey_hash->{foreign_column_name};
                    push @column_values, 'coro';
                    $found_fkey = 1;
                }
            }

            if ( $found_fkey == 0) {
                push @column_values, 0;
                push @column_values, '';
                push @column_values, '';
                push @column_values, $API->sqlToDhxGridType( $column_hash->{type} );
            }


            my $strSQL = "SELECT
                cols.ordinal_position
                ,cols.numeric_precision
                ,cols.numeric_scale
                ,cols.is_nullable
                ,cols.column_default
              FROM
                  information_schema.columns cols
              WHERE
                  cols.table_catalog = 'juris' AND
                  cols.table_name    = '".$_."'    AND
                  cols.column_name    = '".$column_hash->{name}."'    AND
                  cols.table_schema  = 'public';";
            my $sth = $dbh->prepare( $strSQL, );
            $sth->execute(  ) or die $sth->errstr;
            while ( my $record = $sth->fetchrow_hashref())
            {
               push @column_values, $record->{ordinal_position};
               push @column_values, $record->{numeric_precision};
               push @column_values, $record->{numeric_scale};
               push @column_values, $record->{is_nullable};


               my $default = '';
               if ( defined($record->{column_default}) )
               {
                  if ( length( $record->{column_default} ) > 0)
                  {
                    my $string = $record->{column_default};
                    if ( $string =~ /\'(.*?)\'/ )
                    {
                        push @column_values, $1;
                    }
                    else
                    {
                      push @column_values, '';
                    }
                  }
                  else
                  {
                    push @column_values, '';
                  }
                }
               else
               {
                push @column_values, '';
               }
            }

            my $new_maped_column_id = $API->Insert( {
                table => 'agile_rest_column'
                ,columns => '
                  agile_rest_table_id,
                  name,
                  type,
                  dhtmlx_grid_header,
                  dhtmlx_grid_sorting,
                  maxlength,
                  dhtmlx_form_type,
                  format,
                  has_fk,
                  foreign_table_name,
                  foreign_column_name,
                  dhtmlx_grid_type
                  ,ordinal_position
                  ,numeric_precision
                  ,numeric_scale
                  ,is_nullable
                  ,"default"
                '
                ,placeholders => '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?'
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
          response => 'tables sucessful maped',
          tables => [@maped_tables]
  };
  $self->render(
    json => $response,
    status => 200
  );
}


sub model {
  my $self = shift;
  my $API = $self->API;
  #my $access_granted_message = $API->check_authorization( $self );
  #if ( $access_granted_message ne 'granted' )
  #{
  #  return $self->unauthorized( $access_granted_message );
  #}
  my $logger = $self->logger;
  my @tables = $API->get_tables();

  my $dbh = $API->dbh;

  my $model = {};


  my $strSQL = "SELECT * FROM agile_rest_table ORDER BY table_name ASC";
	my $sth = $dbh->prepare( $strSQL, );
	$sth->execute(  ) or $self->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{

    my @fields;
    my $table_id = $record->{"agile_rest_table_id"};
    my $table_name = $record->{"table_name"};
    my @columns;

    $model->{''.$table_name.''} = {
      columns => {},
      primary_key => {

      },
      fields => [],
      str_columns => ''
    };

    #$model->{''.$table_name.''}->{columns}->{test} = 1;

    my $strSQLcolumns = "SELECT * FROM agile_rest_column WHERE  agile_rest_table_id = ? ORDER BY ordinal_position ASC";
    my $sth2 = $dbh->prepare( $strSQLcolumns, );
    $sth2->execute( $table_id ) or $self->fail( $sth->errstr );
    while (  my $r = $sth2->fetchrow_hashref())
    {


      #tie %{ $r }, 'Tie::IxHash';

      my $column_name = $r->{name};
      #my $maxlength = $r->{maxlength};
      #$logger->debug( $column_name );


      if ( $r->{type} ne 'primary_key' ) {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''} = $r;
        delete($model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{agile_rest_column_id});
        delete($model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{agile_rest_table_id});
        #agile_rest_table_id

        delete($model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{name});
      }
      else
      {
        $model->{''.$table_name.''}->{primary_key}->{keyPath} = $r->{name};
        $model->{''.$table_name.''}->{primary_key}->{autoIncrement} = \0;
      }


      if ( $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{unique} == 0) {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{unique} = \0;
      }
      else
      {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{unique} = \1;
      }
      if ( $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{index} == 0) {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{index} = \0;
      }
      else
      {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{index} = \1;
      }
      if ( $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} == 0) {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} = \0;
      }
      else
      {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} = \1;
      }
      if ( $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{has_fk} == 0) {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{has_fk} = \0;
      }
      else
      {
        $model->{''.$table_name.''}->{columns}->{''.$column_name.''}->{has_fk} = \1;
      }





      my $field = {};


      $logger->debug( $r->{type} );

      if ( $r->{type} eq 'primary_key' ) {
        $field->{required} = \1;
        $field->{mask_to_use} = 'integer';
        $field->{validate} = 'NotEmpty';
      }
      else
      {
        $field->{required} = \0;
        $field->{mask_to_use} = $API->sqlToDhxFormMask( $r->{type} );
        $field->{validate} = '';
      }



      $field->{type} = $API->sqlToDhxFormType( $r->{type} );
      $field->{name} = $column_name;
      $field->{tooltip} = '';
      $field->{value} = '';
      $field->{maxLength} = $r->{maxlength};
      $field->{label} = $r->{dhtmlx_grid_header};

      if ( $field->{type}  eq 'calendar') {
        $field->{dateFormat} = '%Y-%m-%d';
        #$field->{enableTime} = \0;
        #$field->{readonly} = \1;
        #
      }




      #dateFormat:"%Y-%m-%d %H:%i"

      #$logger->debug( $self->dumper( $field ) );

      push @fields, $field;
      push @columns, $column_name;
    }

    delete($model->{''.$table_name.''}->{columns}->{''.$model->{''.$table_name.''}->{primary_key}->{keyPath}.''});
    $model->{''.$table_name.''}->{fields} = [@fields];
    $model->{''.$table_name.''}->{str_columns} = join( ',', @columns );
	}


  #tie %{ $model }, 'Tie::IxHash';

  $self->expose_default_headers;
  my $response = undef;
  $response = {
          status => 'success',
          response => 'model generated',
          model => $model
  };




  #tie %{ $response }, 'Tie::IxHash';

  $self->render(
    json => $response,
    status => 200
  );
}

1;
