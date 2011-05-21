/**
Whack-A-Treasury Game Shutdown
by Ari Lacenski for Etsy / 2011

Only run this script to delete ALL games from the current queue!
... does it create treasuries? Ask Justin
*/

import simpleML.*;
import org.json.*;

// Game world parameters
int gameID = 0;
String apiBase = "http://openapi.etsy.com/v2/makerfaire/";
String apiKey = "39u9vrafahzsw66cvvh4j85x";

// Request types
HTMLRequest findAllGamesRequest, 
  updateGameFinishedRequest;
  
void setup() {
  findAllGamesRequest = new HTMLRequest(this, apiBase + "games?status=ready&limit=25&api_key=" + apiKey);
}

void draw() {
 findAllGamesRequest.makeRequest();
}

// in response from simpleML, set gameRequested back to false
void netEvent(HTMLRequest ml) {
  String source = ml.readRawSource();  // Read the raw data
  try {
    JSONObject response = new JSONObject(source);
    JSONArray results = new JSONArray();
    
    if (!(response.get("results").equals(null))) {
      // response!
      results = response.getJSONArray("results");
      String method = (String)response.get("api_method");
      if (method.equals("findAllGames")) { // get a game ID to initialize the new game
        // loop through received games
        for (int i = 0; i < results.length(); i++) {
          JSONObject jsonGame = (JSONObject)results.get(i);
          String id = jsonGame.get("game_id").toString();
          updateGameFinishedRequest = new HTMLRequest(this, apiBase + "games/" + id + "/?status=finished&method=PUT&api_key=" + apiKey);
          updateGameFinishedRequest.makeRequest(); // Kill game
          println("Killed game " + id);
        }
      } else if (method.equals("updateGame")) {
        // nothing
      }
    } else {
      println("Game cache emptied!");
      exit();
    }      	      
  } catch (Exception e) {
    e.printStackTrace();
    exit();
  }
}
