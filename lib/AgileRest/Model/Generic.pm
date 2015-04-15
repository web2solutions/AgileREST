package AgileRest::Model::Generic;

use Moo;

#use utf8;

use Encode qw( encode decode );
#use Deep::Encode;

use Mojo::JSON qw(decode_json encode_json from_json to_json);
#use Data::Dump qw(dump);


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

has 'controller' => (
	is      => 'rw',
	#isa     => 'Str',
	#default => 0,
	required => 1
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


sub get_collection
{
	my $self = shift;
	my $conf = shift;

	my $logger = $self->logger;

	#$self->API->fail( $self->controller, ' xxxxxxxxxxxxxx ' );

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
			$self->API->fail( $self->controller, $relationalColumn . '  is missing on url' )
		}
	}

	# ------ Filtering and Ordering -------------------

	my $filters =  from_json( $filterstr );
	my $sql_filters = "";
	$filter_operator=~ s/[^wd.-]+//;

	my %filters = %{ $filters };
	foreach my $key (%filters) {
	if ( defined( $filters{$key} ) ) {
					my $string = $filters{$key};
					$string=~ s/'//g;
					my $column = $key;
					$column=~ s/[^wd.-]+//;
					$sql_filters = $sql_filters . " " . $column . " LIKE '%" . $string . "%'  ". $filter_operator ."  ";
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
			$column=~ s/[^wd.-]+//;
			my $direction = $order->{direction};
			$direction=~ s/[^wd.-]+//;
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
	$sth->execute() or $self->API->fail( $self->controller, $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{
			$totalCount = $record->{"total_count"};
	}


	my $strSQL = 'SELECT '.$strColumns.' FROM '.$tableName.' '. $sql_ordering . ' ';

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


	$logger->debug( '======> Built SQL string' );
	$logger->debug( $strSQL );


	$sth = $dbh->prepare( $strSQL, );
	$sth->execute() or $self->API->fail( $self->controller, $sth->errstr . ' ----------- '.$strSQL);

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
			#''.$self->collection.'' => [@records_collection],
			#grid_json_model => $grid_json_model,
			#rows =>  => [  ( $grid_json_model eq 'basic' ) ? @records_basic : @records_native],
			sql =>  $strSQL,
			sql_filters => $sql_filters,
			sql_ordering => $sql_ordering,
			total_count => $totalCount,
			pos => $posStart,
			h => decode('UTF-8', 'éó')
	};

	if ($is_dhtmlx_grid) {
		$response->{rows} = [  ( $grid_json_model eq 'basic' ) ? @records_basic : @records_native];
		$response->{grid_json_model} = $grid_json_model;
	}
	else
	{
		$response->{$self->collection} =  [@records_collection];
	}


	return $response;



}


1;
