package AgileRest::Controller::Generic;
use Mojo::Base 'Mojolicious::Controller';

use AgileRest::Model::Generic;

sub list {
  my $self = shift;

  my $API = $self->API;

  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }

  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger
  );

  my $collection_data = $model->list( {
    count => $self->param('count'),
    posStart => $self->param('posStart'),
    columns => $self->param('columns'),
    filter => $self->param('filter'),
    order => $self->param('order'),
    filter_operator => $self->param('filter_operator'),
    relationalColumn => undef,
    relational_id => undef,
    specific_append_sql_logic_select => undef,
  } );

  if ( defined( $collection_data->{error} ) ) {
    return $self->fail( $collection_data->{error} );
  }

  $self->expose_default_headers;
  $self->render(
    json => $collection_data
    ,status => 200
  );
  #$self->respond_to(
  #  json => {
  #    json => $model->get_collection( $conf )
  #  },
  #  xml  => {text => '<hello>world</hello>'}
  #);


  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
    #$c->app->log->debug('We are done');
    #my $logger = $c->logger;
    #$logger->debug( '======> End of transaction.');
  });
}


sub read {
  my $self = shift;

  my $API = $self->API;

  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }

  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger
  );

  my $item_data = $model->read( {
    columns => $self->param('columns'),
    item_id => $self->stash( $model->primary_key )

  } );

  if ( defined( $item_data->{error} ) )
  {
    if ($item_data->{error} eq 'resource_not_found')
    {
      my $strSQL = $item_data->{strSQL};
      my $primaryKey = $item_data->{primaryKey};
      my $str_id = $item_data->{str_id};
      return $self->resource_not_found( $strSQL, $primaryKey, $str_id);
    }
    else
    {
      return $self->fail( $item_data->{error} );
    }
  }

  $self->expose_default_headers;
  $self->render(
    json => $item_data
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
    #$c->app->log->debug('We are done');
    #my $logger = $c->logger;
    #$logger->debug( '======> End of transaction.');
  });
}



sub create {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }

  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger
  );

  my $hash = $self->param('hash') || return $self->fail( 'hash is a mandatory parameter for this end point' );

  my $item_data = $model->create( {
    hash => $hash
  } );

  if ( defined( $item_data->{error} ) )
  {
    return $self->fail( $item_data->{error} );
  }

  $self->expose_default_headers;
  $self->render(
    json => $item_data
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}


sub update {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }

  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger
  );

  my $hash = $self->param('hash') || return $self->fail( 'hash is a mandatory parameter for this end point' );
  my $item_id = $self->stash( $model->primary_key ) || return $self->fail( $model->primary_key. ' parameter is missing on stash' );

  my $item_data = $model->update( {
    item_id => $self->stash( $model->primary_key ),
    hash => $hash
  } );

  if ( defined( $item_data->{error} ) )
  {
    return $self->fail( $item_data->{error} );
  }

  $self->expose_default_headers;
  $self->render(
    json => $item_data
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}


sub del {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }
  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );
  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger
  );

  my $item_id = $self->stash( $model->primary_key ) || return $self->fail( $model->primary_key. ' parameter is missing on stash' );
  my $item_data = $model->del( {
    item_id => $item_id
  } );

  if ( defined( $item_data->{error} ) )
  {
    if ($item_data->{error} eq 'resource_not_found')
    {
      my $strSQL = $item_data->{strSQL};
      my $primaryKey = $item_data->{primaryKey};
      my $str_id = $item_data->{str_id};
      return $self->resource_not_found( $strSQL, $primaryKey, $str_id);
    }
    else
    {
      return $self->fail( $item_data->{error} );
    }
  }

  $self->expose_default_headers;
  $self->render(
    json => $item_data
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}



sub doc {
  my $self = shift;
  my $API = $self->API;
  #my $access_granted_message = $API->check_authorization( $self );
  #if ( $access_granted_message ne 'granted' )
  #{
  #  return $self->unauthorized( $access_granted_message );
  #}



  my $app = $self->app;
  my $logger = $self->logger;

  $logger->debug( ' inside doc ');

  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );


  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger
  );


  my $table_schema = $model->schema;
  my $tableName = $model->table_prefix . $model->collection;

  my $defaultColumns = '';
  for( @{$table_schema->{columns}} )
  {

      $defaultColumns = $defaultColumns . $_->{name} . ',' if $_->{name} ne $model->primary_key;
  }

  $defaultColumns = $defaultColumns . $model->primary_key;

  my @defaultColumns = split(/,/, $defaultColumns);




  $self->render(
    template => 'doc',
    format => 'html',
    handler => 'tt',
    collectionName => $self->stash('collection'),
    tableName => $tableName,
    prefix => '',
    columns => $model->columns,
    defaultColumns => [@defaultColumns],
    defaultColumnsStr => $defaultColumns,
    primaryKey => $model->primary_key
  );



  #$self->expose_default_headers;
  #$self->render(
  #  json => $item_data
  #  ,status => 200
  #);

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}

1;
