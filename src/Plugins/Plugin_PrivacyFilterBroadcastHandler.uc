class Plugin_PrivacyFilterBroadcastHandler extends BroadcastHandler;

var string DiscordPrefix;
var color DiscordChatColor;

function Broadcast(Actor Sender, coerce string Msg, optional name Type)
{
    local string ChannelMsg;

    if(Left(Msg, Len(DiscordPrefix)) ~= DiscordPrefix)
    {
        ChannelMsg = GetChatMessagePrefix();
        ChannelMsg @= Mid(Msg, Len(DiscordPrefix));
    }
    else ChannelMsg = Msg;

    Super.Broadcast(Sender, ChannelMsg, Type);
}

static final function string GetChatMessagePrefix()
{
    return class'Utils'.static.MakeColorCode(default.DiscordChatColor) $ "Discord:";
}

defaultproperties {
    DiscordChatColor=(B=255,G=153,R=0,A=255)
} 