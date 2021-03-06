package AgileRest::API;
use Moo;
use Mojo::JSON_XS; # Must be earlier than Mojo::JSON
use Mojo::JSON qw(decode_json encode_json from_json to_json);
#use Crypt::Digest::SHA256 qw( sha256_hex );
#use MIME::Base64;
use Data::Dump qw(dump);

has 'branch' => (
	is      => 'rw',
	#isa     => 'Str',
	default => 'test' # test, dev and production
);
has 'dbh' => (
	is      => 'rw',
	#isa     => 'Str',
	default => 'not connected'
);

sub sqlToDhxFormType{
    my($self, $sql_type) = @_;
    if ( $sql_type eq 'integer' ) {
        return 'input';
    }
    elsif ( $sql_type eq 'bigint' ) {
        return 'input';
    }
    elsif ( $sql_type eq 'numeric' ) {
        return 'input';
    }
    elsif ( $sql_type eq 'character varying' ) {
        return 'input';
    }
    elsif ( $sql_type eq 'text' ) {
        return 'input';
    }
    elsif ( $sql_type eq 'date' ) {
        return 'calendar';
    }
    elsif ( $sql_type eq 'timestamp without time zone' ) {
        return 'calendar';
    }
    elsif ( $sql_type eq 'primary_key' ) {
        return 'hidden';
    }
    elsif ( $sql_type eq 'boolean' ) {
        return 'btn2state';
    }
    #
    return '';
}

sub sqlToDhxFormMask{
    my($self, $sql_type) = @_;
    if ( $sql_type eq 'integer' ) {
        return 'integer';
    }
    elsif ( $sql_type eq 'bigint' ) {
        return 'integer';
    }
    elsif ( $sql_type eq 'numeric' ) {
        return 'currency';
    }
    elsif ( $sql_type eq 'character varying' ) {
        return '';
    }
    elsif ( $sql_type eq 'text' ) {
        return '';
    }
    elsif ( $sql_type eq 'date' ) {
        return 'date';
    }
    elsif ( $sql_type eq 'timestamp without time zone' ) {
        return 'time';
    }
    return '';
}

sub sqlToDhxGridType{
    my($self, $sql_type) = @_;
    if ( $sql_type eq 'integer' ) {
        return 'edn';
    }
    elsif ( $sql_type eq 'bigint' ) {
        return 'edn';
    }
    elsif ( $sql_type eq 'numeric' ) {
        return 'edn';
    }
    elsif ( $sql_type eq 'character varying' ) {
        return 'ed';
    }
    elsif ( $sql_type eq 'text' ) {
        return 'txttxt';
    }
    elsif ( $sql_type eq 'date' ) {
        return 'dhxCalendar';
    }
    elsif ( $sql_type eq 'timestamp without time zone' ) {
        return 'dhxCalendar';
    }
    elsif ( $sql_type eq 'boolean' ) {
        return 'ch';
    }
	elsif ( $sql_type eq 'primary_key' ) {
        return 'ro';
    }
    return 'ro';
}

sub sqlToDHTMLXsort{
    my($self, $sql_type) = @_;
    if ( $sql_type eq 'integer' ) {
        return 'int';
    }
    elsif ( $sql_type eq 'bigint' ) {
        return 'int';
    }
    elsif ( $sql_type eq 'numeric' ) {
        return 'int';
    }
    elsif ( $sql_type eq 'character varying' ) {
        return 'str';
    }
    elsif ( $sql_type eq 'text' ) {
        return 'str';
    }
    elsif ( $sql_type eq 'date' ) {
        return 'date';
    }
    elsif ( $sql_type eq 'timestamp without time zone' ) {
        return 'date';
    }
    elsif ( $sql_type eq 'boolean' ) {
        return 'int';
    }
    return 'str';
}

sub get_tables{
    my($self) = @_;
    my @tables;
    my $dbh = $self->dbh;
    my $strSQL = "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';";
    my $sth = $dbh->prepare( $strSQL, );
    $sth->execute( ) or die $sth->errstr;
    while ( my $record = $sth->fetchrow_hashref())
    {
        if (
        ( $record->{table_name} ne 'agile_rest_table' )
        and ( $record->{table_name} ne 'agile_rest_column' )
        and ( $record->{table_name} ne 'api_access_token' )
        and ( $record->{table_name} ne 'api_allowed_origin' )
        and ( $record->{table_name} ne 'api_users' )
        and ( $record->{table_name} ne 'api_database_version' )
        #
        )
        {
            push @tables, $record->{table_name};
        }
    }
    return @tables;
}

sub get_table_schema{
    my($self, $table) = @_;
    my $dbh = $self->dbh;
    my $schema = {};
    my @columns;
    $table = $table || die "please provide a table name" ;
    my $strSQL = "SELECT
    cols.column_name,cols.table_schema,cols.table_name,cols.column_name,cols.ordinal_position,cols.data_type,cols.character_maximum_length,
    (
    SELECT
    pg_catalog.col_description(c.oid, cols.ordinal_position::int)
    FROM
    pg_catalog.pg_class c
    WHERE
    c.oid     = (SELECT '".$table."'::regclass::oid) AND
    c.relname = cols.table_name
    ) as column_comment
    FROM
    information_schema.columns cols
    WHERE
    cols.table_catalog = 'juris' AND
    cols.table_name    = '".$table."'    AND
    cols.table_schema  = 'public';";
    my $sth = $dbh->prepare( $strSQL, );
    $sth->execute(  ) or die $sth->errstr;
    while ( my $record = $sth->fetchrow_hashref())
    {
        my $type = '';
        if( $record->{ordinal_position} == 1 )
        {
            $type = 'primary_key';
            $schema->{primary_key} = $record->{column_name};
        }else
        {
            $type = $record->{data_type};
        }
        my $column = {
            name => $record->{column_name},
            description => $record->{column_comment},
            type => $type,
            maxlenght => $record->{character_maximum_length},
            position => $record->{ordinal_position}
        };
        push @columns, $column;
    }
    $schema->{columns} = [@columns];
    #debug $schema->{primary_key};
    return $schema;
}


sub get_column_position{
    my($self, $table, $column) = @_;
    my $dbh = $self->dbh;
	my $position = -1;
    $table = $table || die "please provide a table name" ;
    my $strSQL = "SELECT
    cols.column_name,cols.table_schema,cols.table_name,cols.column_name,cols.ordinal_position,cols.data_type,cols.character_maximum_length,
    (
    SELECT
    pg_catalog.col_description(c.oid, cols.ordinal_position::int)
    FROM
    pg_catalog.pg_class c
    WHERE
    c.oid     = (SELECT '".$table."'::regclass::oid) AND
    c.relname = cols.table_name
    ) as column_comment
    FROM
    information_schema.columns cols
    WHERE
    cols.table_catalog = 'juris' AND
    cols.table_name    = '".$table."'    AND
    cols.table_schema  = 'public';";
    my $sth = $dbh->prepare( $strSQL, );
    $sth->execute(  ) or die $sth->errstr;
    while ( my $record = $sth->fetchrow_hashref())
    {
        if ( $record->{column_name} eq $column ) {
		  $position = $record->{ordinal_position};
		}
    }
    #debug $schema->{primary_key};
    return $position;
}

sub get_table_column_schema{
    my($self, $table, $column) = @_;
    my $dbh = $self->dbh;
    my $schema = {};
    my @columns;
    $table = $table || die "please provide a table name" ;
    my $strSQL = "SELECT
    cols.table_schema,cols.table_name,cols.column_name,cols.ordinal_position,cols.data_type,cols.character_maximum_length,
    (
    SELECT
    pg_catalog.col_description(c.oid, cols.ordinal_position::int)
    FROM
    pg_catalog.pg_class c
    WHERE
    c.oid     = (SELECT '".$table."'::regclass::oid) AND
    c.relname = cols.table_name
    ) as column_comment
    FROM
    information_schema.columns cols
    WHERE
    cols.table_catalog = 'juris' AND
    cols.table_name    = '".$table."'    AND
    cols.column_name    = '".$column."'    AND
    cols.table_schema  = 'public';";
    my $sth = $dbh->prepare( $strSQL, );
    $sth->execute(  ) or die $sth->errstr;
    while ( my $record = $sth->fetchrow_hashref())
    {
        my $type = '';
        if( $record->{ordinal_position} == 1 )
        {
            $type = 'primary_key';
            $schema->{primary_key} = $record->{column_name};
        }else
        {
            $type = $record->{data_type};
        }
        my $column = {
            name => $record->{column_name},
            description => $record->{column_comment},
            type => $type,
            maxlenght => $record->{character_maximum_length},
            position => $record->{ordinal_position}
        };
        push @columns, $column;
    }
    $schema->{columns} = [@columns];
    #debug $schema->{primary_key};
    return $schema;
}

sub get_table_foreing_keys{
    my($self, $table) = @_;
    my @keys;
    my $dbh = $self->dbh;
    my $strSQL = "SELECT
    tc.constraint_name, tc.table_name, kcu.column_name, kcu.column_name AS name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
    FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY' AND tc.table_name='".$table."';";
    my $sth = $dbh->prepare( $strSQL, );
    $sth->execute( ) or die $sth->errstr;
    while ( my $record = $sth->fetchrow_hashref())
    {
        push @keys, $record;
    }
    return @keys;
}

sub normalizeColumnNames
{
    my($self, $strColumns, $packageColumns, $logger) = @_;
    #$logger->debug( '>>>>>>>>>>>>'. $strColumns );
    #$logger->debug( '>>>>>>>>>>>>'. $packageColumns );
    my @columns = split(/,/, $strColumns);
    $strColumns = '';
    for(@columns)
    {
        if ( index($packageColumns, '"'.$_.'"') != -1 )
        {
        }
        elsif ( index($packageColumns, $_) != -1 )
        {
            $strColumns = $strColumns . '"'.$_.'",';
        }
    }
    return substr($strColumns, 0, -1);;
}

sub map_table
{
    my $self = shift;
}

sub map_columns
{
    my $self = shift;
    my $new_maped_table_id = shift;
    my $table_name = shift;
    my $logger = shift->logger;
    my $API = $self;
    my $dbh = $API->dbh;
    # ==== START MAP COLUMN
    my @columns = @{ $API->get_table_schema( $table_name )->{columns} };
    my @fkeys = $API->get_table_foreing_keys( $table_name );
    #$logger->debug( $already_maped );
    $logger->debug( $new_maped_table_id );
    #$logger->debug( $table_name );
    #$logger->debug( $self->dumper( @fkeys ) );
    foreach my $column_hash ( @columns )
    {

		#if ( $column_hash->{name} ne 't_rex_user_id' ) {
		  my $column_exist = $API->Select( "SELECT name FROM agile_rest_column WHERE name = '".$column_hash->{name}."' AND agile_rest_table_id = '".$new_maped_table_id."';" );
		  if ( ! defined $column_exist  )
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
					  #$logger->debug( 'nome da table: ' .$table_name  );
					  #$logger->debug( 'nome da fk: ' .$fkey_hash->{name}  );
					  #$logger->debug( 'nome da coluna : ' .$column_hash->{name}  );
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
			  cols.table_name    = '".$table_name."'    AND
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
						  if ( $string =~ /'(.*?)'/ )
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
			  $sthc->execute( $column_hash->{name}, $table_name ) or die $sthc->errstr;
			  while (  my $re = $sthc->fetchrow_hashref())
			  {
				  $is_fk = 1;
			  }
			  push @column_values, $is_fk;
			  #$logger->debug( $self->dumper( @column_values ) );
			  #$logger->debug( '-------------------' );
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
			  #push @maped_tables, $table_name;
		  }
		#}




    }
    # ==== END MAP COLUMN
}
sub Exec
{

	my($self, $strSQL, @params) = @_;

    my $dbh = $self->dbh;
	my $sth = $dbh->prepare( $strSQL ,  );

	if ( @params ) {
	  if ( @params == 1 && !defined $params[0] ) {
	   $sth->execute( ) or return { error => "Can't exec: " . $dbh->errstr . " . SQL statement: ".$strSQL};
	  }
	  else
	  {
		$sth->execute( @params ) or return { error => "Can't exec: " . $dbh->errstr . " . SQL statement: ".dump(@params)};
	  }


	}
	else
	{
	  $sth->execute( ) or return { error => "Can't exec: " . $dbh->errstr . " . SQL statement: ".$strSQL};
	}





	return {
        status => 'success',
        response => 'Query executed',
        sql => $strSQL,
        place_holders_dump => dump(@params)
    };
}
sub SelectOne
{
    my $self = shift;
    my $dbh = $self->dbh;
    my $sql = shift;
    my $res = $dbh->selectrow_arrayref($sql,undef,@_);
    die "Can't execute select:  '".$sql."'  n".$dbh->errstr if $dbh->err;
    return $res->[0];
}
sub SelectRow
{
    my $self = shift;
    my $dbh = $self->dbh;
    my $res = $dbh->selectrow_hashref(shift,undef,@_);
    die"Can't execute select:n".$dbh->errstr if $dbh->err;
    return $res;
}
sub SelectTable
{
    my $self = shift;
    my $table_name = shift;
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare( 'SELECT * FROM '. $table_name , undef, @_ );
    $sth->execute( );
    #my $res = $dbh->selectall_arrayref( 'SELECT * FROM '. $table_name, { Slice=>{} }, @_ );
    die"Can't execute select:n".$dbh->errstr if $dbh->err;
    return $sth->fetchall_arrayref( { } );
}
#
sub Select
{
    my $self = shift;
    my $dbh = $self->dbh;
    my $res = $dbh->selectall_arrayref( shift, { Slice=>{} }, @_ );
    die"Can't execute select:n".$dbh->errstr if $dbh->err;
    return undef if $#$res == -1;
    #my $cidxor = 0;
    #for(@$res)
    #{
        #    $cidxor = $cidxor ^ 1;
        #    $_->{row_cid} = $cidxor;
    #}
    return $res;
}
sub SelectARef
{
    my $self = shift;
    my $data = Select(@_);
    return [] unless $data;
    return [$data] unless ref($data) eq 'ARRAY';
    return $data;
}
sub Insert
{
    my $self = shift;
    my $conf = shift;
    my $tableName = $conf->{table};
    my $sql_columns = $conf->{columns};
    my $sql_placeholders = $conf->{placeholders};
    my $primaryKey = $conf->{primary_key};
    my @sql_values = @{ $conf->{values} };
    #die dump @sql_values;
    my $dbh = $self->dbh;
    my $strSQL = 'INSERT INTO
    '.$tableName.'(' . $sql_columns . ')
    VALUES(' . $sql_placeholders . ')
    RETURNING '.$primaryKey.';
    ';
    my $sth = $dbh->prepare( $strSQL, );
    $sth->execute( @sql_values ) or die $sth->errstr . " --------- ".$strSQL;
    my $record_id = 0;
    while ( my $record = $sth->fetchrow_hashref())
    {
        $record_id = $record->{$primaryKey};
    }
    return $record_id;
}
sub regex_alnum
{
    my ($self, $value) = @_;
    $value =~ s/ /_/g;
    $value =~ s/W//g;
    return $value;
}

sub clean_file_name
{
    my ($self, $value) = @_;
    $value =~ s/ /_/g;
    $value =~ s/[^0-9a-zA-Z]//g;
    return $value;
}


sub trackAccessLog
{
    my ($self, $c) = @_;
    my $logger = $c->logger;
    my $transaction = $c->tx;
    my $req = $transaction->req;
    my $res = $transaction->res;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $branch = $req->headers->header("X-branch") || 'test';
    my $template = '';
    my $client_ip = $req->headers->header("X-Forwarded-For") || $req->headers->header("REMOTE_ADDR") || $transaction->remote_address; # client IP
    my $client_vendor = ( $req->headers->header("X-Requested-With")  ? $req->headers->header("X-Requested-With") . ''  : 'unknown' . '' );
    my $client_user_agent = $req->headers->header("User-Agent") || 'unknown';
    my $browser_name = $req->headers->header("X-browser-name") || 'unknown';
    my $browser_os = $req->headers->header("X-browser-os") || 'unknown';
    my $browser_version = $req->headers->header("X-browser-version") || 'unknown';
    my $screen_width = $req->headers->header("X-browser-screen-width") || 'unknown';
    my $screen_height = $req->headers->header("X-browser-screen-height") || 'unknown';
    my $rdate = ( $year + 1900 ). '-' . ( $mon + 1 ) . '-' . $mday;
    my $rtime = $hour . ':' . $min . ':' . $sec;
    my $host = $req->headers->header("X-Forwarded-Host") || $req->headers->header("Host");
    my $origin = $req->headers->header("Origin") || 'unknown';
    my $referer = $req->headers->header("Referer") || 'unknown';
    my $company_id = $req->headers->header("X-Company-ID") || 0;
    my $company_branch_id = $req->headers->header("X-Company-Branch-ID") || 0;
    my $token = $c->req->headers->authorization
    || $c->req->env->{'X_HTTP_AUTHORIZATION'}
    || $c->req->env->{'HTTP_AUTHORIZATION'}
    || 'not authorized';
    my $client_session_id = $req->headers->header("X-client-session-id") || 0;
    my $json_document = to_json({
        request_date => $rdate,
        request_time => $rtime,
        client_session_id => $client_session_id,
        branch =>  $branch,
        api_host => $host,
        origin_domain => $origin,
        referer => $referer,
        company_id => $company_id,
        company_branch_id => $company_branch_id,
        token => $token,
        client_ip => $client_ip,
        client_vendor => $client_vendor,
        client_user_agent => $client_user_agent,
        'browser_name' => $browser_name,
        'browser_os' => $browser_os,
        'browser_version' => $browser_version,
        'screen_width' => $screen_width,
        'screen_height' => $screen_height,
        request_method => $req->method,
        request_url => $req->url->path->{path},
        response_status => $res->code,
        response_type => $res->headers->content_type
    });
    my $id = $c->redis->incr('id:api_access_log');
    $c->redis->hmset(api_access_log => $id => $json_document);
    #$logger->debug( @{$c->redis->hmget( api_access_log => $id)}[0]  );
}
sub check_authorization{
    my($self, $c) = @_;
    my $auth = $c->req->headers->authorization
    || $c->req->env->{'X_HTTP_AUTHORIZATION'}
    || $c->req->env->{'HTTP_AUTHORIZATION'}
    || return 'authorization credential is missing';
    $auth =~ s/Digest //gi;
    my $token = MIME::Base64::decode( $auth );
    my $Origin      = $c->req->headers->header('Origin') || return "malformed headers";
    my $dbh = $self->dbh;
    my $token_status = "";
    $Origin = $Origin || return "Please use MAP RESTFul client";
    $token = $token || return  "token can not be empty";
    my $origin_status = "";
    my $strSQLcheckOrigin = "SELECT origin FROM api_allowed_origin WHERE origin = ?";
    my $sth = $dbh->prepare( $strSQLcheckOrigin, );
    $sth->execute( $Origin ) or return  $sth->errstr;
    while ( my $record = $sth->fetchrow_hashref())
    {
        $origin_status = "ok";
    }
    if ( $origin_status eq "" )
    {
        return "Origin not allowed";
    }
    my $strSQLtoken = 'SELECT * FROM api_access_token WHERE token = ? AND active_status = 1 AND date_expiration > '.time.'';
    $sth = $dbh->prepare( $strSQLtoken, );
    $sth->execute( $token ) or return  $c->fail( $sth->errstr );
    while ( my $record = $sth->fetchrow_hashref())
    {
        $token_status = "ok";
    }
    if ( $token_status eq "" ) {
        return "token not authorized";
    }
    return 'granted';
}
sub check_authorization_simple{
    my($self, $c, $token, $Origin) = @_;
    my $dbh = $self->dbh;
    my $token_status = "";
    $Origin = $Origin || return "Please use MAP RESTFul client";
    $token = $token || return  "token can not be empty";
    my $origin_status = "";
    my $strSQLcheckOrigin = "SELECT origin FROM api_allowed_origin WHERE origin = ?";
    my $sth = $dbh->prepare( $strSQLcheckOrigin, );
    $sth->execute( $Origin ) or return  $sth->errstr;
    while ( my $record = $sth->fetchrow_hashref())
    {
        $origin_status = "ok";
    }
    if ( $origin_status eq "" )
    {
        return "Origin not allowed";
    }
    my $strSQLtoken = 'SELECT * FROM api_access_token WHERE token = ? AND active_status = 1 AND date_expiration > '.time.'';
    $sth = $dbh->prepare( $strSQLtoken, );
    $sth->execute( $token ) or return  $c->fail( $sth->errstr );
    while ( my $record = $sth->fetchrow_hashref())
    {
        $token_status = "ok";
    }
    if ( $token_status eq "" ) {
        return "token not authorized";
    }
    return 'granted';
}

1;
