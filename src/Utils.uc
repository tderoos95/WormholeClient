class Utils extends Object;

final simulated static function string MakeColorCode(Color NewColor)
{
    return ((Chr(27) $ Chr(Max(1, NewColor.R))) $ Chr(Max(1, NewColor.G))) $ Chr(Max(1, NewColor.B));
}