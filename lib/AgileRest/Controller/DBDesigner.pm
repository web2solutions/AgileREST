package AgileRest::Controller::DBDesigner;
use Mojo::Base 'Mojolicious::Controller';

use AgileRest::Model::DBDesigner;

use Data::Dump qw(dump);

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
  #$logger->debug( 'inside list.');
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );
  my $model = AgileRest::Model::DBDesigner->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger,
    controller => $self
  );



  my $count = $self->param('count') || 50;
  my $posStart = $self->param('posStart') || 0;
  my $columns = $self->param('columns') || '';
  my $relational_id =  defined $self->stash( 'relationalColumn' ) ? $self->param( $self->stash( 'relationalColumn' ) ) : undef;

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
    relationalColumn => $self->stash( 'relationalColumn' ) || undef,
    grid_json_model =>  $self->stash( 'grid_json_model' ) || 'basic',
    relational_id => $relational_id,
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
  my $model = AgileRest::Model::DBDesigner->new(
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
  my $model = AgileRest::Model::DBDesigner->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger,
    controller => $self
  );
  my $hash = $self->param('hash') || return $self->fail( 'hash is a mandatory parameter for this end point' );
  my $action = $self->param('action') || return $self->fail( 'action is a mandatory parameter for this end point' );
  my $item_data = $model->create( {
    hash => $hash
    ,action => $action
    ,app => $app
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
  my $model = AgileRest::Model::DBDesigner->new(
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
  my $model = AgileRest::Model::DBDesigner->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger,
    controller => $self
  );
  my $action = $self->param('action') || return $self->fail( 'action is a mandatory parameter for this end point' );
  my $table_name = $self->param('table_name') || return $self->fail( 'table_name is a mandatory parameter for this end point' );
  my $column_name = $self->param('column_name') || '';
  my $item_id = $self->stash( $model->primary_key ) || return $self->fail( $model->primary_key. ' parameter is missing on stash' );
  my $item_data = $model->del( {
    item_id => $item_id
    ,action => $action
    ,table_name => $table_name
    ,column_name => $column_name
    ,app => $app
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

  if ( $action eq 'deletetable' ) {
    #my $app = $c->app;
    my $routes = $app->routes;
    $logger->debug('get_'.$table_name);
    $routes->find('get_'.$table_name)->remove;
    $routes->find('post_'.$table_name)->remove;
    $routes->find('geti_'.$table_name)->remove;
    $routes->find('put_'.$table_name)->remove;
    $routes->find('delete_'.$table_name)->remove;
    $routes->find('getd_'.$table_name)->remove;
  }

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}


sub add_rel {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }
  #my $app = $self->app;
  #my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;

  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $table_name = $self->stash( 'table_name' ) || return $self->fail( 'table_name parameter is missing on stash' );
  my $column_name = $self->stash( 'column_name' ) || return $self->fail( 'column_name parameter is missing on stash' );
  my $foreign_table_name = $self->stash( 'foreign_table' ) || return $self->fail( 'cforeign_table parameter is missing on stash' );
  my $foreign_column_value = $self->stash( 'foreign_column' ) || return $self->fail( 'foreign_column parameter is missing on stash' );

  my $strAlter = 'ALTER TABLE '.$table_name.' ';
  my $strAddConstraint = ' ADD CONSTRAINT fkey_'.$API->regex_alnum($table_name).'_'.$API->regex_alnum($column_name).' FOREIGN KEY ('.$API->regex_alnum($column_name).') ';
  my $strReferences = ' REFERENCES '.$API->regex_alnum($foreign_table_name).' ('.$API->regex_alnum($foreign_column_value).') ';
  my $strActions = ' ON UPDATE CASCADE ON DELETE RESTRICT; ';
  my $strSQLforeign_key = $strAlter . $strAddConstraint . $strReferences . $strActions;
  #$sth = $dbh->prepare( $strSQLforeign_key, );
  #$sth->execute( ) or return { error => $sth->errstr . " SQL statement: ".$strSQLforeign_key};

  my $query = $API->Exec( $strSQLforeign_key, undef );

  if ( defined( $query->{error} ) )
  {
    return $self->fail( $query->{error} );
  }

  $self->expose_default_headers;
  $self->render(
    json => $query
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}



sub drop_rel {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }
  #my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;

  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $table_name = $self->stash( 'table_name' ) || return $self->fail( 'table_name parameter is missing on stash' );
  my $constraint_name = $self->stash( 'constraint_name' ) || return $self->fail( 'constraint_name parameter is missing on stash' );
  my $strSQL = ' ALTER TABLE '.$table_name.' DROP CONSTRAINT '.$constraint_name.'; ';
  #my @values;

  #push @values, $table_name;
  #push @values, $constraint_name;

  #$logger->debug($table_name);
  #$logger->debug($constraint_name);
  #$logger->debug(dump(@values));

  my $query = $API->Exec( $strSQL, undef );

  if ( defined( $query->{error} ) )
  {
    return $self->fail( $query->{error} );
  }

  $self->expose_default_headers;
  $self->render(
    json => $query
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );



  });
}


sub add_user_identifier {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }
  #my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;

  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $table_name = $self->stash( 'table_name' ) || return $self->fail( 'table_name parameter is missing on stash' );
  $table_name =~ s/'/''/g;


  my $strSQL = ' ALTER TABLE '.$table_name.' ADD COLUMN t_rex_user_id integer NOT NULL DEFAULT 0; ';
  #my @values;

  #push @values, $table_name;
  #push @values, $constraint_name;

  #$logger->debug($table_name);
  #$logger->debug($constraint_name);
  #$logger->debug(dump(@values));

  my $query = $API->Exec( $strSQL, undef );

  if ( defined( $query->{error} ) )
  {
    my $e = $query->{error};
    $e =~ s/"//g;
    return $self->fail( $e );
  }

  $self->expose_default_headers;
  $self->render(
    json => $query
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}


sub set_column_not_nullable {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }
  #my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;

  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $table_name = $self->stash( 'table_name' ) || return $self->fail( 'table_name parameter is missing on stash' );
  my $column_name = $self->stash( 'column_name' ) || return $self->fail( 'column_name parameter is missing on stash' );

  $table_name =~ s/'/''/g;
  $column_name =~ s/'/''/g;

  my $strSQL = ' ALTER TABLE '.$table_name.' ALTER COLUMN '.$column_name.' SET NOT NULL; ';
  my $query = $API->Exec( $strSQL, undef );

  if ( defined( $query->{error} ) )
  {
    my $e = $query->{error};
    $e =~ s/"//g;
    return $self->fail( $e );
  }

  $strSQL = ' UPDATE agile_rest_column SET is_nullable = \'NO\', required = true where name = \''.$column_name.'\'; ';
  $query = $API->Exec( $strSQL, undef );

  if ( defined( $query->{error} ) )
  {
    my $e = $query->{error};
    $e =~ s/"//g;
    return $self->fail( $e );
  }

  $self->expose_default_headers;
  $self->render(
    json => $query
    ,status => 200
  );

  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $API->trackAccessLog( $c );
  });
}


sub set_column_nullable {
  my $self = shift;
  my $API = $self->API;
  my $access_granted_message = $API->check_authorization( $self );
  if ( $access_granted_message ne 'granted' )
  {
    return $self->unauthorized( $access_granted_message );
  }
  #my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;

  $API->branch( $req->headers->header('X-branch') || 'test' );

  my $table_name = $self->stash( 'table_name' ) || return $self->fail( 'table_name parameter is missing on stash' );
  my $column_name = $self->stash( 'column_name' ) || return $self->fail( 'column_name parameter is missing on stash' );

  $table_name =~ s/'/''/g;
  $column_name =~ s/'/''/g;

  my $strSQL = ' ALTER TABLE '.$table_name.' ALTER COLUMN '.$column_name.' DROP NOT NULL; ';

  my $query = $API->Exec( $strSQL, undef );

  if ( defined( $query->{error} ) )
  {
    my $e = $query->{error};
    $e =~ s/"//g;
    return $self->fail( $e );
  }

  $strSQL = ' UPDATE agile_rest_column SET is_nullable = \'YES\', required = false where name = \''.$column_name.'\'; ';
  $query = $API->Exec( $strSQL, undef );

  if ( defined( $query->{error} ) )
  {
    my $e = $query->{error};
    $e =~ s/"//g;
    return $self->fail( $e );
  }

  $self->expose_default_headers;
  $self->render(
    json => $query
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
  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
  $API->branch( $req->headers->header('X-branch') || 'test' );
  my $model = AgileRest::Model::DBDesigner->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger,
    controller => $self
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
    primaryKey => $model->primary_key
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
