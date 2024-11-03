class GameHandler extends Info;

enum TimerModeType
{
    AwaitGameInitialized,
    AwaitMatchEnded
};

var MutWormhole WormholeMutator;
var TimerModeType TimerMode;
var EventGrid EventGrid;
var bool bIsCoopGame;
var bool bGameStarted;
var bool bGameEnded;

var TriggerEventListener GameEndedListener;

public function OnInitialize()
{
    log("Initializing GameHandler...", 'Wormhole');
    SubscribeToGameInfoEvents();
    log("GameHandler initialized.", 'Wormhole');
    PrepareSendMatchInfo();
}

function SubscribeToGameInfoEvents()
{
    GameEndedListener = Spawn(class'TriggerEventListener');
    GameEndedListener.Subscribe('EndGame');
    GameEndedListener.Callback = AwaitMatchEnded;
}

function PrepareSendMatchInfo()
{
    TimerMode = TimerModeType.AwaitGameInitialized;
    SetTimer(0.1, false);
}

function Timer()
{
    if(TimerMode == AwaitGameInitialized)
    {
        if(Level.Game.GameReplicationInfo == None)
        {
            SetTimer(0.1, false);
            return;
        }

        SendMatchInfo();
    }

    if(TimerMode == AwaitMatchEnded)
    {
        if(!Level.Game.bGameEnded)
        {
            SetTimer(0.1, false);
            return;
        }

        HandleMatchEnded();
    }
}

public function SendMatchInfo()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddString("ServerIp", Level.GetAddressURL());
    Json.AddString("ServerName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Level.Game.GameReplicationInfo.ServerName));
    Json.AddString("GameType", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Level.Game.GameName));
    Json.AddString("MapName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Level.Title));
    EventGrid.SendEvent("match/info", Json);
}

public function MonitorGame()
{ }

public function HandleMatchStarted()
{
    bGameStarted = true;
    EventGrid.SendEvent("match/started", None);
}

function AwaitMatchEnded()
{
    TimerMode = AwaitMatchEnded;
    SetTimer(0.1, false);
}

function HandleMatchEnded()
{
    GameEndedListener.Destroy();
    EventGrid.SendEvent("match/ended", None);
}

function HandleActorSpawned(Actor Other)
{ }

function HandleCommand(string Topic)
{
    if(Topic == "wormhole/command/status")
    {
        HandleStatusCommand();
    }
    else if(Topic == "wormhole/command/commands")
    {
        HandleCommandListCommand();
    }
    else
    {
        SendCommandNotAvailable();
    }
}

function SendCommandNotAvailable()
{
    local JsonObject Json, Color;

    Json = new class'JsonObject';
    Json.AddString("Description", "Command not available or not recognized. Use `/commands` to see available commands.");

    Color = new class'JsonObject';
    Color.AddInt("R", 255);
    Color.AddInt("G", 0);
    Color.AddInt("B", 0);

    Json.AddJson("Color", Color);
    EventGrid.SendEvent("wormhole/relay/discordembed", Json);
}

function HandleCommandListCommand()
{
    local JsonObject Json, Color;
    local array<string> Commands;
    local string Description;
    local int i;

    Json = new class'JsonObject';
    Json.AddString("Title", "Available Commands");

    Color = new class'JsonObject';
    Color.AddInt("R", 73);
    Color.AddInt("G", 35);
    Color.AddInt("B", 255);
    Json.AddJson("Color", Color);

    Commands.Length = 2;
    Commands[0] = "`/status` - Get server status";
    Commands[1] = "`/commands` - Get available commands";

    for(i = 0; i < Commands.Length; i++)
    {
        Description $= Commands[i] $ "\\n";
    }

    Json.AddString("Description", Description);
    EventGrid.SendEvent("wormhole/relay/discordembed", Json);
}

function HandleStatusCommand()
{
    local JsonObject Json, Color;
    local array<JsonObject> Fields;
    local int i;

    Json = new class'JsonObject';
    Json.AddString("Title", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Level.Game.GameReplicationInfo.ServerName));

    // Add color
    Color = new class'JsonObject';
    Color.AddInt("R", 73);
    Color.AddInt("G", 35);
    Color.AddInt("B", 255);
    Json.AddJson("Color", Color);

    // Add fields
    Fields.Length = 3;

    // Field 1: Server IP
    Fields[0] = new class'JsonObject';
    Fields[0].AddString("Name", "IP");
    Fields[0].AddString("Value", Level.GetAddressURL());
    Fields[0].AddBool("Inline", false);

    // Field 2: Map Name
    Fields[1] = new class'JsonObject';
    Fields[1].AddString("Name", "Map");
    Fields[1].AddString("Value", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Level.Title));
    Fields[1].AddBool("Inline", true);

    // Field 3: Game Type
    Fields[2] = new class'JsonObject';
    Fields[2].AddString("Name", "Gametype");
    Fields[2].AddString("Value", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(Level.Game.GameName));
    Fields[2].AddBool("Inline", true);

    EnrichEmbedWithPlayers(Fields);

    // Add fields to embed & send ìt
    Json.AddArrayJson("Fields", Fields);
    EventGrid.SendEvent("wormhole/relay/discordembed", Json);

    // Clear all json objects, so memory is freed up after sending
    for(i = 0; i < Fields.Length; i++)
    {
        Fields[i].Clear();
    }

    Json.Clear();
    Color.Clear();
}

function EnrichEmbedWithPlayers(out array<JsonObject> Fields)
{
    local array<PlayerController> Players;
    local array<PlayerController> RedTeamPlayers;
    local array<PlayerController> BlueTeamPlayers;
    local array<PlayerController> Spectators;
    local int i, FieldIndex;
    local string PlayersString;

    // If teamgame and not coopgame, get all players and filter by team
    if(Level.Game.bTeamGame && !bIsCoopGame)
    {
        Players = GetPlayers();
        Spectators = FilterBySpecator(Players, true);

        Log("Players: " $ Players.Length, 'Wormhole');
        Log("Spectators: " $ Spectators.Length, 'Wormhole');

        RedTeamPlayers = FilterByTeam(Players, 0);
        Log("Red team: " $ RedTeamPlayers.Length, 'Wormhole');

        // Add red team players
        if(RedTeamPlayers.Length > 0)
        {
            for (i = 0; i < RedTeamPlayers.Length; i++)
            {
                Log("Red team player: " $ RedTeamPlayers[i].PlayerReplicationInfo.PlayerName, 'Wormhole');
            }

            PlayersString = GetPlayersString(FilterByTeam(Players, 0));
            FieldIndex = Fields.Length;
            Fields.Length = FieldIndex + 1;
            Fields[FieldIndex] = new class'JsonObject';
            Fields[FieldIndex].AddString("Name", "Red Team");
            Fields[FieldIndex].AddString("Value", PlayersString);
            Fields[FieldIndex].AddBool("Inline", false);
        }

        BlueTeamPlayers = FilterByTeam(Players, 1);
        Log("Blue team: " $ BlueTeamPlayers.Length, 'Wormhole');

        for (i = 0; i < BlueTeamPlayers.Length; i++)
        {
            Log("Blue team player: " $ BlueTeamPlayers[i].PlayerReplicationInfo.PlayerName, 'Wormhole');
        }

        // Add blue team players
        if(BlueTeamPlayers.Length > 0)
        {
            PlayersString = GetPlayersString(FilterByTeam(Players, 1));
            FieldIndex = Fields.Length;
            Fields.Length = FieldIndex + 1;
            Fields[FieldIndex] = new class'JsonObject';
            Fields[FieldIndex].AddString("Name", "Blue Team");
            Fields[FieldIndex].AddString("Value", PlayersString);
            Fields[FieldIndex].AddBool("Inline", false);
        }

        // Add spectators
        if(Spectators.Length > 0)
        {
            PlayersString = GetPlayersString(Spectators);
            FieldIndex = Fields.Length;
            Fields.Length = FieldIndex + 1;
            Fields[FieldIndex] = new class'JsonObject';
            Fields[FieldIndex].AddString("Name", "Spectators");
            Fields[FieldIndex].AddString("Value", PlayersString);
            Fields[FieldIndex].AddBool("Inline", false);
        }
    }
    else
    {
        Players = GetPlayers();
        Spectators = FilterBySpecator(Players, true);
        Players = FilterBySpecator(Players, false);

        Log("Players: " $ Players.Length, 'Wormhole');
        Log("Spectators: " $ Spectators.Length, 'Wormhole');

        // Add players
        if(Players.Length > 0)
        {
            PlayersString = GetPlayersString(Players);
            FieldIndex = Fields.Length;
            Fields.Length = FieldIndex + 1;
            Fields[FieldIndex] = new class'JsonObject';
            Fields[FieldIndex].AddString("Name", "Players");
            Fields[FieldIndex].AddString("Value", PlayersString);
            Fields[FieldIndex].AddBool("Inline", false);
        }

        // Add spectators
        if(Spectators.Length > 0)
        {
            PlayersString = GetPlayersString(Spectators);
            FieldIndex = Fields.Length;
            Fields.Length = FieldIndex + 1;
            Fields[FieldIndex] = new class'JsonObject';
            Fields[FieldIndex].AddString("Name", "Spectators");
            Fields[FieldIndex].AddString("Value", PlayersString);
            Fields[FieldIndex].AddBool("Inline", false);
        }
    }
}

// ========================================
function string GetPlayersString(array<PlayerController> Players)
{
    local string PlayersString;
    local int i;

    for(i = 0; i < Players.Length; i++)
    {
        PlayersString = PlayersString $ FormatPlayerName(Players[i]) $ "\\n";
    }

    return PlayersString;
}

function array<PlayerController> GetPlayers()
{
    local array<PlayerController> Players;
    local int i;

    for (i = 0; i < WormholeMutator.Players.Length; i++)
    {
        if(WormholeMutator.Players[i].PC != None)
        {
            Players.Insert(0, 1);
            Players[0] = WormholeMutator.Players[i].PC;
        }
    }

    return Players;
}

function array<PlayerController> FilterBySpecator(array<PlayerController> Players, bool bSpecator)
{
    local array<PlayerController> FilteredPlayers;
    local PlayerController PC;
    local int i;

    for(i = 0; i < Players.Length; i++)
    {
        PC = Players[i];
        if(PC.PlayerReplicationInfo.bOnlySpectator == bSpecator)
        {
            FilteredPlayers.Insert(0, 1);
            FilteredPlayers[FilteredPlayers.Length - 1] = PC;
        }
    }

    Log("Filtered spectactors: " $ FilteredPlayers.Length, 'Wormhole');

    return FilteredPlayers;
}

function array<PlayerController> FilterByTeam(array<PlayerController> Players, int TeamIndex)
{
    local array<PlayerController> FilteredPlayers;
    local PlayerController PC;
    local int i;

    for(i = 0; i < Players.Length; i++)
    {
        PC = Players[i];

        Log("Player: " $ PC.PlayerReplicationInfo.PlayerName, 'Wormhole');
        Log("Team: " $ PC.PlayerReplicationInfo.Team.TeamIndex, 'Wormhole');
        Log("Only spectator: " $ PC.PlayerReplicationInfo.bOnlySpectator, 'Wormhole');

        if(!PC.PlayerReplicationInfo.bOnlySpectator && PC.PlayerReplicationInfo.Team.TeamIndex == TeamIndex)
        {
            FilteredPlayers.Insert(0, 1);
            FilteredPlayers[0] = PC;

            Log("Added player to team: " $ PC.PlayerReplicationInfo.PlayerName, 'Wormhole');
        }
    }

    Log("Filtered team: " $ FilteredPlayers.Length, 'Wormhole');

    return FilteredPlayers;
}
//

function string FormatPlayerName(PlayerController PC)
{
    // format: {countryflag} Name
    local string IP;
    local int ColonIndex;
    local string SanitizedName;

    Log("Player name: " $ PC.PlayerReplicationInfo.PlayerName, 'Wormhole');
    Log("Player IP: " $ PC.GetPlayerNetworkAddress(), 'Wormhole');

    IP = PC.GetPlayerNetworkAddress();
    ColonIndex = InStr(Ip, ":");
    if(ColonIndex != -1) Ip = Left(Ip, ColonIndex);

    SanitizedName = class'JsonLib.JsonUtils'.static.StripIllegalCharacters(PC.PlayerReplicationInfo.PlayerName);
    return "{" $ Ip $ ":country-flag} " $ SanitizedName;
}

defaultproperties {
    bIsCoopGame=false
}