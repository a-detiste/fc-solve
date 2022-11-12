package FreecellSolver::Site::News;

use strict;
use warnings;
use autodie;
use utf8;
use parent 'HTML::Widgets::NavMenu::Object';
use Path::Tiny qw/ path /;
use MyOldNews  ();
use DateTime   ();

__PACKAGE__->mk_accessors(
    qw(
        dir
        items
        num_on_front
    )
);

my @old_news_items = (
    map {
        +{
            body => $_->{'html'},
            date => DateTime->new(
                year  => $_->{year},
                month => $_->{mon},
                day   => $_->{day_of_month}
            ),
        }
    } @{ MyOldNews::get_old_news() }
);

sub file_to_news_item
{
    my $self     = shift;
    my $filename = shift;
    my $text     = path( $self->dir() . "/" . $filename )->slurp_utf8;
    my $title;
    if ( $text =~ s{\A<!-- TITLE=(.*?)-->\n}{} )
    {
        $title = $1;
    }
    $text     =~ s!<p>!<p class="newsitem">!g;
    $text     =~ s!<ol>!<ol class="newsitem">!g;
    $text     =~ s!<ul>!<ul class="newsitem">!g;
    $text     =~ s#<div class="blogger-post-footer"><img.*?</div>##ms;
    $text     =~ s#<(/?)tt#<${1}code#g;
    $filename =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\.html\z/;
    my ( $y, $m, $d ) = ( $1, $2, $3 );
    return +{
        'date'  => DateTime->new( year => $y, month => $m, day => $d ),
        'body'  => $text,
        'title' => $title,
    };
}

sub calc_rss_items
{
    my $self = shift;

    opendir my $dir, $self->dir();
    my @files = readdir($dir);
    closedir($dir);
    @files = ( grep { /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\.html\z/ms } @files );
    @files = sort { $a cmp $b } @files;
    return [ map { $self->file_to_news_item($_) } @files ];
}

sub calc_items
{
    my $self = shift;
    return [ @old_news_items, @{ $self->calc_rss_items() } ];
}

sub _init
{
    my $self = shift;

    $self->dir( path(__FILE__)->parent(3) . "/feeds/fc-solve.blogspot/" );
    $self->num_on_front(7);

    $self->items( $self->calc_items() );

    return 0;
}

sub get_item_html
{
    my $self = shift;
    my $item = shift;

    my $title = $item->{title};
    my $date  = $item->{date};

    return
          "<article><header><h3 class=\"newsitem\" id=\""
        . $date->strftime("news-%Y-%m-%d") . "\">"
        . $date->strftime("%d-%b-%Y")
        . ( defined($title) ? ": $title" : "" )
        . "</h3></header>\n\n"
        . $item->{'body'}
        . "</article>\n";
}

sub render_items
{
    my $self  = shift;
    my $items = shift;
    return join( "\n\n", ( map { $self->get_item_html($_) } @$items ) );
}

sub render_front_page
{
    my $self  = shift;
    my @items = reverse( @{ $self->items() } );
    return $self->render_items(
        [ @items[ 0 .. ( $self->num_on_front() - 1 ) ] ] );
}

sub render_old
{
    my $self  = shift;
    my @items = @{ $self->items() };
    return $self->render_items(
        [ reverse( @items[ 0 .. ( @items - $self->num_on_front() ) ] ) ] );
}

1;
