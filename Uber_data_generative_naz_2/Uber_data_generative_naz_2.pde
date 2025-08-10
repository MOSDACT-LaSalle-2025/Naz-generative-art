// Uber Rides → Data-driven animated generative eyes (no mouse)
// Columns expected (as in your screenshot):
// Date, Time, Booking ID, Booking Status, Customer ID, Vehicle Type,
// Pickup Location, Drop Location, Avg VTAT, Avg CTAT, Cancelled Rides by Customer,
// Reason for cancelling by Customer, Cancelled Rides by Driver, Driver Cancellation Reason,
// Incomplete Rides, Incomplete Rides Reason, Booking Value, Ride Distance,
// Driver Ratings, Customer Rating, Payment Method

final String FILE_NAME = "uber_rides.csv";
final int CANVAS_W = 1100;
final int CANVAS_H = 720;
final int MAX_EYES  = 650;   // performance cap
final int MARGIN    = 40;

Table table;
ArrayList<Eye> eyes = new ArrayList<Eye>();

float minDist =  Float.POSITIVE_INFINITY;
float maxDist =  Float.NEGATIVE_INFINITY;
float minRate =  Float.POSITIVE_INFINITY;
float maxRate =  Float.NEGATIVE_INFINITY;

void settings() {
  size(CANVAS_W, CANVAS_H);
  smooth(4);
}

void setup() {
  colorMode(HSB, 360, 100, 100, 100);
  background(10);
  noStroke();

  table = loadTable(FILE_NAME, "header");
  if (table == null) {
    println("CSV not found. Put it in data/"+FILE_NAME);
    exit();
  }
  println("rows:", table.getRowCount(), "cols:", table.getColumnCount());

  // Stats for scaling
  for (TableRow r : table.rows()) {
    float d  = parseFloatSafe(r.getString("Ride Distance"));
    if (!Float.isNaN(d)) { minDist = min(minDist, d); maxDist = max(maxDist, d); }
    float rt = parseFloatSafe(r.getString("Driver Ratings"));
    if (!Float.isNaN(rt)) { minRate = min(minRate, rt); maxRate = max(maxRate, rt); }
  }
  if (!isFinite(minDist)) { minDist = 0; maxDist = 1; }
  if (!isFinite(minRate)) { minRate = 0; maxRate = 5; }

  // Even sampling
  int total = table.getRowCount();
  int n = min(total, MAX_EYES);
  float step = (float)total / (float)n;

  float cx = width * 0.5;
  float cy = height * 0.5;

  for (int i = 0; i < n; i++) {
    TableRow r = table.getRow(floor(i * step));

    // --- size from Ride Distance
    float dist = parseFloatSafe(r.getString("Ride Distance"));
    if (Float.isNaN(dist)) dist = random(0.5, 2.0);
    float sizeEye = map(dist, minDist, maxDist, 12, 72);
    sizeEye = constrain(sizeEye, 12, 72);

    // --- color from Vehicle Type
    String vehicle = safe(r.getString("Vehicle Type"));
    int irisHue = (abs(vehicle.hashCode()) % 360);

    // --- brightness from Driver Ratings
    float rating = parseFloatSafe(r.getString("Driver Ratings"));
    if (Float.isNaN(rating)) rating = 3.0;
    float brightness = map(rating, minRate, maxRate, 55, 100);
    brightness = constrain(brightness, 45, 100);
    int irisCol = color(irisHue, 82, brightness);

    // --- ring radius base from hour
    int hour = hourFromTime(safe(r.getString("Time")));
    float baseRadius = map(hour, 0, 23, 70, min(width, height)*0.48);

    // --- path on a circle: from Pickup -> Drop (angles)
    String pickup = safe(r.getString("Pickup Location"));
    String drop   = safe(r.getString("Drop Location"));
    float aStart = radians(abs(pickup.hashCode()) % 360);
    float aEnd   = radians(abs(drop.hashCode())   % 360);

    // --- motion speed from distance (longer ride → faster)
    float speed = map(dist, minDist, maxDist, 0.05, 0.35); // cycles per second
    // --- wobble from rating (better rating → smoother, lower wobble)
    float wobbleAmp = map(5.0 - rating, 0, 5, 0.02, 0.18); // radians

    // --- subtle noise phase seeded per ride (Booking ID preferred)
    String seedKey = safe(r.getString("Booking ID"));
    if (seedKey.length() == 0) seedKey = pickup + drop;
    float seed = (abs(seedKey.hashCode()) % 10000) * 0.001f;

    // --- payment method → outline strength
    String pay = safe(r.getString("Payment Method"));
    float strokeAlpha = 0;
    if (pay.length() > 0) strokeAlpha = 16 + (abs(pay.hashCode()) % 18);

    // --- status → alpha
    String status = safe(r.getString("Booking Status")).toLowerCase();
    float alphaMul = 1.0;
    if (status.contains("cancel") || status.contains("incomplete")) alphaMul = 0.6;

    eyes.add(new Eye(cx, cy, baseRadius, aStart, aEnd, sizeEye, irisCol, speed, wobbleAmp, seed, strokeAlpha, alphaMul));
  }

  println("eyes:", eyes.size());
}

void draw() {
  // trailing background to get motion blur feel
  fill(10, 0, 0, 12);
  rect(0, 0, width, height);

  float t = millis() / 1000.0;
  for (Eye e : eyes) {
    e.update(t);
    e.display();
  }

  // overlay
  fill(0, 0, 100, 85);
  textAlign(LEFT, TOP);
  text("Data-driven eyes — position: Pickup→Drop on ring (hour-based radius),"
     + " size: Ride Distance, hue: Vehicle Type, bright: Driver Ratings,"
     + " motion speed: distance, wobble: rating", 12, 12);
}

// ================= helpers =================
String safe(String s) { return s == null ? "" : s.trim(); }

boolean isFinite(float v) { return !(Float.isNaN(v) || Float.isInfinite(v)); }

float parseFloatSafe(String s) {
  if (s == null) return Float.NaN;
  s = s.replaceAll("[^0-9.\\-]", "");
  if (s.length() == 0) return Float.NaN;
  try { return Float.parseFloat(s); } catch (Exception e) { return Float.NaN; }
}

// "12:39:20" or "12:39 PM" → 0..23
int hourFromTime(String t) {
  if (t.length() == 0) return (int)random(24);
  String T = t.toUpperCase();
  boolean isPM = T.contains("PM");
  T = T.replaceAll("[^0-9:]", "");
  try {
    String[] parts = split(T, ':');
    int h = constrain(Integer.parseInt(parts[0]), 0, 23);
    if (isPM && h < 12) h += 12;
    return constrain(h, 0, 23);
  } catch (Exception e) { return (int)random(24); }
}

// Angle utilities
float angleDiff(float a, float b) {
  float d = (b - a + PI) % (TWO_PI) - PI;
  return d < -PI ? d + TWO_PI : d;
}
float angleLerp(float a, float b, float t) {
  return a + angleDiff(a, b) * t;
}

// ================= Eye =================
class Eye {
  // center of ring
  float cx, cy;
  // base ring
  float baseR;
  // angular path
  float aStart, aEnd;
  // visuals
  float sizeEye;
  int irisCol;
  float speed;       // cycles per second
  float wobbleAmp;   // radians
  float seed;        // for noise phase
  float strokeAlpha;
  float alphaMul;

  // dynamic state
  float x, y;
  float lookAngle;   // iris rotation

  Eye(float cx, float cy, float baseR, float aStart, float aEnd,
      float sizeEye, int irisCol, float speed, float wobbleAmp, float seed,
      float strokeAlpha, float alphaMul) {
    this.cx=cx; this.cy=cy; this.baseR=baseR;
    this.aStart=aStart; this.aEnd=aEnd;
    this.sizeEye=sizeEye; this.irisCol=irisCol;
    this.speed=speed; this.wobbleAmp=wobbleAmp; this.seed=seed;
    this.strokeAlpha=strokeAlpha; this.alphaMul=alphaMul;
  }

  void update(float t) {
    // normalized progress 0..1 (loops)
    float s = fract(t * speed + seed);

    // if you want ping-pong instead of loop:
    // float s = abs(fract(t*speed + seed)*2.0 - 1.0);

    // position angle along path
    float posAng = angleLerp(aStart, aEnd, s);

    // radius wobble (subtle breathing) driven by noise/time
    float rWobble = (noise(seed*3.1f + t*0.25f) - 0.5f) * 30.0f;
    float radius = baseR + rWobble;

    x = cx + cos(posAng) * radius;
    y = cy + sin(posAng) * radius;

    // look direction: along motion + small wobble
    float ahead = angleDiff(aStart, aEnd) >= 0 ? 0.35 : -0.35; // slight lead
    lookAngle = posAng + ahead + sin((t + seed)* (0.8f + speed)) * wobbleAmp;
  }

  void display() {
    pushMatrix();
    translate(x, y);

    // sclera
    noStroke();
    fill(0, 0, 100, 85*alphaMul);
    ellipse(0, 0, sizeEye, sizeEye);

    // outline by payment method
    if (strokeAlpha > 0) {
      stroke(0, 0, 100, strokeAlpha);
      noFill();
      ellipse(0, 0, sizeEye+3, sizeEye+3);
      noStroke();
    }

    // iris
    rotate(lookAngle);
    fill(hue(irisCol), saturation(irisCol), brightness(irisCol), 100*alphaMul);
    ellipse(sizeEye/4.0, 0, sizeEye/2.0, sizeEye/2.0);

    popMatrix();
  }
}

// fract helper (0..1)
float fract(float v) {
  return v - floor(v);
}
