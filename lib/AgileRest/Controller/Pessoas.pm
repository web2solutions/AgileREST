package AgileRest::Controller::Pessoas;
use Mojo::Base 'Mojolicious::Controller';

use AgileRest::Model::Generic;


#helper db => sub { AgileRest::API->dbh };

# This action will render a template
sub get {
  my $self = shift;

  my $API = $self->API;
  my $logger = $self->logger;

  #$logger->debug('Not sure what is happening here');

  my $model = AgileRest::Model::Generic->new(
    API => $API,
    item => 'pessoa',
    collection => 'pessoas',
    logger => $logger
  );

  my @records = $model->get_collection;

  $self->respond_to(
    json => {
      json => {
        item => $model->item,
        collection => $model->collection,
        ''.$model->collection.'' => @records,
        columns => $model->columns
      }
    },
    xml  => {text => '<hello>world</hello>'}
  );

  #$self->render(
  #  json => {foo => [222, 'test', 3]}
  #  ,status => 200
  #);
}

1;
