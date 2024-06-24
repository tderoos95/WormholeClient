class Utils extends Object;

// Strip illegal characters that break JSON parsing
static final function string StripIllegalCharacters(string Input)
{
    local string CurrentChar, SanitizedInput;
    local int CurrentCharCode;
    local bool bIllegalCharacter;
    local string Text;
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

    i = InStr(SanitizedInput, Chr(27));
    while(i != -1)
    {
        Text = Text $ Left(SanitizedInput, i);
        SanitizedInput = Mid(SanitizedInput, i + 4);  
        i = InStr(SanitizedInput, Chr(27));
    }

    return Text $ SanitizedInput;
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