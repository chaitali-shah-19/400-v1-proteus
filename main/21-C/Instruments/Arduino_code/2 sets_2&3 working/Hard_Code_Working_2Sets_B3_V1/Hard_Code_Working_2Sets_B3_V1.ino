int lasers[] = {1,3,4,5,6,7,8,9,10,11,12,13};  // these are the output pins of the arduino boards to lasers
volatile byte state = LOW;
int last_state = 1;
unsigned long current_time;
unsigned long startMillis; 
byte set1[] = {8,10,11,12};
byte set2[] = {6,7,9,13};


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
digitalWrite(1, LOW);
digitalWrite(3, LOW);
digitalWrite(4, LOW);
digitalWrite(5, LOW);
digitalWrite(6, LOW);
digitalWrite(7, LOW);
digitalWrite(8, LOW);
digitalWrite(9, LOW);
digitalWrite(10, LOW);
digitalWrite(11, LOW);
digitalWrite(12, LOW);
digitalWrite(13, LOW);
startMillis = millis();
}


void loop() {
  
state = digitalRead(2);
if (state == HIGH) {
  if (last_state == 1) {
  for (int z = 0; z < sizeof(set1); z = z+1)
{
digitalWrite(set1[z], HIGH);
}
for (int z = 0; z < sizeof(set2); z = z+1) {
digitalWrite(set2[z], LOW);
}
}
else {
for (int z = 0; z < sizeof(set1); z = z+1)
{
digitalWrite(set1[z], LOW);
}
for (int z = 0; z < sizeof(set2); z = z+1) {
digitalWrite(set2[z], HIGH);
}}

current_time = millis();

if ((current_time - startMillis > 30000) && (last_state == 1)){
last_state = 0;
startMillis  = current_time;

}

else if ((current_time - startMillis > 30000) && (last_state == 0)) {
last_state = 1;
startMillis  = current_time;
}
}


else{
state = LOW;
startMillis = millis();
digitalWrite(1, LOW);
digitalWrite(3, LOW);
digitalWrite(4, LOW);
digitalWrite(5, LOW);
digitalWrite(6, LOW);
digitalWrite(7, LOW);
digitalWrite(8, LOW);
digitalWrite(9, LOW);
digitalWrite(10, LOW);
digitalWrite(11, LOW);
digitalWrite(12, LOW);
digitalWrite(13, LOW);
}}
