/*  audio_win32.c
 *
 *  Funções para geração de áudio para o Windows 32 bits usando a
 *  API WinMM
 *
 *  Baseado no audio_win32.c do mpg123
 *
 */

#ifndef AUDIOWIN32_H
#define AUDIOWIN32_H

// Protótipos
int Audio_Abrir(int);
int Audio_Fechar();
int Audio_Tocar(unsigned char *, int);

#endif // AUDIOWIN32_H

// EOF