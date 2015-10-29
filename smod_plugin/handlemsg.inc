new String:messagequeue[MQLIMIT][MAX_MESSAGESIZE];
new clIndex        = 0; // The position of the last confirmed mid in the circular queue (left end)
new crIndex        = 0; // The position of the next mid to be added in the circular queue (right end, out of mqLIMIT)
new cmid           = 0; // Last confirmed mid (left end of queue, big number)
new nextmid        = 0; // The next mid to be added to the queue (right end of queue, next is this + 1)

DeclareError(errno)
{
  PushMessage("E%d", errno);
}

KillServer(errno)
{
  if(errno != ERROR_GRACEFUL_SHUTDOWN)
    DeclareError(errno);
  serverKilled = errno;
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i))
      KickClient(i, "Game ended with error %d", errno)
  }
}

public Action:HeartBeat(Handle:timer)
{
  PushMessage("H");
  CreateTimer(10.0, HeartBeat);
}

public Action:RestartSocket(Handle:timer)
{
  new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
  PrintToServer("[GAMERIST] Starting socket connect...");
  SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "127.0.0.1", 1996)
}


//
// Deal with handlr
//
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
  PrintToServer("Asking for %d", index);
  PushMessage(msg);
}

handleMsgBody(String:str[])
{
  switch(str[0])
  {
    case 'I': { 
      AskForNextPlayer(0); }
    case 'P': {
      PrintToChatAll("[GAMERIST] %s", str[1]); } // this works apparently :O
    case 'L': {
      new pointer = 1;
      new String:stopnow[2]; // '0' = no, '1' = yes, stop right now
      new String:index[4]; // plaintext
      new String:suid[24]; // Steam ID (18 characters, typically)
      new String:teamnumber[2]; // '2' = red, '3' = blue
      pointer = ReadStringUntil(str, stopnow, pointer, '|');
      pointer = ReadStringUntil(str, index, pointer, '|');
      new indexn = atoi(index, 10);
      pointer = ReadStringUntil(str, suid, pointer, '|');
      PrintToChatAll(suid);
      pointer = ReadStringUntil(str, teamnumber, pointer, '\0');
      
      Format(allowedids[indexn], MAXIDSIZE, suid);
      teamnumbers[indexn] = atoi(teamnumber, 10);
      PrintToServer("team number %d is %d", indexn, teamnumbers[indexn]);
      
      if(stopnow[0] == '0')
        AskForNextPlayer(atoi(index, 10) + 1);
    }
    case 'T': {
      KillServer(ERROR_SERVER_TIMED_OUT); }
    case 'A': // generic acknowledge
    {
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
  if(str[pointer] == 'A') {
  // received a new message
  // acknowledged our own message
    // GET THE IDENTIFIER FOR ACK
    PrintToChatAll(str);
    new String:msgn[8];
    pointer++;
    pointer = ReadStringUntil(str, msgn, pointer, '#');
    
    new stid = atoi(msgn, 10);
    if(stid != cmid) {
      KillServer(ERROR_MESSAGE_ACKS_OUT_OF_SYNC);
      return pointer + 1; }
    PrintToServer("Message %d acknowledged!", atoi(msgn, 10), pointer);
    clIndex = (clIndex + 1) % MQLIMIT;
    cmid++;
    
    // DEAL WITH THE MESSAGE BODY
    new String:msg[256];
    pointer = ReadStringUntil(str, msg, pointer, '\n');
    
    PrintToServer("Response was %s", msg);
    handleMsgBody(msg);
    waitingForResponse = 0; }
  return pointer;
}

public OnSocketReceive(Handle:socket, String:rdata[], const size, any:arg)
{
  new pointer = 0;
  while((pointer < strlen(rdata)) && serverKilled == 0) {
    pointer = handleMsg(rdata, pointer); }
  if(serverKilled == 0)
    TryToPushMessages();
}

public OnSocketDisconnected(Handle:socket, any:arg)
{
  PrintToServer("[GAMERIST] Socket has disconnected!");
  CloseHandle(socket);
  sharedSocket = Handle:0;
  CreateTimer(5.0, RestartSocket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg)
{
  if(serverKilled == 0) {
    PrintToServer("[GAMERIST] Socket has disconnected!");
    CloseHandle(socket);
    sharedSocket = Handle:0;
    CreateTimer(5.0, RestartSocket); }
}

TryToPushMessages()
{
  #if TEST_ALONE == 0
  if((nextmid - cmid) > MQLIMIT) {
    KillServer(ERROR_MESSAGES_NOT_BEING_RECEIVED); }
  if(waitingForResponse == 0 && serverKilled == 0 && killingServer == 0 && sharedSocket != Handle:0) {
    PrintToServer("Trying to push messages... There are %d messages to be acknowledged", nextmid - cmid);
    if(!waitingForResponse && cmid < nextmid) {
      new String:fstring[256];
      PrintToServer("Pushing message %d#%s\n", cmid, messagequeue[clIndex]);
      Format(fstring, 256, "%d;%d#%s\n", GetConVarInt(FindConVar("hostport")), cmid, messagequeue[clIndex]);
      SocketSend(sharedSocket, fstring);
      waitingForResponse = 1; } }
  #endif
  #if TEST_ALONE == 1
  ;
  #endif
}

PushMessage(String:message[], any:...)
{
  #if TEST_ALONE == 0
  if(serverKilled == 0) {
    if(nextmid > 4000000) {
      KillServer(ERROR_MESSAGE_LIMIT_REACHED);
      return 0; }
    VFormat(messagequeue[crIndex], MAX_MESSAGESIZE, message, 2);
    crIndex = (crIndex + 1) % MQLIMIT;
    nextmid = (nextmid + 1);
    TryToPushMessages();
  }
  return 1;
  #endif
  #if TEST_ALONE == 1
  ;
  #endif
}
