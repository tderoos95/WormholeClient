class WormholeEventBusSubscriber extends EventBusSubscriber;

var WormholeConnection WormholeConnection;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    WormholeConnection = WormholeConnection(Owner);
}