/*  audio_wave.c
 *
 *  Funções para geração de arquivo wave (.wav)
 *
 */

// Inclusões
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <mmsystem.h>
#include "audio_wave.h"

// Definições

// Variáveis
static FILE  *ArqWave   = NULL;		// Manipulador do arquivo
static DWORD TamDados   = 0;		// Comprimento dos dados

// Funções Internas
// ============================================================================

// Funções Globais
// ============================================================================
int Wave_Abrir(int TaxaAmostragem, char *Arquivo)
{
	TWaveCab WaveCab;

	ArqWave = fopen(Arquivo, "wb+");
	if (!ArqWave)
	{
		fprintf(stderr, "Erro ao criar arquivo %s", Arquivo);
		return 1;
	}
	memset(&WaveCab, 0, sizeof(TWaveCab));

	strcpy(WaveCab.GroupID,  "RIFF");
	WaveCab.GroupLength    = 0;			// Não fornecido agora
	strcpy(WaveCab.TypeID,   "WAVE");
	strcpy(WaveCab.FormatID, "fmt ");
	WaveCab.FormatLength   = 16;
	WaveCab.wFormatTag     = WAVE_FORMAT_PCM;
	WaveCab.NumChannels    = 1;
	WaveCab.SamplesPerSec  = TaxaAmostragem;
	WaveCab.BytesPerSec    = TaxaAmostragem * (16 / 8);
	WaveCab.nBlockAlign    = (16 / 8);
	WaveCab.BitsPerSample  = 16;
	strcpy(WaveCab.DataID,   "data");
	WaveCab.DataLength     = 0;			// Não fornecido agora

	fwrite(&WaveCab, 1, sizeof(TWaveCab), ArqWave);

	return 0;
}

// ============================================================================
int Wave_Fechar()
{
	TWaveCab WaveCab;

	fseek(ArqWave, 0, SEEK_SET);
	fread(&WaveCab, 1, sizeof(TWaveCab), ArqWave);
	WaveCab.DataLength = TamDados;
	WaveCab.GroupLength = TamDados + sizeof(TWaveCab) - 8;
	fseek(ArqWave, 0, SEEK_SET);
	fwrite(&WaveCab, 1, sizeof(TWaveCab), ArqWave);
	fclose(ArqWave);
	return 0;
}

// ============================================================================
int Wave_Tocar(unsigned char *buffer, int tamanho)
{
	int result;

	result = fwrite(buffer, 1, tamanho, ArqWave);
	TamDados += result;
	return result;
}

// EOF