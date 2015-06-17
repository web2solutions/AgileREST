package AgileRest::Controller::Database;
use Mojo::Base 'Mojolicious::Controller';

#use Mojo::JSON_XS; # Must be earlier than Mojo::JSON
use JSON qw(decode_json encode_json from_json to_json);
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


    my $table_name = $_;
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

            #my $foreign_column_text = $fkey_hash->{foreign_column_name};
            #my $foreign_column_value =

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
                    $logger->debug( 'nome da table: ' .$_  );
                    $logger->debug( 'nome da fk: ' .$fkey_hash->{name}  );
                    $logger->debug( 'nome da coluna : ' .$column_hash->{name}  );


                    #foreign_column_name, propriedade text
                    #foreign_column_value, propriedade value

                    my $prop_value = $fkey_hash->{foreign_column_name}; # column_id value
                    $prop_value =~ s/ //gi;

                    my $prop_text = $prop_value; # column text
                    $prop_text =~ s/_id//gi;
                    $prop_text =~ s/_id//gi;

                    #

                    push @column_values, 1;
                    push @column_values, $fkey_hash->{foreign_table_name};
                    push @column_values, $prop_text;
                    push @column_values, $prop_value;
                    push @column_values, 'coro';
                    $found_fkey = 1;
                }
            }

            if ( $found_fkey == 0) {
                push @column_values, 0;
                push @column_values, '';
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

            my $is_fk = 0;
            my $strSQLcheckIfFk = "select R.TABLE_NAME, R.COLUMN_NAME
              from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE u
              inner join INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS FK
                  on U.CONSTRAINT_CATALOG = FK.UNIQUE_CONSTRAINT_CATALOG
                  and U.CONSTRAINT_SCHEMA = FK.UNIQUE_CONSTRAINT_SCHEMA
                  and U.CONSTRAINT_NAME = FK.UNIQUE_CONSTRAINT_NAME
              inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE R
                  ON R.CONSTRAINT_CATALOG = FK.CONSTRAINT_CATALOG
                  AND R.CONSTRAINT_SCHEMA = FK.CONSTRAINT_SCHEMA
                  AND R.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
              WHERE U.COLUMN_NAME = ?

                AND U.TABLE_SCHEMA = 'public'
                AND U.TABLE_NAME = ?
              ";
            my $sthc = $dbh->prepare( $strSQLcheckIfFk, );
            $sthc->execute( $column_hash->{name}, $table_name ) or $self->fail( $sthc->errstr );
            while (  my $re = $sthc->fetchrow_hashref())
            {
              $is_fk = 1;
            }
            push @column_values, $is_fk;


            $logger->debug( $self->dumper( @column_values ) );
            $logger->debug( '-------------------' );
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
                  foreign_column_value,
                  dhtmlx_grid_type
                  ,ordinal_position
                  ,numeric_precision
                  ,numeric_scale
                  ,is_nullable
                  ,"default"
                  ,is_fk
                '
                ,placeholders => '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?'
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

  my $schema = {};
  my $settings = {};
  my $records = {};


  my $strSQL = "SELECT * FROM agile_rest_table ORDER BY output_ordering ASC";
	my $sth = $dbh->prepare( $strSQL, );
	$sth->execute(  ) or $self->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{

    my @fields;
    my $table_id = $record->{"agile_rest_table_id"};
    my $table_name = $record->{"table_name"};
    my @columns;

    $schema->{''.$table_name.''} = {
      columns => {},
      primary_key => {

      },
      foreign_keys => {

      }
    };

     $settings->{''.$table_name.''} = {
      form => {
        template => []
      }
     };

    #$schema->{''.$table_name.''}->{columns}->{test} = 1;

    my $strSQLcolumns = "SELECT * FROM agile_rest_column WHERE  agile_rest_table_id = ? ORDER BY ordinal_position ASC";
    my $sth2 = $dbh->prepare( $strSQLcolumns, );
    $sth2->execute( $table_id ) or $self->fail( $sth->errstr );
    while (  my $r = $sth2->fetchrow_hashref())
    {
      my $is_fk = 0;
      my $child_table = '';
      my $child_column = '';

      $is_fk = $r->{is_fk};
      #tie %{ $r }, 'Tie::IxHash';


      my $column_name = $r->{name};

      my $field = {};


      $logger->debug( $r->{type} );

      if ( $r->{type} eq 'primary_key' ) {
        $field->{required} = \0;
        $field->{mask_to_use} = '';
        $field->{validate} = '';
      }
      else
      {
        if ( $is_fk ) {
         $field->{required} = \1;
         $field->{validate} = 'NotEmpty';
        }
        else
        {
          if ( $r->{is_nullable} ) {
            $field->{required} = \0;
            $field->{validate} = '';
          }
          else
          {
             $field->{required} = \1;
             $field->{validate} = 'NotEmpty';
          }
        }


        $field->{mask_to_use} = $API->sqlToDhxFormMask( $r->{type} );
        $field->{value} = $r->{default};
      }



      $field->{type} = $API->sqlToDhxFormType( $r->{type} );
      $field->{name} = $column_name;
      $field->{tooltip} = '';

      $field->{maxLength} = $r->{maxlength};
      $field->{label} = $r->{dhtmlx_grid_header};

      if ( $r->{type} eq 'integer' ) {
        $field->{maxLength} = $r->{numeric_precision};
        delete( $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{maxlength} );
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{maxlength} = $r->{numeric_precision};
      }


      if ( $field->{type}  eq 'calendar') {
        $field->{dateFormat} = '%Y-%m-%d';
        #$field->{enableTime} = \0;
        #$field->{readonly} = \1;
        #
      }


      if ( $r->{type} ne 'primary_key' ) {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''} = $r;
        delete($schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{agile_rest_column_id});
        delete($schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{agile_rest_table_id});
        #agile_rest_table_id

        delete($schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{name});
      }
      else
      {
        $schema->{''.$table_name.''}->{primary_key}->{keyPath} = $r->{name};
        $schema->{''.$table_name.''}->{primary_key}->{autoIncrement} = \0;
      }


      if ( $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{unique} == 0) {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{unique} = \0;
      }
      else
      {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{unique} = \1;
      }


      if ( $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{index} == 0) {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{index} = \0;
      }
      else
      {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{index} = \1;
      }


      if ( $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} == 0) {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} = \0;
      }
      else
      {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} = \1;
      }


      $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_name} =~ s/ //gi if defined($schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_name});
      $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_value} =~ s/ //gi if defined($schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_value});

      if ( $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{has_fk} == 0) {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{has_fk} = \0;
      }
      else
      {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{has_fk} = \1;
        delete($schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required});
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} = \1;


        my $prop_value = $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_value}; # column_id value
        $prop_value =~ s/ //gi;

        my $prop_text = $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_name}; # column text
        $prop_text =~ s/_id//gi;
        $prop_text =~ s/_id//gi;




        my $foreign_column_text = $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_name};

        $foreign_column_text =~ s/ //gi;
        $foreign_column_text =~ s/_id//gi;

        my $foreign_column_value = $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_column_value};
        $foreign_column_value =~ s/ //gi;


        $schema->{''.$table_name.''}->{foreign_keys}->{''.$column_name.''} = {
          table => $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_table_name}
          ,column => $foreign_column_value
          ,column_value => $foreign_column_value
          ,column_text => $foreign_column_text
        };

        $field->{type} = 'combo';
        $field->{options} = [];
        $field->{validate} = 'NotEmpty';
        $field->{required} = \1;
        $field->{dhx_table} = $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{foreign_table_name};
        $field->{dhx_prop_text} = $foreign_column_text;
        $field->{dhx_prop_value} = $foreign_column_value;

      }

      if ( $is_fk == 1)
      {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{is_fk} = \1;
        delete($schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required});
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{required} = \1;
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{unique} = \1;

        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{validate} = 'NotEmpty';

        $field->{validate} = 'NotEmpty';
        $field->{required} = \1;
      }
      else
      {
        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{is_fk} = \0;
      }


        $schema->{''.$table_name.''}->{columns}->{''.$column_name.''}->{name} = $column_name;

      #dateFormat:"%Y-%m-%d %H:%i"

      #$logger->debug( $self->dumper( $field ) );

      push @fields, $field;
      push @columns, $column_name;
    }

    delete($schema->{''.$table_name.''}->{columns}->{''.$schema->{''.$table_name.''}->{primary_key}->{keyPath}.''});
    $settings->{''.$table_name.''}->{form}->{template} = [@fields];
	}

  my @output_tables;
  $strSQL = "SELECT * FROM agile_rest_table ORDER BY output_ordering ASC";
	$sth = $dbh->prepare( $strSQL, );
	$sth->execute(  ) or $self->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{

    my @fields;
    my $table_id = $record->{"agile_rest_table_id"};
    my $table_name = $record->{"table_name"};
    my @columns;

    my $output_obj = {};

    $output_obj->{table_name} = $record->{table_name};
    $output_obj->{output_ordering} = $record->{output_ordering};

    push @output_tables, $output_obj;

     $records->{''.$table_name.''} = [];

     my @allrecords;


    my $strSQLrecords = "SELECT * from $table_name";
    my $sthc = $dbh->prepare( $strSQLrecords, );
    $sthc->execute(  ) or $self->fail( $sth->errstr );
    while (  my $re = $sthc->fetchrow_hashref())
    {
        push @allrecords, $re;
    }

    $records->{''.$table_name.''} = [@allrecords];
  }


  my @values;
  my $version = 1;
  $strSQL = "SELECT version FROM api_database_version ORDER BY version DESC LIMIT 1";
	$sth = $dbh->prepare( $strSQL, );
	$sth->execute(  ) or $self->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{
    $version = $record->{version} + 1;
  }


  push @values, $version;


  my $response = undef;
  $response = {
          #status => 'success',
          #response => 'model generated',
          db => undef
          ,version => $version
          ,schema => $schema
          ,settings => $settings
          #,records => $records
          ,output_tables => [@output_tables]
  };

  push @values, to_json( $response );

  my $new_version_id = $API->Insert( {
      table => 'api_database_version'
      ,columns => 'version, model'
      ,placeholders => '?, ?'
      ,primary_key => 'api_database_version_id'
      ,values => [@values]
  } );


  $response->{records} = $records;

  #tie %{ $response }, 'Tie::IxHash';
  $self->expose_default_headers;
  $self->render(
    json => $response,
    status => 200
  );
}




sub get_model {
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

  my $schema = {};
  my $settings = {};
  my $records = {};

  my $model;
  my $model_hash;
  my $version;
  my $strSQL = "SELECT * FROM api_database_version ORDER BY version DESC LIMIT 1";
	my $sth = $dbh->prepare( $strSQL, );
	$sth->execute(  ) or $self->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{
    $model = $record->{model};
    $version = $record->{version};
	}

  $model_hash = from_json( $model );

  my @output_tables;
  $strSQL = "SELECT * FROM agile_rest_table ORDER BY output_ordering ASC";
	$sth = $dbh->prepare( $strSQL, );
	$sth->execute(  ) or $self->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{

    my @fields;
    my $table_id = $record->{"agile_rest_table_id"};
    my $table_name = $record->{"table_name"};
    my @columns;


    $records->{''.$table_name.''} = [];
    my @allrecords;
    my $strSQLrecords = "SELECT * from $table_name";
    my $sthc = $dbh->prepare( $strSQLrecords, );
    $sthc->execute(  ) or $self->fail( $sth->errstr );
    while (  my $re = $sthc->fetchrow_hashref())
    {
        push @allrecords, $re;
    }

    $records->{''.$table_name.''} = [@allrecords];
  }


  my $response = undef;
  $response = {
          #status => 'success',
          #response => 'model generated',
          db => undef
          ,version => $model_hash->{version}
          ,schema => $model_hash->{schema}
          ,settings => $model_hash->{settings}
          ,records => $records
          ,output_tables => [@{$model_hash->{output_tables}}]
          ,status => 'success'
  };



  $self->expose_default_headers;

  $self->render(
    json => $response,
    status => 200
  );
}

1;
