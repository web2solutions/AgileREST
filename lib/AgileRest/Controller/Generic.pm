package AgileRest::Controller::Generic;
use Mojo::Base 'Mojolicious::Controller';

use AgileRest::Model::Generic;




sub fail{
  my $self = shift;
  my $err_msg = shift;

  $self->render(
    json => { status => 'err', response =>  'Server error: '. $err_msg }
    ,status => 500
  );
}

# This action will render a template
sub get {
  my $self = shift;

  my $app = $self->app;
  my $API = $self->API;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $remote_address = $transaction->remote_address;
  my $port = $transaction->remote_port;

  #$logger->debug('Not sure what is happening here');

  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => $self->stash('item'),
    collection => $self->stash('collection'),
    logger => $logger,
    controller => $self
  );

  my $conf = {
    count => $self->param('count'),
    posStart => $self->param('posStart'),
    columns => $self->param('columns'),
    filter => $self->param('filter'),
    order => $self->param('order'),
    filter_operator => $self->param('filter_operator'),
    relationalColumn => undef,
    relational_id => undef,
    specific_append_sql_logic_select => undef,
  };


  $self->res->headers->access_control_allow_origin('*');

  #$self->res->headers->allow('GET, POST, PUT, DELETE, OPTIONS');

  $self->res->headers->vary('Accept')->append(Vary => 'Accept-Encoding')->to_string;;

  $self->res->headers->accept_charset('UTF-8');

  $self->cache_control->no_caching;

  $self->res->headers->add('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
  $self->res->headers->add('Access-Control-Max-Age' => 1728000);
  $self->res->headers->add('X-Content-Type-Options' => 'nosniff');
  $self->res->headers->add('X-FRAME-OPTIONS' => 'DENY');
  $self->res->headers->add('X-Server-Time' => time);
  $self->res->headers->add('X-XSS-Protection' => '1; mode=block');
  $self->res->headers->add('X-Powered-By' => 'Perl - Mojolicious');

  #my @records = $model->get_collection( $conf );

  #$self->respond_to(
  #  json => {
  #    json => $model->get_collection( $conf )
  #  },
  #  xml  => {text => '<hello>world</hello>'}
  #);

  $self->render(
    json => $model->get_collection( $conf )
    ,status => 200
  );


  # Do something after the transaction has been finished
  $self->on(finish => sub {
    my $c = shift;
    $c->app->log->debug('We are done');
  });
}

1;
