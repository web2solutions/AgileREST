package YourApplicationName::Controller::DHTMLX;
use Mojo::Base 'Mojolicious::Controller';
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
    my $req = $self->tx->req;
    my $logger = $self->logger;
    my $root_dir = $self->app->config->{root_path_files};
    #$self->app->home->rel_file('/public/storage');

    unless (-d $root_dir) {
        mkpath $root_dir or die "Cannot create dirctory: $root_dir";
    }

    my $response = '';
    if ($self->req->is_limit_exceeded)
    {
        $response = {
            state => ,
            name => ''
            ,extra => {
                  info => 'file is too big'
                  #param => ''
            }
        };
    }
    else
    {
        if ( $self->param('mode') eq "html5" || $self->param('mode') eq "flash" ) {
            my $fileuploaded = $self->req->upload('file');
            my $filename = create_filename() . '_' . $fileuploaded->filename;
            my $size = $fileuploaded->size;
            $fileuploaded->move_to($root_dir . '/' . $filename);
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
                my $fileuploaded = $self->req->upload('file');
                my $filename = create_filename() . '_' . $fileuploaded->filename;
                my $size = $fileuploaded->size;
                $fileuploaded->move_to($root_dir . '/' . $filename);
                $response = {
                    state => 1,
                    name => $filename,
                    size => $size
                };
            }
        }
    }
    $self->render(
    json => $response
    ,status => 200
    );
}
sub vault_upload {
    my $self = shift;
    my $req = $self->tx->req;
    my $logger = $self->logger;
    my $root_dir = $self->app->config->{root_path_files};
    #$self->app->home->rel_file('/public/storage');

    unless (-d $root_dir) {
        mkpath $root_dir or die "Cannot create dirctory: $root_dir";
    }

    my $response = '';
    if ($self->req->is_limit_exceeded)
    {
        $response = {
            state => ,
            name => ''
            ,extra => {
                  info => 'file is too big'
                  #param => ''
            }
        };
    }
    else
    {
        if ( $self->param('mode') eq "html5" || $self->param('mode') eq "flash" ) {
            my $fileuploaded = $self->req->upload('file');
            my $filename = create_filename() . '_' . $fileuploaded->filename;
            my $size = $fileuploaded->size;
            $fileuploaded->move_to($root_dir . '/' . $filename);
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
                my $filename = create_filename() . '_' . $fileuploaded->filename;
                my $size = $fileuploaded->size;
                $fileuploaded->move_to($root_dir . '/' . $filename);
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

    $self->render(
    json => $response
    ,status => 200
    );

}
1;
