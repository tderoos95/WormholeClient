class Utils extends Object;

// Method below made by Wormbo (C) 2005
static final function string StripColorCodes(string Input)
{
    local int i;
    local string Text;

    i = InStr(Input, Chr(27));

    while(i != -1)
    {  
        Text = Text $ Left(Input, i);
        Input = Mid(Input, i + 4);  
        i = InStr(Input, Chr(27));
    }

    return Text $ Input;
}