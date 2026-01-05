

// definição das potas
#define SW 13      
#define DT 12      
#define CLK 11     
#define BUZZER 10  
#define POT A0     
#define MICAN A5   

// Estados: 0=Menu Principal, 1=Menu de Escolha de Ondas, 2=Exp1, 3=Exp2
enum Estado { MENU_PRINCIPAL, MENU_ONDAS, EXP1, EXP2 };
Estado estadoAtual = MENU_PRINCIPAL;

// variáveis gerais
int opcaoMenuPrin = 0; 
int opcaoOnda = 0;     
int ultimoEstadoCLK;
bool ultimoEstadoSW = HIGH;
unsigned long tempoBotao = 0;
float anguloOnda = 0;
unsigned long ultimoEnvio = 0;

//Definição de saídas, entradas e serial
void setup() {
  Serial.begin(115200); 
  pinMode(SW, INPUT_PULLUP);
  pinMode(CLK, INPUT_PULLUP);
  pinMode(DT, INPUT_PULLUP);
  pinMode(BUZZER, OUTPUT);
  ultimoEstadoCLK = digitalRead(CLK);
}


//Loop baseado em funções e estados
void loop() {
  giroCLK();
  botaoSW();

  if (estadoAtual == MENU_PRINCIPAL) {
    noTone(BUZZER);
    Serial.println("0,MENU_P," + String(opcaoMenuPrin));
    delay(50);
  } 
  else if (estadoAtual == MENU_ONDAS) {
    noTone(BUZZER);
    Serial.println("0,MENU_O," + String(opcaoOnda));
    delay(50);
  }
  else if (estadoAtual == EXP1) {
    executarExp1();
  }
  else if (estadoAtual == EXP2) {
    executarExp2();
  }
}

// clique curto do botão do encoder para confirmar a seleção e clique longo para voltar ao menu principal
void botaoSW() {
  bool leituraSW = digitalRead(SW);
  if (leituraSW == LOW && ultimoEstadoSW == HIGH) tempoBotao = millis();
  
  if (leituraSW == HIGH && ultimoEstadoSW == LOW) {
    unsigned long duracao = millis() - tempoBotao;

    if (duracao > 1500) { 
      estadoAtual = MENU_PRINCIPAL; // Clique longo volta pro início
    } else { 
      if (estadoAtual == MENU_PRINCIPAL) {
        estadoAtual = (opcaoMenuPrin == 0) ? MENU_ONDAS : EXP2;
      } 
      else if (estadoAtual == MENU_ONDAS) {
        estadoAtual = EXP1;
      }
    }
    delay(200);
  }
  ultimoEstadoSW = leituraSW;
}


// Giro do encoder para alternar entre as opções do menu
// OBS: corrigir, pois em alguns momente inverte o sentido horário e anti-horário
void giroCLK() {
  int estadoCLK = digitalRead(CLK);

  if (estadoCLK != ultimoEstadoCLK) {

    // Se DT for diferente de CLK = sentido horário
    if (digitalRead(DT) == estadoCLK) {
      if (estadoAtual == MENU_PRINCIPAL)
        opcaoMenuPrin = (opcaoMenuPrin + 1) % 2;
      else if (estadoAtual == MENU_ONDAS)
        opcaoOnda = (opcaoOnda + 1) % 3;
    }
    // Sentido anti-horário
    else {
      if (estadoAtual == MENU_PRINCIPAL)
        opcaoMenuPrin = (opcaoMenuPrin - 1 + 2) % 2;
      else if (estadoAtual == MENU_ONDAS)
        opcaoOnda = (opcaoOnda - 1 + 3) % 3;
    }
  }

  ultimoEstadoCLK = estadoCLK;
}

// Experimento de geração de ondas a partir do potenciômetro
void executarExp1() {
  int freq = map(analogRead(POT), 0, 1023, 20, 500);
  tone(BUZZER, freq);
  if (millis() - ultimoEnvio >= 15) {
    ultimoEnvio = millis();
    float incremento = (2.0 * PI * freq) / 10000.0; //Atualiza fase da onda
    anguloOnda += incremento;
    if (anguloOnda >= TWO_PI) anguloOnda -= TWO_PI;
    
    //Cálculos para formação das ondas
    int v; String n;
    if (opcaoOnda == 0) { v = (sin(anguloOnda) >= 0) ? 230 : 25; n="QUADRADA"; }
    else if (opcaoOnda == 1) { v = (anguloOnda < PI) ? map(anguloOnda*1000, 0, 3141, 25, 230) : map(anguloOnda*1000, 3141, 6283, 230, 25); n="TRIANGULAR"; }
    else { v = (sin(anguloOnda) * 100) + 127; n="SENOIDAL"; }
    
  }
}

void executarExp2() {
  int freq = map(analogRead(POT), 0, 1023, 20, 800);
  tone(BUZZER, freq);

  float incremento = (2.0 * PI * freq) / 10000.0;
  anguloOnda += incremento;
  if (anguloOnda >= TWO_PI) anguloOnda -= TWO_PI;

  // Onda senoidal teórica (buzzer)
  int vTeorico = (sin(anguloOnda) * 100) + 127;

  // Captação da amplitude  do microfone
  unsigned int maxSample = 0;
  unsigned int minSample = 1024;
  unsigned long startMillis = millis();

  while (millis() - startMillis < 2) {
    unsigned int sample = analogRead(MICAN);
    if (sample > maxSample) maxSample = sample;
    if (sample < minSample) minSample = sample;
  }

  int amplitudeReal = maxSample - minSample;
 
}
