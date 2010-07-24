package Zumbis::TelaGameOver;
use Mouse;
use SDL::Rect;
use SDL::Image;
use SDL::Video;
use SDLx::Surface;
use SDL::TTF;
use utf8;

has tempo => (is => 'ro', required => 1);
has ultimo_frame => (is => 'ro', required => 1);
has texto => (is => 'ro', required => 1);
my $image = SDLx::Surface->new(surface => SDL::Image::load('dados/gameover.png'));

SDL::TTF::init;
my $font = SDL::TTF::open_font('dados/AtariSmall.ttf', 30) or
  die 'Erro carregando a fonte';
my $font_p = SDL::TTF::open_font('dados/AtariSmall.ttf', 16) or
  die 'Erro carregando a fonte';
my $color = SDL::Color->new(0,0,0);

my $selectchar =
  SDL::TTF::render_text_blended
  ($font_p, "Aperte 1 para Heroi, 2 para Heroina ou enter para continuar!", $color)
  or die 'TTF render error: ' . SDL::get_error;
my $selectchar_w = $selectchar->w;
my $selectchar_h = $selectchar->h;
my $selectchar_srcrect = SDL::Rect->new(0,0,$selectchar_w,$selectchar_h);

sub BUILDARGS {
    my ($self, %args) = @_;

    my $surface = delete $args{surface}
      or die 'faltou o argumento "surface" com a tela do jogo';

    my $ultimo_frame = SDLx::Surface->new(width => $surface->w,
                                          height => $surface->h);
    my $rect1 =  SDL::Rect->new(0,0,$surface->w,$surface->h);
    my $rect2 =  SDL::Rect->new(0,0,$surface->w,$surface->h);
    $surface->blit($ultimo_frame, $rect1, $rect2);

    my $texto = SDL::TTF::render_text_blended($font, "Voce sobreviveu por ".$args{tempo}." segundos!", $color)
      or die 'TTF render error: ' . SDL::get_error;

    $args{ultimo_frame} = $ultimo_frame;
    $args{texto} = $texto;
    return \%args;
}

sub render {
    my ($self, $surface) = @_;

    my $rect1 = SDL::Rect->new(0,0,$surface->w,$surface->h);
    my $rect2 = SDL::Rect->new(0,0,$surface->w,$surface->h);
    $self->ultimo_frame->blit($surface, $rect1, $rect2);
    my $srcrect = SDL::Rect->new(0,0,759,408);
    my $dstrect = SDL::Rect->new($surface->w/2-759/2,$surface->h/2-408/2,759,408);
    $image->blit($surface, $srcrect, $dstrect);

    my $texto = $self->texto;
    my $texto_w = $texto->w;
    my $texto_h = $texto->h;
    $srcrect = SDL::Rect->new(0,0,$texto_w,$texto_h);
    $dstrect = SDL::Rect->new($surface->w/2-$texto_w/2,$surface->h/2-$texto_h/2,$texto_w,$texto_h);
    SDL::Video::blit_surface($texto, $srcrect, $surface->surface, $dstrect);

    $dstrect = SDL::Rect->new(30,$surface->h - $selectchar_h - 30,$selectchar_w,$selectchar_h);
    SDL::Video::blit_surface($selectchar, $selectchar_srcrect, $surface->surface, $dstrect);

}

__PACKAGE__->meta->make_immutable();


1;
