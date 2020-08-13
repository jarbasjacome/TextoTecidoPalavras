/* Copyright (c) 2020 Jarbas Jácome and others. //<>//
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.  */

import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.util.*;
import java.util.Map;

String texto = "";
boolean atualizarLeioute = true;
String quebraLinha = "\n\r\f";
String separadoresPalavras = "'\"?!:,.;/() \b"+quebraLinha;
String[] palavras;
Tag[] tags;
String[] IGNORAR = {};
HashSet<String> palavrasIgnoradas;
float tamTagMaisFreq = 0.05;
int tagMouseEmCima = -1;
int numTags = 0;
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
int TAM_MAX_TEXTO = 10000;
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
int ultimoModificado = 0;
int corInicialTags = 0;  //Vermelho
int corFinalTags = 213;  //Violeta 

PFont fonte500;
PFont fonte48;
PFont fonte8;
PFont fonte500b;
PFont fonte48b;
PFont fonte8b;

boolean ctrl = false;

PVector[] conexoes;
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
  //size (960, 1080);
  //size (1920, 1080);
  //size (683, 768);
  size (1366, 768);
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
  ultimoModificado = 0;
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

boolean analisaTexto() {
  boolean retorno = true;
  palavras = trim(splitTokens(texto, separadoresPalavras));

  HashMap<String, Integer> tagsIndices = new HashMap<String, Integer>();

  if (texto.length() > TAM_MAX_TEXTO) {
    TAM_MAX_TEXTO = 2*texto.length();
  }
  numLinhas = 0;

  caracteresInfo = new Caractere[TAM_MAX_TEXTO];

  conexoes = new PVector[TAM_MAX_TEXTO];
  numConexoes = 0;

  tags = new Tag[TAM_MAX_TEXTO];
  numTags = 0;

  float larguraLinhaPx = 0;
  alturaTexto = tamTexto;
  PVector posVarredura = new PVector(0, alturaTexto);
  int palavraAtual = 0;
  boolean caracAnteriorEhSeparador = true;

  for (int i=0; i<texto.length(); i++) {
    ultimoModificado = i;

    //Checa se formou uma nova palavra:
    boolean caracAtualSeparaPalavras = false;
    if (match(""+texto.charAt(i), "["+separadoresPalavras+"]") != null) {
      caracAtualSeparaPalavras = true;
    }

    //Define qual deve ser a posição do caractere atual.
    textSize(tamTexto*height);
    float larguraPx = textWidth(texto.charAt(i));      //Largura que o caractere ocupará na tela em pixels
    if (match(""+texto.charAt(i), "["+quebraLinha+"]") != null) { //Se caractere atual quebra linha
      caracteresInfo[i] = new Caractere(new PVector(posVarredura.x, posVarredura.y), 
        larguraPx, caracAtualSeparaPalavras, palavraAtual, numLinhas);
      posVarredura.y += tamTexto;
      posVarredura.x = 0;
      larguraLinhaPx = 0;
      if (!adicionarLinha(alturaAreaTexto)) {
        if (ajustarParaExibirTextoCompleto) {
          retorno = false;
          break;
        }
      }
    } else {                                              //Se caractere atual não quebra linha
      caracteresInfo[i] = new Caractere(new PVector(posVarredura.x, posVarredura.y), 
        larguraPx, caracAtualSeparaPalavras, palavraAtual, numLinhas);
      larguraLinhaPx += larguraPx;
      posVarredura.x += larguraPx/width;
      if (larguraLinhaPx > larguraAreaTexto*width) {          //Palavra passsou do limite da area do texto.
        if (!caracAtualSeparaPalavras) {
          if (palavraAtual > 0) {
            if (textWidth(palavras[palavraAtual-1]) > larguraAreaTexto*width) {
              //if (ajustarParaExibirTextoCompleto) {
              tamTexto *= larguraAreaTexto*width/(float)larguraLinhaPx;
              retorno = false;
              break;
              //}
            } else {
              posVarredura.y += tamTexto;
              posVarredura.x = 0;
              larguraLinhaPx = 0;
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
        if (tagsIndices.get(palavras[indicePalavra])==null) {
          if (!palavrasIgnoradas.contains(palavras[indicePalavra])) {
            tags[numTags] = new Tag(indicePalavra, i);
            tagsIndices.put(palavras[indicePalavra], numTags);
            numTags++;
            numConexoes++;
          }
        } else {
          tags[tagsIndices.get(palavras[indicePalavra])].adicionarAparicao(i);
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
  Arrays.sort(tags, 0, numTags);

  if (palavraSelecionadaAtual == null && palavrasSelecionadas.size() > 0) {
    palavraSelecionadaAtual = palavrasSelecionadas.first();
  }

  atualizarLeioute = false;

  return retorno;
}

boolean adicionarLinha(float alturaAreaTexto) {
  boolean coubeNaAreaTexto = true;
  alturaTexto += tamTexto;
  numLinhas++;
  if (alturaTexto > alturaAreaTexto) {          //Se altura do texto ultrapassar o limite
    if (ajustarParaExibirTextoCompleto) {
      tamTexto *= alturaAreaTexto/alturaTexto;    //diminui o tamanho do texto.
      tamTexto *= 0.9;
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
  if (tags != null & tags[0] != null) {
    tamTags = tamTagMaisFreq/tags[0].frequencia;
  }
  textSize(tamTags*height);


  // Ajusta Tags
  PVector posVarredura = new PVector(0, 0);
  tagMouseEmCima = -1;
  ultimaTagVisivel = -1;
  float tamEspectroCores = 1;
  if (palavras.length*tamTags < 1) {             //Ajusta para diminuir tamanho do expectro caso seja menor q a tela.
    tamEspectroCores = palavras.length*tamTags;
    //posVarredura.y = 0.5 - tamEspectroCores/2.0;
  }
  for (int i=0; i<numTags; i++) {
    if (palavras != null) {
      if (tags[i] != null) {
        if (palavras[tags[i].palavra] != null) {
          float alturaTag = tags[i].frequencia*tamTags;

          //posVarredura.y -= 0.5;
          tags[i].matiz = int((corFinalTags-corInicialTags)*posVarredura.y/(float)tamEspectroCores);
          //posVarredura.y += 0.5;

          if (posVarredura.y <= 1) {
            ultimaTagVisivel = i;      //Candidata para ser a ultima tag visível.
          } else {
            break;
          }
          posVarredura.x = margemDirTexto;
          posVarredura.y += alturaTag;
          textSize(alturaTag*height);
          tags[i].retangulo[0] = new PVector(margemEsqTags, posVarredura.y-alturaTag);
          tags[i].retangulo[1] = new PVector(margemDirTags, posVarredura.y);
          if (mouseEmCima (tags[i].retangulo[0].x*width, tags[i].retangulo[0].y*height, 
            tags[i].retangulo[1].x*width, tags[i].retangulo[1].y*height)) {
            tagMouseEmCima = i;
            tags[i].mouseEmCima = true;
            if (mousePressed) {
              tags[i].mouseClicando = true;
            }
          } else {
            tags[i].mouseEmCima = false;
            if (mousePressed) {
              tags[i].mouseClicando = false;
            }
          }
          tags[i].pos.x = posVarredura.x;
          tags[i].pos.y = posVarredura.y;
        }
      }
    }
  }

  palavrasSelecionadas.clear();
  //Percorre tagsSelecionadas para adicionar as palavrasSelecionadas do texto.
  for (int j=0; j<tagsSelecionadas.size(); j++) {
    //adiciona as palavras do texto correspondente a essa tag em palavrasSelecionadas
    if (tags[tagsSelecionadas.get(j)] != null) {
      for (int i=0; i<tags[tagsSelecionadas.get(j)].aparicoesNoTexto.size(); i++) {
        palavrasSelecionadas.add(caracteresInfo[tags[tagsSelecionadas.get(j)].aparicoesNoTexto.get(i)]);
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
  if (tags == null || tags[i] == null) {
    return;
  }
  p1.x = tags[i].pos.x;
  int numAparicoes = tags[i].aparicoesNoTexto.size();
  for (int j=0; j<numAparicoes; j++) {
    p1.y = tags[i].pos.y-j*tamTags-tamTags/2.0;
    int caracIndice = tags[i].aparicoesNoTexto.get(numAparicoes-1-j);
    p2.x = caracteresInfo[caracIndice].pos.x;
    p2.y = caracteresInfo[caracIndice].pos.y;
    textSize(tamTexto*height); //para posicionar linha no meio da palavra.
    float larguraPalavraPx = textWidth(palavras[tags[i].palavra]);
    stroke(tags[i].matiz, 255, brilho);
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
      fill(tags[i].matiz, 255, brilho);
      if (palavraSelecionadaAtual == caracteresInfo[caracIndice]) {
        fill(tags[i].matiz, 255, brilhoPalavraAtual);
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
  if (ultimaTagVisivel > 0 && tags[ultimaTagVisivel] == null) {
    ultimaTagVisivel--;
  }
  for (int i=0; i<=ultimaTagVisivel; i++) {
    colorMode(HSB);
    if (tags[i].mouseEmCima || tagsSelecionadas.contains(i)) {
      fill(tags[i].matiz, 255, brilhoConexoesSelecionada);
    } else {
      fill(tags[i].matiz, 255, brilhoConexoes);
    }
    if (tags[i].mouseClicando) {
      fill(tags[i].matiz, 255, brilhoConexoesMouseClicando);
    }
    noStroke();
    rectMode(CORNERS);
    rect(tags[i].retangulo[0].x*width, tags[i].retangulo[0].y*height, 
      tags[i].retangulo[1].x*width, tags[i].retangulo[1].y*height);
  }
  for (int i=0; i<=ultimaTagVisivel; i++) {
    float alturaTag = tags[i].frequencia*tamTags;
    textSize(alturaTag*height);
    colorMode(HSB);
    noStroke();
    rectMode(CENTER);
    verificaFonte(alturaTag, true);
    fill(255); 
    text(palavras[tags[i].palavra]+" ("+tags[i].frequencia+")", 
      tags[i].pos.x*width, tags[i].pos.y*height);
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
      palavrasIgnoradas.add(palavras[tags[tagMouseEmCima].palavra]);
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
