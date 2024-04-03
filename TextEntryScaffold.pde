import java.util.Arrays;
import java.util.Collections;
import java.util.Random;
import http.requests.*;
//import javax.xml.bind.DatatypeConverter; // For Base64 encoding
import org.apache.commons.codec.binary.Base64;
import java.io.*;
//import java.awt.image.BufferedImage;
//import javax.imageio.ImageIO;


String[] phrases; //contains all of the phrases
int totalTrialNum = 2; //the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; //the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; //a running total of the number of errors (when hitting next)
String currentPhrase = ""; //the current target phrase
String currentTyped = ""; //what the user has typed so far
final int DPIofYourDeviceScreen = 120; //you will need to look up the DPI or PPI of your device to make sure you get the right scale. Or play around with this value.
final float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
PImage watch;
PImage finger;

// Flag to check if the user is currently drawing
boolean isDrawing = false;
boolean isGesture = false;
boolean shouldClear = true;

// Last positions of the mouse, used to draw lines
float lastMouseX = -1;
float lastMouseY = -1;

boolean redrawStaticUI = true;
long lastClickTime = 0;


//You can modify anything in here. This is just a basic implementation.
void setup()
{
  //noCursor();
  watch = loadImage("watchhand3smaller.png");
  //finger = loadImage("pngeggSmaller.png"); //not using this
  phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases), new Random()); //randomize the order of the phrases with no seed
  //Collections.shuffle(Arrays.asList(phrases), new Random(100)); //randomize the order of the phrases with seed 100; same order every time, useful for testing
 
  orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device
  size(800, 800); //Sets the size of the app. You should modify this to your device's native size. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", 28)); //set the font to arial 24. Creating fonts is expensive, so make difference sizes once in setup, not draw
  noStroke(); //my code doesn't use any strokes
  
  redrawStaticUI = true;
}

//You can modify anything in here. This is just a basic implementation.
void draw()
{
  if (!isDrawing) {
    if (shouldClear) {
      clearBackgroundAndStaticUI();
      shouldClear = false;
    }
  }
  
  if (redrawStaticUI) {
    redrawStaticUI = false;
  }
  
  if (finishTime!=0)
  {
    fill(0);
    textAlign(CENTER);
    text("Trials complete!",400,200); //output
    text("Total time taken: " + (finishTime - startTime),400,220); //output
    text("Total letters entered: " + lettersEnteredTotal,400,240); //output
    text("Total letters expected: " + lettersExpectedTotal,400,260); //output
    text("Total errors entered: " + errorsTotal,400,280); //output
    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    text("Raw WPM: " + wpm,400,300); //output
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    text("Freebie errors: " + nf(freebieErrors,1,3),400,320); //output
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    text("Penalty: " + penalty,400,340);
    text("WPM w/ penalty: " + (wpm-penalty),400,360); //yes, minus, because higher WPM is better
    return;
  } else{
  
  
  
  }
  
  if (shouldClear){
    drawWatch(); //draw watch background
    fill(230, 230, 250);
    stroke(255);
    strokeWeight(1);
    rect(width/2-sizeOfInputArea/2, height/2-sizeOfInputArea/2, sizeOfInputArea, sizeOfInputArea); //input area should be 1" by 1"
    shouldClear = false;
    }
  

  else { // If trials are not complete
    if (shouldClear) {
      drawWatch(); // Redraw watch background
      fill(230, 230, 250);
      rect(width / 2 - sizeOfInputArea / 2, height / 2 - sizeOfInputArea / 2, sizeOfInputArea, sizeOfInputArea); // Input area should be 1" by 1"
      shouldClear = false;
    }

    if (startTime == 0 && !mousePressed) {
      fill(128);
      textAlign(CENTER);
      // Only display the "Click to start time!" message if trials haven't started
      text("Click to start time!", width / 2, height / 4); // Adjusted for visibility
    }

    if (startTime == 0 && mousePressed) {
      nextTrial(); // Start the trials!
    }

    if (startTime != 0) {
    //feel free to change the size and position of the target/entered phrases and next button 
    textAlign(LEFT); //align the text left
    fill(128);
    text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, 70, 50); //draw the trial count
    fill(128);
    text("Target:   " + currentPhrase, 70, 100); //draw the target string
    text("Entered:  " + currentTyped +"I", 70, 140); //draw what the user has entered thus far 
    }}
}

void clearBackgroundAndStaticUI() {
  background(255); // Clear the background
  drawWatch(); // Redraw the watch face
  // Redraw any other static UI components here (e.g., instructions, borders around the drawing area, etc.)
}

void mousePressed() {
  long clickTime = millis();
  
  // Adjusted input area calculations remain the same
  float inputAreaThirdWidth = sizeOfInputArea / 3;
  float inputAreaStartX = width / 2 - sizeOfInputArea / 2;
  float relativeMouseX = mouseX - inputAreaStartX;

  // Adjust the double-click detection threshold if needed, for example, to 500 milliseconds
  if (clickTime - lastClickTime < 500) { // Consider adjusting this threshold
    // Double click logic
    if (relativeMouseX > inputAreaThirdWidth && relativeMouseX < 2 * inputAreaThirdWidth) {
      // Disable drawing for double click action
      isDrawing = false;
      lastMouseX = -1;
      lastMouseY = -1;
      // Add your double-click handling logic here (e.g., saving the drawing)
      saveDrawing();
    }
  } else {
    // This block now handles single click logic more explicitly
    // Reset drawing states for a new action
    lastMouseX = -1;
    lastMouseY = -1;

    if (relativeMouseX < inputAreaThirdWidth) {
      // Left third of the input area for space
      currentTyped += " ";
      shouldClear = true;
    } else if (relativeMouseX > 2 * inputAreaThirdWidth) {
      // Right third of the input area for delete
      if (currentTyped.length() > 0) {
        currentTyped = currentTyped.substring(0, currentTyped.length() - 1);
        shouldClear = true;
      }
    } else {
      // Explicit condition to start drawing
      isDrawing = true;
    }
  }

  lastClickTime = clickTime;
}


void mouseDragged() {
  // Calculate the bounds of the watch area, assuming the watch image is centered
  float watchX = width / 2 - (sizeOfInputArea / 2);
  float watchY = height / 2 - (sizeOfInputArea / 2);
  float watchWidth = sizeOfInputArea;
  float watchHeight = sizeOfInputArea;
  

  // Check if the current mouse position is within the bounds of the watch area
  if (isDrawing && mouseX >= watchX && mouseX <= watchX + watchWidth && mouseY >= watchY && mouseY <= watchY + watchHeight) {
    stroke(0); // Set line color
    strokeWeight(10); // Set line thickness

    if (lastMouseX > -1 && lastMouseY > -1 && lastMouseX >= watchX && lastMouseX <= watchX + watchWidth && lastMouseY >= watchY && lastMouseY <= watchY + watchHeight) {
      
      line(lastMouseX, lastMouseY, mouseX, mouseY);
    }

    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
   
}


void mouseReleased() {
  isDrawing = false; // Ensure drawing is disabled when the mouse is released
  lastMouseX = -1; // Reset the last drawing positions to prevent unwanted lines
  lastMouseY = -1;
}

void nextTrial()
{
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime!=0 && finishTime==0) //in the middle of trials
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    System.out.println("Target phrase: " + currentPhrase); //output
    System.out.println("Phrase length: " + currentPhrase.length()); //output
    System.out.println("User typed: " + currentTyped); //output
    System.out.println("User typed length: " + currentTyped.length()); //output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + (millis()-lastTime)); //output
    System.out.println("Time taken since beginning: " + (millis()-startTime)); //output
    System.out.println("==================");
    lettersExpectedTotal+=currentPhrase.trim().length();
    lettersEnteredTotal+=currentTyped.trim().length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (currTrialNum == totalTrialNum-1) //check to see if experiment just finished
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime)); //output
    System.out.println("Total letters entered: " + lettersEnteredTotal); //output
    System.out.println("Total letters expected: " + lettersExpectedTotal); //output
    System.out.println("Total errors entered: " + errorsTotal); //output

    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    
    System.out.println("Raw WPM: " + wpm); //output
    System.out.println("Freebie errors: " + freebieErrors); //output
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    System.out.println("==================");

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime==0) //first trial starting now
  {
    System.out.println("Trials beginning! Starting timer..."); //output we're done
    startTime = millis(); //start the timer!
  } 
  else
    currTrialNum++; //increment trial number

  lastTime = millis(); //record the time of when this trial ended
  currentTyped = ""; //clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  //currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}

//void saveDrawing() {
//  float watchX = width / 2 - (sizeOfInputArea / 2);
//  float watchY = height / 2 - (sizeOfInputArea / 2);

//  PImage drawing = get(int(watchX), int(watchY), int(sizeOfInputArea), int(sizeOfInputArea));
  
//  byte[] imageBytes = pimageToJPEG(drawing);

//  // Use Apache Commons Codec for Base64 encoding
//  byte[] encoded = Base64.encodeBase64(imageBytes);
//  String encodedImage = new String(encoded);

//  // Now send the encoded image as part of a POST request
//  sendEncodedImage(encodedImage);
//}

//byte[] pimageToJPEG(PImage img) {
//  // Convert PImage to a byte array in JPEG format
//  ByteArrayOutputStream baos = new ByteArrayOutputStream();
//  BufferedImage bimg = (BufferedImage) img.getNative();
//  try {
//    ImageIO.write(bimg, "jpg", baos);
//  } catch (IOException e) {
//    e.printStackTrace();
//  }
//  return baos.toByteArray();
//}
void saveDrawing() {
  // Specify a path for the temporary file
  String tempImagePath = "temp_image.jpg";

  // Save the PImage drawing to the file system
  savePImageToFile(tempImagePath);

  // Convert the saved image file to a byte array
  byte[] imageBytes = fileToByteArray(tempImagePath);

  // Encode the byte array to Base64
  byte[] encoded = Base64.encodeBase64(imageBytes);
  String encodedImage = new String(encoded);

  // Now send the encoded image as part of a POST request
  sendEncodedImage(encodedImage);

  // Optionally, delete the temporary file to clean up
  deleteTempFile(tempImagePath);
}

void savePImageToFile(String filename) {
  // Obtain the PImage from the drawing area
  PImage drawing = get(int(width / 2 - sizeOfInputArea / 2), int(height / 2 - sizeOfInputArea / 2), int(sizeOfInputArea), int(sizeOfInputArea));
  drawing.save(filename); // Save the PImage to a file
}

byte[] fileToByteArray(String filename) {
  ByteArrayOutputStream baos = new ByteArrayOutputStream();
  File file = new File(sketchPath(filename));
  try {
    FileInputStream fis = new FileInputStream(file);
    byte[] byteChunk = new byte[4096]; // Or some other size for the buffer
    int n;

    while ((n = fis.read(byteChunk)) > 0) {
      baos.write(byteChunk, 0, n);
    }
    fis.close();
  } catch (IOException e) {
    e.printStackTrace();
  }
  return baos.toByteArray();
}

void deleteTempFile(String filename) {
  File file = new File(sketchPath(filename));
  if (file.exists()) {
    file.delete();
  }
}

void sendEncodedImage(String encodedImage) {
  // Create a POST request to send the Base64-encoded image
  PostRequest post = new PostRequest("https://c393-174-181-61-232.ngrok-free.app/upload/");
  post.addData("image", encodedImage);
  post.send(); // Send the request
  
  // Print the response in the console
  String responseContent = post.getContent();
  
  JSONObject jsonResponse = JSONObject.parse(responseContent);
  if (jsonResponse != null) {
    // Extract the letter from the JSON response
    String letter = jsonResponse.getString("letter");
    System.out.println("Letter from server: " + letter);
    currentTyped += letter;
    
  } else {
    System.out.println("Failed to parse JSON response.");
  }
  
  shouldClear = true;
}


//probably shouldn't touch this - should be same for all teams.
void drawWatch()
{
  float watchscale = DPIofYourDeviceScreen/138.0; //normalizes the image size
  pushMatrix();
  translate(width/2, height/2);
  scale(watchscale);
  imageMode(CENTER);
  image(watch, 0, 0);
  popMatrix();
}

//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}
