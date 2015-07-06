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

// Message format (square brackets not included, numbers are plain ASCII):
// hndlr -> A[decimal string]#\n = Acknowledged message number N
// hndlr <- A[decimal string]#\n = Acknowledged message number N

// the following messages are preceded by msgindex# and followed by \n
// hndlr <- I = Connection established
// hndlr <- L[index] = Ask for index
// hndlr -> L[stopnow|index|steamid1|team number] = add player to list(index, steamid, teamnumber, seperated by pipe, up to 32 characters)
// hndlr -> P[string] = Print this string to chat
// hndlr <- E[string] = Error with string, game finished STATE_FAILED
// hdnlr <- D = Game finished STATE_OVER
// hndlr <- DP[index|points] = Player with index, score
// hndlr <- DT[teamindex|points] = Team with index, score
// hndlr <- H = heartbeat

#define MQLIMIT 64 // total capacity of the message queue
#define MAX_MESSAGESIZE 256
#define IDLIMIT 34
#define MAXIDSIZE 32

#define ERROR_MESSAGES_NOT_BEING_RECEIVED 5 // MQLIMIT is reached!!
#define ERROR_MESSAGE_LIMIT_REACHED 6 // 4 million messages is too much!!
#define ERROR_MESSAGE_ACKS_OUT_OF_SYNC 7 // Wrong numbers!!

new String:allowedids[IDLIMIT][MAXIDSIZE]; // 1 string is 24 characters, null terminator included
new teamnumbers[IDLIMIT];

new String:messagequeue[MQLIMIT][MAX_MESSAGESIZE];
new clIndex        = 0; // The position of the last confirmed mid in the circular queue (left end)
new crIndex        = 0; // The position of the next mid to be added in the circular queue (right end, out of mqLIMIT)
new cmid           = 0; // Last confirmed mid (left end of queue, big number)
new nextmid        = 0; // The next mid to be added to the queue (right end of queue, next is this + 1)

new serverKilled   = 0;

new waitingForResponse = 0;

new communicationState = 0;

// states:
#define STATE_NODATA 0 // no data received!
#define STATE_GOTDATA 1 // data received! regular operation

new Handle:sharedSocket;

// Integer power
power(x, y) // wow
{
  assert y >= 0
  new r = 1
  for (new i = 0; i < y; i++)
  r *= x
  return r
}

// Char to byte
byte(chr)
{
  return chr - 48
}

// String to integer
atoi(String:numero[], base)
{
  new result = 0;
  new ilen   = strlen(numero);
  for(new i = 0; i < ilen; i++)
  {
    result += byte(numero[i]) * (power(base, ilen - i - 1));
  }
  return result;
}

public OnPluginStart()
{
  PrintToServer("[GAMERIST] Gamerist starting up...");
  
  CreateTimer(2.0, RestartSocket);
  
  GetInitialData();
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
  PrintToServer("[GAMERIST] SOCKET CONNECTED");
  waitingForResponse = 0;
  sharedSocket = socket;
  TryToPushMessages();
}

GetInitialData()
{
  PushMessage("I");
}

AskForNextPlayer(index)
{
  new String:msg[4];
  Format(msg, 4, "L%d", index);
  PushMessage(msg);
}

handleMsgBody(String:str[])
{
  switch(str[0])
  {
    case 'I':
    {
      AskForNextPlayer(0);
    }
    case 'P':
    {
      PrintToServer("[GAMERIST] %s", str[1]); // this works apparently :O
    }
    case 'L':
    {
      new pointer = 1;
      new String:stopnow[2]; // '0' = no, '1' = yes, stop right now
      new String:index[4]; // plaintext
      new String:suid[24]; // Steam ID (18 characters, typically)
      new String:teamnumber[2]; // '2' = red, '3' = blue
      pointer = ReadStringUntil(str, stopnow, pointer, '|');
      pointer = ReadStringUntil(str, index, pointer, '|');
      new indexn = atoi(index, 10)
      pointer = ReadStringUntil(str, suid, pointer, '|');
      PrintToServer(suid);
      pointer = ReadStringUntil(str, teamnumber, pointer, '\0');
      AskForNextPlayer(atoi(index, 10) + 1);
    }
  }
}

ReadStringUntil(String:source[], String:destination[], pointer, div)
{
  new next = 0;
  new sid  = 0;
  while(next == 0)
  {
    if(source[pointer] == div)
      next = 1;
    else
    {
      destination[sid] = source[pointer];
      sid++;
      pointer++;
    }
  }
  return pointer + 1;
}

handleMsg(String:str[], lpointer)
{
  new pointer = lpointer;
  if(str[pointer] == 'A')
  {
  // received a new message
  // acknowledged our own message
    // GET THE IDENTIFIER FOR ACK
    PrintToServer(str);
    new String:msgn[8];
    pointer++;
    pointer = ReadStringUntil(str, msgn, pointer, '#');
    
    PrintToServer(msgn);
    PrintToServer("%d", cmid);
    
    new stid = atoi(msgn, 10);
    if(stid != cmid)
    {
      // TODO KILL SERVER
      return pointer + 1;
    }
    PrintToServer("Message %d acknowledged!", atoi(msgn, 10), pointer);
    clIndex = (clIndex + 1) % MQLIMIT;
    cmid++;
    
    // DEAL WITH THE MESSAGE BODY
    new String:msg[256];
    pointer = ReadStringUntil(str, msg, pointer, '\n');
    
    PrintToServer("Response was %s", msg);
    handleMsgBody(msg);
    waitingForResponse = 0;
    return pointer;
  }
}

public OnSocketReceive(Handle:socket, String:rdata[], const size, any:arg)
{
  new pointer = 0;
  while((pointer < strlen(rdata)) && serverKilled == 0)
  {
    PrintToServer("%d out of %d", pointer, strlen(rdata));
    pointer = handleMsg(rdata, pointer);
  }
  TryToPushMessages();
}

public OnSocketDisconnected(Handle:socket, any:arg)
{
  PrintToServer("[GAMERIST] Socket has disconnected!");
  CloseHandle(socket);
  sharedSocket = 0;
  CreateTimer(5.0, RestartSocket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg)
{
  if(serverKilled == 0)
  {
    PrintToServer("[GAMERIST] Socket has disconnected!");
    CloseHandle(socket);
    sharedSocket = 0;
    CreateTimer(5.0, RestartSocket);
  }
}

TryToPushMessages()
{
  if((nextmid - cmid) > MQLIMIT) {
    KillServer(ERROR_MESSAGES_NOT_BEING_RECEIVED); }
    
  if(waitingForResponse == 0 && serverKilled == 0 && sharedSocket != 0)
  {
    PrintToServer("Trying to push messages... There are %d messages to be acknowledged", nextmid - cmid);
    if(!waitingForResponse && cmid < nextmid)
    {
      new String:fstring[256];
      PrintToServer("Pushing message %d#%s\n", cmid, messagequeue[clIndex]);
      Format(fstring, 256, "%d#%s\n", cmid, messagequeue[clIndex]);
      SocketSend(sharedSocket, fstring);
      waitingForResponse = 1;
    } 
  }
}

PushMessage(String:message[])
{
  if(serverKilled == 0)
  {
    if(nextmid > 4000000)
    {
      KillServer(ERROR_MESSAGE_LIMIT_REACHED);
      return 0;
    }
    Format(messagequeue[crIndex], MAX_MESSAGESIZE, message);
    crIndex = (crIndex + 1) % MQLIMIT;
    nextmid = (nextmid + 1);
    TryToPushMessages();
  }
}

