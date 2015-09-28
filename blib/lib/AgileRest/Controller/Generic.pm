package AgileRest::Controller::Generic;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dump qw(dump);
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
  $logger->debug( 'inside list.');
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );
  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger,
    controller => $self
  );

  my $count = $self->param('count') || 50;
  my $posStart = $self->param('posStart') || 0;
  my $columns = $self->param('columns') || '';

   #$logger->debug( $columns );

  # to be used with redis for caching responses in the future
  # my $identifier = sha256_hex( 'cache_table_' . $self->stash('collection') . '_' . $count. '_' . '_' . $posStart . '_' . '_' . $columns . '_' );

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
    logger => $logger,
    controller => $self
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
    logger => $logger,
    controller => $self
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
    logger => $logger,
    controller => $self
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
    logger => $logger,
    controller => $self
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
  my $dbh = $API->dbh;
  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger,
    controller => $self
  );

  my $table_schema = $model->schema;
  my $tableName = $model->table_prefix . $model->collection;
  my $defaultColumns = $model->default_columns;

  my $table_id = 0;
  my $table_MetaData = undef;


  my $strSQL = "SELECT * FROM agile_rest_table WHERE table_name = ?;";
  my $sth = $dbh->prepare( $strSQL, );
  $sth->execute( $tableName ) or $self->fail( $sth->errstr );
  while ( my $record = $sth->fetchrow_hashref())
  {

    $table_MetaData = $record;
    $table_id = $record->{"agile_rest_table_id"};

  }

  my @columnsMetaData;
  $strSQL = "SELECT * FROM agile_rest_column WHERE agile_rest_table_id = ? ORDER BY ordinal_position ASC";
  $sth = $dbh->prepare( $strSQL, );
  $sth->execute( $table_id ) or $self->fail( $sth->errstr );
  while ( my $record = $sth->fetchrow_hashref())
  {
      push @columnsMetaData, $record;
      #$logger->debug( dump $record );
  }

  $logger->debug( dump @columnsMetaData );

  my @defaultColumns = split(/,/, $defaultColumns);
  return $self->render(
    template => 'doc',
    format => 'html',
    handler => 'tt',
    collectionName => $self->stash('collection'),
    tableName => $tableName,
    prefix => '',
    columns => $model->columns,
    defaultColumns => [@defaultColumns],
    defaultColumnsStr => $defaultColumns,
    primaryKey => $model->primary_key,
    columnsMetaData => [@columnsMetaData],
    table_MetaData => $table_MetaData
  ) if $self->req->url->to_abs->userinfo eq $self->app->config->{doc_user} . ':' . $self->app->config->{doc_password};

  $self->res->headers->www_authenticate('Basic');
  $self->render(text => 'Sorry Bill, you need to authenticate!', status => 401);


  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;

    $API->trackAccessLog( $c );
  });
}

1;
