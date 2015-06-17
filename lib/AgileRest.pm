package AgileRest;
use Mojo::Base 'Mojolicious';
use Mojo::Log;
use Mojo::Redis2;
use Mojolicious::Plugin::TtRenderer::Engine;
use AgileRest::API;

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

# Every CPAN module needs a version
#our $VERSION = '1.0';


# This method will run once at server start
sub startup {
  my $app = shift;
  #my $self = shift;

  #$app->config(hypnotoad => {
  #  listen => ['http://*:3000']
  #  #,accepts => 100 # default 1000 Maximum number of connections a worker is allowed to accept before stopping gracefully and then getting replaced with a newly started worker
  #  #,clients => 100 # default 1000 Maximum number of concurrent connections each worker process is allowed to handle
  #  ,proxy => 1
  #  ,workers => 10 # default 4
  #});


  # mv public lib/AgileRest/
  # mv templates lib/AgileRest/
  # Switch to installable home directory
  #$app->home->parse(catdir(dirname(__FILE__), 'AgileREST'));

  # Switch to installable "public" directory
  #$app->static->paths->[0] = $self->home->rel_dir('public');

  # Switch to installable "templates" directory
  #$app->renderer->paths->[0] = $self->home->rel_dir('templates');



  # >>>>>>>============= START PLUGINS =============<<<<<<<<<<
  # Documentation browser under "/perldoc"
  #$app->plugin('PODRenderer');

  # use config file
  $app->plugin('Config');

  # http://search.cpan.org/~graf/Mojolicious-Plugin-AccessLog-0.006/lib/Mojolicious/Plugin/AccessLog.pm
  #$app->plugin(AccessLog => log => '/var/log/mojo/access.log');

  # fast JSON parser
  $app->plugin('JSON::XS');

  # add default Mojo helpers
  $app->plugin('DefaultHelpers');

  $app->plugin( 'Mojolicious::Plugin::PDFRenderer', {
            javascript_delay => 1000
            , load_error_handling => 'ignore'
            , page_height => '5in'
            , page_width => '10.5in'
            # options that would otherwise be passed to PDF::WebKit,
            # see `wkhtmltopdf --extended-help` for more (replace dashes w/ underscores)
  } );

  # set db helper via database plugin
  $app->plugin('database', {
      dsn      => 'dbi:Pg:dbname=juris;host=localhost',
      #host      => '10.0.0.9',
      username => $app->config('db_user'),
      password => $app->config('db_password'),
      options  => { 'pg_enable_utf8' => 1, AutoCommit => 1 },
      helper   => 'db',
    }
  );



  # >>>>>>>============= END PLUGINS =============<<<<<<<<<<



  # force respond application/json; charset=utf-8 when JSON
  $app->types->type( json => 'application/json; charset=utf-8' );

  # create API object
  my $API = AgileRest::API->new( dbh => $app->db );
  $app->helper(
      API => sub{
        return $API;
      }
  );



  # >>>>>>>============= START HELPERS =============<<<<<<<<<<

  my $redis = Mojo::Redis2->new;
  $app->helper(
      redis => sub{
        return $redis;
      }
  );

  # helper for disconnect db
  $app->helper(
      db_disconnect => sub{
        my $self = shift;
        $self->db->disconnect;
        #$self->db = "";
      }
  );

  $app->helper(
    'unauthorized' => sub{
      my $c = shift;
      my $err_msg = shift;
      my $logger = $c->logger;
      my $origin = $c->req->headers->header('Origin') || '*';
      $c->res->headers->header('Access-Control-Allow-Origin'=> $origin);
      $c->res->headers->header('Content-Type'=> 'application/json; charset=utf-8');
      $c->res->headers->www_authenticate('Basic');

      $c = $c->render(
        json => {
          status => 'err', response =>  'Unauthorized: '. $err_msg
        },
        any => '',
        status => 401
      );
    }
  );

  $app->helper(
    'fail' => sub{
      my $c = shift;
      my $err_msg = shift || ' unknow error';
      my $logger = $c->logger;
      $logger->debug( 'inside fail' );
      my $origin = $c->req->headers->header('Origin') || '*';
      $c->res->headers->header('Access-Control-Allow-Origin'=> $origin);
      $c = $c->render(
        json => {
          status => 'err', response =>  'Server error: '. $err_msg
        },
        any => '',
        status => 500
      );
    }
  );


  $app->helper(
    'resource_not_found' => sub{
      my $c = shift;
      my $strSQL = shift;
      my $primaryKey = shift;
      my $str_id = shift;
      my $logger = $c->logger;
      $logger->debug( 'inside resource_not_found' );
      $c = $c->render(
        json => {
          status => 'success',
          response => 'resource not found.',
          sql => $strSQL,
          ''.$primaryKey.'' => $str_id
        },
        #any => '',
        status => 404
      );
    }
  );


  # looger helper
  my $logger = Mojo::Log->new;
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
    'expose_default_headers' => sub{
      my $c = shift;
      my $logger = $c->logger;
      my $transaction = $c->tx;
      my $remote_address = $transaction->remote_address;
      my $port = $transaction->remote_port;
      my $address = $transaction->original_remote_address;
      my $req = $transaction->req;
      my $res = $transaction->res;
      my $version = $req->env->{GATEWAY_INTERFACE} || 'unknow';
      #my $version = $req->env->{'psgi.version'} || 'unknow';
      my $url = $req->url;
      my $info = $req->url->to_abs->userinfo || '';
      my $host = $req->url->to_abs->host;
      my $path = $req->url->to_abs->path;
      my $origin = $req->headers->header('Origin') || '*';
      $c->res->headers->access_control_allow_origin( $origin );
      $c->res->headers->vary('Accept')->append(Vary => 'Accept-Encoding')->to_string;;
      $c->res->headers->accept_charset('UTF-8');
      $c->res->headers->add('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
      $c->res->headers->add('Access-Control-Max-Age' => 1728000);
      $c->res->headers->add('X-Content-Type-Options' => 'nosniff');
      $c->res->headers->add('X-Frame-Options' => 'DENY');
      $c->res->headers->add('X-Server-Time' => time);
      $c->res->headers->add('X-XSS-Protection' => '1; mode=block');
      $c->res->headers->add('X-Powered-By' => 'Perl - Mojolicious');
      # https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
      $c->res->headers->add('Access-Control-Allow-Credentials' => 'true');
      $c->cache_control->no_caching;
    }
  );

  # >>>>>>>============= END HELPERS =============<<<<<<<<<<



  # add support to template toolkit engine
  my $tt = Mojolicious::Plugin::TtRenderer::Engine->build(
    mojo => $app,
    template_options => {
      #PROCESS  => 'tpl/wrapper',
      FILTERS  => [ ],
      UNICODE  => 1,
      ENCODING => 'UTF-8',
    }
  );
  $app->renderer->add_handler( tt => $tt );



  # >>>>>>>============= START ROUTES =============<<<<<<<<<<


    # >>>>>>>===== routes events ======<<<<<<<<<<
  $app->hook(before_dispatch => sub {
    my $c = shift;
    my $API = $c->API;
    my $logger = $c->logger;
    #$logger->debug( $c->dumper( $c->req->url->path ) );
    if ( $c->req->url->path eq '/auth.json' )
    {

    }
    else
    {
      my $access_granted_message = $API->check_authorization( $c );
      if ( $access_granted_message ne 'granted' )
      {
        #return $c->unauthorized( $access_granted_message );
      }
    }
  });

  $app->hook(after_static => sub {
    my $c = shift;
    $c->res->headers->cache_control('max-age=3600, must-revalidate');
  });
    # >>>>>>>===== routes events ======<<<<<<<<<<


  # Router
  my $routes = $app->routes;

  # add generic answer to OPTIONS request method
  $routes->options('*')->to(cb => sub {
    my $self = shift;
    my $origin = $self->req->headers->header('Origin') || '*';
    $self->res->headers->header('Access-Control-Allow-Origin'=> $origin);
    $self->res->headers->header('Access-Control-Allow-Credentials' => 'true');
    $self->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
    $self->res->headers->header('Access-Control-Allow-Headers' => $self->req->headers->header('Access-Control-Request-Headers'));
    $self->res->headers->header('Access-Control-Max-Age' => '1728000');
    $self->res->headers->header('Content-Type' => 'application/json; charset=utf-8');
    #$self->res->headers->header('Access-Control-Allow-Credentials' => 'true');
    $self->respond_to(any => { data => '', status => 200 });
  });


  # ==== HELPERS end points
  # github hook - notify changes on branches
  $routes->post('/github/hook')->to(
    controller => 'github',
    action => 'hook'
  );

  # authentication
  $routes->post('/auth')->to(
    controller => 'auth',
    action => 'auth'
  );

  # map database and generate end points data
  $routes->get('/database/map')->to(
    controller => 'database',
    action => 'map'
  );

  $routes->get('/database/generatemodel')->to(
    controller => 'database',
    action => 'model'
  );

  $routes->get('/database/getmodel')->to(
        controller => 'database',
        action => 'get_model',
  );



  $routes->get('/agile_rest_column')->to(
        controller => 'generic',
        action => 'list',
        collection => 'agile_rest_column',
        item => 'column'
  );

  # ==== HELPERS end points

  # >>>>>>>>>>>> Generic END POINTS
  my $dbh = $app->db;
  my $strSQL = 'SELECT table_name FROM agile_rest_table ORDER BY table_name ASC';
	my $sth = $dbh->prepare( $strSQL, );
	$sth->execute() or return { error => $sth->errstr . ' ----------- '.$strSQL };
	while ( my $record = $sth->fetchrow_hashref())
	{
      my $primary_key = $API->get_table_schema( $record->{table_name} )->{primary_key};
      my $tem_name = substr($record->{table_name}, 0, -1);

      $routes->get('/'.$record->{table_name}.'')->to(
        controller => 'generic',
        action => 'list',
        collection => $record->{table_name},
        item => $tem_name
      );

      $routes->post('/'.$record->{table_name}.'')->to(
        controller => 'generic',
        action => 'create',
        collection => $record->{table_name},
        item => $tem_name
      );

      $routes->get('/'.$record->{table_name}.'/:'.$primary_key.'')->to(
        controller => 'generic',
        action => 'read',
        collection => $record->{table_name},
        item => $tem_name
      );

      $routes->put('/'.$record->{table_name}.'/:'.$primary_key.'')->to(
        controller => 'generic',
        action => 'update',
        collection => $record->{table_name},
        item => $tem_name
      );

      $routes->delete('/'.$record->{table_name}.'/:'.$primary_key.'')->to(
        controller => 'generic',
        action => 'del',
        collection => $record->{table_name},
        item => $tem_name
      );

      $routes->get('/'.$record->{table_name}.'/doc/doc')->to(
        controller => 'generic',
        action => 'doc',
        collection => $record->{table_name},
        item => $tem_name
      );
  }
  # >>>>>>>>>>>> Generic END POINTS

   # >>>>>>>============= END ROUTES =============<<<<<<<<<<
}

1;
