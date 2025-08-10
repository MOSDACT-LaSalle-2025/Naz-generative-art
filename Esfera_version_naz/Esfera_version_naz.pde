int cuantos = 20000;
Pelo[] lista;
float radio = 2000;
float rx = 0;
float ry = 0;

void setup() {
  size(1024, 768, P3D);
  radio = height / 3.5;

  lista = new Pelo[cuantos];
  for (int i = 0; i < lista.length; i++) {
    lista[i] = new Pelo();
  }
  noiseDetail(10);
}

void draw() {
  background(0);
  
  float rxp = (mouseX - (width / 2)) * 0.005;
  float ryp = (mouseY - (height / 2)) * 0.005;
  rx = rx * 0.9 + rxp * 0.1;
  ry = ry * 0.9 + ryp * 0.1;

  translate(width / 2, height / 2);
  rotateY(rx);
  rotateX(ry);
  fill(0);
  noStroke();
  sphere(radio);

  for (int i = 0; i < lista.length; i++) {
    lista[i].dibujar();
  }
}

class Pelo {
  float z, phi, baseLargo, theta;
  color currentColor, targetColor;
  float colorLerpAmt = 0; // 0..1 arası geçiş

  Pelo() {
    z = random(-radio, radio);
    phi = random(TWO_PI);
    baseLargo = random(0.005, 1.5); // <-- boy çeşitliliği
    theta = asin(z / radio);
    currentColor = randomColor();
    targetColor = randomColor();
  }

  void dibujar() {
    float off =  (noise(millis() * 0.00001, sin(phi)) - 0.5) * 0.1;
    float offb = (noise(millis() * 0.00001, sin(z) * 0.01) - 0.5) * 0.1;

    float thetaff = theta + off;
    float phff = phi + offb;

    float x = radio * cos(theta) * cos(phi);
    float y = radio * cos(theta) * sin(phi);
    float z = radio * sin(theta);

    float xo = radio * cos(thetaff) * cos(phff);
    float yo = radio * cos(thetaff) * sin(phff);
    float zo = radio * sin(thetaff);

    float t = millis() * 0.001;  // hız parametresi (küçük → yavaş)
    float largoNow = baseLargo + map(noise(t + phi), 0, 1, -0.001, 2);

    float xb = xo * largoNow;
    float yb = yo * largoNow;
    float zb = zo * largoNow;

    // Smooth color geçişi
    colorLerpAmt += 0.002;
    if (colorLerpAmt >= 1) {
      currentColor = targetColor;
      targetColor = randomColor();
      colorLerpAmt = 0;
    }
    color cNow = lerpColor(currentColor, targetColor, colorLerpAmt);

    strokeWeight(15);
    beginShape(LINES);
    stroke(0);
    vertex(x, y, z);
    stroke(cNow, 300); 
    vertex(xb, yb, zb);
    endShape();
  }


  color randomColor() {
    return color(random(360), 80 + random(100), 80 + random(100));
  }
}
