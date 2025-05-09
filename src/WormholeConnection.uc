class WormholeConnection extends TcpLink;

const EndOfMessageChar   = "";

var MutWormhole WormholeMutator;
var WormholeSettings Settings;
var string ServerHostName;
var IpAddr ServerAddress;

var bool bConnected;

// EventGrid subscribers
var RemoteProcessingEventGridSubscriber RemoteProcessingEventGridSubscriber;
var ConnectionEventGridSubscriber ConnectionEventGridSubscriber;

// EventGrid for debugging purposes
var EventGrid EventGrid;
var JsonObject DebugJson;

// Delegates
delegate OnTimeout();

function PreBeginPlay()
{
	Super.PreBeginPlay();
	LoadSettings();
	SpawnSubscribers();
}

function LoadSettings()
{
	WormholeMutator = MutWormhole(Owner);
	Settings = WormholeMutator.Settings;
}

function SpawnSubscribers()
{
	RemoteProcessingEventGridSubscriber = Spawn(Settings.RemoteProcessingEventGridSubscriberClass, self);
	ConnectionEventGridSubscriber = Spawn(class'ConnectionEventGridSubscriber', self);
	EventGrid = RemoteProcessingEventGridSubscriber.GetOrCreateEventGrid();
}

function SendDebugDataToEventGrid(string Topic, JsonObject Json)
{
	if(Settings.bDebug)
		EventGrid.SendEvent(Topic, Json);
}

function SetConnection(string Server, int Port)
{
	ServerHostName		= Server;
	ServerAddress.Port	= Port;
	
	Connect();
}

function Connect();
function Reconnect();

function SendEventData(string Topic, JsonObject EventData)
{
	local JsonObject ProcessEventJson, Json;
	local array<JsonObject> Arguments;

	// Desired message template:
	// "{""type"":1,
	// ""target"":""ProcessEvent"",
	// ""arguments"":[{""Topic"":""authentication/request"",
	//                 ""Data"":{""Token"":"""",""GameServerName"":""""}}]}"

	// Create SignalR wrapper json
	ProcessEventJson = new class'JsonObject';
	ProcessEventJson.AddInt("type", 1);
	ProcessEventJson.AddString("target", "ProcessEvent");

	Json = new class'JsonObject';
	Json.AddString("Topic", Topic);
	Json.AddJson("Data", EventData);

	Arguments.Length = 1;
	Arguments[0] = Json;
	ProcessEventJson.AddArrayJson("arguments", Arguments);

	SendJson(ProcessEventJson);
}

function SendJson(JsonObject Json)
{
	local string Data;
	local bool bGarbageCollection;

	// Determine if we should prevent garbage collection for this json object
	bGarbageCollection = !Json.GetBool("Wormhole.ManualDisposal");
	json.RemoveValue("Wormhole.ManualDisposal");

	Data = Json.ToString();
    Data $= EndOfMessageChar;

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("Data", Data);
		SendDebugDataToEventGrid("wormhole/debug/sendtext", DebugJson);
	}

	if(Settings.bDebugDataFlow)
	{
		log("Sending: " $ Data, 'Wormhole');
	}

    SendText(Data);

	// Garbage collection
	if(bGarbageCollection)
		Json.Clear();
}

function JsonObject DeserializeJson(string Message)
{
	if(class'JsonConvert'.static.EndsWith(Message, EndOfMessageChar))
		Message = Left(Message, Len(Message) - 1);

	return class'JsonConvert'.static.Deserialize(Message);
}

function UnwrapIncomingJson(JsonObject Json)
{
	// Wormhole: * type: 1
	// Wormhole: * target: "wormhole/authentication/response"
	// Wormhole: arguments:
	// Wormhole: * {"success":false}
	local array<string> Arguments;
	local int Type;
	local int i;

	Type = Json.GetInt("type");

	// Check if message is relevant for us
	if(Type != 1)
		return;

	Arguments = Json.GetArrayValue("arguments");

	if(Arguments.length == 0)
		return;

	// Deserialize nested values into root json object
	for(i = 0; i < Arguments.length; i++)
		class'JsonConvert'.static.DeserializeIntoExistingObject(Json, Arguments[i]);

	Json.RemoveValue("type");
	Json.RemoveArrayValue("arguments");
}

function ForwardToEventGrid(JsonObject Json)
{
	local string Target;

	Target = Json.GetString("Target");

	if(Len(Target) > 0)
		EventGrid.SendEvent(Target, Json);
}

event Closed()
{
	EventGrid.SendEvent("wormhole/connection/lost", None);
	SendDebugDataToEventGrid("wormhole/debug/disconnected", None);
	GotoState('NotConnected');
}

auto state NotConnected
{
	function Connect()
	{
		if(ServerAddress.Addr != 0 && ServerAddress.Port > 0)
		{
			if(BindPort() == 0)
			{
				EventGrid.SendEvent("wormhole/connection/failed", None);
				log("ERROR - Can't bind port for wormhole connection.", Name);
			}
			else
			{
				log("Attempting to connect to wormhole remote server...", Name);
				EventGrid.SendEvent("wormhole/connection/attempt", None);
				Open(ServerAddress);
			}
		}
		else if(ServerHostName != "" && ServerAddress.Port > 0)
		{
			SendDebugDataToEventGrid("wormhole/debug/resolving", None);
			Resolve(ServerHostName);
		}
		else
		{
			SendDebugDataToEventGrid("wormhole/debug/failed", None);
			EventGrid.SendEvent("wormhole/connection/attempt/failed", None);
			log("ERROR - Missing server address or port.", Name);
		}
	}

	function Reconnect()
	{
		log("Attempting to connect to wormhole remote server...", Name);
		EventGrid.SendEvent("wormhole/connection/attempt", None);
		Close();
		Open(ServerAddress);
	}
	
	event Resolved(IpAddr Address)
	{
		SendDebugDataToEventGrid("wormhole/debug/resolved", None);

		if(Address.Addr != 0)
		{
			ServerAddress.Addr = Address.Addr;
			Connect();
		}
		else
			log("ERROR - Resolving resulted in 0.0.0.0", Name);
	}
	
	event ResolveFailed()
	{
		SendDebugDataToEventGrid("wormhole/debug/resolvefailed", None);
		log("ERROR - Could not resolve server address.", Name);
	}
	
	event Opened()
	{
		EventGrid.SendEvent("wormhole/connection/established", None);
		SendDebugDataToEventGrid("wormhole/debug/connected", None);
		GotoState('AwaitingHandshake');
	}
	
begin:
	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "NotConnected");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}
}

state AwaitingHandshake
{
	function SendJson(JsonObject Json)
	{
		local string Data;
		local bool bGarbageCollection;
		local bool bHandshakeRequest;

		bHandshakeRequest = Json.GetString("protocol") ~= "json" && Json.GetInt("version") == 1;

		// Handshake request should always be the first message sent, block other messages for now
		if(!bHandshakeRequest)
		{
			Json.Clear(); // discard json from memory
			return;
		}

		// Determine if we should prevent garbage collection for this json object
		bGarbageCollection = !Json.GetBool("Wormhole.ManualDisposal");
		Json.RemoveValue("Wormhole.ManualDisposal");

		Data = Json.ToString();
		Data $= EndOfMessageChar;

		if(Settings.bDebug)
		{
			DebugJson = new class'JsonObject';
			DebugJson.AddString("Data", Data);
			SendDebugDataToEventGrid("wormhole/debug/sendtext", DebugJson);
		}

		if(Settings.bDebugDataFlow)
		{
			log("Sending: " $ Data, 'Wormhole');
		}

		SendText(Data);

		// Garbage collection
		if(bGarbageCollection)
			Json.Clear();
	}

	event ReceivedText(string Message)
	{
		local JsonObject Json;

		if(Settings.bDebugDataFlow)
		{
			log("Received raw text: " $ Message, Name);
		}

		Json = DeserializeJson(Message);
		SendDebugDataToEventGrid("wormhole/debug/receivedtext", Json);

		if(Len(Json.GetString("error")) == 0)
			GotoState('AwaitingAuthentication');
		else GotoState('NotConnected');
	}

	function SendHandshakeRequest()
	{
		local JsonObject Json;

		Json = new class'JsonObject';
		Json.AddString("protocol", "json");
		Json.AddInt("version", 1);
		SendJson(Json);
	}
	
Begin:
	log("Connection established", Name);

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "AwaitingHandshake");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}

	SendHandshakeRequest();
}

state AwaitingAuthentication // HandshakePerformed
{
	function SendAuthenticationRequest()
	{
		local JsonObject Json;

		log("Sending authentication request", Name);

		Json = new class'JsonObject';
		Json.AddString("ClientVersion", WormholeMutator.RELEASE_VERSION);
		Json.AddString("Token", Settings.Token);
		SendEventData("wormhole/authentication/request", Json);
	}

	function ReceivedText(string Message)
	{
		local JsonObject Json;
		
		if(Settings.bDebugDataFlow)
		{
			log("Received raw text: " $ Message, Name);
		}

		Json = DeserializeJson(Message);
		UnwrapIncomingJson(Json);
		SendDebugDataToEventGrid("wormhole/debug/receivedtext", Json);
		ForwardToEventGrid(Json);
	}

begin:
	log("Handshake performed, awaiting authentication verification", Name);

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "AwaitingAuthentication");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}

	SendAuthenticationRequest();
}

state Authenticated
{
	event ReceivedText(string Message)
	{
		local JsonObject Json;

		if(Settings.bDebugDataFlow)
		{
			log("Received raw text: " $ Message, Name);
		}
		
		Json = DeserializeJson(Message);
		UnwrapIncomingJson(Json);
		SendDebugDataToEventGrid("wormhole/debug/receivedtext", Json);
		ForwardToEventGrid(Json);
	}
	
Begin:
	log("Succesfully authenticated by server", Name);

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "Authenticated");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}
}


defaultproperties
{
	Name = 'WormholeBot'
}