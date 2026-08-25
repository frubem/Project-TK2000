/*  audio_win32.c
 *
 *  Funções para geração de áudio para o Windows 32 bits usando a
 *  API mmsystem
 *
 *  Baseado no audio_win32.c do mpg123
 *
 */


// Inclusões
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <mmsystem.h>

// Definições
#define MAX_BLOCOS 6			// Numero máximo de blocos

// Variáveis
static CRITICAL_SECTION cs;		// Para sincronização
WAVEHDR  *wh[MAX_BLOCOS + 1];	// Cabeçalhos Waves
static HWAVEOUT disp    = NULL;	// Manipulador do dispositivo WAVE
static int      nBlocos = 0;	// Números de blocos usados
static int      fi      = -1;	// Index livre


// Funções Internas
// ============================================================================
static __inline void Esperar(void)
{
	while(nBlocos)
		Sleep(77);
}

// ============================================================================
static void CALLBACK wave_callback(HWAVE hWave,
									UINT  uMsg, 
									DWORD dwInstance, 
									DWORD dwParam1, 
									DWORD dwParam2)
{
	if(uMsg == WOM_DONE)
	{
		EnterCriticalSection( &cs );
		wh[++fi] = (WAVEHDR *)dwParam1;
		nBlocos--;						// diminui o número de blocos usados
		LeaveCriticalSection( &cs );
	}
}

// ============================================================================
void Libera_Recursos(void)
{
	WAVEHDR *whfi;
	HGLOBAL hg;

	EnterCriticalSection( &cs );
	whfi = wh[fi--];
	LeaveCriticalSection( &cs );

	waveOutUnprepareHeader(disp, whfi, sizeof (WAVEHDR));

	//Deallocate the buffer memory
	hg = GlobalHandle(whfi->lpData);
	GlobalUnlock(hg);
	GlobalFree(hg);
  
	//Deallocate the header memory
	hg = GlobalHandle(whfi);
	GlobalUnlock(hg);
	GlobalFree(hg);
}

// Funções Globais
// ============================================================================
int Audio_Abrir(int TaxaAmostragem)
{
	MMRESULT res;
	WAVEFORMATEX outFormatex;

	if(!waveOutGetNumDevs())
	{
		fprintf(stderr, "Nenhum Dispositivo de Audio Presente!\n");
		return -1;
	}

	outFormatex.wFormatTag      = WAVE_FORMAT_PCM;
	outFormatex.wBitsPerSample  = 16;
	outFormatex.nChannels       = 1;
	outFormatex.nSamplesPerSec  = TaxaAmostragem;
	outFormatex.nAvgBytesPerSec = outFormatex.nSamplesPerSec * outFormatex.nChannels * outFormatex.wBitsPerSample/8;
	outFormatex.nBlockAlign     = outFormatex.nChannels * outFormatex.wBitsPerSample/8;

	res = waveOutOpen(&disp, WAVE_MAPPER, &outFormatex, (DWORD)wave_callback, 0, CALLBACK_FUNCTION);

	if(res != MMSYSERR_NOERROR)
	{
		char erro[MAX_PATH];		// variavel que guarda erro desconhecido
		switch(res)
		{
			case MMSYSERR_ALLOCATED:
				fprintf(stderr, "Dispositivo já está aberto.\n");
			break;

			case MMSYSERR_BADDEVICEID:
				fprintf(stderr, "O dispositivo especificado está fora da faixa.\n");
			break;

			case MMSYSERR_NODRIVER:
				fprintf(stderr, "Não há drivers para este dispositivo.\n");
			break;

			case MMSYSERR_NOMEM:
				fprintf(stderr, "Erro ao alocar memória de buffer do som.\n");
			break;

			case WAVERR_BADFORMAT:
				fprintf(stderr, "Este formato de áudio não é suportado.\n");
			break;

			case WAVERR_SYNC:
				fprintf(stderr, "O dispositivo é síncrono.\n");
			break;

			default:
				waveOutGetErrorText(res, erro, MAX_PATH);
				fprintf(stderr, "%s.\n", erro);
			break;
		}
		return -1;
	}

	waveOutReset(disp);
	InitializeCriticalSection(&cs);
	return 0;
}

// ============================================================================
int Audio_Fechar()
{
	if(disp)
	{
		Esperar();
		waveOutReset(disp);      //reset the device
		waveOutClose(disp);      //close the device
		disp = NULL;
	}
	DeleteCriticalSection(&cs);
	nBlocos = 0;
	return 0;
}

// ============================================================================
int Audio_Tocar(unsigned char *buffer, int tamanho)
{
	HGLOBAL   hg, hg2;
	LPWAVEHDR wh;
	MMRESULT  res;
	void      *b;

	/* first, free used blocks */
	while (fi >= 0)
	{
		Libera_Recursos();
	}

	////////////////////////////////////////////////////////
	//  Wait for a few FREE blocks...
	///////////////////////////////////////////////////////
	while(nBlocos > MAX_BLOCOS)
		Sleep(77);

	////////////////////////////////////////////////////////
	// FIRST allocate some memory for a copy of the buffer!
	////////////////////////////////////////////////////////
	hg2 = GlobalAlloc(GMEM_MOVEABLE, tamanho);
	if(!hg2)
	{
		fprintf(stderr, "Falta de memoria!!!\n");
		return -1;
	}
	b = GlobalLock(hg2);

	//////////////////////////////////////////////////////////
	// Here we can call any modification output functions we want....
	///////////////////////////////////////////////////////////
	CopyMemory(b, buffer, tamanho);

	///////////////////////////////////////////////////////////
	// now make a header and WRITE IT!
	///////////////////////////////////////////////////////////
	hg = GlobalAlloc (GMEM_MOVEABLE | GMEM_ZEROINIT, sizeof (WAVEHDR));
	if(!hg)
	{
		fprintf(stderr, "Falta de memoria!!!\n");
		return -1;
	}
	wh = GlobalLock(hg);
	wh->dwBufferLength = tamanho;
	wh->lpData = b;

	res = waveOutPrepareHeader(disp, wh, sizeof (WAVEHDR));
	if(res)
	{
		fprintf(stderr, "Falta de memoria!!!\n");
		GlobalUnlock(hg);
		GlobalFree(hg);
		return -1;
	}
	res = waveOutWrite(disp, wh, sizeof (WAVEHDR));
	if(res)
	{
		GlobalUnlock(hg);
		GlobalFree(hg);
		return (-1);
	}

	EnterCriticalSection( &cs );
	nBlocos++;
	LeaveCriticalSection( &cs );
	return tamanho;
}

// EOF