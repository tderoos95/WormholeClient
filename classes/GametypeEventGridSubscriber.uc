class GameTypeEventGridSubscriber extends WormholeEventGridSubscriber;

// Invasion events
const WaveCountdownStarted = "match/invasion/wavecountdownstarted";
const WaveStarted          = "match/invasion/wavestarted";

// Bunker Building events
const BuildTimeExpired     = "match/bunkerbuilding/buildtimeexpired";

function ProcessEvent(string Topic, JsonObject EventData)
{
    WormholeConnection.SendEventData(Topic, EventData);
}

defaultproperties
{
    SubscriptionTopics(0)="match/invasion/wavecountdownstarted"   // WaveCountDownStarted
    SubscriptionTopics(1)="match/invasion/wavestarted"            // WaveStarted

    SubscriptionTopics(2)="match/bunkerbuilding/buildtimeexpired" // BuildTimeExpired
}