/* Copyright (c) 2020 Jarbas Jácome and others.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.  */

class Caractere implements Comparable  {
  float larguraPx;     //medida em pixels
  PVector pos;       //posição do centro do caracter em relação ao mundo
  boolean ehSeparador;
  int palavra;
  int linha;
  
  Caractere (PVector p, float l, boolean eh, int pal, int lin) {
    pos = p;
    larguraPx = l;
    ehSeparador = eh;
    palavra = pal;
    linha = lin;
  }
  
  int compareTo(Object o) {
    int retorno = 0;
    Caractere e = (Caractere) o;
    if (e.pos.y != this.pos.y) {
      retorno = int(this.pos.y*height-e.pos.y*height);
    } else {
      retorno = int(this.pos.x*width-e.pos.x*width);
    }
    return retorno;
  }
}
