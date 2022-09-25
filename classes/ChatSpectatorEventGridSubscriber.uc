class ChatSpectatorEventGridSubscriber extends EventGridSubscriber;

const DiscordChat = "discord/chatmessage";

var ChatSpectator ChatSpectator;

function PreBeginPlay()
{
    ChatSpectator = ChatSpectator(Owner);
}

function ProcessEvent(string Topic, JsonObject EventData)
{
    if (Topic == DiscordChat)
    {
        OnDiscordChat(EventData);
    }
}

// Forward chat from discord to UT2004
function OnDiscordChat(JsonObject EventData)
{
    local string Author;
    local string Message;

    Author = EventData.GetString("username");
    Message = EventData.GetString("message");
    ChatSpectator.ServerSay(Author $ ":" @ Message);
}

defaultproperties
{
    SubscriptionTopics(0)="discord/chatmessage";
}