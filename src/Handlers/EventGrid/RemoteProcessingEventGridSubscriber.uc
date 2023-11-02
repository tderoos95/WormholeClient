class RemoteProcessingEventGridSubscriber extends WormholeEventGridSubscriber;

// It is by no means necessary to write all of these events down,
// however, it creates a good overview of which events are being sent.

//=============================================================================
// Event Topics
//=============================================================================

// Internal
const SuccessfullyAuthenticated  = "wormhole/internal/authenticated";
const RelayConfig                = "wormhole/internal/relay/config";

// Match events
const MatchInfo                  = "match/info";
const MatchStarted               = "match/started";
const MatchEnded                 = "match/ended";
const MapSwitch                  = "match/mapswitch";

// Invasion events
const WaveCountdownStarted       = "match/invasion/wavecountdownstarted";
const WaveStarted                = "match/invasion/wavestarted";

// Bunker Building events
const BuildTimeExpired           = "match/bunkerbuilding/buildtimeexpired";

// Player events
const PlayerConnecting           = "player/connecting";
const PlayerConnected            = "player/connected";
const PlayerDisconnected         = "player/disconnected";
const PlayerChat                 = "player/chat";
const PlayerKilled               = "player/killed";
const PlayerResurrected          = "player/resurrected";

// RPG Events
const PlayerLeveledUp            = "player/rpg/leveledup";

//=============================================================================
// Event Queue
//=============================================================================
struct IQueuedEvent
{
    var string Topic;
    var JsonObject EventData;
};
var array<IQueuedEvent> QueuedEvents;
var bool bIsAuthenticated;
// todo: bIsConnected

//=============================================================================
// Topic filtering
//=============================================================================
var array<string> FilterableTopics;
var array<string> EnabledTopics;

//=============================================================================

function ProcessEvent(string Topic, JsonObject EventData)
{
    if(Topic ~= SuccessfullyAuthenticated)
    {
        HandleAuthenticated();
        return;
    }

    if(!bIsAuthenticated)
        EnqueueEvent(Topic, EventData);
    else SendEvent(Topic, EventData);
}

function HandleAuthenticated()
{
    bIsAuthenticated = true;
    ProcessQueuedEvents();
}

private function ProcessQueuedEvents()
{
    log("Processing queued events: " $ QueuedEvents.Length, 'Wormhole');

    while(QueuedEvents.Length > 0)
    {
        SendEvent(QueuedEvents[0].Topic, QueuedEvents[0].EventData);
        QueuedEvents.Remove(0, 1);
    }

    log("Finished processing queued events", 'Wormhole');
}

function EnqueueEvent(string Topic, JsonObject EventData)
{
    local int NewEntryIndex;

    log("Enqueuing event: " $ Topic, 'Wormhole');
    NewEntryIndex = QueuedEvents.Length;
    QueuedEvents.Length = QueuedEvents.Length + 1;
    QueuedEvents[NewEntryIndex].Topic = Topic;
    QueuedEvents[NewEntryIndex].EventData = EventData;
}

function SendEvent(string Topic, JsonObject EventData)
{
    if(ShouldFilterTopic(Topic))
        return;

    WormholeConnection.SendEventData(Topic, EventData);
}

function bool ShouldFilterTopic(string Topic)
{
    local bool bFilterable;
    local int i;

    if(FilterableTopics.Length == 0)
        return false;

    for(i = 0; i < FilterableTopics.Length; i++)
    {
        if(FilterableTopics[i] ~= Topic)
        {
            bFilterable = true;
            break;
        }
    }

    if(!bFilterable)
        return false;

    // If the topic is filterable, check if it is enabled
    for(i = 0; i < EnabledTopics.Length; i++)
    {
        if(EnabledTopics[i] ~= Topic)
            return false;
    }

    return true;
}

defaultproperties
{
    SubscriptionTopics(0)="match/"                           // All match related events
    SubscriptionTopics(1)="player/"                          // All player related events
    SubscriptionTopics(2)="wormhole/internal/authenticated"  // Authentication event
    SubscriptionTopics(3)="wormhole/internal/relay/config"   // Relay configuration event
}