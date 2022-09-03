class RemoteProcessingEventGridSubscriber extends WormholeEventGridSubscriber;

// It is by no means necessary to write all of these events down,
// however, it creates a good overview of which events are being sent.

// Match events
const MatchInfo            = "match/info";
const MatchStarted         = "match/started";
const MatchEnded           = "match/ended";
const MapSwitch            = "match/mapswitch";

// Invasion events
const WaveCountdownStarted = "match/invasion/wavecountdownstarted";
const WaveStarted          = "match/invasion/wavestarted";

// Bunker Building events
const BuildTimeExpired     = "match/bunkerbuilding/buildtimeexpired";

// Player events
const PlayerConnecting     = "player/connecting";
const PlayerConnected      = "player/connected";
const PlayerDisconnected   = "player/disconnected";
const PlayerChat           = "player/chat";
const PlayerKilled         = "player/killed";
const PlayerResurrected    = "player/resurrected";

// RPG Events
const PlayerLeveledUp      = "player/rpg/leveledup";

function ProcessEvent(string Topic, JsonObject EventData)
{
    WormholeConnection.SendEventData(Topic, EventData);
}

defaultproperties
{
    SubscriptionTopics(0)="match/"     // All match related events
    SubscriptionTopics(1)="player/"    // All player related events
}