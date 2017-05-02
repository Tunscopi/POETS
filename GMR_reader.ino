
/*========================================================================================================
// Poets GMR sensor to current, I Arduino file

// Description: This code serves to read in Analog data from a GMR sensor and produce an output current
                which should correspond to the magnitude of the magnetic field detected by the GMR sensor.
                

// Date: 9/13/2016
//========================================================================================================
*/


int GMR_sensor0 = A0;    // input pin for the GMR sensor
int GMR_sensor1 = A1;    // input pin for the GMR sensor
float running_sum = 0.0, current = 0;
int no_data_points;
unsigned long time, ref_time, curr_ref_time;
int count = 0;
float atmospheric_constant = 0.0;

void setup() {
  Serial.begin(19200);
  ref_time =  millis();
}

void loop() {
  curr_ref_time = millis();
  no_data_points = 0.0;
  running_sum = 0.0;

  while (millis() - curr_ref_time < 1000) {
     running_sum += analogRead(GMR_sensor0) - analogRead(GMR_sensor1);
     no_data_points++;
  }

 current = running_sum/no_data_points;
 current = 0.397*current - 0.3689 + atmospheric_constant;
 Serial.print((millis()-ref_time)/1000);
 Serial.print("      ");
 Serial.println(current);

  //stall_function();  */
}

void stall_function() 
{
  int i = 0;
  while (i == 0) {
 
  }
}
