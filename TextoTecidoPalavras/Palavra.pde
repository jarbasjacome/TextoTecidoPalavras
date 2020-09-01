/* Copyright (c) 2020 Jarbas Jácome and others.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.  */

class Palavra implements Comparable {
  int palavra;
  int frequencia=0;
  IntList aparicoesNoTexto; //indices do primeiro caractere de cada aparicao dessa tag no texto.
  PVector pos;
  boolean mouseEmCima;
  PVector[] retangulo;
  int matiz;
  boolean mouseClicando;
  
  Palavra (int p, int indiceCaractere) {
    palavra = p;
    aparicoesNoTexto = new IntList();
    adicionarAparicao(indiceCaractere);
    retangulo = new PVector[2];
    mouseEmCima = false;
    mouseClicando = false;
    pos = new PVector(0,0);
  }
  
  void adicionarAparicao(int indiceCaractere) {
    aparicoesNoTexto.append(indiceCaractere);
    frequencia = aparicoesNoTexto.size();
  }

  int compareTo(Object o) {
    Palavra e = (Palavra)o;
    return e.frequencia-frequencia;
  }
}
