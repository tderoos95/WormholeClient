class ConnectionEventGridSubscriber extends WormholeEventGridSubscriber;

// Connection events
const AuthenticationResponse   = "wormhole/authentication/response";
const ConnectionAttempt        = "wormhole/connection/attempt";
const ConnectionFailed         = "wormhole/connection/failed";
const ConnectionEstablished    = "wormhole/connection/established";
const ConnectionLost           = "wormhole/connection/lost";

// Timer elapse events
const ConnectionTimeOutElapsed = "wormhole/connection/timeout/elapsed";
const ReconnectElapsed         = "wormhole/connection/reconnect/elapsed";

// This is about as close we can get to DI in UScript
var TimerController TimerController; 
var WormholeSettings Settings;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    TimerController = WormholeConnection.WormholeMutator.TimerController;
    Settings = WormholeConnection.WormholeMutator.Settings;
}

function ProcessEvent(string Topic, JsonObject Json)
{
    if(Topic ~= AuthenticationResponse)
        ProcessAuthenticationResponse(Json);
    else if(Topic ~= ConnectionAttempt)
        ProcessConnectionAttempt();
    else if(Topic ~= ConnectionFailed)
        ProcessConnectionFailed();
    else if(Topic ~= ConnectionEstablished)
        ProcessConnectionEstablished();
    else if(Topic ~= ConnectionLost)
        ProcessConnectionLost();
    else if(Topic ~= ConnectionTimeOutElapsed)
        ProcessTimeoutElapsed();
    else if(Topic ~= ReconnectElapsed)
        ProcessReconnectTimerElapsed();
}

function ProcessAuthenticationResponse(JsonObject Json)
{
    if(!WormholeConnection.IsInState('AwaitingAuthentication'))
        return;
    
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

function ProcessConnectionAttempt()
{
    TimerController.CreateTimer(ConnectionTimeOutElapsed, Settings.ConnectTimeout);
}

function ProcessConnectionFailed()
{
    TimerController.CreateTimer(ReconnectElapsed, Settings.ReconnectInterval);
}

function ProcessConnectionEstablished()
{
    TimerController.DestroyTimer("wormhole/connection/timeout");
    TimerController.DestroyTimer("wormhole/connection/reconnect");
}

function ProcessConnectionLost()
{
    TimerController.CreateTimer(ReconnectElapsed, Settings.ReconnectInterval);
}

function ProcessTimeoutElapsed()
{
    if(WormholeConnection.IsInState('Connected'))
        return;
    
    WormholeConnection.GotoState('NotConnected');
    log("Connection timed out, disconnecting...", 'Wormhole');

    // todo set reconnect timer
}

function ProcessReconnectTimerElapsed()
{
    if(WormholeConnection.IsInState('Connected'))
        return;
    
    WormholeConnection.GotoState('NotConnected');
    log("Reconnecting...", 'Wormhole');
    
    // todo connect
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/authentication/response";   // AuthenticationResponse
    SubscriptionTopics(1)="wormhole/connection/";               // Connection wildcard for all wormhole/connection type events
}