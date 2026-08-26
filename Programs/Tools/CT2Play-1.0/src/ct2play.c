/*  tc2play - Utilitário para ler arquivo ct2 e gerar áudio para
 *            ser lido no TK2000 pelo cassete
 *
 *  by Fábio Belavenuto - Copyright 2004
 *
 *  Versão 0.1beta
 *
 *  Este arquivo é distribuido pela Licença Pública Geral GNU.
 *  Veja o arquivo "Licenca.txt" distribuido com este software.
 *
 *  ESTE SOFTWARE NÃO OFERECE NENHUMA GARANTIA
 */

#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include "buffer.h"

// Definições
#define VERSAO  "1.0"
#define MAX(a,b)	(((a) > (b)) ? (a) : (b))
#define MIN(a,b)	(((a) < (b)) ? (a) : (b))

#define TAMBUFFER 102400		// 100 KBytes
#define MINBUFFER 10240			//  10 KBytes
#define MAXBUFFER 1048576		//   1 MBytes
#define DURSILENP 1000			//   1 seg
#define DURSILENS 500			// 500 ms
#define DURCABA   3000			//   3 seg
#define MINCABA   500			// 500 ms
#define MAXCABA   5000			//   5 seg
#define TAXAAMOST 44100

#define  CT2_MAGIC "CTK2"
#define  CT2_CAB_A "CA"
#define  CT2_CAB_B "CB"
#define  CT2_DADOS "DA"

#include <pshpack1.h>

typedef struct STKCab
{
	BYTE Nome[6];
	BYTE TotalBlocos;
	BYTE BlocoAtual;
} TTKCab;

typedef struct STKEnd
{
	WORD EndInicial;
	WORD EndFinal;
} TTKEnd;

typedef struct SCh
{
	BYTE ID[2];
	WORD Tam;
} TCh;

#include <poppack.h>

// Variáveis
char *BufferGeral    = NULL;
int  pontBufferGeral = 0;
int  TamBuffer       = TAMBUFFER;
int  DurSilencioP    = DURSILENP;
int  DurSilencioS    = DURSILENS;
int  DurCabA         = DURCABA;
int  TaxaAmostragem  = TAXAAMOST;

// Funções

// =============================================================================
void VerificaBuffer()
{
	if (pontBufferGeral >= TamBuffer)
	{
		Buffer_Submeter(BufferGeral, pontBufferGeral);
		pontBufferGeral = 0;
	}
}
// =============================================================================
void GeraSilencio(int Duracaoms)
{
	static short Pico = 32767;
	int c;
	int Total;

	Total = (TaxaAmostragem * Duracaoms) / 1000 * 2;

	c = 0;
	while (c < Total)
	{
		*(short*)(BufferGeral + pontBufferGeral) = 0;
		pontBufferGeral += 2;
		c += 2;
		VerificaBuffer();
	}
}

// =============================================================================
void GeraSom(int Frequencia, int Duracaoms)
{
	static short Pico = 32767;
	int   c, i;
	int   Total, CicloT, Ciclo1, Ciclo2;

	CicloT = TaxaAmostragem / Frequencia;
	Ciclo1 = (int)((double)CicloT / 2 + .5);
	Ciclo2 = CicloT / 2;
	Total = CicloT * Duracaoms * 2;

	c = i = 0;
	while (c < Total)
	{
		i = 0;
		while (i < Ciclo1)
		{
			*(short*)(BufferGeral + pontBufferGeral) = Pico;
			pontBufferGeral += 2;
			c += 2;
			i++;
			VerificaBuffer();
		}
		Pico = 0-Pico;
		i = 0;
		while (i < Ciclo2)
		{
			*(short*)(BufferGeral + pontBufferGeral) = Pico;
			pontBufferGeral += 2;
			c += 2;
			i++;
			VerificaBuffer();
		}
		Pico = 0-Pico;
	}
}

// =============================================================================
void TocaCabA(int DurSilencio)
{
	GeraSilencio(DurSilencio);
	GeraSom(980, DurCabA);
}

// =============================================================================
void TocaCabB()
{
	GeraSom(722, 30);
	GeraSom(1900, 1);		// bit 0
}

// =============================================================================
void TocaByte(BYTE b)
{
	int i;

	for (i = 7; i >=0; i--)
	{
		if (b & (1 << i))
		{
			GeraSom(980, 1);
		}
		else
		{
			GeraSom(1900, 1);
		}
	}
}

// =============================================================================
void ImprimeInf(TTKCab *Cab, TTKEnd *End)
{
	int  i;
	char Nome[7];
	
	for (i=0; i<6; i++)
		Nome[i] = Cab->Nome[i] & 0x7F;
	Nome[6] = 0;
	printf("\nTocando arquivo \'%s\' de 0x%.2X bloco(s)\n", Nome, Cab->TotalBlocos);
	printf("Endereco inicial = 0x%.4X - Endereco final = 0x%.4X\n", End->EndInicial, End->EndFinal);
}

// =============================================================================
int tocar(char *nomearq)
{
	FILE   *ArqEntrada;
	int    cont, tamanho, comp, pos;
	TTKCab Cab;
	TTKEnd Ends;
	TCh    Ch;
	BYTE   b;
	int    SilencioAtual = DurSilencioP;

	printf("Tocando %s...\n", nomearq);

	if (!(ArqEntrada = fopen(nomearq, "rb")))
	{
		fprintf(stderr, "Erro ao abrir arquivo %s\n", nomearq);
		exit(1);
	}
	fseek(ArqEntrada, 0, SEEK_END);
	tamanho = ftell(ArqEntrada);
	fseek(ArqEntrada, 0, SEEK_SET);
	fread(&Ch, 1, 4, ArqEntrada);
	if (strncmp((char*)&Ch, CT2_MAGIC, 4))
	{
		fclose(ArqEntrada);
		fprintf(stderr, "ERRO: Arquivo nao esta no formato .CT2\n");
		return 1;
	}

	BufferGeral = (char*)malloc(TamBuffer+2);
	if (!BufferGeral)
	{
		fclose(ArqEntrada);
		fprintf(stderr, "Falta de memoria!\n");
		return 2;
	}

	// Enquanto não acabar o arquivo
	while (!feof(ArqEntrada))
	{
		// Lê Chunk de 4 bytes
		fread(&Ch, 1, 4, ArqEntrada);
		// Tamanho do chunk
		comp = Ch.Tam;
		// Se for um chunk informando ser cabecalho A
		if (!strncmp(Ch.ID, CT2_CAB_A, 2))
		{
			TocaCabA(SilencioAtual);
			SilencioAtual = DurSilencioS;
		}
		else
		// Se for um chunk informando ser cabecalho B
		if (!strncmp(Ch.ID, CT2_CAB_B, 2))
		{
			TocaCabB();
		}
		else
		// Se for um chunk informando ser dados
		if (!strncmp(Ch.ID, CT2_DADOS, 2))
		{
			// Toca Dados
			pos = ftell(ArqEntrada);
			fread(&Cab, 1, sizeof(TTKCab), ArqEntrada);
			// Verifica se é o primeiro bloco
			if (Cab.BlocoAtual == 0)
			{
				fread(&Ends, 1, sizeof(TTKEnd), ArqEntrada);
				ImprimeInf(&Cab, &Ends);
			}
			// Toca Dados
			fseek(ArqEntrada, pos, SEEK_SET);
			for (cont = 0; cont < comp; cont++)
			{
				fread(&b, 1, 1, ArqEntrada);
				TocaByte(b);
			}
			// Verifica se é o final do arquivo;
			if (Cab.BlocoAtual == Cab.TotalBlocos)
			{
				GeraSilencio(100);
				printf("Arquivo Terminado.\n\n");
				if (pontBufferGeral)
				{
					Buffer_Submeter(BufferGeral, pontBufferGeral);
					pontBufferGeral = 0;
				}
			}
		}
	}
	// Verifica se o buffer está vazio
	if (pontBufferGeral)
	{
		Buffer_Submeter(BufferGeral, pontBufferGeral);
		pontBufferGeral = 0;
	}
	fclose(ArqEntrada);
	free(BufferGeral);
	// Esperar o driver de som finalizar
	Sleep(1000);
	return 0;
}

// =============================================================================
void MostraUso(char *nomeprog)
{
	fprintf(stderr, "\n");
	fprintf(stderr, "%s - Utilitario para \"tocar\" um arquivo .ct2\n", nomeprog);
	fprintf(stderr, "          para o TK2000. Versao %s\n\n", VERSAO);
	fprintf(stderr, "  Uso:\n");
	fprintf(stderr, "    %s [opcoes] <arquivos>\n\n", nomeprog);
	fprintf(stderr, "  Opcoes:\n");
	fprintf(stderr, "  -t <sps>    - Determina a taxa de amostragem em \"Samples per Second\".\n");
	fprintf(stderr, "                Padrao: %d sps\n", TaxaAmostragem);
	fprintf(stderr, "  -p <ms>     - Determina a duracao do silencio inicial.\n");
	fprintf(stderr, "                Padrao: %d ms \n", DurSilencioP);
	fprintf(stderr, "  -s <ms>     - Determina a duracao do silencio entre 2 arquivos.\n");
	fprintf(stderr, "                Padrao: %d ms \n", DurSilencioS);
	fprintf(stderr, "  -c <ms>     - Determina a duracao do cabecalho.\n");
	fprintf(stderr, "                Padrao: %d ms, Minimo de %d ms, Maximo de %d ms \n", DurCabA, MINCABA, MAXCABA);
	fprintf(stderr, "  -b <KBytes> - Determina o tamanho do buffer.\n");
	fprintf(stderr, "                Padrao: %d KBytes, Minimo de %d KBytes, Maximo de %d KBytes\n", TamBuffer/1024, MINBUFFER/1024, MAXBUFFER/1024);
	fprintf(stderr, "  -w <arq.>   - Gera um arquivo .wav ao inves de tocar na placa de som.\n");
	fprintf(stderr, "\n");
	exit(0);
}

// =============================================================================
int main (int argc, char *argv[])
{
	int  c = 1, ca = 0, err;
	int  TipoSaida = TS_AUDIO;
	char *NomeArq[100];
	char *NomeArqWave;

	if (argc < 2)
		MostraUso(argv[0]);

	while (c < argc)
	{
		if (argv[c][0] == '-' || argv[c][0] == '/')
		{
			if (c+1 == argc)
			{
				fprintf(stderr, "Falta parametro para a opcao %s", argv[c]);
				return 1;
			}
			switch(argv[c][1])
			{
				case 't':
					++c;
					TaxaAmostragem = MIN(88200, MAX(8000, atoi(argv[c])));
				break;

				case 'p':
					++c;
					DurSilencioP = MAX(1, atoi(argv[c]));
				break;

				case 's':
					++c;
					DurSilencioS = MAX(1, atoi(argv[c]));
				break;

				case 'c':
					++c;
					DurCabA = MIN(MAXCABA, MAX(MINCABA, atoi(argv[c])));
				break;

				case 'b':
					++c;
					TamBuffer = MIN(MAXBUFFER, MAX(MINBUFFER, atoi(argv[c])*1024));
				break;

				case 'w':
					NomeArqWave = argv[++c];
					TipoSaida   = TS_WAVE;
				break;
				
				default:
					fprintf(stderr, "Opcao invalida: %s\n", argv[c]);
					return 1;
				break;
			} // switch
		}
		else
			NomeArq[++ca] = argv[c];
		c++;
	}

	if (!ca)
	{
		fprintf(stderr, "Falta nome do arquivo.\n");
		return 1;
	}
	c = 1;

	if (Buffer_Iniciar(TipoSaida, TaxaAmostragem, NomeArqWave))
	{
		exit(1);
	}

	while (c <= ca)
		if (err = tocar(NomeArq[c++]))
			return err;

	Buffer_Terminar();
	return 0;
}
