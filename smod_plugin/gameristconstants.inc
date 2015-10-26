#include <sourcemod>
#include <socket>
#include <sdktools>

public Plugin:myinfo =
{
  name = "Gamerist",
  author = "gert",
  description = "Video game reporter",
  version = "1.0",
  url = "http://www.gamerist"
};

// Message format (square brackets not included, numbers are plain ASCII):
// hndlr <- [decimal string]#[MSG]\n = Message N
// hndlr -> A[decimal string]#[MSG]\n = Acknowledged message number N

// the following messages are preceded by msgindex# and followed by \n
// hndlr <- I = Connection established
// hndlr <- L[index] = Ask for index
// hndlr -> L[stopnow|index|steamid1|team number] = add player to list(index, steamid, teamnumber, seperated by pipe, up to 32 characters)
// hndlr -> P[string] = Print this string to chat
// hndlr <- E[string] = Error with string, game finished STATE_FAILED
// hdnlr <- D = Game finished STATE_OVER
// hndlr <- DP[index|points] = Player with index, score
// hndlr <- DT[winningteam][losingteam] = Team with index, score; either DT23 or DT32
//
// hndlr <- H = heartbeat
// hndlr -> H = affirm
// hndlr -> T = server timed out!

#define MQLIMIT         64 // total capacity of the message queue
#define MAX_MESSAGESIZE 256
#define IDLIMIT         34
#define MAXIDSIZE       32

#define ERROR_GRACEFUL_SHUTDOWN           4
#define ERROR_MESSAGES_NOT_BEING_RECEIVED 5 // MQLIMIT is reached!!
#define ERROR_MESSAGE_LIMIT_REACHED       6 // 4 million messages is too much!!
#define ERROR_MESSAGE_ACKS_OUT_OF_SYNC    7 // Getting wrong numbers!!
#define ERROR_UNRECOGNIZED_MAP            8 // this should not happen at all
#define ERROR_SERVER_TIMED_OUT            9 // timed out to handlr
#define ERROR_NOT_ENOUGH_PLAYERS          10 // not enough players connected!
#define ERROR_VOTECANCEL                  11

#define MISSING_PLAYERS_ALLOWANCE 1

#define TEAM_RED 2
#define TEAM_BLU 3

#define TEST_ALONE       1

#define GAME_TF  1
#define GAME_CSS 2

new String:allowedids[IDLIMIT][MAXIDSIZE]; // 1 string is 24 characters, null terminator included
new teamnumbers[IDLIMIT];

new serverKilled   = 0;
new killingServer  = 0;

new waitingForResponse = 0;

new globalRoundsPlayed = 0;

new Handle:sharedSocket;

new gameStarted = 0;

