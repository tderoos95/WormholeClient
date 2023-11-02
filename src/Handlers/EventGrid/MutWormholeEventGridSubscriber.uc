class MutWormholeEventGridSubscriber extends EventGridSubscriber;

const ConnectionEstablished = "wormhole/connection/established";
var MutWormhole WormholeMutator; 

function PreBeginPlay()
{
    Super.PreBeginPlay();
    WormholeMutator = MutWormhole(Owner);
}

public function ProcessEvent(string Topic, JsonObject EventData)
{
    if (Topic == ConnectionEstablished)
    {
        WormholeMutator.StartMonitoringGame();
    }
}

defaultproperties 
{
    SubscriptionTopics(0) = "wormhole/connection/established";
}