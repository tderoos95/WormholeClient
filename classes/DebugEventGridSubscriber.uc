class DebugEventGridSubscriber extends EventGridSubscriber;

const Instantiated  = "wormhole/debug/instantiated";
const Connected     = "wormhole/debug/connected";
const Disconnected  = "wormhole/debug/disconnected";
const Failed        = "wormhole/debug/failed";
const Resolving     = "wormhole/debug/resolving";
const Resolved      = "wormhole/debug/resolved";
const StateChanged  = "wormhole/debug/statechanged";
const ReceivedText  = "wormhole/debug/receivedtext";
const SendText      = "wormhole/debug/sendtext";

var PlayerController PC;

function ProcessEvent(string Topic, JsonObject EventData)
{
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
    else
    {
        PC.ClientMessage("Debug: " $ Topic);
    }
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/debug/instantiated" // Instantiated
    SubscriptionTopics(1)="wormhole/debug/connected"    // Connected
    SubscriptionTopics(2)="wormhole/debug/disconnected" // Disconnected
    SubscriptionTopics(3)="wormhole/debug/failed"       // Failed
    SubscriptionTopics(4)="wormhole/debug/resolving"    // Resolving
    SubscriptionTopics(5)="wormhole/debug/resolved"     // Resolved
    SubscriptionTopics(6)="wormhole/debug/statechanged" // StateChanged
    SubscriptionTopics(7)="wormhole/debug/receivedtext" // ReceivedText
    SubscriptionTopics(8)="wormhole/debug/sendtext"     // SendText
}