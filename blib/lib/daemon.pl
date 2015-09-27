use Mojo::Server::Daemon;

my $daemon = Mojo::Server::Daemon->new(listen => ['http://*:3000']);
$daemon->run('/Users/eduardoalmeida/apps/AgileREST/script/agile_rest');
