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

var PlayerController DebuggerPC;
var WormholeConnection Connection;

function ProcessEvent(string Topic, JsonObject EventData)
{
    if(Topic == StateChanged)
    {
        PrintDebug("Debug: state changed to " $ EventData.GetString("State"));
    }
    else if(Topic == ReceivedText)
    {
        log("Debug: received text: " $ EventData.ToString());
        PrintDebug("Debug: received text " $ EventData.ToString());
    }
    else if(Topic == SendText)
    {
        log("Debug: send text: " $ EventData.GetString("Data"));
        PrintDebug("Debug: send text " $ EventData.GetString("Data"));
    }
    else if(Topic == TestFlood)
    {
        Connection.SendEventData(Topic, EventData);
    }
    else
    {
        PrintDebug("Debug: " $ Topic);
    }
}

function PrintDebug(string Message)
{
    local PlayerController PC;
    local Controller C;

    for(C = Level.ControllerList; PlayerController(C) != None; C = C.NextController)
    {
        PC = PlayerController(C);

        if(PC.PlayerReplicationInfo.bAdmin || PC == DebuggerPC)
            PC.ClientMessage(Message);
    }
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/"  // Wildcard for all wormhole topics
    SubscriptionTopics(1)="player/"  // Wildcard for all wormhole topics
}