// Thanks to voltz for this code :D
class WormholeServerActor extends Info;

function PreBeginPlay()
{
    Level.Game.AddMutator(string(class'MutWormhole'), true);
    Destroy();
}

defaultproperties
{
}