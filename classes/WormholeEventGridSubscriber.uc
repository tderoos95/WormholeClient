class WormholeEventGridSubscriber extends EventGridSubscriber;

var WormholeConnection WormholeConnection;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    WormholeConnection = WormholeConnection(Owner);
}