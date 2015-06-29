use Mojo::Server::Morbo;


my $morbo = Mojo::Server::Morbo->new;
my $daemon = $morbo->daemon;
$morbo     = $morbo->daemon(Mojo::Server::Daemon->new);

my $watch = $morbo->watch;
$morbo    = $morbo->watch(['/Users/eduardoalmeida/apps/AgileREST/lib']);

$morbo->run('/Users/eduardoalmeida/apps/AgileREST/script/agile_rest');
