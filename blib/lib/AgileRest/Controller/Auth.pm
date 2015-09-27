package AgileRest::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use Crypt::Digest::SHA256 qw( sha256_hex );
use MIME::Base64;


sub auth {
    my $self = shift;

    my $auth = $self->req->headers->authorization
    || $self->req->env->{'X_HTTP_AUTHORIZATION'}
    || $self->req->env->{'HTTP_AUTHORIZATION'}
    || return $self->unauthorized( 'authorization credential is missing' );
    $auth =~ s/Basic //gi;
    $auth = MIME::Base64::decode($auth) ||  return $self->unauthorized( 'unable to decode credential' );

    my $app = $self->app;
    my $API = $self->API;
    my $logger = $self->logger;
    my $transaction = $self->tx;
    my $req = $transaction->req;
    $API->branch( $req->headers->header('X-branch') || 'test' );

    my $ip = $self->req->env->{REMOTE_ADDR};
    my $host = $self->req->url->to_abs->host;

    my ($salt_api_user, $salt_api_secret) = split(/:/, ($auth || ":"));
    my $private_key  = $self->req->headers->user_agent || return $self->unauthorized( "malformed headers");
    my $user = MIME::Base64::decode( $salt_api_user ) || return $self->unauthorized( "unable decode salt_api_user");

    my $auth_status = "disconnected";
    my $secret_status = "";
    my $token_status = "";

    if ( defined($user) ) {
        #code
    }
    else
    {
        return $self->unauthorized( "invalid username")
    }

    my $username     =  $user || return $self->unauthorized( "invalid username 1");
    my $Origin      = $self->req->headers->header('Origin') || return $self->unauthorized( "malformed headers");
    my $origin_status = "";

    my $token = "";
    my $name = "";
    #my $last_name = "";
    my $title = "";
    my $is_new_token = 0;
    my $date_creation = 0;
    my $date_expiration = 0;

    my $entity_id = undef;
    my $api_user_id = undef;
    my $group = undef;
    my $company_id = undef;
    my $company_branch_id = undef;
    my $person_type = undef;
    my $storage_quota = 0;
    my $time_zone = 'America/Sao_Paulo';
    my $is_admin = \0;
    my $is_customer = \1;
    my $type = '';

    my $response = undef;
    my $strSQLcreateToken = '';

    my $dbh = $API->dbh;
    my $sth = undef;

    my $strSQLcheckOrigin = "SELECT origin FROM api_allowed_origin WHERE origin = ?";
    $sth = $dbh->prepare( $strSQLcheckOrigin, );
    $sth->execute( $Origin ) or $self->fail( $sth->errstr );
    while ( my $record = $sth->fetchrow_hashref())
    {
        #$logger->debug( '======> origin found ' . $Origin );
        $origin_status = "ok";
    }

    if ( $origin_status eq "" )
    {
        return $self->unauthorized( 'origin '.$Origin.' not allowed');
    }

    my $strSQLsecret = 'SELECT * FROM api_users WHERE username = ?';
    $sth = $dbh->prepare( $strSQLsecret, );
    $sth->execute( $username ) or $self->fail( $sth->errstr );
    while ( my $record = $sth->fetchrow_hashref())
    {
        $secret_status = "ok";
        my $user_salt_pass = sha256_hex( $private_key . '_' . $record->{"password"} );
        #$logger->debug( '$user_salt_pass:::::: ' . $user_salt_pass );
        #$logger->debug( '$salt_api_secret:::::: ' . $salt_api_secret );
        if ( $user_salt_pass ne $salt_api_secret) {
            return $self->unauthorized( "invalid password" );
        }
    if ( $record->{"status"} ne 1) {
            return $self->unauthorized( " user deactivated")
        }


        $api_user_id = $record->{"api_user_id"};
        $entity_id = $record->{"entity_id"};
        #$is_admin = $record->{"is_admin"};
        #$is_customer = $record->{"is_customer"};
        $type = $record->{"type"};
    }




    my $strSQLentity = 'SELECT * FROM entities WHERE entities_id = ?';
    $sth = $dbh->prepare( $strSQLentity, );
    $sth->execute( $entity_id ) or $self->fail( $sth->errstr );
    while ( my $record = $sth->fetchrow_hashref())
    {
        $name = $record->{"first_name"} . ' ' . $record->{"last_name"};
        $title = $record->{"title"};
        $group = $record->{"grupo_id"};
        $company_id = $record->{"empresa_id"} || 0;
        #$company_branch_id = $record->{"company_branch_id"};
        #$storage_quota = $record->{storage_quota};
        $time_zone = $record->{time_zone};
    }


    $person_type = '';

    if ( $secret_status eq "" )
    {
        return $self->unauthorized( "invalid username");
    }

    my $strSQLtoken = 'SELECT * FROM api_access_token WHERE entity_id = ? AND active_status = 1 AND date_expiration > '.( time * 1000 ).'';
    $sth = $dbh->prepare( $strSQLtoken, );
    $sth->execute( $entity_id ) or $self->fail( $sth->errstr );
    while ( my $record = $sth->fetchrow_hashref())
    {
        $token_status = "ok";
        $auth_status = "connected";
        $token = $record->{"token"};
        $date_creation = $record->{"date_creation"};
        $date_expiration = $record->{"date_expiration"};
    }

    if ( $token_status eq "" )
    {
        $token = sha256_hex( $entity_id . "_" . ( time * 1000 ));
        $date_creation = time * 1000;
        $date_expiration = $date_creation + 86400000;
        $strSQLcreateToken = 'INSERT INTO api_access_token( entity_id, token, date_creation, date_expiration, active_status ) VALUES( ?, ?, ?, ?, 1);';
        $sth = $dbh->prepare( $strSQLcreateToken, );
        $sth->execute( $entity_id, $token, $date_creation, $date_expiration ) or $self->fail( $sth->errstr );
        $is_new_token = 1;
        $auth_status = "connected";
        $token_status = "ok";
    }

    if ( $auth_status ne 'connected') {
        return $self->unauthorized( );
    }
    else
    {
        my $auth_data = {
            name =>    $name,
            username => $username,
            token => $token,
            date_expiration => $date_expiration,
            auth_status => $auth_status,
            origin => $Origin,
            client_session_id => $entity_id . '_' . time,
            entity_id => $entity_id,
            api_user_id => $api_user_id,
            storage_quota => $storage_quota,
            group => $group,
            company_id => $company_id,
            is_admin => $is_admin,
            is_customer => $is_customer,
            type => $type,
            time_zone => $time_zone
        };

        $response = {
            status => 'success', response => 'authorized'
            , auth_data => $auth_data, is_new_token => $is_new_token
        };

        if ( $API->branch ne 'production') {
            $response->{strSQLsecret} = $strSQLsecret;
            $response->{strSQLtoken} = $strSQLtoken;
            $response->{strSQLcreateToken} = $strSQLcreateToken;
            $response->{strSQLcheckOrigin} = $strSQLcheckOrigin;
        }
    };

    $self->expose_default_headers;
    $self->render(
    json => $response,
    status => 200
    );

    # Do something after the transaction has been finished
    $self->on(finish => sub {
        my $c = shift;
        $API->trackAccessLog( $c );
    });
}

1;
