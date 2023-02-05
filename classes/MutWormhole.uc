class MutWormhole extends Mutator
    dependson(WormholeConnection)
    config(Wormhole);

const RELEASE_VERSION = "0.8.4-beta";

//=========================================================
// Wormhole related variables
//=========================================================
var WormholeSettings Settings;
var WormholeConnection Connection;
var ChatSpectator ChatSpectator;
var EventGridTimerController TimerController;
var WormholeGameRules GameRules;

//=========================================================
// Game handlers
//=========================================================
struct GameHandlerRegistration {
    var string GameTypeName;
    var class<GameHandler> GameHandler;
};
var GameHandler GameHandler;

//=========================================================
// Event management
//=========================================================
var DebugEventGridSubscriber DebugSubscriber;
var MutWormholeEventGridSubscriber MutatorEventGridSubscriber;
var EventGrid EventGrid;

//=========================================================
// Tracking variables for reporting
//=========================================================
struct IPlayer {
    var PlayerController PC;
    var PlayerReplicationInfo PRI;
    var bool bIsSpectator;
    var TeamInfo LastTeam;
    var string LastName;
    var string PlayerIdHash;
};

var array<IPlayer> Players;
var bool bHasReportedServerTravel;

function PreBeginPlay()
{
    Super.PreBeginPlay();

    Settings = new class'WormholeSettings';
    Settings.SaveConfig();
	SaveConfig();

    log("===================================================================", 'Wormhole');
    log("Wormhole " $ RELEASE_VERSION, 'Wormhole');
    log("https://discord.unrealuniverse.net", 'Wormhole');
    if(Settings.bDebug) log("!! Wormhole is running in DEBUG mode, debug commands are enabled !!", 'Wormhole');
    log("===================================================================", 'Wormhole');

    MutatorEventGridSubscriber = Spawn(class'MutWormholeEventGridSubscriber', self);
    EventGrid = MutatorEventGridSubscriber.GetOrCreateEventGrid();
    TimerController = Spawn(class'EventGridTimerController', self);
    ChatSpectator = Spawn(class'ChatSpectator', self);

    AddGameRules();
    CreateConnection();
}

function AddGameRules()
{
    GameRules = Spawn(class'WormholeGameRules', self);
    Level.Game.AddGameModifier(GameRules);
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
    AddGameHandler(Level.Game.Class);
}

function AddGameHandler(class<GameInfo> GameType)
{
    local string GameTypeName;
    local int i;
    
    GameTypeName = string(GameType);
    log("Adding game handler for " $ GameTypeName $ "...", 'Wormhole');

    for (i = 0; i < Settings.GameHandlers.length; i++)
    {
        if (Settings.GameHandlers[i].GameTypeName ~= GameTypeName)
        {
            log("Found game handler '" $ string(Settings.GameHandlers[i].GameHandler.Class) $ "' for " $ GameTypeName $ "!");
            GameHandler = Spawn(Settings.GameHandlers[i].GameHandler, self);
            GameHandler.EventGrid = EventGrid;
            GameHandler.PostInitialize();
            return;
        }
    }

    log("No game handler found for " $ GameTypeName $ ", adding default GameHandler", 'Wormhole');
    GameHandler = Spawn(class'GameHandler', self);
    GameHandler.EventGrid = EventGrid;
    GameHandler.PostInitialize();
}

function Mutate(string Command, PlayerController PC)
{
    local string GivenIp;
    local bool bAuthorized;

    if(NextMutator != None)
        NextMutator.Mutate(Command, PC);
    
    bAuthorized = Settings.bDebug && PC.PlayerReplicationInfo.bAdmin;
    if(!bAuthorized)
        return;

    if(Command ~= "ToggleDebug")
    {
        PC.ClientMessage("Instantiating wormhole debug subscriber...");
        DebugSubscriber = Spawn(class'DebugEventGridSubscriber');
        DebugSubscriber.DebuggerPC = PC;
        DebugSubscriber.Connection = Connection;
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
    local bool bIsPlayer;

    bIsPlayer = PlayerController(Other) != None && UTServerAdminSpectator(Other) == None;
    if(bIsPlayer)
    {
        Players.Insert(0, 1);
        Players[0].PC = PlayerController(Other);
    }
    return Super.CheckReplacement(Other, bSuperRelevant);
}

function StartMonitoringGame()
{
    SetTimer(0.1, true);
}

function Timer()
{
    MonitorPlayers();

    if(GameHandler != None)
        GameHandler.MonitorGame();
}

function MonitorPlayers()
{
    local string Ip;
    local int i, ColonIndex;
    local JsonObject Json;

    for(i = 0; i < Players.length; i++)
    {
        // Player disconnected
        if(Players[i].PC == None && Players[i].LastName != "")
        {
            Json = new class'JsonObject';
            Json.AddString("PlayerId", Players[i].PlayerIdHash);
            Json.AddString("PlayerName", Players[i].LastName);
            EventGrid.SendEvent("player/disconnected", Json);

            // Remove player and correct array index
            Players.Remove(i, 1);
            i--;
            continue;
        }

        // Check if player has joined newly
        if(Players[i].PRI == None)
        {
            Ip = Players[i].PC.GetPlayerNetworkAddress();
            ColonIndex = InStr(Ip, ":");
            if(ColonIndex != -1) Ip = Left(Ip, ColonIndex);

            Json = new class'JsonObject';
            Json.AddString("Ip", Ip);
            Json.AddString("PlayerId", Players[i].PC.GetPlayerIdHash());
            Json.AddString("PlayerName", Players[i].PC.GetHumanReadableName());
            EventGrid.SendEvent("player/connected", Json);

            Players[i].PRI = Players[i].PC.PlayerReplicationInfo;
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
        if(Players[i].PRI.Team != None && Players[i].PRI.Team != Players[i].LastTeam || Players[i].bIsSpectator != Players[i].PRI.bOnlySpectator)
        {
            Json = new class'JsonObject';
            Json.AddString("PlayerId", Players[i].PC.GetPlayerIdHash());
            Json.AddString("PlayerName", Players[i].PC.GetHumanReadableName());
            Json.AddInt("Team", Players[i].PRI.Team.TeamIndex);
            Json.AddBool("IsSpectator", Players[i].PRI.bOnlySpectator);

            EventGrid.SendEvent("player/changedteam", Json);
            Players[i].LastTeam = Players[i].PRI.Team;
            Players[i].bIsSpectator = Players[i].PRI.bOnlySpectator;
        }
    }
}

function bool StartsWith(string String, string Prefix)
{
    return Left(String, Len(Prefix)) ~= Prefix;
}

// Match starts
function MatchStarting()
{
    if(GameHandler != None)
        GameHandler.HandleMatchStarted();
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

    if(bHasReportedServerTravel) 
        return; // this fix is required for InvasionPro. InvasionPro calls ServerTraveling twice.
    bHasReportedServerTravel = true;
	
	if(NextURL ~= "?restart")
	{
		NextMap = string(Outer.Name);
		NextGame = string(Level.Game.Class);
	}
	else
	{
		SeparatorCharacterIndex = InStr(NextURL, "?");
		
		if(SeparatorCharacterIndex > 0)
        {
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
    // FriendlyName="Wormhole"
    Description="Wormhole is a mutator that reports everything that happens inside the server to the Wormhole server. The wormhole server is then able to report to Discord, or even a live feed on a website."
}