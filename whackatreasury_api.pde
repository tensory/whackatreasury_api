/**
Whack-A-Treasury
by Ari Lacenski for Etsy / 2011
*/

import processing.serial.*;
import simpleML.*;
import org.json.*;

// Game world parameters
Game g;
int gameID = 0;
int lastGameID = 0;
boolean newGameRequested = false;
String source = "";
String apiBase = "http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/";
int numSquares = 6;
Coord[] origins = new Coord[numSquares];
Coord curPos;
int curPosKey = 0;
int offset = 34;
int imgSize = 400;
int rectSize = 150;
int boardX = 1024;
int boardY = 768;
int treasurySize = 2;
int deadGameCount = 0;

Serial myPort;

// Timing
Timer timer;

boolean killGameRequest = false;

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
  size(boardX, boardY);
  background(255);
  
  /*
  listRequest = new HTMLRequest(this,"http://api.jsheckler.ny4dev.etsy.com/v2/makerfaire/");
  listRequest.makeRequest();*/
  
  // set up target origins
  origins[0] = new Coord(0, 0);
  origins[1] = new Coord(1, 0);
  origins[2] = new Coord(2, 0);
  origins[3] = new Coord(0, 1);
  origins[4] = new Coord(1, 1);
  origins[5] = new Coord(2, 1);
  
  // set up request types
  findAllGamesRequest = new HTMLRequest(this, apiBase + "games?status=ready&limit=1");
  
  timer = new Timer(2000); // display image in millis
  myPort = new Serial(this, Serial.list()[0], 9600); // init serial port
  
  textFont(font);
  drawBoard();
}

void draw() {
  drawBoard();
  if (gameID > 0) {
    // Playable game
    if (gameID != lastGameID) {
      g = null;
      g = new Game(gameID);
      lastGameID = gameID;
 
     
       // playable loop starts here     
    } else { // Play through game since its ID exists
      println(g.gameID);
      gameID = g.gameID;
      getGameRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/?status=ready&includes=GameListings"); // 
      
      if (g.listingRequestSent) {
        if (g.isReady()) {
          if (!timer.isFinished()) {
            renderImage(curPos);
            drawSelectedPad(curPosKey);
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
                newGameRequested = false;
                gameID = -1; // set to -1 so that next draw loop will trigger new game start
              }
            } else {
              println("No listings");
            }
          } // end else case for timer
        } // end check for ready
      } else {
          getGameRequest.makeRequest();
//          println("made game request");
          g.listingRequestSent = true;
      }
    }
  } else {
    if (gameID == -1) {
      setup();
    }
    deadGameCount++;    
  }
  
  if (deadGameCount > 200) {
    println("Out of games to play!");
    exit();
  }
}


// in response from simpleML, set gameRequested back to false
void netEvent(HTMLRequest ml) {
  source = ml.readRawSource();  // Read the raw data
  try {
    JSONObject response = new JSONObject(source);
    JSONArray results = new JSONArray();
    
    if (!(response.get("results").equals(null))) {
      // response!
      results = response.getJSONArray("results");
      String method = (String)response.get("api_method");
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
        JSONArray gameListings = null;
          
        try {
          gameListings = jsonGame.getJSONArray("GameListings");
          g.loadListings(gameListings); // load listings, which will set game state to ready
         } catch (Exception e) {
          println("The last game loaded had null listings!");
          gameID = -1;
          if (killGameRequest == false) {
            updateGameFinishedRequest = new HTMLRequest(this, apiBase + "games/" + jsonGame.get("game_id") + "/?status=played&method=PUT");
            updateGameFinishedRequest.makeRequest(); // Send current game status
            killGameRequest = true;
          }
          deadGameCount++;  
        }
      } else if (method.equals("updateGameListings")) { // send a hit
        // do nothing
      } else if (method.equals("updateGame")) { // callback from killed game request 
        killGameRequest = false; // let us move on
      }
    } else { // no response
      // drawWaitingState("Waiting for a game entry");
      // println("Empty game response! Try again");
      deadGameCount++;
    }
  } catch (JSONException e) {
    e.printStackTrace();
  }
}

void mousePressed() {
  try {
    if (newGameRequested == false) {
      findAllGamesRequest.makeRequest();
      newGameRequested = true;
      println("Requested game" + newGameRequested);
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
  int offsetY = (pos.y * 5 * offset) + offset + 500;
    
  //println("Running at " + pos.x + ", " + pos.y);
  stroke(0, 100, 255);
  Listing current = g.curListing; 
  try {
    image(current.getImage(), ((boardX/2)-(imgSize/2)), (offset), imgSize, imgSize);
  } catch(Exception e) {
    println("Null pointer exception on image");
  }
} 

void updatePos() {
  curPosKey = (int)random(0, numSquares-1);
  curPos = origins[curPosKey];
}

void drawBoard() {
  // Fill background
  background(255);
  if (gameID == lastGameID || gameID == -1) { // prompt
    fill(255, 143, 0);
    text("Are you ready?", (boardX/2 - 120), 220);
  }
  // draw image target board
  
  stroke(255, 0,0);
  for (int i = 0; i < numSquares; i++) {
    Coord coord = origins[i];
    int offsetX = (coord.x * 5 * offset) + offset + (boardX/2 - 280); //offset from left of board
    int offsetY = (coord.y * 5 * offset) + offset + (boardY - 380); //offset from bottom of board
    stroke(208, 211,179);
    fill(224,228,204);
    rect(offsetX, offsetY, rectSize, rectSize);
    fill(255, 182, 88);
    textFont(bigFont);
    text(i+1, offsetX + 48, offsetY + 106);
    textFont(font);
  }
}

void drawSelectedPad(int index) {
    Coord coord = origins[index];
    int offsetX = (coord.x * 5 * offset) + offset + (boardX/2 - 280); //offset from left of board
    int offsetY = (coord.y * 5 * offset) + offset + (boardY - 380); //offset from bottom of board
    stroke(208, 211,179);
    fill(0,0,255);
    rect(offsetX, offsetY, rectSize, rectSize);
    fill(255, 255, 255);
    textFont(bigFont);
    text(index+1, offsetX + 48, offsetY + 106);
    
    textFont(font);

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
        updateGameListingsRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/listings/" + g.curListing.getListingID() + "/?status=" + thisShit + "&method=PUT");  
        updateGameListingsRequest.makeRequest(); 
      }
    } 
    g.totalHits++;
  }
}

void serialEvent(Serial p) { 
  String inString = p.readString(); 

  // set up whack event
  // prepare hit request, but don't make it until hit
  String thisShit = "whacked"; // yo
  
  Integer k = (Integer)inString;
  if (g.hashCode() > 0) {
    if (k.equals((Integer)curPosKey+1)) {
      g.successfulHits++;
      if (g.successfulHits <= treasurySize) {
        updateGameListingsRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/listings/" + g.curListing.getListingID() + "/?status=" + thisShit + "&method=PUT");  
        updateGameListingsRequest.makeRequest(); 
      }
    } 
    g.totalHits++;
  }
}
