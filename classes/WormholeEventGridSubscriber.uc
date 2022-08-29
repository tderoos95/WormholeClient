class WormholeEventGridSubscriber extends EventGridSubscriber;

var WormholeConnection WormholeConnection;

// Match events
const MatchInfo = "match/info";
const MatchStarted = "match/started";
const MatchEnded = "match/ended";
const MapSwitch = "match/mapswitch";

// Player events
const PlayerConnecting = "player/connecting";
const PlayerConnected = "player/connected";
const PlayerDisconnected = "player/disconnected";
const PlayerChat = "player/chat";
const PlayerKilled = "player/killed";
const PlayerResurrected = "player/resurrected";

// RPG Events
const PlayerLeveledUp = "player/rpg/leveledup";

function ProcessEvent(string Topic, JsonObject EventData)
{
    WormholeConnection.Send(Topic, EventData);
}

defaultproperties
{
    SubscriptionTopics(0)="match/info"             // MatchInfo
    SubscriptionTopics(1)="match/started"          // MatchStarted
    SubscriptionTopics(2)="match/ended"            // MatchEnded
    SubscriptionTopics(3)="match/mapswitch"        // MapSwitch

    SubscriptionTopics(4)="player/connecting"      // PlayerConnecting
    SubscriptionTopics(5)="player/connected"       // PlayerConnected
    SubscriptionTopics(6)="player/disconnected"    // PlayerDisconnected
    SubscriptionTopics(7)="player/chat"            // PlayerChat
    SubscriptionTopics(8)="player/killed"          // PlayerKilled
    SubscriptionTopics(9)="player/resurrected"     // PlayerResurrected

    SubscriptionTopics(10)="player/rpg/leveledup"  // PlayerLeveledUp
}