/*========================================================================================================
// Poets GMR DataWrite processing file

//Description: This code serves to write out data collected by the Arduino and thrown to the serial monitor. 
		NB: Arduino Serial monitor must be closed for code to work.
		Also, ensure the right port on your computer is being accessed
		
// Date: 10/3/2016
//========================================================================================================
*/

import processing.serial.*;

Serial Port;  // Create object from Serial class
String val;     // Data received from the serial port
int lf = 10; // ASCII linefeed
PrintWriter output;
int fileIndex = 11;    //11 files

void setup() 
{
 String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
 Port = new Serial(this, portName, 19200);
 output = createWriter("GMRTest" + fileIndex + ".txt");
}

void draw()
{
   if ( Port.available() > 0)  {  // If data is available,
   
      val = Port.readStringUntil(lf);         // read it and store it in val
      
       //String value = Port.readString();
       if (val != null) 
            output.println( val );
       
   } 
   println(val); //print it out in the console
}

void keyPressed() {
    output.flush();  // Writes the remaining data to the file
    output.close();  // Finishes the file
    exit();  // Stops the program
}
