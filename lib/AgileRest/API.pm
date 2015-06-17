package AgileRest::API;
use Moo;
#use Mojo::Message::Response;
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
	return '';
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


sub Exec
{
	my $self = shift;
	my $dbh = $self->dbh;
	$dbh->do(shift,undef,@_) || die"Can't exec:\n".$dbh->errstr;
}

sub SelectOne
{
	my $self = shift;
	my $dbh = $self->dbh;
	my $sql = shift;
	my $res = $dbh->selectrow_arrayref($sql,undef,@_);
	die "Can't execute select:  '".$sql."'  \n".$dbh->errstr if $dbh->err;
	return $res->[0];
}

sub SelectRow
{
	my $self = shift;
	my $dbh = $self->dbh;
	my $res = $dbh->selectrow_hashref(shift,undef,@_);
	die"Can't execute select:\n".$dbh->errstr if $dbh->err;
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
	die"Can't execute select:\n".$dbh->errstr if $dbh->err;

	return $sth->fetchall_arrayref( { } );
}

#

sub Select
{
	my $self = shift;
	my $dbh = $self->dbh;
	my $res = $dbh->selectall_arrayref( shift, { Slice=>{} }, @_ );
	die"Can't execute select:\n".$dbh->errstr if $dbh->err;
	return undef if $#$res == -1;
	#my $cidxor = 0;
	#for(@$res)
	#{
	#	$cidxor = $cidxor ^ 1;
	#	$_->{row_cid} = $cidxor;
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
	$value =~ s/\W//g;
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
  my $Origin  	= $c->req->headers->header('Origin') || return "malformed headers";

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

	my $dbh = dbh();

	my $token_status = "";
	$Origin = $Origin || $c->unauthorized( "Please use MAP RESTFul client" );
	$token = $token || $c->unauthorized( "token can not be empty" );
	my $origin_status = "";

	my $strSQLcheckOrigin = "SELECT origin FROM tbl_api_allowed_origin WHERE origin = ?";
	my $sth = $dbh->prepare( $strSQLcheckOrigin, );
	$sth->execute( $Origin ) or $c->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{
		$origin_status = "ok";
	}

	if ( $origin_status eq "" )
	{
		$c->unauthorized("Origin not allowed");
	}

	my $strSQLtoken = 'SELECT * FROM tbl_api_access_token WHERE token = ? AND active_status = 1 AND date_expiration > '.time.'';
	$sth = $dbh->prepare( $strSQLtoken, );
	$sth->execute( $token ) or $c->fail( $sth->errstr );
	while ( my $record = $sth->fetchrow_hashref())
	{
		$token_status = "ok";
	}


	if ( $token_status eq "" ) {
		$c->unauthorized("token not authorized");
	}
}

1;
