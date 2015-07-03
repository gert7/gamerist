#include <sourcemod>
#include <socket>

public Plugin:myinfo =
{
  name = "Gamerist",
  author = "gert",
  description = "Video game reporter",
  version = "1.0",
  url = "http://www.gamerist"
};

#define MQLIMIT 64 // total capacity of the message queue
#define MAX_MESSAGESIZE 256
#define IDLIMIT 34
#define MAXIDSIZE 24

#define ERROR_MESSAGES_NOT_BEING_RECEIVED 5

new String:allowedids[IDLIMIT][MAXIDSIZE]; // 1 string is 24 characters, null terminator included

new String:messagequeue[MQLIMIT][MAX_MESSAGESIZE];
new clIndex        = 0; // The position of the last confirmed mid in the circular queue (left end)
new crIndex        = 0; // The position of the last mid in the circular queue (right end, out of mqLIMIT)
new cmid           = 0; // Last confirmed mid (left end of queue, big number)
new lastmid        = 0; // The last mid added to the queue (right end of queue, next is this + 1)

new serverKilled   = 0;

new Handle:sharedSocket;

public OnPluginStart()
{
  PrintToServer("[GAMERIST] Gamerist starting up...");
  
  CreateTimer(2.0, RestartSocket);
  CreateTimer(2.0, ShoveMessages);
}

public Action:ShoveMessages(Handle:timer)
{
  new String:primer[256];
  for(new i = 0; i < 69; i++)
  {
    Format(primer, sizeof(primer), "hellou %d", i)
    PushMessage(primer);
  }
}

KillServer(errno)
{
  serverKilled = errno;
  PrintToServer("[GAMERIST] CATASTROPHIC FAILURE, SERVER KILLED, ERROR %d", errno);
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i))
      KickClient(i)
  }
}

public Action:RestartSocket(Handle:timer)
{
  new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
  PrintToServer("[GAMERIST] Starting socket connect...");
  SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "127.0.0.1", 1996)
}

public OnClientAuthorized(client, const String:auth[])
{
  PrintToServer("[GAMERIST] Client %d has SteamID %s", client, auth);
  if(serverKilled != 0)
    KickClient(client, "Game canceled due to error %d", serverKilled);
  else
    KickClient(client, "You are not in the whitelist!");
}

public OnSocketConnected(Handle:socket, any:arg)
{
  SocketSend(socket, "Guten abend!\n");
  sharedSocket = socket;
}

public OnSocketReceive(Handle:socket, String:rdata[], const size, any:arg)
{
  PrintToServer(rdata);
}

public OnSocketDisconnected(Handle:socket, any:arg)
{
  CloseHandle(socket);
  CreateTimer(5.0, RestartSocket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg)
{
  if(serverKilled == 0)
  {
    PrintToServer("[GAMERIST] socket error %d (errno %d)", errorType, errorNum);
    CloseHandle(socket);
    CreateTimer(5.0, RestartSocket);
  }
}

TryToPushMessages()
{
  if((lastmid - cmid) > MQLIMIT)
    KillServer(ERROR_MESSAGES_NOT_BEING_RECEIVED);
  if(serverKilled == 0)
  {
    PrintToServer("Trying to push messages... There are %d messages to be acknowledged", lastmid - cmid);
    cmid = cmid + 1;
  }
}

PushMessage(String:message[])
{
  if(serverKilled == 0)
  {
    crIndex = (crIndex + 1) % MQLIMIT;
    lastmid = (lastmid + 1);
    Format(messagequeue[crIndex], MAX_MESSAGESIZE, message);
    PrintToServer("Pushing message %s", message);
    TryToPushMessages();
  }
}

