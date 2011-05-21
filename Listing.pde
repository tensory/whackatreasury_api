class Listing {
  private int listingID = 0;
  private PImage img; // Prevent image from being overwritten
  boolean submitted = false;
  String imgPath = "/Volumes/TOFUBOMB/whack_a_treasury/";
  Listing (int id) {
    listingID = id;
    img = loadImage(imgPath + id + ".jpg");
  }
 
  PImage getImage() {
    return img;
  }
 
 int getListingID() {
    return listingID;
 } 
}


