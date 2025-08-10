// Uber Rides → Generative Eyes (Naz için özel sürüm)
// Kolonlar:
// Date, Time, Booking ID, Booking Status, Customer ID, Vehicle Type,
// Pickup Location, Drop Location, Avg VTAT, Avg CTAT, Cancelled Rides by Customer,
// Reason for cancelling by Customer, Cancelled Rides by Driver, Driver Cancellation Reason,
// Incomplete Rides, Incomplete Rides Reason, Booking Value, Ride Distance,
// Driver Ratings, Customer Rating, Payment Method

final String FILE_NAME = "uber_rides.csv";
final int CANVAS_W = 1100;
final int CANVAS_H = 720;
final int MAX_EYES  = 700;    // performans için örnekleme
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
  background(12);
  noStroke();

  table = loadTable(FILE_NAME, "header");
  if (table == null) {
    println("CSV bulunamadı. Lütfen 'data/"+FILE_NAME+"' olarak ekleyin.");
    exit();
  }
  println("rows:", table.getRowCount(), "cols:", table.getColumnCount());

  // 1) özet istatistikler (Ride Distance & Driver Ratings)
  for (TableRow r : table.rows()) {
    float d = parseFloatSafe(r.getString("Ride Distance"));
    if (!Float.isNaN(d)) { minDist = min(minDist, d); maxDist = max(maxDist, d); }
    float rt = parseFloatSafe(r.getString("Driver Ratings"));
    if (!Float.isNaN(rt)) { minRate = min(minRate, rt); maxRate = max(maxRate, rt); }
  }
  if (!isFinite(minDist)) { minDist = 0; maxDist = 1; }
  if (!isFinite(minRate)) { minRate = 0; maxRate = 5; }

  // 2) örnekleme (eşit aralıklı)
  int total = table.getRowCount();
  int n = min(total, MAX_EYES);
  float step = (float)total / (float)n;

  for (int i = 0; i < n; i++) {
    TableRow r = table.getRow(floor(i * step));

    // ---- Boyut: Ride Distance
    float dist = parseFloatSafe(r.getString("Ride Distance"));
    if (Float.isNaN(dist)) dist = random(0.2, 1.0);
    float sizeEye = map(dist, minDist, maxDist, 10, 70);
    sizeEye = constrain(sizeEye, 10, 70);

    // ---- Renk: Vehicle Type
    String vehicle = safe(r.getString("Vehicle Type"));
    int irisHue = (abs(vehicle.hashCode()) % 360);
    // ---- Parlaklık: Driver Ratings (0–5 → 55–100)
    float rating = parseFloatSafe(r.getString("Driver Ratings"));
    if (Float.isNaN(rating)) rating = 3.0;
    float brightness = map(rating, minRate, maxRate, 55, 100);
    brightness = constrain(brightness, 40, 100);
    int irisCol = color(irisHue, 82, brightness);

    // ---- Konum: açı = Pickup Location hash, yarıçap = saate göre
    String pickup = safe(r.getString("Pickup Location"));
    float angle = radians(abs(pickup.hashCode()) % 360);
    int hour = hourFromTime(safe(r.getString("Time")));
    float radius = map(hour, 0, 23, 60, min(width, height)*0.48);

    // dairesel yerleşimi merkeze taşı
    float cx = width * 0.5;
    float cy = height * 0.5;
    // hafif jitter + hash’e bağlı mikro sapma
    float j = noise(i*0.137)*18;
    float x = cx + cos(angle) * radius + random(-j, j);
    float y = cy + sin(angle) * radius + random(-j, j);

    // ---- İnce vurgu: Payment Method -> kontur yoğunluğu
    String pay = safe(r.getString("Payment Method"));
    float strokeAlpha = 0;
    if (pay.length() > 0) {
      // aynı ödemede benzer kontur:
      strokeAlpha = 18 + (abs(pay.hashCode()) % 20);
    }

    // ---- Booking Status: iptal/eksik ise hafif soluklaştır
    String status = safe(r.getString("Booking Status")).toLowerCase();
    float alphaMul = 1.0;
    if (status.contains("cancel") || status.contains("incomplete")) {
      alphaMul = 0.6;
    }

    eyes.add(new Eye(x, y, sizeEye, irisCol, strokeAlpha, alphaMul));
  }

  println("Çizilecek göz:", eyes.size());
}

void draw() {
  // hafif iz bırakma efekti
  fill(12, 0, 0, 12);
  rect(0, 0, width, height);

  for (Eye e : eyes) {
    e.update(mouseX, mouseY);
    e.display();
  }

  // başlık
  fill(0, 0, 100, 85);
  textAlign(LEFT, TOP);
  text("Uber Generative Eyes — size: Ride Distance | hue: Vehicle Type | bright: Driver Ratings | pos: Pickup+Time",
       12, 12);
}

// ================= helpers =================
String safe(String s) { return s == null ? "" : s.trim(); }

boolean isFinite(float v) {
  return !(Float.isNaN(v) || Float.isInfinite(v));
}

float parseFloatSafe(String s) {
  if (s == null) return Float.NaN;
  s = s.replaceAll("[^0-9.\\-]", "");
  if (s.length() == 0) return Float.NaN;
  try { return Float.parseFloat(s); } catch (Exception e) { return Float.NaN; }
}

// Time -> hour (0–23). "12:39:20" / "12:39 PM" vb.
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
  } catch (Exception e) {
    return (int)random(24);
  }
}

// ================= Eye =================
class Eye {
  float x, y, size;
  int irisCol;
  float strokeAlpha;
  float alphaMul;
  float angle = 0;

  Eye(float x, float y, float size, int irisCol, float strokeAlpha, float alphaMul) {
    this.x = x; this.y = y; this.size = size;
    this.irisCol = irisCol; this.strokeAlpha = strokeAlpha;
    this.alphaMul = alphaMul;
  }

  void update(float mx, float my) {
    angle = atan2(my - y, mx - x);
  }

  void display() {
    pushMatrix();
    translate(x, y);

    // gövde (beyaz)
    noStroke();
    fill(0, 0, 100, 85*alphaMul);
    ellipse(0, 0, size, size);

    // isteğe bağlı kontur (Payment Method)
    if (strokeAlpha > 0) {
      stroke(0, 0, 100, strokeAlpha);
      noFill();
      ellipse(0, 0, size+3, size+3);
      noStroke();
    }

    // iris
    rotate(angle);
    fill(hue(irisCol), saturation(irisCol), brightness(irisCol), 100*alphaMul);
    ellipse(size/4.0, 0, size/2.0, size/2.0);

    popMatrix();
  }
}
