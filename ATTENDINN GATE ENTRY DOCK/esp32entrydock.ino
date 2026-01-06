#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <SPI.h>
#include <MFRC522.h>
#include <HTTPClient.h> // Required for Google Sheets logging

// --- WIFI & FIREBASE CONFIG ---
#define WIFI_SSID "CHATTERJEE VILLA 4G" 
#define WIFI_PASSWORD "Apurba@1234" 

// Database Secret and URL
#define DATABASE_SECRET "e3fYGDgexH084qA1t0CvBFEOaBCdgTHW52E1qcZZ" 
#define DATABASE_URL "attendinn-9847f-default-rtdb.firebaseio.com" 

// --- GOOGLE APPS SCRIPT CONFIG ---
// Paste your Web App URL here
const String GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbw-XLLeIvlBfLijLCzdZ2Y_af-VSaUoNDOjaAbWLp_8ikJxQBmtcNg2OCbEC6_d5wA/exec";

// --- PINS ---
#define SS_PIN 5 
#define RST_PIN 22 
#define GREEN_LED 12
#define RED_LED 14
#define BUZZER_PIN 26

MFRC522 mfrc522(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key; 

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// --- FEEDBACK FUNCTIONS ---

void triggerSuccess() {
  digitalWrite(GREEN_LED, HIGH);
  digitalWrite(BUZZER_PIN, HIGH);
  delay(500);
  digitalWrite(BUZZER_PIN, LOW);
  delay(1000);
  digitalWrite(GREEN_LED, LOW);
}

void triggerError() {
  digitalWrite(RED_LED, HIGH);
  for(int i=0; i<3; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(100);
    digitalWrite(BUZZER_PIN, LOW);
    delay(100);
  }
  digitalWrite(RED_LED, LOW);
}

// Function to log entry to Google Sheets
void logToGoogleSheet(String id, String role) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    // Prepare JSON payload
    String jsonPayload = "{\"type\":\"gate_entry\",\"uid\":\"" + id + "\",\"role\":\"" + role + "\"}";
    
    // Google Scripts require following redirects
    http.begin(GOOGLE_SCRIPT_URL);
    http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);
    
    int httpResponseCode = http.POST(jsonPayload);
    
    if (httpResponseCode > 0) {
      Serial.print("Google Sheets Log Success: ");
      Serial.println(httpResponseCode);
    } else {
      Serial.print("Google Sheets Log Error: ");
      Serial.println(http.errorToString(httpResponseCode).c_str());
    }
    http.end();
  }
}

// --- SETUP ---

void setup() {
  Serial.begin(115200);
  SPI.begin();
  mfrc522.PCD_Init();
  
  for (byte i = 0; i < 6; i++) key.keyByte[i] = 0xFF;

  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\nWiFi Connected!");

  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET; 

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("System Ready. Scan Card...");
}

// --- MAIN LOOP ---

void loop() {
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) return;

  byte block = 4; 
  byte buffer[18];
  byte size = sizeof(buffer);
  
  if (mfrc522.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, block, &key, &(mfrc522.uid)) != MFRC522::STATUS_OK) {
    Serial.println("Authentication failed");
    return;
  }

  if (mfrc522.MIFARE_Read(block, buffer, &size) == MFRC522::STATUS_OK) {
    String cardData = "";
    for (uint8_t i = 0; i < 16; i++) {
      if (isAlphaNumeric(buffer[i])) {
        cardData += (char)buffer[i];
      }
    }
    cardData.trim();

    if (cardData.length() > 0) {
      Serial.println("--------------------------");
      Serial.println("Card Data Read: " + cardData);
      
      String studentPath = "/users/students/" + cardData;
      String teacherPath = "/users/teachers/" + cardData;

      // 1. Search Students
      if (Firebase.RTDB.get(&fbdo, studentPath.c_str()) && fbdo.dataType() != "null") {
        Serial.println("✅ STUDENT FOUND: " + cardData);
        if (Firebase.RTDB.setBool(&fbdo, studentPath + "/at_door", true)) {
          logToGoogleSheet(cardData, "student"); // Log entry to sheet
          triggerSuccess();
        }
      } 
      // 2. Search Teachers
      else if (Firebase.RTDB.get(&fbdo, teacherPath.c_str()) && fbdo.dataType() != "null") {
        Serial.println("✅ TEACHER FOUND: " + cardData);
        logToGoogleSheet(cardData, "teacher"); // Log entry to sheet
        triggerSuccess();
      } 
      else {
        Serial.println("❌ UNKNOWN ID");
        triggerError();
      }
    }
  }

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
  delay(2000); 
}