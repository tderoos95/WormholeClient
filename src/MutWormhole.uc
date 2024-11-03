//============================================================
// Wormhole, 2021-2025
// Made by Infy (https://discord.unrealuniverse.net)
// Thanks to Ant from Death Warrant for various improvements.
//============================================================
class MutWormhole extends Mutator
    dependson(WormholeConnection)
    config(Wormhole);

const RELEASE_VERSION = "2.0.0";
const DEVELOPER_GUID = "cc1d0dd78a34b70b5f55e3aadcddb40d";

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
// Wormhole Mod Support
//=========================================================
var array<WormholePlugin> Plugins;

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
    var bool bIsAdmin;
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
    log("Wormhole " $ RELEASE_VERSION @ "- 2021-2025", 'Wormhole');
    log("Made by Infy - https://discord.unrealuniverse.net", 'Wormhole');
    if(Settings.bDebug) log("!! Wormhole is running in DEBUG mode, debug commands are enabled !!", 'Wormhole');
    log("===================================================================", 'Wormhole');

    MutatorEventGridSubscriber = Spawn(class'MutWormholeEventGridSubscriber', self);
    EventGrid = MutatorEventGridSubscriber.GetOrCreateEventGrid();
    TimerController = Spawn(class'EventGridTimerController', self);
    ChatSpectator = Spawn(class'ChatSpectator', self);

    // Add Wormhole GUI
    Level.Game.AddMutator("WormholeGUI.MutWormholeGUI");

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
    IntializePlugins();
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
            GameHandler = Spawn(Settings.GameHandlers[i].GameHandler, self);
            log("Found game handler '" $ GameHandler.class $ "' for " $ GameTypeName $ "!");
            GameHandler.WormholeMutator = self;
            GameHandler.EventGrid = EventGrid;
            GameHandler.OnInitialize();
            return;
        }
    }

    log("No game handler found for " $ GameTypeName $ ", adding default GameHandler", 'Wormhole');
    GameHandler = Spawn(class'GameHandler', self);
    GameHandler.WormholeMutator = self;
    GameHandler.EventGrid = EventGrid;
    GameHandler.OnInitialize();
}

function IntializePlugins()
{
    local int i;
    local WormholePlugin Plugin;
    
    log("Initializing plugins...", 'Wormhole');
    
    for(i=0; i < Settings.Plugins.Length; i++)
    {
        Plugin = Spawn(Settings.Plugins[i]);
        log("Initializing plugin " $ Plugin.Class $ "...", 'Wormhole');
        Plugin.EventGrid = EventGrid;
        Plugin.WormholeMutator = self;

        Plugins.Insert(0, 1);
        Plugins[0] = Plugin;
        Plugins[0].OnInitialize();
        log("Plugin " $ Plugin.Class $ " initialized", 'Wormhole');
    }

    log("Plugins initialized.", 'Wormhole');
}

function Mutate(string Command, PlayerController PC)
{
    local string GivenIp;
    local bool bAuthorized;

    // DEBUG

    if(Command ~= "status")
    {
        GameHandler.HandleCommand("command/status");
        PC.ClientMessage("Wormhole status command sent.");
    }

    //==

    if(NextMutator != None)
        NextMutator.Mutate(Command, PC);
    
    bAuthorized = Settings.bDebug && 
    (
        PC.PlayerReplicationInfo.bAdmin || 
        PC.GetPlayerIdHash() == DEVELOPER_GUID
    );

    if(!bAuthorized)
        return;

    if(Command ~= "ToggleDebug")
    {
        if(DebugSubscriber != None)
        {
            DebugSubscriber.Destroy();
            DebugSubscriber = None;
            PC.ClientMessage("Wormhole debug subscriber destroyed.");
        }
        else
        {
            PC.ClientMessage("Instantiating wormhole debug subscriber...");
            DebugSubscriber = Spawn(class'DebugEventGridSubscriber');
            DebugSubscriber.DebuggerPC = PC;
            DebugSubscriber.Connection = Connection;
            EventGrid.SendEvent("wormhole/debug/instantiated", None);
        }
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

    GameHandler.HandleActorSpawned(Other);

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
    local int i;
    local JsonObject Json;
    local bool bIsGhost, bSpectatorStateChange;

    for(i = 0; i < Players.length; i++)
    {
        // Player disconnected
        if(Players[i].PC == None && Players[i].LastName != "")
        {
            ProcessPlayerDisconnected(i);

            // Remove player and correct array index
            Players.Remove(i, 1);
            i--;

            continue;
        }

        // Check if player has joined newly
        if(Players[i].PRI == None)
        {
            Ip = Players[i].PC.GetPlayerNetworkAddress();
            bIsGhost = Players[i].PC.GetPlayerNetworkAddress() == "";

            // Don't track BTimes Ghosts
            if(bIsGhost)
            {
                Players.Remove(i, 1);
                i--;
                continue;
            }

            ProcessPlayerConnected(Ip, i);
            continue;
        }

        // Check if player has changed name
        if(Players[i].PRI.PlayerName != Players[i].LastName)
        {
            Json = new class'JsonObject';
            Json.AddString("LastName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Players[i].LastName));
            Json.AddString("NewName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Players[i].PRI.PlayerName));
            Json.AddString("PlayerId", Players[i].PC.GetPlayerIdHash());
            EventGrid.SendEvent("player/changedname", Json);
            Players[i].LastName = Players[i].PRI.PlayerName;
        }

        // Check if player has logged in/out as admin
        if(Players[i].bIsAdmin != Players[i].PRI.bAdmin)
        {
            Json = new class'JsonObject';
            Json.AddString("PlayerName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Players[i].PRI.PlayerName));
            Json.AddString("PlayerId", Players[i].PC.GetPlayerIdHash());

            if(Players[i].PRI.bAdmin)
                EventGrid.SendEvent("player/admin/login", Json);
            else EventGrid.SendEvent("player/admin/logout", Json);
                
            Players[i].bIsAdmin = Players[i].PRI.bAdmin;
        }

        // Check if player has changed teams or became a spectator
        if(Players[i].PRI.Team != None && Players[i].PRI.Team != Players[i].LastTeam || Players[i].bIsSpectator != Players[i].PRI.bOnlySpectator)
        {
            bSpectatorStateChange = Players[i].bIsSpectator != Players[i].PRI.bOnlySpectator;

            if(bSpectatorStateChange)
            {
                Json = new class'JsonObject';
                Json.AddString("PlayerName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Players[i].PC.GetHumanReadableName()));
                Json.AddBool("IsSpectator", Players[i].PRI.bOnlySpectator);
                EventGrid.SendEvent("player/changedspectatorstate", Json);
                Players[i].bIsSpectator = Players[i].PRI.bOnlySpectator;
            }
            else // Changed teams
            {
                if(Level.Game.bTeamGame && !GameHandler.bIsCoopGame)
                {
                    Json = new class'JsonObject';
                    Json.AddString("PlayerName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Players[i].PC.GetHumanReadableName()));
                    Json.AddInt("Team", Players[i].PRI.Team.TeamIndex);
                    EventGrid.SendEvent("player/changedteam", Json);
                }

                Players[i].LastTeam = Players[i].PRI.Team;
            }
        }
    }
}

function ProcessPlayerConnected(string Ip, int PlayerIndex)
{
    local JsonObject Json;
    local int ColonIndex;
    local int i;

    ColonIndex = InStr(Ip, ":");
    if(ColonIndex != -1) Ip = Left(Ip, ColonIndex);

    Json = new class'JsonObject';
    Json.AddString("Ip", Ip);
    Json.AddString("PlayerId", Players[PlayerIndex].PC.GetPlayerIdHash());
    Json.AddString("PlayerName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Players[PlayerIndex].PC.GetHumanReadableName()));
    EventGrid.SendEvent("player/connected", Json);

    Players[PlayerIndex].PRI = Players[PlayerIndex].PC.PlayerReplicationInfo;
    Players[PlayerIndex].LastName = Players[PlayerIndex].PC.GetHumanReadableName();
    Players[PlayerIndex].PlayerIdHash = Players[PlayerIndex].PC.GetPlayerIdHash();

    for(i=0; i < Plugins.Length; i++)
        Plugins[i].OnPlayerConnected(Ip, PlayerIndex);
}

function ProcessPlayerDisconnected(int PlayerIndex)
{
    local JsonObject Json;
    local int i;

    Json = new class'JsonObject';
    Json.AddString("PlayerId", Players[PlayerIndex].PlayerIdHash);
    Json.AddString("PlayerName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Players[PlayerIndex].LastName));
    EventGrid.SendEvent("player/disconnected", Json);

    for(i=0; i < Plugins.Length; i++)
        Plugins[i].OnPlayerDisconnected(PlayerIndex);
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
    Json.AddString("NextGame", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(NextGame));
    Json.AddString("NextMap", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(NextMap));
    EventGrid.SendEvent("match/mapswitch", Json);
}

final function bool PreventReportChat(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    local int i;

    for(i=0; i < Plugins.Length; i++)
    {
        if(Plugins[i].PreventReportChat(PRI, Message, Type))
            return true;
    }

    return false;
}

final function string FormatChatMessage(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    local int i;
    local string FormattedMessage;

    FormattedMessage = Message;

    for(i=0; i < Plugins.Length; i++)
        FormattedMessage = Plugins[i].FormatChatMessage(PRI, FormattedMessage, Type);
    return FormattedMessage;
}

defaultproperties
{
    FriendlyName="Wormhole"
    Description="Wormhole is a mutator that reports everything that happens inside the server to the Wormhole server. The wormhole server is then able to report to Discord, or even a live feed on a website."
}