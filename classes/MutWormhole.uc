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

//=============================================================================
// Tracking variables for reporting
//=============================================================================
struct IPlayer {
    var PlayerController PC;
    var PlayerReplicationInfo PRI;
    var bool bIsSpectator;
    var TeamInfo LastTeam;
    var string LastName;
    var string PlayerIdHash;
};

var array<IPlayer> Players;
var bool bGameEnded;


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
    
    CreateConnection();
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
        DebugSubscriber.DebuggerPC = PC;
        DebugSubscriber.Connection = Connection;
        //
        StartMonitoringPlayers(); // todo: move this to the connection eventgrid subscriber
        //
        EventGrid.SendEvent("wormhole/debug/instantiated", None);
    }
    // else if(Command ~= "Connect")
    // {
    //     PC.ClientMessage("Connecting to " $ Settings.HostName $ ":" $ Settings.Port);
    //     CreateConnection();
    // }
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
    else if(StartsWith(Command, "FloodWormhole"))
    {
        FloodWormhole(PC, Command);
    }
}

function FloodWormhole(PlayerController PC, string Command)
{
    local JsonObject Json;
    local int SpaceIndex;
    local int Count;
    local int i;
    local bool bManualDisposal;
    local string NextPart;

    SpaceIndex = InStr(Command, " ");

    if(SpaceIndex == -1)
    {
        PC.ClientMessage("Usage: FloodWormhole <garbagecollection:bool> <count:int>");
        return;
    }

    NextPart = Mid(Command, SpaceIndex + 1);
    SpaceIndex = InStr(NextPart, " ");

    PC.ClientMessage("Garbage collection: " $ Left(NextPart, SpaceIndex));

    bManualDisposal = !bool(Left(NextPart, SpaceIndex));
    Count = int(Mid(NextPart, SpaceIndex + 1));

    if(Count <= 0)
    {
        PC.ClientMessage("Count must be greater than 0");
        return;
    }

    PC.ClientMessage(Eval(bManualDisposal, 
        "Flooding wormhole without garbage collection. " $ Count $ " messages...",
        "Flooding wormhole with garbage collection. " $ Count $ " messages..."));

    for(i = 0; i < Count; i++)
    {
        Json = new class'JsonObject';
        Json.AddInt("id", i);
        Json.AddString("text", "This is a test message");
        Json.AddFloat("time", Level.TimeSeconds);
        Json.AddString("type", "chat");
        Json.AddString("sender", "Test");
        Json.AddString("team", "Red");
        Json.AddString("channel", "All");
        Json.AddString("color", "255,0,0");

        Json.AddBool("Wormhole.ManualDisposal", bManualDisposal);
        EventGrid.SendEvent("wormhole/test/flood", Json);
    }

    PC.ClientMessage("Flooded wormhole with " $ Count $ " messages");
}

function WormholeConnection CreateConnection()
{
    if(Connection != None)
        Connection.Destroy();
    
    Connection = Spawn(class'WormholeConnection', self);
    Connection.SetConnection(Settings.HostName, Settings.Port);
    return Connection;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    if(PlayerController(Other) != None)
    {
        Players.Insert(0, 1);
        Players[0].PC = PlayerController(Other);
    }
    return Super.CheckReplacement(Other, bSuperRelevant);
}

function StartMonitoringPlayers()
{
    SetTimer(0.1, true);
}

function Timer()
{
    MonitorPlayers();
    CheckEndGame();
}

function MonitorPlayers()
{
    local int i;
    local JsonObject Json;

    for(i = 0; i < Players.length; i++)
    {
        if(Players[i].PC == None)
            continue; // Removal of Player is handled in NotifyLogout

        // Check if player has joined newly
        if(Players[i].PRI == None)
        {
            Json = new class'JsonObject';
            Json.AddString("PlayerId", Players[i].PC.GetPlayerIdHash());
            Json.AddString("PlayerName", Players[i].PC.GetHumanReadableName());
            EventGrid.SendEvent("player/connected", Json);

            Players[i].PRI = Players[i].PC.PlayerReplicationInfo;
            Players[i].bIsSpectator = Players[i].PRI.bIsSpectator;
            Players[i].LastTeam = Players[i].PRI.Team;
            Players[i].LastName = Players[i].PC.GetHumanReadableName();
            Players[i].PlayerIdHash = Players[i].PC.GetPlayerIdHash();
            continue;
        }

        // Check if player has changed name
        if(Players[i].PRI.PlayerName != Players[i].LastName)
        {
            Json = new class'JsonObject';
            Json.AddString("LastName", Players[i].LastName);
            Json.AddString("NewName", Players[i].PRI.PlayerName);
            Json.AddString("PlayerId", Players[i].PC.GetPlayerIdHash());
            EventGrid.SendEvent("player/changedname", Json);

            Players[i].LastName = Players[i].PRI.PlayerName;
        }

        // Check if player has changed teams or became a spectator
        if(Players[i].PRI.Team != Players[i].LastTeam)
        {
            Json = new class'JsonObject';
            Json.AddString("PlayerId", Players[i].PC.GetPlayerIdHash());
            Json.AddString("PlayerName", Players[i].PC.GetHumanReadableName());
            Json.AddInt("Team", Players[i].PRI.Team.TeamIndex);
            Json.AddBool("IsSpectator", Players[i].PRI.bOnlySpectator);

            EventGrid.SendEvent("player/changedteam", Json);
            Players[i].LastTeam = Players[i].PRI.Team;
        }
    }
}

function CheckEndGame()
{
    if(!bGameEnded && Level.Game.bGameEnded)
    {
        bGameEnded = true;
        EventGrid.SendEvent("match/ended", None);
    }
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
    local string PlayerIdHash;

	Super.NotifyLogout(Exiting);
	PC = PlayerController(Exiting);
	
	if(PC == None)
        return; // not a player

    // PlayerIdHash changes when player disconnects, retrieve stored value instead
    PlayerIdHash = GetStoredPlayerIdHash(PC.GetHumanReadAbleName());

    Json = new class'JsonObject';
    Json.AddString("PlayerId", PlayerIdHash);
    Json.AddString("PlayerName", PC.PlayerReplicationInfo.PlayerName);
    EventGrid.SendEvent("player/disconnected", Json);
    RemovePlayer(PC);
}

final function string GetStoredPlayerIdHash(string PlayerName)
{
    local int i;

    for(i = 0; i < Players.length; i++)
    {
        if(Players[i].PC.GetHumanReadableName() ~= PlayerName)
            return Players[i].PlayerIdHash;
    }
    return "";
}

function RemovePlayer(PlayerController PC)
{
    local int i;

    for(i = 0; i < Players.length; i++)
    {
        if(Players[i].PC == PC)
        {
            Players.Remove(i, 1);
            break;
        }
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