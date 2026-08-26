/*  buffer.c
 *
 *  Funções para manipulação do buffer do áudio.
 *
 */

// Inclusões
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include "buffer.h"
#include "audio_wave.h"
#include "audio_win32.h"

// Definições

// Variaveis
int  TipoSaida = TS_WAVE;

// Funções Globais
// ============================================================================
int Buffer_Iniciar(int Tipo, int Taxa, char *Arquivo)
{
	TipoSaida = Tipo;

	switch(TipoSaida)
	{
		case TS_WAVE:
			return Wave_Abrir(Taxa, Arquivo);
		break;

		case TS_AUDIO:
			return Audio_Abrir(Taxa);
		break;
	}
	return 0;
}

// ============================================================================
int Buffer_Terminar()
{
	switch(TipoSaida)
	{
		case TS_WAVE:
			return Wave_Fechar();
		break;

		case TS_AUDIO:
			return Audio_Fechar();
		break;
	}
	return 0;
}

// ============================================================================
int Buffer_Submeter(unsigned char *buffer, int tamanho)
{
	switch(TipoSaida)
	{
		case TS_WAVE:
			return Wave_Tocar(buffer, tamanho);
		break;

		case TS_AUDIO:
			return Audio_Tocar(buffer, tamanho);
		break;
	}
	return 0;
}
