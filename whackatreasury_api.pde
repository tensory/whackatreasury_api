/**
Whack-A-Treasury
by Ari Lacenski for Etsy / 2011
*/

import simpleML.*;
import org.json.*;

// Game world parameters
Game g;
int gameID = 0;
int lastGameID = 0;
boolean newGameRequested = false;
String source = "";
Coord[] origins = new Coord[9];
Coord curPos;
int curPosKey = 0;
int offset = 42;
int rectSize = 180;
int boardSize = 700;
int treasurySize = 3;

// Timing
Timer timer;
boolean endImageDisplay = false;

// Label board
PFont font = createFont(PFont.list()[1], 32);
PFont bigFont = createFont(PFont.list()[1], 90);

// Request types
HTMLRequest findAllGamesRequest, 
  getGameRequest, 
  updateGameListingsRequest, 
  updateGameFinishedRequest,
  listRequest;

void setup() {
  size(boardSize - 20, boardSize + 60);
  background(0);
  listRequest = new HTMLRequest(this,"http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/");
  listRequest.makeRequest();
  // set up target origins
  origins[0] = new Coord(0, 0);
  origins[1] = new Coord(1, 0);
  origins[2] = new Coord(2, 0);
  origins[3] = new Coord(0, 1);
  origins[4] = new Coord(1, 1);
  origins[5] = new Coord(2, 1);
  origins[6] = new Coord(0, 2);
  origins[7] = new Coord(1, 2);
  origins[8] = new Coord(2, 2);
  
  // set up request types
  findAllGamesRequest = new HTMLRequest(this,"http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/games?status=ready&limit=1");
  
  timer = new Timer(2000); // display image in millis
  textFont(font);
}

// if game_id is not valid
void draw() {
  if (gameID <= 0) {
    /*
    // wait for a new game to start
    if (gameID == 0) {
      drawWaitingState("Click to start");
    } else if (gameID == -1) {
      // game has been invalidated already
      // request new game
      // indicate that game has been requested
      newGameRequested = true;
      
    }
    */
  } else {
    if (gameID != lastGameID) { // if game id is different from last game id
    // play the current game
      // if treasury size is reached in current game
        // set current game status to played
        // set current game id to invalid
        // destroy the object for the old game
    }
  }      
} // end draw()

// in response from simpleML, set gameRequested back to false
void netEvent(HTMLRequest ml) {
  source = ml.readRawSource();  // Read the raw data
  println(source);
  
  try {
    JSONObject response = new JSONObject(source);
    JSONArray results = new JSONArray();
    newGameRequested = false; // reset requested state to false
    
    if (!(response.get("results").equals(null))) {
      // response!
      results = response.getJSONArray("results");
      println(results);
      String method = "foo";
      //String method = (String)response.get("ApiMethod");
      if (method.equals("findAllGames")) { // get a game ID to initialize the new game
        // set game ID
        // required to start game
        JSONObject jsonGame = (JSONObject)results.get(0);
        String id = jsonGame.get("game_id").toString();
        gameID = Integer.parseInt(id);
      } else if (method.equals("getGame")) { // make listing ids available to the current Game
        /* 
          this is not a good way to do this 
          (should be in Game constructor), 
          but listings must be pulled from game environment to be handled with netEvent 
        */
        JSONObject jsonGame = (JSONObject)results.get(0);
        JSONArray gameListings = jsonGame.getJSONArray("GameListings");
        
        //g.loadListings(gameListings);
      } else if (method.equals("updateGameListings")) { // send a hit
        // do nothing
      } else if (method.equals("updateGame")) {
      }
      
      
    } else { // no response
      drawWaitingState("Waiting for a game entry");
      println("Empty game response! Try again");
    }
  } catch (JSONException e) {
    e.printStackTrace();
  }
}

void drawWaitingState(String message) {
  println(message);
}

void mousePressed() {
  if (newGameRequested == false) {
    findAllGamesRequest.makeRequest();
    newGameRequested = true;
    println("requested");
    updatePos();  
  } else {
    println("Already requested");
  }
}

void updatePos() {
  curPosKey = (int)random(0, 8);
  curPos = origins[curPosKey];
}

