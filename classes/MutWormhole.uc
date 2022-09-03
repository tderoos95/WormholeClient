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

function PreBeginPlay()
{
    Super.PreBeginPlay();

    Settings = new class'WormholeSettings';
    Settings.SaveConfig();
	SaveConfig();

    EventGrid = GetOrCreateEventGrid();
    Connection = Spawn(class'WormholeConnection', self);
    TimerController = Spawn(class'TimerController', self);
}

function EventGrid GetOrCreateEventGrid()
{
    local bool bFound;

    foreach AllActors(class'EventGrid', EventGrid)
    {
        bFound = true;
        break;
    }
    
    if(!bFound)
    {
        log("EventGrid not found, creating one");
        EventGrid = Spawn(class'EventGrid');
    }
    
    return EventGrid;
}

function Mutate(string Command, PlayerController PC)
{
    local string GivenIp;
    local int i;

    if(NextMutator != None)
        NextMutator.Mutate(Command, PC);
    
    if(Command ~= "ToggleDebug")
    {
        PC.ClientMessage("Instantiating wormhole debug subscriber...");
        DebugSubscriber = Spawn(class'DebugEventGridSubscriber');
        DebugSubscriber.PC = PC;
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
    else if(Command ~= "TestTimerOneShot")
    {
        TimerController.CreateTimer("wormhole/test/timer/elapsed", 3);
    }
    else if(Command ~= "TestTimer")
    {
        TimerController.CreateTimer("wormhole/test/timer/elapsed", 3, true);
    }
    else if(Command ~= "RemoveTestTimer")
    {
        TimerController.DestroyTimer("wormhole/test/timer/elapsed");
    }
    else if(Command ~= "DebugTimer")
    {
        PC.ClientMessage("Current time: " $ Level.TimeSeconds);
        PC.ClientMessage("Next elapse: " $ TimerController.NextTimerElapse);

        for(i = 0; i < TimerController.ActiveTimers.length; i++)
        {
            PC.ClientMessage(TimerController.ActiveTimers[i].CallbackTopic $ " elapses at " $ TimerController.ActiveTimers[i].ElapsesAt);
        }
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