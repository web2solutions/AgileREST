package AgileRest;
use Mojo::Base 'Mojolicious';
use Mojo::Log;

use AgileRest::API;


# This method will run once at server start
sub startup {
  my $app = shift;
  #my $self = shift;



  # Documentation browser under "/perldoc"
  #$app->plugin('PODRenderer');

  # http://search.cpan.org/~graf/Mojolicious-Plugin-AccessLog-0.006/lib/Mojolicious/Plugin/AccessLog.pm
  #$app->plugin(AccessLog => log => '/var/log/mojo/access.log');

  $app->plugin('database', {
      dsn      => 'dbi:Pg:dbname=juris;host=localhost',
      #host      => '10.0.0.9',
      username => 'eduardoalmeida',
      password => 'fuzzy24k',
      options  => { 'pg_enable_utf8' => 1, AutoCommit => 0 },
      helper   => 'db',
    }
  );

  $app->plugin('DefaultHelpers');

  $app->types->type( json => 'application/json; charset=utf-8' );

  my $API = AgileRest::API->new( dbh => $app->db );
  $app->helper(
      API => sub{
        return $API;
      }
  );

  # Log to STDERR
  my $logger = Mojo::Log->new;
  # Log messages
  #$log->debug('Not sure what is happening here');
  $app->helper(
      logger => sub{
        return $logger;
      }
  );


  $app->helper(
    'cache_control.no_caching' => sub{
      my $c = shift;
      $c->res->headers->cache_control('private, max-age=0, no-cache');
    }
  );


  $app->helper(
    'cache_control.five_minutes' => sub{
      my $c = shift;
      $c->res->headers->cache_control('public, max-age=300');
    }
  );



  $app->helper(
    'Access-Control-Allow-Methods' => sub{
      my $c = shift;
      $c->res->headers->cache_control('public, max-age=300');
    }
  );






  # Router
  my $routes = $app->routes;

  # Normal route to controller
  $routes->get('/pessoas')->to(
    controller => 'generic',
    action => 'get',
    collection => 'pessoas',
    item => 'pessoa'
  );




}

1;
