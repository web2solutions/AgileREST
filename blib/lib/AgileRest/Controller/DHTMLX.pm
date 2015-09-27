package AgileRest::Controller::DHTMLX;
use Mojo::Base 'Mojolicious::Controller';
use JSON qw(decode_json encode_json from_json to_json);
use File::Basename 'basename';
use File::Path 'mkpath';
use Mojo::Upload;
use Data::Dump qw(dump);
sub create_filename {
    # Date and time
    my ($sec, $min, $hour, $mday, $month, $year) = localtime;
    $month = $month + 1;
    $year = $year + 1900;
    # Random number(0 ~ 99999)
    my $rand_num = int(rand 100000);
    # Create file name form datatime and random number
    # (like image-20091014051023-78973)
    my $name = sprintf(
    "%04s%02s%02s%02s%02s%02s-%05s",
    $year,
    $month,
    $mday,
    $hour,
    $min,
    $sec,
    $rand_num
    );
    return $name;
}
sub form_upload {
    my $self = shift;
    my $API = $self->API;
    my $req = $self->tx->req;
    my $access_granted_message = $API->check_authorization_simple( $self, $self->param('token'), $req->headers->header("Origin") );
    if ( $access_granted_message ne 'granted' )
    {
        return $self->unauthorized( $access_granted_message );
    }
    #my $app = $self->app;
    my $logger = $self->logger;
    $API->branch( $req->headers->header('X-branch') || 'test' );
    my $root_dir = $self->app->config->{root_path_files};
    #$self->app->home->rel_file('/public/storage');
    # $self->app->config->{root_path_files}
    #my $company_id = $self->param('company_id') || return $self->render(
    #json => {
    #    state => ,
    #    name => $self->param('file'),
    #    extra => {
    #        info => 'company_id is a mandatory parameter'
    #        #param => ''
    #    }
    #}
    #,status => 200
    #);
    my $user_id = $self->param('user_id') || return $self->render(
    json => {
        state => ,
        name => $self->param('file'),
        extra => {
            info => 'user_id is a mandatory parameter'
            #param => ''
        }
    }
    ,status => 200
    );
    my $resource_name = $self->param('resource_name') || return $self->render(
    json => {
        state => ,
        name => $self->param('file'),
        extra => {
            info => 'resource_name is a mandatory parameter'
            #param => ''
        }
    }
    ,status => 200
    );
    my $resource_id = $self->param('resource_id') || return $self->render(
    json => {
        state => ,
        name => $self->param('file'),
        extra => {
            info => 'resource_id is a mandatory parameter'
            #param => ''
        }
    }
    ,status => 200
    );
    my $path = $root_dir . '/' . $resource_name. '/' . $resource_id;
    #my $filename = $agency_id  . '_' . $user_id . '_' . time . '_' . $self->param('file');
    unless (-d $root_dir) {
        mkpath $root_dir or die "Cannot create dirctory: $root_dir";
    }
    unless (-d $path) {
        mkpath $path or die "Cannot create dirctory: $path";
    }
    my $response = '';
    if ($self->req->is_limit_exceeded)
    {
        $response = {
            state => ,
            name => 'file is too big'
            #extra => {
                #  info => 'file is too big'
                #  #param => ''
            #}
        };
    }
    else
    {
        if ( $self->param('mode') eq "html5" || $self->param('mode') eq "flash" ) {
            #my $filetype = $self->req->param('filetype');
            my $fileuploaded = $self->req->upload('file');
            my $filename = create_filename() . '_' . $API->clean_file_name($fileuploaded->filename);
            my $size = $fileuploaded->size;
            $fileuploaded->move_to($path . '/' . $filename);
            #my $uploaded_file = request->upload('file');
            #$uploaded_file->copy_to($path . $filename);
            #debug "My Log 2: " . ref($uploaded_file);
            $response = {
                state => 1,
                name => $filename
            };
        }
        if ( $self->param('mode') eq "html4" ) {
            if ( $self->param('actions') eq "cancel" ) {
                $response = {
                    state => 'cancelled'
                };
            }
            else
            {
                #my $uploaded_file = request->upload('file');
                #$uploaded_file->copy_to($path . $filename);
                my $fileuploaded = $self->req->upload('file');
                my $filename = create_filename() . '_' . $API->clean_file_name($fileuploaded->filename);
                my $size = $fileuploaded->size;
                $fileuploaded->move_to($path . '/' . $filename);
                $response = {
                    state => 1,
                    name => $filename,
                    size => $size
                };
            }
        }
    }
    $self->expose_default_headers;
    $self->render(
    json => $response
    ,status => 200
    );
    # Do something after the transaction has been finished
    $self->on(finish => sub {
        my $c = shift;
        $API->trackAccessLog( $c );
    });
}
sub vault_upload {
    my $self = shift;
    my $API = $self->API;
    my $req = $self->tx->req;
    my $access_granted_message = $API->check_authorization_simple( $self, $self->param('token'), $req->headers->header("Origin") );
    if ( $access_granted_message ne 'granted' )
    {
        return $self->unauthorized( $access_granted_message );
    }
    #my $app = $self->app;
    my $logger = $self->logger;
    #$logger->debug( 'inside upload.');
    $API->branch( $req->headers->header('X-branch') || 'test' );
    my $root_dir = $self->app->config->{root_path_files};
    #$self->app->home->rel_file('/public/storage');
    # $self->app->config->{root_path_files}
    my $mode = $self->param('mode');
    #my $company_id = $self->param('company_id') || return $self->render(
    #json => {
    #    state => ,
    #    name => $self->param('file'),
    #    extra => {
    #        info => 'company_id is a mandatory parameter'
    #        #param => ''
    #    }
    #}
    #,status => 200
    #);
    my $user_id = $self->param('user_id') || return $self->render(
    json => {
        state => ,
        name => $self->param('file'),
        extra => {
            info => 'user_id is a mandatory parameter'
            #param => ''
        }
    }
    ,status => 200
    );
    my $resource_name = $self->param('resource_name') || return $self->render(
    json => {
        state => ,
        name => $self->param('file'),
        extra => {
            info => 'resource_name is a mandatory parameter'
            #param => ''
        }
    }
    ,status => 200
    );
    my $resource_id = $self->param('resource_id') || return $self->render(
    json => {
        state => ,
        name => '',
        extra => {
            info => 'resource_id is a mandatory parameter'
            #param => ''
        }
    }
    ,status => 200
    );
    my $path = $root_dir . '/' . $resource_name. '/' . $resource_id;
    #my $filename = $agency_id  . '_' . $user_id . '_' . time . '_' . $self->param('file');
    unless (-d $root_dir) {
        mkpath $root_dir or die "Cannot create dirctory: $root_dir";
    }
    unless (-d $path) {
        mkpath $path or die "Cannot create dirctory: $path";
    }
    my $response = '';
    #$logger->debug( dump ($self->req) );
    #$logger->debug( $self->req->max_message_size );
    if ($self->req->is_limit_exceeded)
    {
        $response = {
            state => ,
            name => 'file is too big'
            #extra => {
                #  info => 'file is too big'
                #  #param => ''
            #}
        };
    }
    else
    {
        if ( $self->param('mode') eq "html5" || $self->param('mode') eq "flash" ) {
            my $fileuploaded = $self->req->upload('file');

            my $filename = create_filename() . '_' . $API->clean_file_name($fileuploaded->filename);
            my $size = $fileuploaded->size;
            $fileuploaded->move_to($path . '/' . $filename);
            $response = {
                state => 1,
                name => $filename
            };
        }
        elsif ( $self->param('mode') eq "html4" ) {
            if ( $self->param('actions') eq "cancel" )
            {
                $response = {
                    state => 'cancelled'
                };
            }
            else
            {
                my $fileuploaded = $self->req->upload('file');
                my $filename = create_filename() . '_' . $API->clean_file_name($fileuploaded->filename);
                my $size = $fileuploaded->size;
                $fileuploaded->move_to($path . '/' . $filename);
                $response = {
                    state => 1,
                    name => $filename,
                    size => $size
                };
            }
        }
        elsif ( $self->param('mode') eq "conf" ) {
            $response = { maxFileSize => $self->req->max_message_size };
        }
    }
    $self->expose_default_headers;
    $self->render(
    json => $response
    ,status => 200
    );
    # Do something after the transaction has been finished
    $self->on(finish => sub {
        my $c = shift;
        $API->trackAccessLog( $c );
    });
}
1;
