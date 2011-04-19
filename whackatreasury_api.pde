/**
Whack-A-Treasury
by Ari Lacenski for Etsy / 2011
*/

import simpleML.*;
import org.json.*;

/* 
  Request types:
  findAllGamesRequest: called to determine next game to run
  getGameRequest: called to get listings for current game
*/
HTMLRequest findAllGamesRequest, 
  getGameRequest, 
  updateGameListingsRequest, 
  updateGameFinishedRequest,
  listRequest;


// Game world variables
Game g;
int gameID = 0;
int lastGameID = 0;
 // Set up origins of rectangles on the board   
Coord[] origins = new Coord[9];
Coord curPos;
int curPosKey = 0;
int offset = 42;
int rectSize = 180;
int boardSize = 700;
int treasurySize = 3;

PImage loadingAnim;
float animAngle = 0;

// Label board
PFont font = createFont(PFont.list()[1], 32);
PFont bigFont = createFont(PFont.list()[1], 90);

Timer timer;
boolean endImageDisplay = false;
boolean hasRequestedNewGame = false;

String source = "";

void setup() {
  size(boardSize - 20, boardSize + 60);
  background(0);
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
  findAllGamesRequest = new HTMLRequest(this,"http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/games?status=ready&limit=1");
  
  timer = new Timer(2000); // display image in millis
  textFont(font);
}

void draw() {
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
  
  // if game state ID is set
  if (gameID > 0) {    
    if (gameID != lastGameID) {
      // if game is new
      // should this run during the endgame state or at init?
      g = new Game(gameID); // start that game up
      lastGameID = gameID;
      // reset background animations 
      animAngle = 0.0;
      // initialize new game
    } else { // still playing the same game
      // run the game
      
      getGameRequest = new HTMLRequest(this,"http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/games/" + g.gameID + "/?status=ready&includes=GameListings"); // 
      if (g.listingRequestSent) {
        if (g.isReady() == true) {
          // start showing images
          if (!timer.isFinished()) {
            renderImage(curPos);
          } else {
            if (g.listings.size() > 0) {
              if (g.successfulHits <= treasurySize) {
                updatePos();
                g.setNextListing(); // next curListing is ready
                
                println("Currently displaying " + g.curListing.getListingID() + " at " + (curPosKey+1));
                // todo: figure out how to end correctly
                timer.start();
              } else {
                // Game is over
                updateGameFinishedRequest = new HTMLRequest(this, "http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/games/" + g.gameID + "/?status=played&method=PUT");
                updateGameFinishedRequest.makeRequest(); // Send current game status 
                hasRequestedNewGame = false;
                // trigger new game from here
                
                gameID = -1; // set to -1 so that next draw loop will trigger new game start
                
                // eeee                
                background(255);
                textFont(bigFont);
                fill(255, 0, 0);
                text("a winner is you", 10, 120); // WIN
  
                animAngle += HALF_PI / 24.0;                  
                   translate(boardSize/2, boardSize/2);
                   rotate(animAngle);
                   translate(-258/2, -356/2);
                   image(loadingAnim, 0, 0);                                  
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
        g.listingRequestSent = true;
      }
    }
  } else { // if game id is not set 
      
    
    if (gameID == -1) { // special case for restarting
      drawWaitingState("Waiting for next game");      
      g = null; // explicitly null old Game object
      if (hasRequestedNewGame == false) {
        findAllGamesRequest.makeRequest();
        hasRequestedNewGame = true;
        updatePos();
      }
    } else if (gameID == 0) {
      drawWaitingState("Click to start");      
    }
  }
}

void mousePressed() {
  if (hasRequestedNewGame == false) {
    findAllGamesRequest.makeRequest();
    hasRequestedNewGame = true;
    println("requested");
    updatePos();
  } else {
    println("Already requested");
  }
}

void keyPressed() {
  // set up whack event
  // prepare hit request, but don't make it until hit
  String thisShit = "whacked"; // yo
  
  Integer k = (Integer)Character.digit(key, 10);
  if (g.hashCode() > 0) {
    if (k.equals((Integer)curPosKey+1)) {
      g.successfulHits++;
      updateGameListingsRequest = new HTMLRequest(this,"http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/games/" + g.gameID + "/listings/" + g.curListing.getListingID() + "/?status=" + thisShit + "&method=PUT");  
      updateGameListingsRequest.makeRequest(); 
    } 
    
    /*else {
      println("BOO!"); 
    }
    */
    g.totalHits++;
  }
}

// When a request is finished
void netEvent(HTMLRequest ml) {
  source = ml.readRawSource();  // Read the raw data
  println(source);
  //Parse response for type, get data out
  try {
    JSONObject response = new JSONObject(source);
    JSONArray results = new JSONArray();
    
    if (!(response.get("results").equals(null))) {
      results = response.getJSONArray("results");
    } else {
      drawWaitingState("Waiting for a game entry");
      println("Empty game response! Try again");
    }
    
    String method = (String)response.get("api_method");
    if (!(response.get("results").equals(null))) { // if there are results
      // set game state based on method called
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
        
        g.loadListings(gameListings);
      } else if (method.equals("updateGameListings")) { // send a hit
        // do nothing
      } else if (method.equals("updateGame")) {
      }
    }
  } catch (JSONException e) {
    e.printStackTrace();
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

void drawWaitingState(String message) {
  background(0);
  fill(105, 210, 231);
  text(message, offset, 720);
}
