/*  buffer.h
 *
 *  Funções para manipulação do buffer do áudio.
 *
 */

#ifndef AUDIO_H
#define AUDIO_H

// Definições
#define TS_WAVE  0
#define TS_AUDIO 1

// Protótipos
int Buffer_Iniciar(int, int, char *);
int Buffer_Terminar();
int Buffer_Submeter(unsigned char *, int);

#endif // AUDIO_H

// EOF