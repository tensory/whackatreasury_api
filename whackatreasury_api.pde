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
String apiBase = "http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/";
Coord[] origins = new Coord[9];
Coord curPos;
int curPosKey = 0;
int offset = 42;
int rectSize = 180;
int boardSize = 700;
int treasurySize = 3;

PImage loadingAnim;
float animAngle = 0;

int internal = 0;

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
  background(255);
  loadingAnim = loadImage("extras/rokali.jpg");
  
  
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
  findAllGamesRequest = new HTMLRequest(this, apiBase + "games?status=ready&limit=1");
  
  timer = new Timer(2000); // display image in millis
  textFont(font);
  
  //frameRate(4);
}

// if game_id is not valid
void draw() {
  drawBoard();
  
  if (gameID <= 0) {
    if (gameID == -1) { // special case for restarting
      //drawWaitingState("Waiting for next game");      
      g = null; // explicitly null old Game object
      if (newGameRequested == false) {
        internal = 0;
        background(0, 0, 0);
        startNewGame();
        println("starting new game");
      }
    } else if (gameID == 0) {
      //drawWaitingState("Click to start");      
    }
  } else { // else if game id is valid
    // draw the game board here?
    if (gameID != lastGameID) { // if local gameID is different from previous game
      println("current game id " + gameID);
      println("last game id " + lastGameID);

      // initialize new Game
      g = new Game(gameID); // start that game up
      lastGameID = gameID;
      
      getGameRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/?status=ready&includes=GameListings"); 
    } else { // haven't requested new game yet
      // still on the same game
      // play through the game
      if (g.listingRequestSent) {
        //println(g.isReady() + " ready?");
        if (g.isReady() == true) {
          println("Game " + g.gameID + " is ready");
          
          // start showing images
          if (!timer.isFinished()) {
            renderImage(curPos);
          } else {
            if (g.listings.size() > 0) {
              println("Game has " + g.listings.size() + " images");
              if (g.successfulHits <= treasurySize) {
                updatePos();
                g.setNextListing(); // next curListing is ready
                
                println("Currently displaying " + g.curListing.getListingID() + " at " + (curPosKey+1));
                // todo: figure out how to end correctly
                timer.start();
              } else {
                // Game is over
                updateGameFinishedRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/?status=played&method=PUT");
                updateGameFinishedRequest.makeRequest(); // Send current game status 
                newGameRequested = false;
                // trigger new game from here
                
                gameID = -1; // set to -1 so that next draw loop will trigger new game start
                
                // eeee                
                background(255);
                textFont(bigFont);
                fill(255, 0, 0);
                text("a winner is you", 10, 120); // WIN
  /*
                animAngle += HALF_PI / 24.0;                  
                   translate(boardSize/2, boardSize/2);
                   rotate(animAngle);
                   translate(-258/2, -356/2);
                   image(loadingAnim, 0, 0);
*/
              }
            } else {
              // No more listings!
              // endgame state lives here
              // endgame: make API requests to start a game
              println("GAME IS OUT OF LISTINGS");
              println("START NEW GAME?");
              delay(10000);
              exit();
            }
          } // end timer loop
        }
      } else {
        getGameRequest.makeRequest();
        println("made request");
        g.listingRequestSent = true;
      }
    
    } // end playing same game
  } // end valid game id
} // end draw

// in response from simpleML, set gameRequested back to false
void netEvent(HTMLRequest ml) {
  source = ml.readRawSource();  // Read the raw data
  try {
    JSONObject response = new JSONObject(source);
    JSONArray results = new JSONArray();
    
    if (!(response.get("results").equals(null))) {
      // response!
      results = response.getJSONArray("results");
      println(results);
      String method = (String)response.get("api_method");
      if (method.equals("findAllGames")) { // get a game ID to initialize the new game
        //newGameRequested = false; // reset requested state to false
    
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
        JSONArray gameListings = null;
        try {
          gameListings = jsonGame.getJSONArray("GameListings");
          g.loadListings(gameListings); // load listings, which will set game state to ready
        } catch (Exception e) {
          if (gameListings.equals(null)) {
            println("argh");
            newGameRequested = false;
          }
            // if gameListings is null, this game is badly formed
            /*
            String error = "Game " + jsonGame.get("game_id") + " (" + jsonGame.get("player") + ") did not initialize. Requesting next game.";
            println(error);

            updateGameFinishedRequest = new HTMLRequest(this, apiBase + "games/" + jsonGame.get("game_id") + "/?status=played&method=PUT");
            updateGameFinishedRequest.makeRequest(); // Send current game status
            gameID = -1;
            */
        }
      } else if (method.equals("updateGameListings")) { // send a hit
        // do nothing
      } else if (method.equals("updateGame")) {
      }
    } else { // no response
//      drawWaitingState("Waiting for a game entry");
      println("Empty game response! Try again");
      newGameRequested = false;
    }
  } catch (JSONException e) {
    e.printStackTrace();
  }
}

void drawWaitingState(String message) {
  println(message);
}

void mousePressed() {
  try {
    if (newGameRequested == false) {
      findAllGamesRequest.makeRequest();
      newGameRequested = true;
      println("requested");
      updatePos();  
    } else {
      println("Keep waiting for game...");
    }
  } catch (Exception e) { // this doesn't actually get caught here :(
    // if there's a connection error, reset everything
    newGameRequested = false;
  }
}

void renderImage(Coord pos) {
  int offsetX = (pos.x * 5 * offset) + offset;
  int offsetY = (pos.y * 5 * offset) + offset + 20;
  //println("Running at " + pos.x + ", " + pos.y);
  stroke(0, 100, 255);
  Listing current = g.curListing; 
  image(current.getImage(), offsetX, offsetY, rectSize, rectSize);
} 

void updatePos() {
  curPosKey = (int)random(0, 8);
  curPos = origins[curPosKey];
}

void startNewGame() {
  findAllGamesRequest.makeRequest();
  newGameRequested = true;
  updatePos();
}

void drawBoard() {
  // Fill background
  background(255);
  fill(255, 143, 0);
  text("Etsy Whack-A-Treasury!", offset, 45);
  // draw image target board
  
  for (int i = 0; i < 9; i++) {
    Coord coord = origins[i];
    int offsetX = (coord.x * 5 * offset) + offset;
    int offsetY = (coord.y * 5 * offset) + offset + 20;
    stroke(208, 211,179);
    fill(224,228,204);
    rect(offsetX, offsetY, rectSize, rectSize);
    fill(255, 182, 88);
    textFont(bigFont);
    text(i+1, offsetX + 60, offsetY + 120);
    
    textFont(font);
  }
}


void keyPressed() { // this will become serialEvent
  // set up whack event
  // prepare hit request, but don't make it until hit
  String thisShit = "whacked"; // yo
  
  Integer k = (Integer)Character.digit(key, 10);
  if (g.hashCode() > 0) {
    if (k.equals((Integer)curPosKey+1)) {
      g.successfulHits++;
      if (g.successfulHits <= treasurySize) {
        updateGameListingsRequest = new HTMLRequest(this, apiBase + "/games/" + g.gameID + "/listings/" + g.curListing.getListingID() + "/?status=" + thisShit + "&method=PUT");  
        updateGameListingsRequest.makeRequest(); 
      }
    } 
    g.totalHits++;
  }
}
