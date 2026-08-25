/*  audio_wave.h
 *
 *  Funções para geração de arquivo wave (.wav)
 *
 */

#ifndef AUDIOWAVE_H
#define AUDIOWAVE_H

// Definições
#include <pshpack1.h>

typedef struct SWaveCab
{
	BYTE  GroupID[4];		// RIFF
	DWORD GroupLength;
	BYTE  TypeID[4];		// WAVE
	BYTE  FormatID[4];		// fmt 
	DWORD FormatLength;
	WORD  wFormatTag;
	WORD  NumChannels;
	DWORD SamplesPerSec;
	DWORD BytesPerSec;
	WORD  nBlockAlign;
	WORD  BitsPerSample;
	BYTE  DataID[4];
	DWORD DataLength;
} TWaveCab, *PTWave;

#include <poppack.h>

// Protótipos
int Wave_Abrir(int, char *);
int Wave_Fechar();
int Wave_Tocar(unsigned char *, int);

#endif // AUDIOWAVE_H