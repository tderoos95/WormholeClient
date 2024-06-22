class Utils extends Object;

// Method below made by Wormbo (C) 2005
static final function string StripIllegalCharacters(string Input)
{
     local int i;
    local string Text;
    local string Result;
    local string Part;

    // Remove color codes
    i = InStr(Input, Chr(27));

    while (i != -1)
    {  
        Text = Text $ Left(Input, i);
        Input = Mid(Input, i + 4);  
        i = InStr(Input, Chr(27));
    }

    Text = Text $ Input;

    // Remove 'ç' and 'Ç' from the Text
    for (i = 1; i <= Len(Text); i++)
    {
        Part = Mid(Text, i, 1);
        if (Part != "ç" && Part != "Ç")
        {
            Result = Result $ Part;
        }
    }

    return Result;
}

final simulated static function string MakeColorCode(Color NewColor)
{
    return ((Chr(27) $ Chr(Max(1, NewColor.R))) $ Chr(Max(1, NewColor.G))) $ Chr(Max(1, NewColor.B));
}