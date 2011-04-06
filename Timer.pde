class Timer {
  int savedTime; //when timer started
  int totalTime; // how long timer should last
  boolean finished;
  Timer (int tempTotalTime){
    totalTime = tempTotalTime;
    finished=false;
  }
 
  //Starting the timer
  void start(){
   if(endImageDisplay == false) {
      savedTime = millis(); //when the timer starts it stores the current time in milliseconds
   }
  }
  void reset() {
    savedTime=0; 
  }
 
 boolean isFinished(){
   //Check how much time has passed
   int passedTime = millis() - savedTime;
   if(passedTime > totalTime){
     finished = true;
     return true;
   } else{
     finished = false;
     return false;
   }
 } 
}
