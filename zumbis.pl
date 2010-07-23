#!/usr/bin/perl
use 5.10.0;
use strict;
use warnings;
use SDL;
use SDL::Rect;
use SDL::Event;
use SDL::Events;
use SDLx::Sprite;
use SDLx::Sprite::Animated;
use SDLx::Surface;
use SDLx::Controller;
use Zumbis::Mapa;
use Zumbis::Tiro;
use Zumbis::Zumbi;

my $mapa = Zumbis::Mapa->new( arquivo => 'mapas/mapa-de-teste-1.xml' );

my $heroi = SDLx::Sprite::Animated->new(
    image => 'dados/heroi.png',
    rect  => SDL::Rect->new(5,14,32,45),
    ticks_per_frame => 2,
);

my @zumbis;
my @tiros;

$heroi->set_sequences(
    parado_esquerda => [ [1, 3] ],
    parado_direita  => [ [1, 1] ],
    parado_cima     => [ [1, 0] ],
    parado_baixo    => [ [1, 2] ],
    esquerda        => [ [0,3], [1,3], [2,3] ],
    direita         => [ [0,1], [1,1], [2,1] ],
    cima            => [ [0,0], [1,0], [2,0] ],
    baixo           => [ [0,2], [1,2], [2,2] ],
);

my ( $heroi_x, $heroi_y ) = $mapa->playerstart_px;
#$heroi->x( $heroi_x );
#$heroi->y( $heroi_y );
my $heroi_vel = 0.15;
$heroi->sequence('parado_baixo');
$heroi->start;

my $tela = SDLx::Surface::display( 
    width => $mapa->width_px,
    height => $mapa->height_px
);

sub eventos {
    my $e = shift;
    return 0 if $e->type == SDL_QUIT;
    return 0 if $e->key_sym == SDLK_ESCAPE;

    if ( $e->type == SDL_KEYDOWN ) {
        $heroi->sequence('esquerda')  if $e->key_sym == SDLK_LEFT;
        $heroi->sequence('direita') if $e->key_sym == SDLK_RIGHT;
        $heroi->sequence('baixo')  if $e->key_sym == SDLK_DOWN;
        $heroi->sequence('cima')    if $e->key_sym == SDLK_UP;

        if ($e->key_sym == SDLK_SPACE && scalar @tiros < 2) {
            my $type;
            given ($heroi->sequence) {
                when (/esquerda/) { $type = 'rtl' };
                when (/direita/)  { $type = 'ltr' };
                when (/baixo/)    { $type = 'tpd' };
                when (/cima/)     { $type = 'btu' };
            };
            push @tiros, Zumbis::Tiro->new(x => int($heroi_x), y => int($heroi_y),
                                           type => $type);
        }
    }
    elsif ( $e->type == SDL_KEYUP ) {
        $heroi->sequence('parado_esquerda')  if $e->key_sym == SDLK_LEFT;
        $heroi->sequence('parado_direita') if $e->key_sym == SDLK_RIGHT;
        $heroi->sequence('parado_baixo')  if $e->key_sym == SDLK_DOWN;
        $heroi->sequence('parado_cima')    if $e->key_sym == SDLK_UP;
    }
    return 1;
}

my $last_zumbi_dt = 0;
sub cria_zumbis {
    my $dt = shift;
    $last_zumbi_dt += $dt;
    if ($last_zumbi_dt > 500) {
        my ($x, $y) = $mapa->next_spawnpoint_px;
        push @zumbis, Zumbis::Zumbi->new(x => $x, y => $y);
        $last_zumbi_dt = 0;
    }
}

sub move_heroi {
    my $dt = shift;
    my $tilesize = $mapa->dados->{tilesize};

    # verifica se o heroi foi tocado por um zumbi
    # (condicao de derrota)
    for my $z (@zumbis) {
        next if abs($heroi_x - $z->x) > 25;
        next if abs($heroi_y - $z->y) > 25;
        print "MORREU!\n";
        exit;
    }

    $_->tick($dt, $mapa) for @tiros;
    @tiros = grep { !$_->collided } @tiros;

    my $sequencia = $heroi->sequence;
    my ($change_x, $change_y) = (0,0);
    $change_x = 0 - $heroi_vel * $dt if $sequencia eq 'esquerda';
    $change_x = $heroi_vel * $dt if $sequencia eq 'direita';
    $change_y = 0 - $heroi_vel * $dt if $sequencia eq 'cima';
    $change_y = $heroi_vel * $dt if $sequencia eq 'baixo';

    my $tilex = int(($heroi_x + $change_x + 15) / $tilesize);
    my $tiley = int(($heroi_y + $change_y + 35) / $tilesize);

    unless ($mapa->colisao->[$tilex][$tiley]) {
        $heroi_x += $change_x;
        $heroi_y += $change_y;
    }


}

sub move_zumbis { $_->move for @zumbis }


sub exibicao {
    $mapa->render( $tela->surface );
    $_->render($tela->surface) for @tiros;
    $_->render($tela->surface) for @zumbis;
    $heroi->draw_xy( $tela->surface, $heroi_x, $heroi_y );
    $tela->update;
}

my $jogo = SDLx::Controller->new;
$jogo->add_event_handler( \&eventos );
$jogo->add_show_handler( \&exibicao );
$jogo->add_move_handler( \&move_heroi );
$jogo->add_move_handler( \&cria_zumbis );
$jogo->add_move_handler( \&move_zumbis );
$jogo->run;

