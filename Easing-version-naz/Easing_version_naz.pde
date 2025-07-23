/**
 * Easing. 
 * 
 * Move the mouse across the screen and the symbol will follow.  
 * Between drawing each frame of the animation, the program
 * calculates the difference between the position of the 
 * symbol and the cursor. If the distance is larger than
 * 1 pixel, the symbol moves part of the distance (0.05) from its
 * current position toward the cursor. 
 */
 
float x;
float y;
float easing = 0.05;

ArrayList<TrailDot> trail;

void setup() {
  size(640, 360);
  noStroke();
  trail = new ArrayList<TrailDot>();
}

void draw() {
  background(20);

  float targetX = mouseX;
  float dx = targetX - x;
  x += dx * easing;

  float targetY = mouseY;
  float dy = targetY - y;
  y += dy * easing;

  // Her frame yeni bir iz noktası oluştur
  trail.add(new TrailDot(x, y, millis()));

  for (int i = trail.size() - 1; i >= 0; i--) {
    TrailDot dot = trail.get(i);
    float age = (millis() - dot.timestamp) / 200.0;

    if (age > 10) {
      trail.remove(i);
    } else {
      float alpha = map(age, 0, 10, 255, 0);

      // Renk geçişi: Y konumuna göre renk tonu değişir
      color c = color(map(dot.y, 0, height, 0, 255), 150, 255, alpha);
      fill(c);

      // Rastgele şekil türü
      switch (dot.shapeType) {
        case 0:
          ellipse(dot.x, dot.y, 20, 20); // daire
          break;
        case 1:
          rectMode(CENTER);
          rect(dot.x, dot.y, 20, 20); // kare
          break;
        case 2:
          drawTriangle(dot.x, dot.y, 20); // üçgen
          break;
      }

      // Organik çizgiler (dallanma efekti)
      stroke(255, alpha * 0.5);
      strokeWeight(1);
      for (int j = 0; j < 3; j++) {
        float angle = noise(dot.x * 0.01 + j, dot.y * 0.01 + frameCount * 0.01) * TWO_PI * 2;
        float r = 10 + noise(j, frameCount * 0.01) * 10;
        float ex = dot.x + cos(angle) * r;
        float ey = dot.y + sin(angle) * r;
        line(dot.x, dot.y, ex, ey);
      }
      noStroke();
    }
  }

  // Kırmızı takip dairesi
  fill(255, 255, 255);
  ellipse(x, y, 20, 20);
}

// Üçgen çizme fonksiyonu
void drawTriangle(float cx, float cy, float size) {
  float h = size * sqrt(3) / 2;
  triangle(cx, cy - h / 2, cx - size / 2, cy + h / 2, cx + size / 2, cy + h / 2);
}

// İz noktası sınıfı
class TrailDot {
  float x, y;
  int timestamp;
  int shapeType;

  TrailDot(float x, float y, int timestamp) {
    this.x = x;
    this.y = y;
    this.timestamp = timestamp;
    this.shapeType = int(random(3));  // 0: daire, 1: kare, 2: üçgen
  }
}
