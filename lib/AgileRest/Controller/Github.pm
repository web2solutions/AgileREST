package AgileRest::Controller::Github;
use Mojo::Base 'Mojolicious::Controller';

use Mail::SendEasy;

sub hook {
  my $self = shift;

  my $API = $self->API;
  my $app = $self->app;
  my $logger = $self->logger;
  my $transaction = $self->tx;
  my $req = $transaction->req;
	my $event = request->header('X-Github-Event');
  my $signature = request->header('X-Hub-Signature');
  my $delivery_id = request->header('X-Github-Delivery');
  my $jsonpayload = request->body || 'my body';
  my $payload =  from_json( $jsonpayload );
  my $repo = $payload->{repository}->{name};

  my $person = '';

  my $message = '
    Hello, this is an automated event notice\'s about the '.$repo.' repository. <br><br>

    Please don\'t respond this message. <br><br>

    <b>Event type:</b><br>
    '. $event . '<br><br>
  ';

  #head_commit


  if ( $event eq 'push' ) {
      $message = $message .'


      '. $payload->{head_commit}->{author}->{name} . ' did <b>' .$event.'</b> at <b>'.$repo.'</b> repository.<br><br>

      <b>Commit\'s message:</b><br>
      '. $payload->{head_commit}->{message} . '<br><br>

      <b>Commit\'s date:</b><br>
      '. $payload->{head_commit}->{timestamp} . '<br><br>

      <b>Commit\'s detail:</b><br>
      <a href="'. $payload->{head_commit}->{url} . '">'. $payload->{head_commit}->{url} . '</a><br><br>

      <b>Commiter\'s detail:</b><br>
      <a href="https://github.com/'. $payload->{head_commit}->{author}->{username} . '/">'. $payload->{head_commit}->{author}->{name} . '</a><br><br>

      ';

      $person = $payload->{head_commit}->{author}->{name};
  }
  else
  {
      $person = $payload->{sender}->{login};

  }


  $message = $message . '
  <b>Repository\'s description:</b><br>
  '. $payload->{repository}->{description} . '<br><br>

  <b>Repository\'s Link:</b><br>
  <a href="'. $payload->{repository}->{html_url} . '">'. $payload->{repository}->{html_url} . '</a><br><br>

  <b>Sender\'s information:</b><br>
  <a href="'. $payload->{sender}->{html_url} . '"><img width="100" height="100" border="0" src="'. $payload->{sender}->{avatar_url} . '" /></a><br><br>


  <br>Best regards<br>
  ---------------------------------<br>
  WEB2 Solutions\' software engineering team<br><br>

  ';

  my @target = (
    'eduardo.llmeida@cairsolutions.com',
    'mark.livings@cairsolutions.com',
    'alvaro.brasilia@gmail.com'

  );

  my $mail = new Mail::SendEasy(
    smtp => 'smtp.web2solutions.com.br',
    user => 'eduardo@web2solutions.com.br',
    pass => 'fuzzy24k',
    port => '587'
  );
  my $status = $mail->send(
    from    => 'eduardo@web2solutions.com.br',
    from_title => 'WEB2\' GitHub Hooker',
    reply   => 'eduardo@web2solutions.com.br' ,
    error   => 'eduardo@web2solutions.com.br' ,
    to      => 'eduardo@web2solutions.com.br' ,
    cc => join('; ', @target),
    subject => $person . ' ' .$event.'ed at '.$repo.' repository' ,
    msg     => "" ,
    html    => $message,
  );


  $self->expose_default_headers;
  my $response = undef;
  if (!$status)
  {
      $response =  {
          status => 'err',
          response => $mail->error,
      };
  }else
  {
      $response = {
          status => 'success',
          response => 'sent',
      };
  }

  $self->render(
    json => $response,
    status => 200
  );

}

1;
