import processing.serial.*;

Serial porta;

// Buffers
int[] bufferExp1 = new int[900];      // Exp 1
int[] bufferTeorico = new int[900];   // Exp 2 (onda do buzzer)
int[] bufferMic = new int[900];       // Exp 2 (amplitude real)

// Variáveis gerais
float freqBuzzer = 0;
boolean congelado = false;

int menuEstado = 0; // 0: Principal | 1: 1º Expe | 2: 2º Exp
int selItem = 0;
String tipoOnda = "";

void setup() {
  size(1000, 750);
  porta = new Serial(this, Serial.list()[1], 115200); // comunicação com a serial USB
  porta.bufferUntil('\n');
}

void draw() {
  background(15);

  if (menuEstado == 0) {
    desenharMenuPrincipal();
  } 
  else if (menuEstado == 1) {
    desenharMenuOndas();
  } 
  else if (tipoOnda.equals("COMPARA")) {
    desenharExperimento2();
  } 
  else {
    desenharExperimento1();
  }
}

// MENUS

void desenharMenuPrincipal() {
  textAlign(CENTER, CENTER);
  fill(0, 255, 200);
  textSize(35);
  text("LABORATÓRIO INTERATIVO DE ONDAS", width/2, height/2 - 60);

  fill(255);
  textSize(28);
  text((selItem == 0) ? "> EXPERIMENTO 1: GERADOR DE ONDAS TEÓRICAS<"
                     : "EXPERIMENTO 1: GERADOR DE ONDAS TEÓRICAS",
       width/2, height/2);

  text((selItem == 1) ? "> EXPERIMENTO 2: CAPTAÇÃO DO SOM AMBIENTE <"
                     : "EXPERIMENTO 2: CAPTAÇÃO DO SOM AMBIENTE",
       width/2, height/2 + 50);
}

void desenharMenuOndas() {
  textAlign(CENTER, CENTER);
  fill(0, 200, 255);
  textSize(35);
  text("ESCOLHA A FORMA DE ONDA", width/2, height/2 - 100);

  fill(255);
  textSize(28);
  text((selItem == 0) ? "> QUADRADA <" : "QUADRADA", width/2, height/2 - 20);
  text((selItem == 1) ? "> TRIANGULAR <" : "TRIANGULAR", width/2, height/2 + 30);
  text((selItem == 2) ? "> SENOIDAL <" : "SENOIDAL", width/2, height/2 + 80);
}

//   EXPERIMENTO 1

void desenharExperimento1() {
  color verde = color(0, 255, 150);

  fill(verde);
  textSize(18);
  textAlign(LEFT);
  text("EXP 1: ONDA " + tipoOnda + " | FREQ: " + int(freqBuzzer) + " Hz", 50, 45);

  noFill();
  stroke(verde, 100);
  rect(50, 210, 900, 350, 10);

  stroke(verde);
  strokeWeight(3);
  beginShape();
  for (int i = 0; i < 900; i++) {
    float y = map(bufferExp1[i], 25, 230, 500, 300);
    vertex(50 + i, y);
  }
  endShape();

  stroke(verde, 50);
  line(50, 400, 950, 400);
}

// EXPERIMENTO 2

void desenharExperimento2() {
  color verde = color(0, 255, 150);
  color amarelo = color(255, 200, 0);

  // ----- Onda Teórica -----
  fill(verde);
  textSize(18);
  textAlign(LEFT);
  text("EXP 2: ONDA TEÓRICA x SOM REAL | FREQ: " + int(freqBuzzer) + " Hz", 50, 45);

  noFill();
  stroke(verde, 80);
  rect(50, 60, 900, 250, 10);

  stroke(verde);
  strokeWeight(2);
  beginShape();
  for (int i = 0; i < 900; i++) {
    float y = map(bufferTeorico[i], 25, 230, 260, 120);
    vertex(50 + i, y);
  }
  endShape();

  fill(verde);
  text("Onda Teórica (Buzzer)", 50, 90);

  fill(amarelo);
  text("Amplitude do som ambiente", 50, 350);

  noFill();
  stroke(amarelo, 80);
  rect(50, 370, 900, 300, 10);

// Corrigir posteriormente. Barras indo para baixo

  stroke(amarelo);
  strokeWeight(2);
  beginShape();
  for (int i = 0; i < 900; i++) {
   float altura = map(bufferMic[i], 0, 300, 0, 250);
   vertex(map(i, 0, 900, 50, 950), 650 - altura);

  }
  endShape();
}

// serial

void serialEvent(Serial p) {
  try {
    String m = trim(p.readStringUntil('\n'));
    if (m == null) return;

    String[] s = split(m, ',');

    if (s[1].equals("MENU_P")) {
      menuEstado = 0;
      selItem = int(s[2]);
    } 
    else if (s[1].equals("MENU_O")) {
      menuEstado = 1;
      selItem = int(s[2]);
    } 
    else if (s.length == 4 && !s[1].equals("COMPARA")) {
      // EXP 1
      menuEstado = 2;
      tipoOnda = s[1];
      freqBuzzer = float(s[2]);

      for (int i = 0; i < 899; i++)
        bufferExp1[i] = bufferExp1[i + 1];

      bufferExp1[899] = int(s[0]);
    } 
    else if (s[1].equals("COMPARA")) {
      // EXP 2
      menuEstado = 2;
      tipoOnda = "COMPARA";
      freqBuzzer = float(s[2]);

      // Onda teórica
      for (int i = 0; i < 899; i++)
        bufferTeorico[i] = bufferTeorico[i + 1];

      bufferTeorico[899] = int(s[0]);

      // Onda real (amplitude)
      for (int i = 0; i < 899; i++)
        bufferMic[i] = bufferMic[i + 1];

      bufferMic[899] = int(s[3]);
    }
  } 
  catch (Exception e) {}
}
