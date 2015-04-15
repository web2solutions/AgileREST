package AgileRest::API;
use Moo;

use Mojo::Message::Response;


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


sub get_table_schema{
	my($self, $table) = @_;

	my $dbh = $self->dbh;
	my $schema = {};

	my @columns;
	$table = $table || MAP::API->fail( "please provide a table name" );

	my $strSQL = "select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = ? ORDER BY ORDINAL_POSITION ASC";
	my $sth = $dbh->prepare( $strSQL, );
	$sth->execute( $table ) or die $sth->errstr;
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

sub regex_alnum
{
	my ($self, $value) = @_;

	$value =~ s/ /_/g;
	$value =~ s/\W//g;
	return $value;
}


sub fail{
	my($self, $controller, $err_msg) = @_;

	#$controller->render(
  #  json => { status => 'err', response =>  'Server error: '. $err_msg }
  #  ,status => 500
  #);

	#exit;

  die Mojo::Exception->new($err_msg)->trace(2)->verbose(1);


    #debug $err_msg;
	#halt(Dancer::Response->new(
	#	status =>500,
	#	content => $wcontent,
	#	headers => [
	#		'Content-Type' => 'application/json',
	#		'Content-Length' => length($wcontent),
	#		'Access-Control-Allow-Origin' => request->header("Origin")
	#	]
	#));
}


1;
