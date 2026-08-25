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

LEBYTES .EQU	$EE20
RECSIN2	.EQU	$FCFA
RECSIN1	.EQU	$FCFD
LEBYTE	.EQU	$FCEC
COUT	.EQU	$FDED
PRBYTE	.EQU	$FDDA
PRERR	.EQU	$FF2D

	.ORG	$6000

INICIO
	LDA	#BUF & $FF
	STA	ENDI
	LDA	#BUF >> 8
	STA	ENDI+1
	LDA	#(BUF + 12) & $FF
	STA	ENDF
	LDA	#(BUF + 12) >> 8
	STA	ENDF+1

	LDX	#$FF
	STX	CS
LOOPC1
	LDX	#$10
LOOPC2
	LDY	#$25
	JSR	RECSIN1
	BCC	LOOPC1
	DEX
	BNE	LOOPC2
	JSR	IMPTEXTO
	JSR	RECSIN2
LOOPC3
	LDY	#$24
	JSR	RECSIN1
	BCS	LOOPC3
	JSR	RECSIN1
	LDX	#0
	LDY	#$3A
	JSR	LEBYTES
	LDY	#$34
	JSR	LEBYTE
	CMP	CS
	BEQ	OK
	LDA	#' ' | $80
	JSR	COUT
	JMP	PRERR
OK
	JSR	IMPTEXTO
	RTS

IMPTEXTO
	LDA	#$17
	STA	CV
	LDY	#1
	STY	CH
	DEY
IMPTEXTO_L1
	LDA	BUF,Y
	JSR	COUT
	INY
	CPY	#6
	BNE	IMPTEXTO_L1
IMPTEXTO_L2
	LDA	#' ' | $80
	JSR	COUT
	LDA	BUF,Y
	JSR	PRBYTE
	INY
	CPY	#8
	BNE	IMPTEXTO_L2
	RTS
BUF
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	.END
