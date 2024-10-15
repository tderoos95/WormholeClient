class MutWormholeEventGridSubscriber extends EventGridSubscriber;

const ConnectionEstablished = "wormhole/connection/established";
const CommandPrefix = "wormhole/command/";
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
    if (Left(Topic, Len(CommandPrefix)) == CommandPrefix)
    {
        WormholeMutator.GameHandler.HandleCommand(Topic);
    }
}

defaultproperties 
{
    SubscriptionTopics(0) = "wormhole/connection/established";
    SubscriptionTopics(1) = "wormhole/command/";
}