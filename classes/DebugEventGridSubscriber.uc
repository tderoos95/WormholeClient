class DebugEventGridSubscriber extends EventGridSubscriber;

const Instantiated    = "wormhole/debug/instantiated";
const Connected       = "wormhole/debug/connected";
const Disconnected    = "wormhole/debug/disconnected";
const Failed          = "wormhole/debug/failed";
const Resolving       = "wormhole/debug/resolving";
const Resolved        = "wormhole/debug/resolved";
const ResolveFailed   = "wormhole/debug/resolvefailed";
const StateChanged    = "wormhole/debug/statechanged";
const ReceivedText    = "wormhole/debug/receivedtext";
const SendText        = "wormhole/debug/sendtext";
const TestFlood       = "wormhole/test/flood";

var PlayerController PC;
var WormholeConnection Connection;

function ProcessEvent(string Topic, JsonObject EventData)
{
    local bool bGarbageCollection;

    if(Topic == StateChanged)
    {
        PC.ClientMessage("Debug: state changed to " $ EventData.GetString("State"));
    }
    else if(Topic == ReceivedText)
    {
        log("Debug: received text: " $ EventData.ToString());
        PC.ClientMessage("Debug: received text " $ EventData.ToString());
    }
    else if(Topic == SendText)
    {
        log("Debug: send text: " $ EventData.GetString("Data"));
        PC.ClientMessage("Debug: send text " $ EventData.GetString("Data"));
    }
    else if(Topic == TestFlood)
    {
        bGarbageCollection = !EventData.GetBool("manualdisposal");
        Connection.SendEventData(Topic, EventData);
    }
    else
    {
        PC.ClientMessage("Debug: " $ Topic);
    }
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/"  // Wildcard for all wormhole topics
    SubscriptionTopics(1)="player/"  // Wildcard for all wormhole topics
}