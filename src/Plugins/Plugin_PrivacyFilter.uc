class Plugin_PrivacyFilter extends WormholePlugin
    config(Wormhole);

var config string DiscordPrefix;
var config bool EnableHudColor;

function OnInitialize()
{
    local Plugin_PrivacyFilterBroadcastHandler NewBroadcastHandler;
    local BroadcastHandler OldBroadcastHandler;

    if(EnableHudColor)
    {
        log("Plugin_PrivacyFilter: Spawning new BroadcastHandler with HUD color enabled");
        NewBroadcastHandler = Spawn(class'Plugin_PrivacyFilterBroadcastHandler');
        NewBroadcastHandler.DiscordPrefix = DiscordPrefix;
        OldBroadcastHandler = Level.Game.BroadcastHandler;
        Level.Game.BroadcastHandler = NewBroadcastHandler;
        OldBroadcastHandler.Destroy();
        log("Plugin_PrivacyFilter: BroadcastHandler replaced");
    }
}

function bool PreventReportChat(PlayerReplicationInfo PRI, out string Message, name Type)
{
    local string Prefix;
   
    if(EnableHudColor)
        Prefix = class'Plugin_PrivacyFilterBroadcastHandler'.static.GetChatMessagePrefix();
    else Prefix = DiscordPrefix;

    if(Left(Message, Len(Prefix)) ~= Prefix)
        return false;
    return true;
}

function string FormatChatMessage(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    local string Prefix;
    local string NewMessage;
    local int PrefixLength;

    if(EnableHudColor)
        Prefix = class'Plugin_PrivacyFilterBroadcastHandler'.static.GetChatMessagePrefix();
    else Prefix = DiscordPrefix;

    PrefixLength = Len(class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Prefix));

    if(Left(Message, Len(Prefix)) == Prefix)
    {
        NewMessage = class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Message);
        NewMessage = Mid(NewMessage, PrefixLength); // +1 for space

        // Trim leading spaces
        while(Left(NewMessage, 1) == " ")
            NewMessage = Mid(NewMessage, 1);

        return NewMessage;
    }

    return Message;
}

defaultproperties {
    DiscordPrefix="!d"
    EnableHudColor=False
}