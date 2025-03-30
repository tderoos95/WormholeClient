class Plugin_PrivacyFilter extends WormholePlugin
    config(Wormhole);

var config string DiscordPrefix;

function OnInitialize()
{
    local Plugin_PrivacyFilterBroadcastHandler NewBroadcastHandler;
    local BroadcastHandler OldBroadcastHandler;

    log("Plugin_PrivacyFilter: Spawning new BroadcastHandler");
    OldBroadcastHandler = Level.Game.BroadcastHandler;

    // Spawn the new BroadcastHandler
    NewBroadcastHandler = Spawn(class'Plugin_PrivacyFilterBroadcastHandler');
    NewBroadcastHandler.DiscordPrefix = DiscordPrefix;

    // Prioritize the new BroadcastHandler, and put the old one after it
    NewBroadcastHandler.NextBroadcastHandler = OldBroadcastHandler;
    Level.Game.BroadcastHandler = NewBroadcastHandler;
    log("Plugin_PrivacyFilter: Added new BroadcastHandler");
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

    PrefixLength = Len(class'Utils'.static.StripIllegalCharacters(Prefix));

    if(Left(Message, Len(Prefix)) == Prefix)
    {
        NewMessage = class'Utils'.static.StripIllegalCharacters(Message);
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