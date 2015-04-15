package AgileRest::Model::Pessoas;
use Moo;


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


has 'default_columns' => (
	is      => 'rw',
	default => ''
);



sub columns
{
	my $self = shift;
	my $columns = '';
	my $a = 0;
	#if ( $self->default_columns eq '' )
	#{
		my $API = $self->API;
		my $table_schema = $API->get_table_schema( $self->collection );
		my $primaryKey = $table_schema->{primary_key};

		for( @{$table_schema->{columns}} )
		{
			$columns = $columns . $_->{name} . ',' if $_->{name} ne $primaryKey;
			$a = $a  + 1;
		}
		$columns = $columns . $primaryKey;

		$self->default_columns( $columns );
	#}



	return $table_schema->{columns};
}

sub table_data
{
	my $self = shift;
	my $API = $self->API;

	my @table_data = $API->SelectTable( $self->collection );

	return @table_data;
}




1;
