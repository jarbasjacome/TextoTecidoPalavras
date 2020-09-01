/* Copyright (c) 2020 Jarbas Jácome and others. //<>//
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.  */

// Ctrl + v: cola texto da área de transferência (Clipboard)
// Ctrl + t: ajusta tamanho do texto sobre qual o mouse está posicionado.
// Ctrl + l: liga ou desliga as linhas de conexões (tecido)
// Ctrl + mouse wheel: aumenta ou diminui o tamanho do texto.
// Ctrl + delete: apaga todo texto.
// mouse wheel: sobe ou desce o texto.
// clique com botao esquerdo nas palavras seleciona ou desseleciona.
// clique com botao direito nas palavras adiciona para a lista palavras ignoradas e ocultadas.

//Importar bibliotecas para permitir ler o que foi colado com ctrl+C (clipboard)
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;

//Importa estruturas de dados não padrão do Processing.
import java.util.HashSet;
import java.util.TreeSet;
import java.util.Map;
import java.util.Arrays;

String texto = "";
boolean atualizarLeioute = true;

String quebraLinha = "\n\r\f";
String separadoresPalavras = "'\"?!:,.;/() \b"+quebraLinha;
String[] textoSeparadoPorPalavras;
Palavra[] listaDePalavras;
String[] IGNORAR = {};
HashSet<String> palavrasIgnoradas;
float tamTagMaisFreq = 0.05;
int tagMouseEmCima = -1;
int numPalavras = 0;
int ultimaTagVisivel = 0;
ArrayList<Integer> tagsSelecionadas;
//https://stackoverflow.com/questions/36645938/collection-that-uses-listiterator-and-is-a-unique-list
TreeSet<Caractere> palavrasSelecionadas;             //Utilizando primeiro caractere da palavra como âncora.
Caractere palavraSelecionadaAtual;
int brilhoConexoes = 90;
int brilhoConexoesSelecionada = 180;
int brilhoConexoesMouseClicando = 255;
int brilhoPalavraAtual = 255;
float grossuraLinhaConexao = 0.1;          //Em relação ao tamanho do caractere do texto;
float grossuraLinhaConexaoDestaque = 0.2;
int[] frequencias;
float tamTexto = 1;
float tamTextoManual = 1;
boolean ajustarParaExibirTextoCompleto = true;
float tamTags = 1;
int TAM_MAX_PALAVRA = 200;
float margemEsqTexto = 0.0;
float margemDirTexto = 0.5;
float margemSupTexto = 0.0;
float margemInfTexto = 1.0;
float margemEsqTags = margemDirTexto;
float margemDirTags = 1;
float margemSupTags = margemSupTexto;
float margemInfTags = margemInfTexto;
float larguraAreaTexto = margemDirTexto-margemEsqTexto;
float alturaAreaTexto = margemInfTexto-margemSupTexto;
Caractere[] caracteresInfo;
int numLinhas = 1;
PVector posTexto;
PVector novaPosTexto;
int posCursor;
float alturaTexto = 0;
int corInicialTags = 0;  //Vermelho
int corFinalTags = 213;  //Violeta 

PFont fonte500;
PFont fonte48;
PFont fonte8;
PFont fonte500b;
PFont fonte48b;
PFont fonte8b;

boolean ctrl = false;

int numConexoes = 0;
boolean desenhaTodasConexoesDasTagsVisiveis = false;
//Se ultrapassar esse numero o programa passa a exibir somente selecionadas
//por questões de performance.
int numMaximoConexoesParaExibir = 500;

int linhaAtual = 0;
float recuoPalavraSel = 0.2;

int instanteUltimoFrame = 0;
int duracaoAnimacaoMudaLinha = 300;
int instanteIniciouMudanca;

//[PROBLEMAS PX] Pq eu acho mais fácil declarar variaveis grandes do que criar uma classe??????
int duracaoStatusTecladoMouse = 600;
String statusControl = "";
String statusTecla = "";
String statusMouse = "";
int instanteSoltouTecladoMouse = 0;
float tamStatusTecladoMouse = 0.06;
boolean exibirStatusTecladoMouse = true;

void setup()
{
  size(800,600);
  //fullScreen();
  background (0);
  fonte500 = loadFont("Cantarell-Bold-500.vlw");
  fonte48 = loadFont("Cantarell-Bold-48.vlw");
  fonte8 = loadFont("Cantarell-Bold-8.vlw");
  fonte500b = loadFont("Cantarell-Bold-500.vlw");
  fonte48b = loadFont("Cantarell-Bold-48.vlw");
  fonte8b = loadFont("Cantarell-Bold-8.vlw");
  textFont (fonte500, tamTexto);
  textAlign(CENTER);

  limpaTudo();
}

void draw()
{
  background(0);
  colorMode(HSB);
  fill(255, 0, 255);
  larguraAreaTexto = margemDirTexto-margemEsqTexto;
  alturaAreaTexto = margemInfTexto-margemSupTexto;

  if (atualizarLeioute) {
    atualizarLeioute = !analisaTexto();
  }
  ajustaPosCaracteres();

  desenhaConexoes();
  desenhaTexto();
  desenhaTags();

  desenhaStatusTecladoMouse();
  instanteUltimoFrame = millis();
}

void desenhaStatusTecladoMouse() {
  String status = "";
  if (millis() - instanteSoltouTecladoMouse > duracaoStatusTecladoMouse) {
    exibirStatusTecladoMouse = false;
    statusControl = "";
    statusTecla = "";
    statusMouse = "";
  } else if (exibirStatusTecladoMouse) {
    if (statusControl.length() > 0) {
      status = statusControl;
    }
    if (statusMouse.length() > 0) {
      if (status.length() > 0) {
        status += " + ";
      }
      status += statusMouse;
    } else if (statusTecla.length() > 0) {
      if (status.length() > 0) {
        status += " + ";
      }
      status += statusTecla;
    }

    textSize(tamStatusTecladoMouse*height);
    rectMode(CENTER);
    fill(0, 200);
    rect(width/2.0, height/2.0-tamStatusTecladoMouse*height/2.0, 1.2*textWidth(status), 2*tamStatusTecladoMouse*height);
    textAlign(CENTER);
    fill(255);
    verificaFonte (tamStatusTecladoMouse, false);
    text(status, width/2.0, height/2.0);
  }
}

void limpaTudo() {
  texto = "";
  atualizarLeioute = true;
  posTexto = new PVector(margemDirTexto-margemEsqTexto, (margemInfTexto-margemSupTexto)/2);
  novaPosTexto = new PVector(posTexto.x, posTexto.y);

  palavrasIgnoradas = new HashSet<String>();
  for (int i=0; i<IGNORAR.length; i++) {
    palavrasIgnoradas.add(IGNORAR[i]);
  }

  palavrasSelecionadas = new TreeSet<Caractere>();

  desenhaTodasConexoesDasTagsVisiveis = true;

  tagsSelecionadas = new ArrayList<Integer>();

  ajustarParaExibirTextoCompleto = true;
  tamTexto = 1;
}

void irParaLinhaDaProximaPalavraSel() {
  if (palavrasSelecionadas.size()>0) {
    if (palavraSelecionadaAtual == null) {
      palavraSelecionadaAtual = palavrasSelecionadas.first();
      irParaLinha(palavraSelecionadaAtual.linha-int(recuoPalavraSel/(float)tamTexto));
    } else {
      Caractere proximaPalSel = palavrasSelecionadas.higher(palavraSelecionadaAtual);
      if (proximaPalSel != null) {
        irParaLinha(proximaPalSel.linha-int(recuoPalavraSel/(float)tamTexto));
        palavraSelecionadaAtual = proximaPalSel;
      }
    }
  }
}

void irParaLinhaDaPalavraSelAnterior() {
  if (palavrasSelecionadas.size()>0) {
    if (palavraSelecionadaAtual == null) {
      palavraSelecionadaAtual = palavrasSelecionadas.first();
      irParaLinha(palavraSelecionadaAtual.linha-int(recuoPalavraSel/(float)tamTexto));
    } else {  
      Caractere proximaPalSel = palavrasSelecionadas.lower(palavraSelecionadaAtual);
      if (proximaPalSel != null) {
        irParaLinha(proximaPalSel.linha-int(recuoPalavraSel/(float)tamTexto));
        palavraSelecionadaAtual = proximaPalSel;
      }
    }
  }
}

void irParaLinha(int novaLinha) {
  if (novaLinha >= 0 && novaLinha < numLinhas) {
    float posicaoCorrigida = delimita(converteLinhaParaPosTexto (novaLinha), 
      convertePosBarraRolagemParaPosTexto (1), 
      convertePosBarraRolagemParaPosTexto (0)); 
    if (novaPosTexto.y != posicaoCorrigida) {
      novaPosTexto.y = posicaoCorrigida;
      linhaAtual = convertePosTextoParaLinha(novaPosTexto.y);
    }
  }
}

float converteLinhaParaPosTexto (int linha) {
  return convertePosBarraRolagemParaPosTexto(0) - linha*tamTexto;
}
int convertePosTextoParaLinha (float posTex) {
  return floor(convertePosBarraRolagemParaLinha(convertePosTextoParaPosBarraRolagem(posTex)));
}
float convertePosBarraRolagemParaPosTexto (float posBarra) {
  return  map(posBarra, 1, 0, 1-tamTexto*(numLinhas+1)/2.0, tamTexto*(numLinhas+1)/2.0);
}
float convertePosTextoParaPosBarraRolagem (float posTexto) {
  return  map(posTexto, 1-tamTexto*(numLinhas+1)/2.0, tamTexto*(numLinhas+1)/2.0, 1, 0);
}
int convertePosBarraRolagemParaLinha(float posBarra) {
  return round(map(posBarra, 0, 1, 0, (numLinhas+1)-alturaAreaTexto/(float)tamTexto));
}

void verificaFonte (float tam, boolean negrito) {
  if (!negrito) {
    textFont (fonte500, tam*height);
    if (tam*height < 50) {
      textFont (fonte48, tam*height);
    } else if (tam*height < 10) {
      textFont (fonte8, tam*height);
    }
  } else {
    textFont (fonte500b, tam*height);
    if (tam*height < 50) {
      textFont (fonte48b, tam*height);
    } else if (tam*height < 10) {
      textFont (fonte8b, tam*height);
    }
  }
}


void keyPressed() {
  instanteSoltouTecladoMouse = millis();
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrl = true;
      statusControl = "CONTROL";
      exibirStatusTecladoMouse = true;
    }
  }
  if (ctrl) {
    if (keyCode == "v".charAt(0) || keyCode == "V".charAt(0)) {
      texto = texto + GetTextFromClipboard();
      statusTecla = "V";
      exibirStatusTecladoMouse = true;
      atualizarLeioute = true;
    } else if (keyCode == "t".charAt(0) || keyCode == "T".charAt(0)) {
      ajustarParaExibirTextoCompleto = ! ajustarParaExibirTextoCompleto;
      statusTecla = "T";
      exibirStatusTecladoMouse = true;
      atualizarLeioute = true;
    } else if (keyCode == DELETE) {
      statusTecla = "DELETE";
      exibirStatusTecladoMouse = true;
      limpaTudo();
    } else if (keyCode == "l".charAt(0) || keyCode == "L".charAt(0)) {
      statusTecla = "L";
      exibirStatusTecladoMouse = true;
      desenhaTodasConexoesDasTagsVisiveis = !desenhaTodasConexoesDasTagsVisiveis;
    }
  } else {
    if (key == BACKSPACE) {
      if (texto.length()>0) {
        texto = texto.substring(0, texto.length()-1);
        atualizarLeioute = true;
      }
    } else if (keyCode == LEFT) {
      statusTecla = "SETA ESQUERDA";
      exibirStatusTecladoMouse = true;
      irParaLinhaDaPalavraSelAnterior();
    } else if (keyCode == RIGHT) {
      statusTecla = "SETA DIREITA";
      exibirStatusTecladoMouse = true;
      irParaLinhaDaProximaPalavraSel();
    } else if (keyCode == UP) {
      statusTecla = "SETA CIMA";
      exibirStatusTecladoMouse = true;
      irParaLinha (linhaAtual-1);
    } else if (keyCode == DOWN) {
      statusTecla = "SETA BAIXO";
      exibirStatusTecladoMouse = true;
      irParaLinha (linhaAtual+1);
    } else if (key != CODED) {
      texto = texto + key;
      atualizarLeioute = true;
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrl = false;
    }
  }
} 

// Identifica e conta a frequência de palavras.
// Posiciona os caracteres na área de texto.
// Quando o texto não cabe na área de texto, reajusta o tamanho e interrompe (break no for) a análise.
// Essa interrupção (break no for) que dá o efeito de animação de preenchimento mais perceptível
// quando um texto grande é colado.
boolean analisaTexto() {
  // Retorna verdadeiro se conseguiu encaixar o texto inteiro na área sem precisar ajustar tamanho.
  boolean retorno = true;

  // Para auxiliar a contagem de freqüência das palavras, 
  // Carrega todas as palavras que aparecem no texto no array palavras
  // mantendo a ordem em que aparecem e as repetições.
  textoSeparadoPorPalavras = trim(splitTokens(texto, separadoresPalavras));

  // Guarda o índice da palavra em textoSeparadoPorPalavras que está sendo analisada
  // em cada iteração do for.
  int palavraAtual = 0;
  
  // Para auxiliar a contagem de freqüência das palavras, inicia estrutura palavrasComIndice
  // que guarda as palavras encontradas, sem repetí-las e guardando o índice correspondente no
  // array de palavras textoSeparadoPorPalavras.
  HashMap<String, Integer> palavrasComIndice = new HashMap<String, Integer>();

  // Número total de linhas.
  numLinhas = 0;

  // Inicia o array que guarda as posições dos caracteres em relação à tela (normalizada, entre 0 e 1).
  caracteresInfo = new Caractere[texto.length()];

  // Número total de conexoes.
  numConexoes = 0;

  // Inicia lista de palavras encontradas, sem repetição.
  listaDePalavras = new Palavra[texto.length()];
  
  numPalavras = 0;  // Número total de palavras sem contar as repetições.

  float larguraLinhaPx = 0;  // largura da linha na tela em número de pixels
  alturaTexto = tamTexto;  // altura que o texto realmente ocupa dentro da área.

  // Guarda a posição normalizada em relação à tela (entre 0 e 1)
  // em que deverá ser colocado o caractere atual de cada iteração do for.
  PVector posVarredura = new PVector(0, alturaTexto);  
  
  // Informa se o caractere da iteração anterior era um separador de palavras.
  boolean caracAnteriorEhSeparador = true;

  // Esse for percorre os caracteres da String texto.
  // Quando detecta que o texto ultrapassa a área de texto, esse laço é interrompido
  // e o texto é desenhado incompleto, recomeçando no próximo loop, já com o tamanho ajustado,
  // criando o efeito de animação da área de texto sendo preenchida, ao passar dos quadros.
  for (int i=0; i<texto.length(); i++) {
    //Checa se o caractere atual separa palavras:
    boolean caracAtualSeparaPalavras = false;
    if (match(""+texto.charAt(i), "["+separadoresPalavras+"]") != null) {
      caracAtualSeparaPalavras = true;
    }

    //Calcula qual deverá ser a posição do caractere atual em relação à tela.
    textSize(tamTexto*height); // define o tamanho do texto para textWidth() poder calcular
                               // a largura na tela do caractere atual.
    float larguraCaracPx = textWidth(texto.charAt(i));      //Largura que o caractere atual ocupará na tela em pixels
  
    //Se caractere atual quebra linha
    if (match(""+texto.charAt(i), "["+quebraLinha+"]") != null) {
      // Cria um novo caractere informando a posição do posVarredura, largura q o caractere ocupa,
      // se é separador de palavras, índice da palavra a qual esse caractere pertence (palavraAtual),
      // e a linha a qual pertence (numLinhas informa qual a linha atual)
      caracteresInfo[i] = new Caractere(new PVector(posVarredura.x, posVarredura.y), 
        larguraCaracPx, caracAtualSeparaPalavras, palavraAtual, numLinhas);

      posVarredura.y += tamTexto; // Incrementa na altura de uma linha o "cursor" que posiciona os caracteres.
      posVarredura.x = 0;         // Como ocorre uma quebra de linha a posição X é no canto esquerdo (=0); 
      larguraLinhaPx = 0;         // Como ocorre uma quebra de linha o contador da largura da linha deve ser zerado; 
      if (!adicionarLinha(alturaAreaTexto)) {    // Se adiciona linha e texto não cabe...
        if (ajustarParaExibirTextoCompleto) {    // Se estiver exibindo texto todo...
          retorno = false;                       // analisaTexto() retorna falso, pois precisa ser chamada de novo
          break;                                 // e para o for. Isso serve para fazer o efeito de animação do
                                                 // texto preenchendo.
        }
      }
    } else { //Se caractere atual não quebra linha
      caracteresInfo[i] = new Caractere(new PVector(posVarredura.x, posVarredura.y), 
        larguraCaracPx, caracAtualSeparaPalavras, palavraAtual, numLinhas);
      larguraLinhaPx += larguraCaracPx;        // incrementa o contador de largura da linha em pixels.
      posVarredura.x += larguraCaracPx/width;  // incrementa a posição x do "cursor" que posiciona os caracteres.
      if (larguraLinhaPx > larguraAreaTexto*width) {          //Linha ultrapasssou a largura da área do texto.
        if (!caracAtualSeparaPalavras) {       // se o caractere atual não é um separador de palavras 
          if (palavraAtual > 0) {
            if (textWidth(textoSeparadoPorPalavras[palavraAtual-1]) > larguraAreaTexto*width) {
              // Entra aqui se a própria palavra (não apenas a linha) ultrapassa a largura da área de texto.
              // calcula um novo tamanho de texto suficientemente pequeno para caber na largura essa palavra.
              tamTexto *= larguraAreaTexto*width/(float)larguraLinhaPx;
              retorno = false;               // analisaTexto() retorna falso, pois precisa ser chamada de novo
              break;                         // e para o for. Isso serve para fazer o efeito de animação do
                                             // texto preenchendo.
            } else { // a palavra sozinha não ultrapassa a largura da área de texto.
              posVarredura.y += tamTexto;    // passa o cursor para próxima linha.
              posVarredura.x = 0;            // posiciona o cursor no lado esquerdo.
              larguraLinhaPx = 0;            // reinicia a variável que conta a largura da linha.

              // aqui começa uma gambiarra feiosa para reposicionar todos os caracteres dessa palavra para
              // que ela seja movida para a próxima linha, no lado esquedo.
              int j=i;
              while (!caracteresInfo[j].ehSeparador) {        //Volta até achar o início da palavra.
                j--;
              }
              j++;                                           //Pula o separador antes do início da palavra.
              for (; j<=i; j++) {                            //Corrige as posições dos caracteres da palavra.
                caracteresInfo[j].pos.x = posVarredura.x;
                caracteresInfo[j].pos.y = posVarredura.y;
                caracteresInfo[j].linha++;
                posVarredura.x += caracteresInfo[j].larguraPx/width;
                larguraLinhaPx += caracteresInfo[j].larguraPx;
              }
              // Como ele moveu a palavra que ultrapassou a largura, para baixo, precisa adicionar uma nova linha
              // e reanalisar o texto, caso esteja no modo de ajuste automático para exibir texto completo.
              if (!adicionarLinha(alturaAreaTexto)) {
                if (ajustarParaExibirTextoCompleto) {
                  retorno = false;
                  break;
                }
              }
            }
          }
        }
      }
    }

    // Calcular frequencia das tags
    if (!caracAtualSeparaPalavras) {         //Caractere atual NÃO É separador de palavras.
      if (caracAnteriorEhSeparador) {
        int indicePalavra = palavraAtual;
        if (palavrasComIndice.get(textoSeparadoPorPalavras[indicePalavra])==null) {
          if (!palavrasIgnoradas.contains(textoSeparadoPorPalavras[indicePalavra])) {
            listaDePalavras[numPalavras] = new Palavra(indicePalavra, i);
            palavrasComIndice.put(textoSeparadoPorPalavras[indicePalavra], numPalavras);
            numPalavras++;
            numConexoes++;
          }
        } else {
          listaDePalavras[palavrasComIndice.get(textoSeparadoPorPalavras[indicePalavra])].adicionarAparicao(i);
          numConexoes++;
        }
        palavraAtual++;
      }
      caracAnteriorEhSeparador = false;     //Para próxima iteração do for.
    } else {
      caracAnteriorEhSeparador = true;      //Para próxima iteração do for.
    }
  }

  // Ordena tags por frequencia decrescente.
  Arrays.sort(listaDePalavras, 0, numPalavras);

  if (palavraSelecionadaAtual == null && palavrasSelecionadas.size() > 0) {
    palavraSelecionadaAtual = palavrasSelecionadas.first();
  }

  atualizarLeioute = false;

  return retorno;
}

// Incrementa a contagem de linhas de texto e se a altura final ultrapassar
// a altura da área de texto, reduz o tamanho da fonte e retorna false.
boolean adicionarLinha(float alturaAreaTexto) {
  boolean coubeNaAreaTexto = true;
  alturaTexto += tamTexto;            // ajusta a informação da altura ocupada pelo texto.
  numLinhas++;
  if (alturaTexto > alturaAreaTexto) {          //Se altura do texto ultrapassar o limite
    if (ajustarParaExibirTextoCompleto) {
//      tamTexto *= alturaAreaTexto/alturaTexto;
      tamTexto *= 0.9;                            // Reduz o tamanho da fonte em 90%
                                                  //[TODO] Essa redução determina a velocidade de animação
                                                  // do texto preenchendo a área de texto. Melhor fazer
                                                  // isso como um parâmetro de velocidade.
    }
    coubeNaAreaTexto = false;
  }
  return coubeNaAreaTexto;
}

void ajustaPosCaracteres() {
  if (posTexto.y != novaPosTexto.y) {
    posTexto.y += (novaPosTexto.y - posTexto.y)/(float)5;
    if (abs(novaPosTexto.y - posTexto.y) < 0.01) {
      posTexto.y = novaPosTexto.y;
    }
  }
  if (tamTexto*(numLinhas+1) < 1) {
    posTexto.y=novaPosTexto.y=0.5;
  } else {
    float posTextoCorrigida = delimita(novaPosTexto.y, 1-tamTexto*(numLinhas+1)/2.0, tamTexto*(numLinhas+1)/2.0);
    if (posTextoCorrigida != novaPosTexto.y) {
      novaPosTexto.y=posTextoCorrigida;
      linhaAtual = convertePosTextoParaLinha(novaPosTexto.y);
    }
  }
  // Calcula tamanho das tags baseada no tamanho fixo da tag mais frequente;
  if (listaDePalavras != null & listaDePalavras.length>0) {
    if (listaDePalavras[0] != null) {
      tamTags = tamTagMaisFreq/listaDePalavras[0].frequencia;
    }
  }
  textSize(tamTags*height);


  // Ajusta Tags
  PVector posVarredura = new PVector(0, 0);
  tagMouseEmCima = -1;
  ultimaTagVisivel = -1;
  float tamEspectroCores = 1;
  if (textoSeparadoPorPalavras.length*tamTags < 1) {             //Ajusta para diminuir tamanho do expectro caso seja menor q a tela.
    tamEspectroCores = textoSeparadoPorPalavras.length*tamTags;
    //posVarredura.y = 0.5 - tamEspectroCores/2.0;
  }
  for (int i=0; i<numPalavras; i++) {
    if (textoSeparadoPorPalavras != null) {
      if (listaDePalavras[i] != null) {
        if (textoSeparadoPorPalavras[listaDePalavras[i].palavra] != null) {
          float alturaTag = listaDePalavras[i].frequencia*tamTags;

          //posVarredura.y -= 0.5;
          listaDePalavras[i].matiz = int((corFinalTags-corInicialTags)*posVarredura.y/(float)tamEspectroCores);
          //posVarredura.y += 0.5;

          if (posVarredura.y <= 1) {
            ultimaTagVisivel = i;      //Candidata para ser a ultima tag visível.
          } else {
            break;
          }
          posVarredura.x = margemDirTexto;
          posVarredura.y += alturaTag;
          textSize(alturaTag*height);
          listaDePalavras[i].retangulo[0] = new PVector(margemEsqTags, posVarredura.y-alturaTag);
          listaDePalavras[i].retangulo[1] = new PVector(margemDirTags, posVarredura.y);
          if (mouseEmCima (listaDePalavras[i].retangulo[0].x*width, listaDePalavras[i].retangulo[0].y*height, 
            listaDePalavras[i].retangulo[1].x*width, listaDePalavras[i].retangulo[1].y*height)) {
            tagMouseEmCima = i;
            listaDePalavras[i].mouseEmCima = true;
            if (mousePressed) {
              listaDePalavras[i].mouseClicando = true;
            }
          } else {
            listaDePalavras[i].mouseEmCima = false;
            if (mousePressed) {
              listaDePalavras[i].mouseClicando = false;
            }
          }
          listaDePalavras[i].pos.x = posVarredura.x;
          listaDePalavras[i].pos.y = posVarredura.y;
        }
      }
    }
  }

  palavrasSelecionadas.clear();
  //Percorre tagsSelecionadas para adicionar as palavrasSelecionadas do texto.
  for (int j=0; j<tagsSelecionadas.size(); j++) {
    //adiciona as palavras do texto correspondente a essa tag em palavrasSelecionadas
    if (listaDePalavras[tagsSelecionadas.get(j)] != null) {
      for (int i=0; i<listaDePalavras[tagsSelecionadas.get(j)].aparicoesNoTexto.size(); i++) {
        palavrasSelecionadas.add(caracteresInfo[listaDePalavras[tagsSelecionadas.get(j)].aparicoesNoTexto.get(i)]);
      }
    }
  }
  if (numConexoes > numMaximoConexoesParaExibir) {
    desenhaTodasConexoesDasTagsVisiveis = false;
  }
}

void desenhaConexoes() {
  PVector p1 = new PVector(0, 0);
  PVector p2 = new PVector(0, 0);
  if (desenhaTodasConexoesDasTagsVisiveis == true) {
    for (int i=ultimaTagVisivel-1; i>=0; i--) {
      desenhaConexoesTag (i, p1, p2, brilhoConexoes, grossuraLinhaConexao);
    }
  }
  for (int i=tagsSelecionadas.size()-1; i>=0; i--) {
    desenhaConexoesTag (tagsSelecionadas.get(i), p1, p2, brilhoConexoesSelecionada, grossuraLinhaConexaoDestaque);
  }
  if (tagMouseEmCima>-1) {
    if (mousePressed) {
      desenhaConexoesTag (tagMouseEmCima, p1, p2, brilhoConexoesMouseClicando, grossuraLinhaConexaoDestaque);
    } else {
      desenhaConexoesTag (tagMouseEmCima, p1, p2, brilhoConexoesSelecionada, grossuraLinhaConexaoDestaque);
    }
  }
}

void desenhaConexoesTag (int i, PVector p1, PVector p2, int brilho, float grossura) {
  if (listaDePalavras == null || listaDePalavras[i] == null) {
    return;
  }
  p1.x = listaDePalavras[i].pos.x;
  int numAparicoes = listaDePalavras[i].aparicoesNoTexto.size();
  for (int j=0; j<numAparicoes; j++) {
    p1.y = listaDePalavras[i].pos.y-j*tamTags-tamTags/2.0;
    int caracIndice = listaDePalavras[i].aparicoesNoTexto.get(numAparicoes-1-j);
    p2.x = caracteresInfo[caracIndice].pos.x;
    p2.y = caracteresInfo[caracIndice].pos.y;
    textSize(tamTexto*height); //para posicionar linha no meio da palavra.
    float larguraPalavraPx = textWidth(textoSeparadoPorPalavras[listaDePalavras[i].palavra]);
    stroke(listaDePalavras[i].matiz, 255, brilho);
    strokeWeight(tamTexto*height*grossura);
    line(p1.x*width, p1.y*height, 
      p2.x*width+larguraPalavraPx/2, 
      (posTexto.y-tamTexto/2-tamTexto*(numLinhas+1)/2.0)*height+p2.y*height);

    float destaquePx = 0.2*tamTexto*height;
    float pos2Y = (posTexto.y-tamTexto-tamTexto*(numLinhas+1)/2.0+p2.y)*height-destaquePx;
    // não desenhar retangulo se tiver fora da tela.
    if (pos2Y <= height && pos2Y > -tamTexto*height) {
      rectMode(CORNER);
      noStroke();
      fill(listaDePalavras[i].matiz, 255, brilho);
      if (palavraSelecionadaAtual == caracteresInfo[caracIndice]) {
        fill(listaDePalavras[i].matiz, 255, brilhoPalavraAtual);
      }
      rect(p2.x*width-destaquePx, 
        pos2Y, 
        larguraPalavraPx+2*destaquePx, tamTexto*height+2*destaquePx);
    }
  }
}

void desenhaTexto() {
  for (int i=0; i<texto.length(); i++) {
    if (caracteresInfo[i] != null) {
      float posY = (posTexto.y-tamTexto*(numLinhas+1)/2.0)*height+caracteresInfo[i].pos.y*height;
      if (posY < height && posY > -tamTexto*height) {
        textSize(tamTexto*height);
        rectMode(CORNER);
        textAlign(LEFT);
        fill(255);
        verificaFonte (tamTexto, false);
        text(texto.charAt(i), caracteresInfo[i].pos.x*width, posY);
      }
    }
  }
}

void desenhaTags() {
  textSize(tamTags*height);
  if (ultimaTagVisivel > 0 && listaDePalavras[ultimaTagVisivel] == null) {
    ultimaTagVisivel--;
  }
  for (int i=0; i<=ultimaTagVisivel; i++) {
    colorMode(HSB);
    if (listaDePalavras[i].mouseEmCima || tagsSelecionadas.contains(i)) {
      fill(listaDePalavras[i].matiz, 255, brilhoConexoesSelecionada);
    } else {
      fill(listaDePalavras[i].matiz, 255, brilhoConexoes);
    }
    if (listaDePalavras[i].mouseClicando) {
      fill(listaDePalavras[i].matiz, 255, brilhoConexoesMouseClicando);
    }
    noStroke();
    rectMode(CORNERS);
    rect(listaDePalavras[i].retangulo[0].x*width, listaDePalavras[i].retangulo[0].y*height, 
      listaDePalavras[i].retangulo[1].x*width, listaDePalavras[i].retangulo[1].y*height);
  }
  for (int i=0; i<=ultimaTagVisivel; i++) {
    float alturaTag = listaDePalavras[i].frequencia*tamTags;
    textSize(alturaTag*height);
    colorMode(HSB);
    noStroke();
    rectMode(CENTER);
    verificaFonte(alturaTag, true);
    fill(255); 
    text(textoSeparadoPorPalavras[listaDePalavras[i].palavra]+" ("+listaDePalavras[i].frequencia+")", 
      listaDePalavras[i].pos.x*width, listaDePalavras[i].pos.y*height);
  }
}

boolean mouseEmCima ( float ret1x, float ret1y, float ret2x, float ret2y) {
  boolean retorno = false;
  if (mouseX > ret1x & mouseY > ret1y & mouseX < ret2x & mouseY < ret2y) {
    retorno = true;
  }
  return retorno;
}

void mouseReleased() {
  if (mouseButton == RIGHT) {
    if (tagMouseEmCima > -1) {
      palavrasIgnoradas.add(textoSeparadoPorPalavras[listaDePalavras[tagMouseEmCima].palavra]);
      if (tagsSelecionadas.contains(tagMouseEmCima)) {
        tagsSelecionadas.remove(Integer.valueOf(tagMouseEmCima));
      }
      atualizarLeioute = true;
    }
  } else if (mouseButton == LEFT) {
    if (tagMouseEmCima > -1) {
      if (!tagsSelecionadas.contains(tagMouseEmCima)) {
        tagsSelecionadas.add(tagMouseEmCima);
      } else {
        tagsSelecionadas.remove(Integer.valueOf(tagMouseEmCima));
      }
      //depois de adicionar ou remover palavras da seleção é necessário atualizar a palavra atual,
      //caso ela tenha sido removida, a função floor da NavigableSet (que TreeSet implementa) localiza
      //a anterior mais próxima.
      /*if (palavrasSelecionadas.size()>0) {
       if (palavraSelecionadaAtual != null) {
       palavraSelecionadaAtual = palavrasSelecionadas.floor(palavraSelecionadaAtual);
       } else {
       palavraSelecionadaAtual = palavrasSelecionadas.first();
       }
       }*/
      atualizarLeioute = true;
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  instanteSoltouTecladoMouse = millis();
  if (e > 0) {
    statusMouse = "MOUSE WHEEL BAIXO";
    exibirStatusTecladoMouse = true;
  } else {
    statusMouse = "MOUSE WHEEL CIMA";
    exibirStatusTecladoMouse = true;
  }
  if (ctrl) {
    ajustarParaExibirTextoCompleto = false;
    if (mouseX > margemDirTexto*width) {
      if (e > 0) {
        tamTagMaisFreq *= 0.9;
      } else {
        tamTagMaisFreq *= 1.1;
      }
    } else {
      if (e > 0) {
        tamTexto *= 0.9;
      } else {
        tamTexto *= 1.1;
      }
      posTexto.y = novaPosTexto.y = converteLinhaParaPosTexto(linhaAtual);
    }
    atualizarLeioute = true;
  } else {
    if (mouseX > margemDirTexto*width) {
    } else if (tamTexto*(numLinhas+1) > 1) {
      //int numLinhasIncremento = floor(0.1*alturaAreaTexto/(float)tamTexto);
      if (e < 0) {
        //irParaLinha(linhaAtual-numLinhasIncremento);
        novaPosTexto.y += 0.1;
      } else if (e > 0) {
        //irParaLinha(linhaAtual+numLinhasIncremento);
        novaPosTexto.y -= 0.1;
      }
      //linhaAtual = convertePosTextoParaLinha(novaPosTexto.y);
      irParaLinha(convertePosTextoParaLinha(novaPosTexto.y));
    }
  }
}

float delimita (float valor, float piso, float teto) {
  float novoValor = valor;
  if (valor < piso) {
    novoValor = piso;
  } else if (valor > teto) {
    novoValor = teto;
  }
  return novoValor;
}

String GetTextFromClipboard () {
  String text = (String) GetFromClipboard(DataFlavor.stringFlavor);

  if (text==null) 
    return "";
  return text;
}

Object GetFromClipboard (DataFlavor flavor) {

  Clipboard clipboard = getJFrame(getSurface()).getToolkit().getSystemClipboard();

  Transferable contents = clipboard.getContents(null);
  Object object = null; // the potential result 

  if (contents != null && contents.isDataFlavorSupported(flavor)) {
    try
    {
      object = contents.getTransferData(flavor);
    }

    catch (UnsupportedFlavorException e1) // Unlikely but we must catch it
    {
      e1.printStackTrace();
    }

    catch (java.io.IOException e2)
    {
      e2.printStackTrace() ;
    }
  }

  return object;
} 

static final javax.swing.JFrame getJFrame(final PSurface surf) {
  return
    (javax.swing.JFrame)
    ((processing.awt.PSurfaceAWT.SmoothCanvas)
    surf.getNative()).getFrame();
}
