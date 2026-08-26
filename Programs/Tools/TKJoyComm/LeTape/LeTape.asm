; LeTape - 
; by Fábio Belavenuto - Copyright 2004

; Versão 0.1

;Este arquivo é distribuido pela Licença Pública Geral GNU.
;Veja o arquivo Licenca.txt distribuido com este software.

;ESTE SOFTWARE NÃO OFERECE NENHUMA GARANTIA

; Esse código fonte deve ser compilado com o Table Assembler

CH	.EQU	$24			; HTAB
CV	.EQU	$25			; VTAB
CS	.EQU	$2E			; Checksum
ENDI	.EQU	$3C
ENDF	.EQU	$3E

TAM	.EQU	$F0
END	.EQU	$F2
SEND	.EQU	$F4
COMP	.EQU	$F6
VALOR	.EQU	$F8
QTDE	.EQU	$F9

KBOUT	.EQU	$C000
KBIN	.EQU	$C010
LEBYTES .EQU	$EE20
PRNTAX	.EQU	$F941
RECSIN2	.EQU	$FCFA
RECSIN1	.EQU	$FCFD
LEBYTE	.EQU	$FCEC
COUT	.EQU	$FDED
PRBYTE	.EQU	$FDDA
PRERR	.EQU	$FF2D

COMMEM	.EQU	$0C00

	.ORG	$0900

; -----------------------------------------------------------------------------
INICIO
	; TODO: Mudar para pagina 2 de vídeo (MP)

	JSR	IMPRIME_ESP		; Imprime mensagem de espera
	JSR	RECEBEBYTE		; Recebe quantidade de arquivos para ler
	STA	QTDE
	JSR	IMPRIME_MAN		; Imprime mensagem da quantidade de arquivos
	LDA	QTDE
	JSR	PRBYTE			; Imprime em Hexa a quantidade de Arquivo
	LDA	#$8D
	JSR	COUT

	LDA	#COMMEM & $FF		; Configura endereço inicial COMMEM
	STA	ENDI
	STA	END
	STA	SEND
	LDA	#COMMEM >> 8
	STA	ENDI+1
	STA	END+1
	STA	SEND+1
	LDA	#(COMMEM + 7) & $FF	; Configura endereço final COMMEM + 7
	STA	ENDF
	LDA	#COMMEM >> 8
	STA	ENDF+1
INICIO_LG
	DEC	QTDE
	LDA	QTDE
	CMP	#$FF			; Decrementa quantidade para verificar se acabou
	BEQ	INICIO_FIM
	LDX	#$00			; Gera um atraso
	LDY	#$00
	LDA	#5
INICIO_A1
	INY
	BNE	INICIO_A1
	INX
	BNE	INICIO_A1
	SEC
	SBC	#1
	BNE	INICIO_A1
INICIO_L1
	JSR	LERBLOCO		; Le 1 bloco
	LDA	CS			; Verifica se o Checksum é 0
	BNE	ERRO			; Se não for 0 teve erro
	LDY	#7
	LDA	(SEND),Y		; Verifica se o Bloco é o 0
	BNE	INICIO_BN0		; Se não for pula

	LDY	#$A			; Bloco 0 - Ler Endereco Inicial e Final para
	LDA	(SEND),Y		;           calcular tamanho do arquivo
	SEC
	LDY	#8
	SBC	(SEND),Y		; Faz End. Final - End. Inicial + 1
	STA	COMP
	LDY	#$B
	LDA	(SEND),Y
	LDY	#9
	SBC	(SEND),Y
	STA	COMP+1
	LDA	COMP
	CLC
	ADC	#1
	STA	COMP
	LDA	COMP+1
	ADC	#0
	STA	COMP+1
INICIO_BN0				; Bloco > 0
	JSR	IMPRIMEINF		; Imprime informações
	LDA	ENDF
	CLC
	ADC	#1			; Faz EndI = EndF+1
	STA	ENDI
	STA	SEND
	LDA	ENDF+1
	ADC	#0
	STA	ENDI+1

	LDA	ENDI
	STA	SEND			; Faz SEND = EndI
	CLC
	ADC	#7			; Agora faz EndF = EndI+7
	STA	ENDF
	LDA	ENDI+1
	STA	SEND+1
	ADC	#0
	STA	ENDF+1

	LDA	COMP+1
	BNE	INICIO_L1		; Verifica se o comprimento chegou a 0
	LDA	COMP
	BNE	INICIO_L1
	JMP	INICIO_LG		; Se acabou um arquivo, refaz o loop geral

INICIO_FIM	
	LDA	ENDI
	STA	TAM
	LDA	ENDI+1
	SEC
	SBC	#COMMEM >> 8
	STA	TAM+1
;	LDA	#'E' | $80
;	JSR	COUT
;	LDA	#'N' | $80
;	JSR	COUT
;	LDA	#'V' | $80
;	JSR	COUT
	LDA	#0			; Envia 0 para o PC indicando sem erros
	JSR	ENVIABYTE
	JMP	ENVMEM

; -----------------------------------------------------------------------------
ERRO
	LDA	#1			; Envia 1 para o PC indicando erro
	JSR	ENVIABYTE
	JMP	PRERR

; -----------------------------------------------------------------------------
LERBLOCO
	LDA	#$FF
	STA	CS
LERBLOCO_L1
	LDX	#$10
LERBLOCO_L2
	LDY	#$25			; Espera 16 vezes o cabecalho B
	JSR	RECSIN1
	BCC	LERBLOCO_L1
	DEX
	BNE	LERBLOCO_L2
	LDY	#$FF
	JSR	RECSIN1
LERBLOCO_L3
	LDY	#$24			; Pula restante do cabecalho B
	JSR	RECSIN1
	BCS	LERBLOCO_L3
	JSR	RECSIN1			; Pula bit stop 0
	LDY	#$3A
	JSR	LEBYTES			; Ler bytes de ($3C) até ($3E)
	JSR	VERBLOCO
	JSR	LEBYTES			; Ler bytes de ($3C) até ($3E)
;	LDY	#$34
;	JSR	LEBYTE			; Ler Checksum
;	CMP	CS
;	BNE	ERRO
	RTS				; Retorna

; -----------------------------------------------------------------------------
VERBLOCO
	LDA	(ENDF,X)
	BEQ	VERBLOCO_E0		; Se for o bloco 0, pula
	LDA	COMP+1			; Bloco > 0, ler mais bytes
	BNE	VERBLOCO_P1
	LDA	ENDF			; bloco < 256
	SEC				; Somar 1 por causa do Checksum
	ADC	COMP
	STA	ENDF
	LDA	ENDF+1
	ADC	#$00
	STA	ENDF+1
	LDA	#$00
	STA	COMP
	LDY	#$32
	RTS
VERBLOCO_P1
	LDA	ENDF			; bloco >= 256
	CLC
	ADC	#1			; Somar 1 por causa do Checksum
	STA	ENDF
	LDA	ENDF+1
	ADC	#1
	STA	ENDF+1
	DEC	COMP+1
	LDY	#$32
	RTS
VERBLOCO_E0
	LDA	ENDF
	CLC
	ADC	#$05			; 4 + 1 do Checksum
	STA	ENDF
	LDY	#$34
	RTS

; -----------------------------------------------------------------------------
IMPRIMEINF
	RTS
	LDA	#23
	STA	CV
	LDY	#0
	STY	CH
IMPRIME_L1
	LDA	(SEND),Y
	JSR	COUT
	INY
	CPY	#6
	BNE	IMPRIME_L1
IMPRIME_L2
	LDA	#' ' | $80
	JSR	COUT
	LDA	(SEND),Y
	JSR	PRBYTE
	INY
	CPY	#7
	BNE	IMPRIME_L2
	LDA	#' ' | $80
	JSR	COUT
	LDA	COMP+1
	LDX	COMP
	JSR	PRNTAX			; Imprime comprimento do arquivo
	LDA	#' ' | $80
	JSR	COUT
	LDA	CS
	JSR	PRBYTE			; Imprime Checksum calculado
	LDA	#' ' | $80
	JSR	COUT
	RTS

; -----------------------------------------------------------------------------
ENVMEM
	LDA	TAM
	JSR	ENVIABYTE
	LDA	TAM+1
	JSR	ENVIABYTE
	LDY	#0
ENVMEM_LOOP
	DEC	TAM
	LDA	TAM
	CMP	#$FF
	BNE	ENVMEM_PULA1
	DEC	TAM+1
	LDA	TAM+1
	CMP	#$FF
	BEQ	ENVMEM_FIM
ENVMEM_PULA1
	LDA	(END),Y
	JSR	ENVIABYTE
	INC	END
	LDA	END
	BNE	ENVMEM_LOOP
	INC	END+1
	JMP	ENVMEM_LOOP
ENVMEM_FIM
	RTS

; -----------------------------------------------------------------------------
IMPRIME_ESP
	LDY	#0
IMPRIME_ESP_L1
	LDA	MSG1,Y
	BEQ	IMPRIME_ESP_FIM
	ORA	#$80
	JSR	COUT
	INY
	BNE	IMPRIME_ESP_L1
IMPRIME_ESP_FIM
	RTS

; -----------------------------------------------------------------------------
IMPRIME_MAN
	LDY	#0
IMPRIME_MAN_L1
	LDA	MSG2,Y
	BEQ	IMPRIME_MAN_FIM
	ORA	#$80
	JSR	COUT
	INY
	BNE	IMPRIME_MAN_L1
IMPRIME_MAN_FIM
	RTS

; -----------------------------------------------------------------------------
HANDSHAKING
	LDA	#00011111b
	STA	KBOUT
LOOP1
	LDA	KBIN
	AND	#01010001b
	CMP	#01010001b
	BNE	LOOP1

	LDA	#00000000b
	STA	KBOUT
LOOP2
	LDA	KBIN
	AND	#01010001b
	CMP	#00000000b
	BNE	LOOP2
	RTS

; -----------------------------------------------------------------------------
ENVIABYTE
	PHA				; Envia Byte
	JSR	HANDSHAKING
	LDX	#2			; Repetir 2 vezes
LOOPEB
	LDA	#00010000b
	STA	KBOUT
LOOPE1
	LDA	KBIN
	AND	#01000000b
	CMP	#01000000b
	BNE	LOOPE1

	PLA
	PHA
	AND	#00001111b
	STA	KBOUT
LOOPE2
	LDA	KBIN
	CMP	#00000000b
	BNE	LOOPE2

	PLA
	ROR	A
	ROR	A
	ROR	A
	ROR	A
	PHA
	DEX
	BNE	LOOPEB
	PLA
	RTS

; -----------------------------------------------------------------------------
RECEBEBYTE
	JSR	HANDSHAKING
	LDA     #$00
	STA     VALOR
	LDX	#4			; Repetir 4 vezes
LOOPRB
	LDA	#00010000b
	STA	KBOUT
LOOPR1
	LDA	KBIN
	AND	#01000000b
	CMP	#01000000b
	BNE	LOOPR1

	LDA	KBIN
	AND	#00010001b
	ROL	A
	ROL	A
	ROL	A
	ROL	A
	PHP
	ROL	A
	ROL	A
	ROL	A
	ROL	A
	ROR	VALOR
	PLP
	ROR	VALOR
	LDA	#00000000B
	STA	KBOUT
LOOPR2
	LDA	KBIN
	CMP	#00000000b
	BNE	LOOPR2

	DEX
	BNE	LOOPRB
	LDA	VALOR
	RTS

MSG1
	.TEXT	"ESPERANDO PC"
	.DB	13,0
MSG2
	.TEXT	"ENVIAR "
	.DB	0

	.END
