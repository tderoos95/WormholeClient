class MutWormhole extends Mutator
    dependson(WormholeConnection)
    config(Wormhole);

const DEBUG = true;

var WormholeSettings Settings;
var WormholeConnection Connection;
var ChatSpectator ChatSpectator;
var EventGridTimerController TimerController;
var WormholeGameRules GameRules;

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
    TimerController = Spawn(class'EventGridTimerController', self);
    ChatSpectator = Spawn(class'ChatSpectator', self);

    // Add game rules
    GameRules = Spawn(class'WormholeGameRules', self);
    Level.Game.AddGameModifier(GameRules);
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
    
    if(!DEBUG)
        return;

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
        CreateConnection();
    }
    else if(StartsWith(Command, "ConnectTo"))
    {
        GivenIp = Mid(Command, Len("ConnectTo") + 1);
        PC.ClientMessage("Connecting to " $ GivenIp $ ":" $ Settings.Port);
        Connection.SetConnection(GivenIp, Settings.Port);
    }
    else if(Command ~= "TestTimerMultiple")
    {
        TimerController.CreateTimer("wormhole/test/timer/1", 9);
        TimerController.CreateTimer("wormhole/test/timer/2", 6, true);
        TimerController.CreateTimer("wormhole/test/timer/3", 3);
        PC.ClientMessage("Test timers created");
    }
    else if(Command ~= "DestroyTimer")
    {
        TimerController.DestroyTimer("wormhole/test/timer/2");
        PC.ClientMessage("Destroyed timer");
    }
    else if(Command ~= "TestTimerOneShot")
    {
        TimerController.CreateTimer("wormhole/test/timer/elapsed", 3);
        PC.ClientMessage("Created timer");
    }
    else if(Command ~= "TestTimer")
    {
        TimerController.CreateTimer("wormhole/test/timer/elapsed", 1, true);
        PC.ClientMessage("Created timer");
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

function WormholeConnection CreateConnection()
{
    Connection.Destroy();
    Connection = Spawn(class'WormholeConnection', self);
    Connection.SetConnection(Settings.HostName, Settings.Port);
    return Connection;
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

// Match starts
function MatchStarting()
{
    EventGrid.SendEvent("match/started", None);
}

// Player disconnected
function NotifyLogout(Controller Exiting)
{
	local PlayerController PC;
    local JsonObject Json;

	Super.NotifyLogout(Exiting);
	PC = PlayerController(Exiting);
	
	if(PC != None)
	{
        Json = new class'JsonObject';
        Json.AddString("PlayerId", PC.GetPlayerIdHash());
        Json.AddString("PlayerName", PC.PlayerReplicationInfo.PlayerName);
        EventGrid.SendEvent("player/disconnected", Json);
	}
}

// Map switch
function ServerTraveling(string URL, bool bItems)
{
    ReportTravel(URL);

    if(NextMutator != None)
        NextMutator.ServerTraveling(URL, bItems);
}

function ReportTravel(string NextURL)
{
    local JsonObject Json;
	local string NextMap;
	local string NextGame;
	local int SeparatorCharacterIndex;
	
	local class<GameInfo> NextGameClass;
	
	if(NextURL ~= "?restart")
	{
		NextMap = string(Outer.Name);
		NextGame = string(Level.Game.Class);
	}
	else
	{
		SeparatorCharacterIndex = InStr(NextURL, "?");
		
		if(SeparatorCharacterIndex > 0) {
			NextMap = Left(NextURL, SeparatorCharacterIndex);
			NextURL = Mid(NextURL, SeparatorCharacterIndex);
		}
		else if(SeparatorCharacterIndex == -1 && NextURL != "")
			NextMap = NextURL;
		else
			NextMap = string(Outer.Name);
		
		if(Level.Game.HasOption(NextURL, "game"))
			NextGame = Level.Game.ParseOption(NextURL, "game");
		else
			NextGame = string(Level.Game.Class);
	}
	
	if(NextGame ~= string(Level.Game.Class))
		NextGame = Level.Game.GameName;
	else
	{
		NextGameClass = class<GameInfo>(DynamicLoadObject(NextGame, class'Class'));
		
		if(NextGameClass != None)
			NextGame = NextGameClass.default.GameName;
		else NextGame = GetItemName(NextGame);
	}

    Json = new class'JsonObject';
    Json.AddString("NextGame", NextGame);
    Json.AddString("NextMap", NextMap);
    EventGrid.SendEvent("match/mapswitch", Json);
}

defaultproperties
{
    FriendlyName="Wormhole"
    Description="Wormhole is a mutator that reports everything that happens inside the server to the Wormhole server. The wormhole server is then able to report to Discord, or even a live feed on a website."
}