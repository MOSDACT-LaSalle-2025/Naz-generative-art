// Naz — Kökten Uca Büyüyen Mercanlar + Sonradan Silinen Eski Dallar
// Basit: iki liste (active/finished), her dal kendi yol noktalarını saklar.

import java.util.ArrayList;

ArrayList<Branch> active   = new ArrayList<Branch>();
ArrayList<Branch> finished = new ArrayList<Branch>();
ArrayList<Branch> toAdd    = new ArrayList<Branch>();

// 10 tonluk kırmızı–turuncu palet
color[] coralPalette = {
  color(255, 69, 0),  color(255, 99, 71),  color(255,127, 80),
  color(255,140, 0),  color(255,160,122),  color(255, 69, 90),
  color(255, 80, 80), color(255,110, 70),  color(255,150, 50),
  color(220, 20, 60)
};

// hız: kare başına kaç adım? (1 = yavaş, 3-5 = daha hızlı)
int stepsPerFrame = 1;

// bitmiş dalların sahnede kalma süresi (frame): 600 ≈ 10 sn @60fps
int finishedLifespan = 300;

void setup() {
  size(800, 800);                 // settings() yok; ilk satır
  background(250);
  strokeCap(ROUND);

  // iki kök: sol-alt ve sağ-alt
  active.add(new Branch(40, height - 40, 10, randomPaletteColor()));
  active.add(new Branch(width - 40, height - 40, 10, randomPaletteColor()));
}

void draw() {
  background(250);

  // 1) bitmiş dalları çiz (azalan alfa ile), süreleri bitti ise kaldır
  for (int i = finished.size() - 1; i >= 0; i--) {
    Branch b = finished.get(i);
    b.fadeAndDraw();
    if (b.lifespan <= 0) finished.remove(i);
  }

  // 2) aktif dalları büyüt ve çiz
  for (int s = 0; s < stepsPerFrame; s++) {
    // tersten dön: güvenli silme
    for (int i = active.size() - 1; i >= 0; i--) {
      Branch b = active.get(i);

      // bir adım büyüt (kökten uca)
      Branch child = b.step();

      // dal bitti mi? → finished listesine taşı
      if (b.finished) {
        b.lifespan = finishedLifespan;
        finished.add(b);
        active.remove(i);
        // alttan yeni kök ekle
        toAdd.add(new Branch(random(20, width - 20), height - 20, 10, randomPaletteColor()));
      }

      // çocuk dal varsa, şimdi değil döngü sonunda ekle
      if (child != null) toAdd.add(child);
    }

    // toplanan yeni dalları ekle
    if (!toAdd.isEmpty()) { active.addAll(toAdd); toAdd.clear(); }
  }

  // her kare tüm aktif dalları tam opak çiz
  for (Branch b : active) b.drawFullPath(255);
}

// ----------------------------------------------------
// Yardımcılar

color randomPaletteColor() {
  return coralPalette[(int)random(coralPalette.length)];
}

// ----------------------------------------------------
// Dal sınıfı: yol noktalarını saklar, adım adım büyür, sonra solup kaybolur.

class Branch {
  ArrayList<PVector> pts = new ArrayList<PVector>();
  float step = 8;        // kıvrım miktarı kadar rastgele adım
  float w;               // kalınlık (incelir)
  color col;             // dal rengi (paletten)
  boolean finished = false;

  int lifespan = 0;      // sadece finished iken kullanılır (fade için)

  Branch(float sx, float sy, float thick, color c) {
    pts.add(new PVector(sx, sy));
    w   = thick;
    col = c;
  }

  // bir adım büyüt ve gerekirse yan dal döndür
  Branch step() {
    if (finished) return null;

    PVector p = pts.get(pts.size() - 1);
    float nx = p.x + random(-step, step);
    float ny = p.y + random(-step * 0.2, -step);  // yukarı önyargılı
    nx = constrain(nx, 0, width);
    ny = constrain(ny, 0, height);
    pts.add(new PVector(nx, ny));

    // incelme
    w = max(1.6, w * 0.992);

    // bitiş: inceldiyse veya tepeye yaklaştıysa
    if (w <= 1.6 || ny <= 60) finished = true;

    // küçük olasılıkla yan dal
    if (!finished && w > 2 && random(1) < 0.006) {
      Branch child = new Branch(nx, ny, w * 0.7, randomPaletteColor());
      child.step = this.step * 0.85;
      return child;
    }
    return null;
  }

  // tüm yolu verilen alfa ile çiz (aktif dallar için 255)
  void drawFullPath(int alpha) {
    stroke(col, alpha);
    strokeWeight(w);
    for (int i = 1; i < pts.size(); i++) {
      PVector a = pts.get(i - 1);
      PVector b = pts.get(i);
      line(a.x, a.y, b.x, b.y);
    }
  }

  // bitmiş dalı yavaşça soluklaştırıp çiz
  void fadeAndDraw() {
    float a = map(lifespan, 0, finishedLifespan, 0, 255);
    drawFullPath((int)a);
    lifespan--;  // zamanla kaybolsun
  }
}
