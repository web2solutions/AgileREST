# AgileREST [![Build Status](https://travis-ci.org/web2solutions/AgileREST.svg?branch=master)](https://travis-ci.org/web2solutions/AgileREST)

REST interface for T-Rex web toolkit (https://github.com/web2solution/T-Rex-Specs)



## Summary

 AgileREST is the REST interface used on T-Rex web stack to provide server support for applications done using $dhx framework (https://github.com/web2solution/dhx)

 It provides standardized database access and file upload through REST end points.

 It does not server static files, which is done through a CDN.

 All end points require HTTP authentication.

 All end points has built in documentation.

 

## Dependencies

  - Perl Modules: 

    cpanm Mojolicious Mojolicious::Lite Moose Moo Mojo::JSON Mojo::JSON_XS Data::Dump Crypt::Digest::SHA256 Mojo::Log Mojo::Redis Mojo::Redis2 Mojolicious::Plugin::TtRenderer::Engine File::Basename File::Spec::Functions MIME::Base64 JSON Tie::IxHash Encode DateTime Protocol::Redis::XS DBI
    JSON::XS DBIx::Connector Mojolicious::Plugin::JSON::XS Mojolicious::Plugin::PDFRenderer

  - Perlbrew:

    curl -L http://install.perlbrew.pl | bash

    http://perlbrew.pl/

  - PostgreSQL 9.4

  - Redis 2.8.10


## Perl version

  	5.20.1


## Tested OS

  	- Mac OSX
  	- Centos 5.9
  	- Centos 6



### AUTHORS, LICENSE AND COPYRIGHT

 - José Eduardo Perotta de Almeida. eduardo at web2solutions.com.br

  Copyright 2015 

- AGPL for personal use.
- Commercial && Enterpsise 
 If you need a commercial or an enterprise license, you will need also to be licensed by DHTMLX. Please contact the author for commercial usage


### BUGS

Actually this software is under development. There is no stable version yet.

Please report any bugs or feature requests through the email address: eduardo at web2solutions.com.br


### DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


