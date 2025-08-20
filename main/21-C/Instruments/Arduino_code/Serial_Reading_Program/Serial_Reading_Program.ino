//Laser Board Software for Arduino
const byte numChars = 36;
char receivedChars[numChars];
boolean newData = false;
int lasers[] = {1,3,4,5,6,7,8,9,10,11,12,13};  // these are the output pins of the arduino boards to lasers
volatile byte state = LOW;
int stop_time = 45; // this is the time in seconds before everything shuts off for safety
unsigned long current_time=0;
unsigned long total_on_time = 0;
int clock_reset = 50; // set this time to change how ofter the clock will reset on the arduinos
unsigned long rest_time = 0;
unsigned long total_rest_time = 0;
int last_state = 0;
void setup() {
    Serial.begin(9600);

 pinMode(1, OUTPUT);
 pinMode(2, INPUT_PULLUP);
 pinMode(3, OUTPUT);
 pinMode(4, OUTPUT);
 pinMode(5, OUTPUT);
 pinMode(6, OUTPUT);
 pinMode(7, OUTPUT);
 pinMode(8, OUTPUT);
 pinMode(9, OUTPUT);
 pinMode(10, OUTPUT);
 pinMode(11, OUTPUT);
 pinMode(12, OUTPUT);
 pinMode(13, OUTPUT);
}
void loop() {
    recvWithStartEndMarkers();
    showNewData();
    int j = 0;
for (int x = 0; x < 100; x = x+1) {
state = digitalRead(2);
if (state == HIGH) {
j = j+1;
}
}
if (j>80){
state = HIGH;
if (last_state > 0){
  current_time = millis() - current_time;
  total_on_time = total_on_time + current_time;

} }
else{
state = LOW;
if (total_on_time > 0 &&  rest_time>0){
rest_time = millis()- rest_time;
total_rest_time = total_rest_time + rest_time;
}
}
if(total_rest_time>clock_reset){
total_on_time = 0;
total_rest_time = 0;
current_time = 0;
rest_time=0;
}


for (int z = 0; z < 13; z = z+1) {
if((receivedChars[z])=='1'){     // this only turns on select pins, and only when the trigger is on
digitalWrite(lasers[z], state);
}
else { digitalWrite(lasers[z], LOW); // otherwise pins are low
}}
current_time = millis();
rest_time = millis();
last_state = state;
}
// Misc. Functions
void recvWithStartEndMarkers() {
    static boolean recvInProgress = false;
    static byte ndx = 0;
    char startMarker = '<';
    char endMarker = '>';
    char rc;
 // if (Serial.available() > 0) {
    while (Serial.available() > 0 && newData == false) {
        rc = Serial.read();
        if (recvInProgress == true) {
            if (rc != endMarker) {
                receivedChars[ndx] = rc;
                ndx++;
                if (ndx >= numChars) {
                    ndx = numChars - 1;
                }
            }
            else {
                receivedChars[ndx] = '\0'; // terminate the string
                recvInProgress = false;
                ndx = 0;
                newData = true;
            }
        }
        else if (rc == startMarker) {
            recvInProgress = true;
        }
    }
}
void showNewData() {
    if (newData == true) {
        Serial.print("Laser Board Reads: ");
        Serial.println(receivedChars);
        newData = false;
    }
}
