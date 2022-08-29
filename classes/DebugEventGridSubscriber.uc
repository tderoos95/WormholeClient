class DebugEventGridSubscriber extends EventGridSubscriber;

const Instantiated = "wormhole/debug/instantiated";
const Connected = "wormhole/debug/connected";
const Disconnected = "wormhole/debug/disconnected";
const Failed = "wormhole/debug/failed";
const Resolving = "wormhole/debug/resolving";
const Resolved = "wormhole/debug/resolved";

var PlayerController PC;

function ProcessEvent(string Topic, JsonObject EventData)
{
    if(PC != None)
        PC.ClientMessage("Debug: " $ Topic);
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/debug/instantiated" // Instantiated
    SubscriptionTopics(1)="wormhole/debug/connected"    // Connected
    SubscriptionTopics(2)="wormhole/debug/disconnected" // Disconnected
    SubscriptionTopics(3)="wormhole/debug/failed"       // Failed
    SubscriptionTopics(4)="wormhole/debug/resolving"    // Resolving
    SubscriptionTopics(5)="wormhole/debug/resolved"     // Resolved
}