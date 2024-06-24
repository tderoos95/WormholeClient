class Utils extends Object;

// Strip illegal characters that break JSON parsing
static final function string StripIllegalCharacters(string Input)
{
    local string CurrentChar, SanitizedInput;
    local int CurrentCharCode;
    local bool bIllegalCharacter;
    local int i;

    for(i = 0; i < Len(Input); i++)
    {
        CurrentChar = Mid(Input, i, 1);
        CurrentCharCode = GetChrCode(CurrentChar);
        bIllegalCharacter = CurrentCharCode < 32;

        if(!bIllegalCharacter)
        {
            SanitizedInput = SanitizedInput $ CurrentChar;
        }
    }
    
    return SanitizedInput;
}

static final function int GetChrCode(string Char)
{
    local int i;

    for(i = 0; i < 256; i++)
    {
        if(Char == Chr(i))
        {
            return i;
        }
    }

    return -1;
}

final simulated static function string MakeColorCode(Color NewColor)
{
    return ((Chr(27) $ Chr(Max(1, NewColor.R))) $ Chr(Max(1, NewColor.G))) $ Chr(Max(1, NewColor.B));
}