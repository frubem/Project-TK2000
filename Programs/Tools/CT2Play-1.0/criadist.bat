@echo off
echo Limpando
del /s *.o *.obj *.pdb *.exp *.ncb *.dcu *.dof *.opt *.pch *.plg *.idb *.~* *.sbr *.ilk *.bsc

set nomedist=CT2Play
set version=1.0

echo Criando Distribuicao
cd ..
tar cvjf %nomedist%-%version%-src.tar.bz2 --exclude=Release --exclude=Debug %nomedist%-%version%
move %nomedist%-%version%-src.tar.bz2 %nomedist%-%version%
cd %nomedist%-%version%
dir /b %nomedist%-%version%-src.tar.bz2
pause
