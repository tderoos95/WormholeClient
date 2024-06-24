class Utils extends Object;

// Strip illegal characters that break JSON parsing
static final function string StripIllegalCharacters(string Input)
{
    local int i;
    local string Text;
    local bool bIllegalCharacter;
    local int CurrentCharCode;
    local string CurrentChar, SanitizedInput;

    Log("* Before stripping illegal characters");
    OutputChrCodes(Input);

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

    Log("* After stripping illegal characters");
    OutputChrCodes(SanitizedInput);

    i = InStr(SanitizedInput, Chr(27));
    while(i != -1)
    {
        Text = Text $ Left(SanitizedInput, i);
        SanitizedInput = Mid(SanitizedInput, i + 4);  
        i = InStr(SanitizedInput, Chr(27));
    }

    return Text $ SanitizedInput;
}

static final function OutputChrCodes(string Text)
{
    local string CurrentChar;
    local int i;

    Log("--------------------");
    Log("* Dissecting string: " $ Text);

    for(i = 0; i < Len(Text); i++)
    {
        CurrentChar = Mid(Text, i, 1);
        Log("*" @ CurrentChar $ ": " $ "Chr(" $ GetChrCode(CurrentChar) $ ")");
    }


    Log("--------------------");
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