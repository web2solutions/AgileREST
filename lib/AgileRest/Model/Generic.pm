package AgileRest::Model::Generic;
use Moo;
use Encode qw( encode decode );
use Data::Dump qw(dump);
use Mojo::JSON_XS; # Must be earlier than Mojo::JSON
use Mojo::JSON qw(decode_json encode_json from_json to_json);
use JSON;

has 'API' => (
	is      => 'rw',
	#isa     => 'Str',
	default => 'test',
	required => 1
);

has 'collection' => (
	is      => 'rw',
	#isa     => 'Str',
	default => '',
	required => 1
);

has 'item' => (
	is      => 'rw',
	#isa     => 'Str',
	default => '',
	required => 1
);


has 'logger' => (
	is      => 'rw',
	#isa     => 'Str',
	default => 0,
	required => 0
);

has 'default_columns' => (
	is      => 'rw',
	default => ''
);

has 'primary_key' => (
	is      => 'rw',
	default => ''
);


has 'columns' => (
	is      => 'rw',
	default => ''
);


has 'table_prefix' => (
	is      => 'rw',
	default => ''
);


sub BUILD {

	my $self = shift;

	my $API = $self->API;

	my $logger = $self->logger;

  $logger->debug( $self->table_prefix . $self->collection );

	my $table_schema = $API->get_table_schema( $self->table_prefix . $self->collection );
	my $primaryKey = $table_schema->{primary_key};
	my $columns = '';
	for( @{$table_schema->{columns}} )
	{
		$columns = $columns . $_->{name} . ',' if $_->{name} ne $primaryKey;
	}
	$columns = $columns . $primaryKey;

	$self->default_columns( $columns );

	$self->primary_key( $primaryKey );

	$self->columns( $table_schema->{columns} );
}


sub table_data
{
	my $self = shift;
	my $API = $self->API;

	my @table_data = $API->SelectTable( $self->collection );

	return @table_data;
}


sub list
{
	my $self = shift;
	my $conf = shift;
	my $logger = $self->logger;

	# read conf or assume defaults
	my $columns = $conf->{columns} || $self->default_columns;
	my $filterstr = $conf->{filter} || '{}';
	my $orderstr = $conf->{order} || '{}';
	my $filter_operator = $conf->{filter_operator} || 'and';
	my $relationalColumn = $conf->{relationalColumn} || undef; # undef
	my $specific_append_sql_logic_select = $conf->{specific_append_sql_logic_select} || undef;
	my $relational_id = $conf->{relational_id} || undef;

	my $is_dhtmlx_grid = $conf->{is_dhtmlx_grid} || 0;
	my $grid_json_model = $conf->{grid_json_model} || 'basic'; # basic || native

	# smart rendering
	#my $isSmartRendering = $conf->{isSmartRendering} || 0;
	my $count = $conf->{count} || 50;

	# universal start position of paging
	my $posStart = $conf->{posStart} || 0;

	# not smart
	#my $nCurrentPag = $conf->{nCurrentPag} || 1;
	#my $nRegPag = $conf->{nRegPag} || 1000;

	my $tableName = $self->table_prefix . $self->collection;

	my $API = $self->API;

	my $defaultColumns = $self->default_columns;
	my $strColumns = $columns || $defaultColumns;
	$strColumns=~ s/'//g;
	my @columns = split(/,/, $strColumns);
	#$strColumns = MAP::API->normalizeColumnNames( $strColumns, $defaultColumns );


	if ( defined( $relationalColumn ) )
	{
		if ( defined( $relational_id ) ) {
			$relational_id=~ s/'//g;
		}
		else
		{
			return { error => $relationalColumn . '  is missing on url' };
		}
	}

	# ------ Filtering and Ordering -------------------


	$logger->debug( '======> filtering hash' );
	$logger->debug( $filterstr );

	my $filters =  from_json( $filterstr );
	my $sql_filters = "";
	$filter_operator=~ s/[^wd.-]+//;

	my %filters = %{ $filters };


	$logger->debug( dump( %filters ) );

	foreach my $key (%filters) {
			if ( defined( $filters{$key} ) ) {

				$logger->debug( $key );

					my $string = $filters{$key};
					$string=~ s/'//g;
					my $column = $key;
					#$column=~ s/[^wd.-]+//;
					$sql_filters = $sql_filters . " " . $column . " ILIKE '%" . $string . "%'  ". $filter_operator ."  ";
			}
	}

	if ( length($sql_filters) > 1 ) {
			$sql_filters = ' AND ( '.  substr($sql_filters, 0, -5) . ' )';
	}

	if ( defined($specific_append_sql_logic_select) ) {
			#$specific_append_sql_logic_select
			$sql_filters = ' '.  $specific_append_sql_logic_select. ' ';
	}


	my $sql_ordering = ' ORDER BY '. $self->primary_key .' ASC';
	my $order =  from_json( $orderstr );
	if ( defined( $order->{orderby} ) && defined( $order->{direction} ) )
	{
			my $column = $order->{orderby};
			#$column=~ s/[^wd.-]+//;
			my $direction = $order->{direction};
			#$direction=~ s/[^wd.-]+//;
			$sql_ordering = ' ORDER BY "' . $column . '" '. $direction ;
	}
	# ------ Filtering and Ordering -------------------

	my $dbh = $API->dbh;

	my $strSQLstartWhere = ' 1 = 1 ';
	if ( defined(  $relationalColumn ) ) {
			$strSQLstartWhere = '( "'.$relationalColumn.'" IN ('.$relational_id.') ) ';
	}

	my $totalCount = 0;
	my $sth = $dbh->prepare( 'SELECT COUNT('.$self->primary_key.') as total_count FROM '.$tableName.' WHERE '.$strSQLstartWhere.' ' . $sql_filters . ';', );
	$sth->execute() or return { error => $sth->errstr };
	while ( my $record = $sth->fetchrow_hashref())
	{
			$totalCount = $record->{"total_count"};
	}

	my $strSQL = 'SELECT '.$strColumns.' FROM '.$tableName.'  WHERE '.$strSQLstartWhere.' ' . $sql_filters . ' '. $sql_ordering . ' ';

	# if smart rendering
	#if($isSmartRendering)
  #{
	    $strSQL = $strSQL .  " LIMIT $count OFFSET $posStart ";
	#}
	#else # if not smart rendering
	#{
	#    $nCurrentPag = $nCurrentPag - 1;

	#    $nCurrentPag = $nRegPag * $nCurrentPag;

	#    $strSQL = $strSQL .  " LIMIT $nRegPag OFFSET $nCurrentPag ";
	#}


	#$logger->debug( '======> Built SQL string' );
	#$logger->debug( $strSQL );


	$sth = $dbh->prepare( $strSQL, );
	$sth->execute() or return { error => $sth->errstr . ' ----------- '.$strSQL };

	my @records_basic;
	my @records_native;
	my @records_collection;
	while ( my $record = $sth->fetchrow_hashref())
	{
			#push @records, $record;
			my @values;
			my $row_basic = {
					id =>    $record->{$self->primary_key},
					bgColor => '',
					class => '',
					style => '',
					locked => Mojo::JSON->false,
			};
			my $row_collection = {
					id =>    $record->{$self->primary_key},
			};
			my $row_native = {

			};
			foreach (@columns)
			{
				if (defined($record->{$_}))
				{
					#push @values, decode('UTF-8', $record->{$_}); # DBI is internally decoding
					#$row_native->{$_} = decode('UTF-8', $record->{$_}); # DBI is internally decoding
					#$row_collection->{$_} = decode('UTF-8', $record->{$_}); # DBI is internally decoding
					push @values, $record->{$_};
					$row_native->{$_} = $record->{$_};
					$row_collection->{$_} = $record->{$_}
				}
				else
				{
					push @values, undef;
					$row_native->{$_} = undef;
					$row_collection->{$_} = undef;
				}
			}
			$row_basic->{data} = [@values];
			$row_collection->{data} = [@values];

			push @records_basic, $row_basic;
			push @records_native, $row_native;
			push @records_collection, $row_collection;
	}
	#$dbh->disconnect();

	#if( $posStart == 0 )
	#{
	#		$posStart = "";
	#}
	#else
	#{
	#		$posStart = $posStart - 1;
	#}

	my $response = {
			item => $self->item,
      collection => $self->collection,
      columns => $self->columns,
			status => 'success',
			response => 'Succcess',
			total_count => $totalCount,
			pos => $posStart
	};

	if ( $API->branch ne 'production') {
      $response->{sql} = $strSQL;
      $response->{sql_filters} = $sql_filters;
      $response->{sql_ordering} = $sql_ordering;
  }

	if ($is_dhtmlx_grid) {
		$response->{rows} = [  ( $grid_json_model eq 'basic' ) ? @records_basic : @records_native];
		$response->{grid_json_model} = $grid_json_model;
	}
	else
	{
		$response->{$self->collection} =  [@records_collection];
	}

	return $response || {};
}


sub read
{
	my $self = shift;
	my $conf = shift;
	my $logger = $self->logger;
	my $API = $self->API;

	# read conf or assume defaults
	my $columns = $conf->{columns} || $self->default_columns;
	my $str_id  = $conf->{item_id} || return  { error => 'item_id is missing' };
	$str_id=~ s/'//g;
	my $primaryKey = $self->primary_key;

	my $tableName = $self->table_prefix . $self->collection;
	my $defaultColumns = $self->default_columns;
	my $strColumns = $columns || $defaultColumns;
	$strColumns=~ s/'//g;
	my @columns = split(/,/, $strColumns);

	my $dbh = $API->dbh;
	my $strSQL = 'SELECT '.$strColumns.' FROM '.$tableName.' WHERE '.$primaryKey.' = ?';
	my $sth = $dbh->prepare( $strSQL, );
	$sth->execute( $str_id ) or return { error => $sth->errstr . ' ----------- '.$strSQL };

	if ( $sth->rows == 0 ) {
			return {
				error => 'resource_not_found',
				strSQL => $strSQL,
				primaryKey => $primaryKey,
        str_id => $str_id
			}
	}

	my $response = {
				 status => 'success',
				 response => 'Succcess',
				 hash => $sth->fetchrow_hashref(),
				 #sql =>  $strSQL
	};

	if ( $API->branch ne 'production') {
      $response->{sql} = $strSQL;
  }

	return $response || {};
}


sub create
{
	my $self = shift;
	my $conf = shift;

	my $logger = $self->logger;
	my $API = $self->API;
	my $primaryKey = $self->primary_key;
	my $columns = $conf->{columns} || $self->default_columns;

	my $tableName = $self->table_prefix . $self->collection;
	my $defaultColumns = $self->default_columns;
	my $strColumns = $columns || $defaultColumns;

	my $hashStr = $conf->{hash} || '{}';
	my $json_bytes = encode('UTF-8', $hashStr);
	my $hash = JSON->new->utf8->decode($json_bytes) or return { error => "unable to decode"};
	#my $hash =  from_json( $hashStr );
	my $sql_columns = "";
	my $sql_placeholders = "";
	my @sql_values;

	my %hash = %{ $hash };

	my $dbh = $API->dbh;

	foreach my $key (%hash)
	{
			if ( defined( $key ) )
			{
					if ( defined( $hash{$key} ) )
					{
							if ( index($defaultColumns, $key) != -1 )
							{
									if ( $key ne $primaryKey) {
											if ( index($sql_columns, '"' .$key.'"') < 0 )
											{
													$sql_columns = $sql_columns .'"' .$key.'", ';
													$sql_placeholders  = $sql_placeholders . '?, ';
													push @sql_values, $hash{$key};
											}
									}
							}
					}
			}
	}

	if( length($sql_columns) < 2)
	{
		return { error => 'please provide a hash of properties' }
	}

	my $strSQL = 'INSERT INTO
		'.$tableName.'(' . substr($sql_columns, 0, -2) . ')
		VALUES(' . substr($sql_placeholders, 0, -2) . ')
		RETURNING '.$primaryKey.';
	';
	my $sth = $dbh->prepare( $strSQL, );
	$sth->execute( @sql_values ) or return { error => $sth->errstr . " --------- ".$strSQL };
	my $record_id = 0;
	while ( my $record = $sth->fetchrow_hashref())
	{
			$record_id = $record->{$primaryKey};
	}

	return {
			status => 'success',
			response => 'Item '.$record_id.' added on ' . $self->collection,
			sql => $strSQL,
			''.$primaryKey.'' => $record_id,
			place_holders_dump => dump(@sql_values)
	};
}


1;
