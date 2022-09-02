class MutWormhole extends Mutator
    dependson(WormholeConnection)
    config(Wormhole);

var WormholeSettings Settings;
var WormholeConnection Connection;
var ChatSpectator ChatSpectator;
var TimerController TimerController;

// debug
var DebugEventGridSubscriber DebugSubscriber;
var EventGrid EventGrid;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    Settings = new class'WormholeSettings';
    Settings.SaveConfig();
	SaveConfig();

    Connection = Spawn(class'WormholeConnection', self);
    TimerController = Spawn(class'TimerController', self);
}

function Mutate(string Command, PlayerController PC)
{
    local string GivenIp;

    if(NextMutator != None)
        NextMutator.Mutate(Command, PC);
    
    if(Command ~= "ToggleDebug")
    {
        PC.ClientMessage("Instantiating wormhole debug subscriber...");
        DebugSubscriber = Spawn(class'DebugEventGridSubscriber');
        DebugSubscriber.PC = PC;
        EventGrid = DebugSubscriber.GetOrCreateEventGrid();
        EventGrid.SendEvent("wormhole/debug/instantiated", None);
    }
    else if(Command ~= "Connect")
    {
        PC.ClientMessage("Connecting to " $ Settings.HostName $ ":" $ Settings.Port);
        Connection.SetConnection(Settings.HostName, Settings.Port);
    }
    else if(StartsWith(Command, "ConnectTo"))
    {
        GivenIp = Mid(Command, Len("ConnectTo") + 1);
        PC.ClientMessage("Connecting to " $ GivenIp $ ":" $ Settings.Port);
        Connection.SetConnection(GivenIp, Settings.Port);
    }
} 

function Timer()
{
    // if not connected, try to connect
    if(!Connection.bConnected)
    {
        Connection.SetConnection(Settings.HostName, Settings.Port);
    }
    // else
    // {
    //     // if connected, send a heartbeat
    //     Connection.SendHeartbeat();
    // }
}

function bool StartsWith(string String, string Prefix)
{
    return Left(String, Len(Prefix)) ~= Prefix;
}

defaultproperties
{
    FriendlyName="Wormhole"
    Description="Wormhole is a mutator that reports everything that happens inside the server to the Wormhole server. The wormhole server is then able to report to Discord, or even a live feed on a website."
}