class IncomingDataEventGridSubscriber extends WormholeEventGridSubscriber;

const AuthenticationResponse = "wormhole/authentication/response";

function ProcessEvent(string Topic, JsonObject Json)
{
    if(Topic == AuthenticationResponse)
        ProcessAuthenticationResponse(Json);
}

function ProcessAuthenticationResponse(JsonObject Json)
{
    if(Json.GetBool("Success"))
    {
        WormholeConnection.GotoState('Authenticated');
        log("Authentication successful", 'Wormhole');
    }
    else
    {
        WormholeConnection.GotoState('NotConnected');
        log("Authentication failed, disconnecting...", 'Wormhole');
    }
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/authentication/response";   // AuthenticationResponse
}