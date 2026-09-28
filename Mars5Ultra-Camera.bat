@echo off
setlocal EnableExtensions
title Mars 5 Ultra - Camera ao Vivo
color 0B
cls

set "IP=192.168.31.190"
set "PORTA=554"
set "STREAM=rtsp://%IP%:%PORTA%/video"
set "FFPLAY="

echo.
echo ============================================================
echo                  ELEGOO MARS 5 ULTRA
echo                     CAMERA AO VIVO
echo ============================================================
echo.

rem ============================================================
rem 1. NAO PERMITE DUAS SESSOES FFPLAY AO MESMO TEMPO
rem ============================================================

echo [1/4] Verificando se a camera ja esta aberta...

tasklist /FI "IMAGENAME eq ffplay.exe" 2>nul | find /I "ffplay.exe" >nul

if not errorlevel 1 (
    echo.
    echo [ATENCAO] Ja existe uma sessao de video aberta neste computador.
    echo.
    echo           Para proteger a conexao da camera, este arquivo
    echo           NAO vai abrir uma segunda sessao e NAO vai matar
    echo           o FFplay que ja esta em execucao.
    echo.
    echo           Feche normalmente a janela da camera existente
    echo           e execute este arquivo novamente.
    echo.
    pause
    goto :EOF
)

echo [ OK ] Nenhuma sessao duplicada encontrada.
echo.

rem ============================================================
rem 2. LOCALIZA O FFPLAY
rem ============================================================

echo [2/4] Preparando o sistema de video...

rem Caminho que ja foi encontrado funcionando neste computador.
set "FFPLAY_TESTADO=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.1-essentials_build\bin\ffplay.exe"

if exist "%FFPLAY_TESTADO%" (
    set "FFPLAY=%FFPLAY_TESTADO%"
)

rem Se a versao mudar no futuro, tenta pelo PATH.
if not defined FFPLAY (
    for /f "delims=" %%F in ('where ffplay.exe 2^>nul') do (
        if not defined FFPLAY set "FFPLAY=%%F"
    )
)

rem Ultima tentativa: procura SOMENTE no pacote correto do WinGet.
if not defined FFPLAY (
    for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg.Essentials_*") do (
        for /d %%E in ("%%~fD\ffmpeg-*-essentials_build") do (
            if exist "%%~fE\bin\ffplay.exe" (
                if not defined FFPLAY set "FFPLAY=%%~fE\bin\ffplay.exe"
            )
        )
    )
)

rem Se nao existir, instala automaticamente.
if not defined FFPLAY (
    echo.
    echo       O componente de video ainda nao esta instalado.
    echo       Instalando automaticamente...
    echo       Isso acontece somente na primeira execucao.
    echo.

    where winget.exe >nul 2>&1

    if errorlevel 1 (
        echo [ERRO] O instalador WinGet nao foi encontrado neste Windows.
        echo.
        pause
        goto :EOF
    )

    winget install --id Gyan.FFmpeg.Essentials -e --accept-source-agreements --accept-package-agreements --silent --disable-interactivity

    rem Procura novamente no PATH.
    for /f "delims=" %%F in ('where ffplay.exe 2^>nul') do (
        if not defined FFPLAY set "FFPLAY=%%F"
    )

    rem E no pacote especifico do WinGet.
    if not defined FFPLAY (
        for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg.Essentials_*") do (
            for /d %%E in ("%%~fD\ffmpeg-*-essentials_build") do (
                if exist "%%~fE\bin\ffplay.exe" (
                    if not defined FFPLAY set "FFPLAY=%%~fE\bin\ffplay.exe"
                )
            )
        )
    )
)

if not defined FFPLAY (
    echo.
    echo [ERRO] Nao consegui localizar o FFplay.
    echo.
    pause
    goto :EOF
)

echo [ OK ] Sistema de video pronto.
echo.

rem ============================================================
rem 3. TESTE RAPIDO DA PORTA RTSP
rem ============================================================

echo [3/4] Localizando a Mars 5 Ultra na rede...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$c = New-Object System.Net.Sockets.TcpClient; try { $a = $c.BeginConnect('%IP%', %PORTA%, $null, $null); if ($a.AsyncWaitHandle.WaitOne(2500, $false)) { $c.EndConnect($a); exit 0 } else { exit 1 } } catch { exit 1 } finally { $c.Close() }" >nul 2>&1

if errorlevel 1 (
    echo.
    echo [ERRO] Nao consegui acessar a camera em %IP%:%PORTA%.
    echo.
    echo        A impressora pode estar desligada, fora da rede
    echo        ou ter recebido outro endereco IP.
    echo.
    echo        Nenhuma sessao de video foi aberta.
    echo.
    pause
    goto :EOF
)

echo [ OK ] Mars 5 Ultra encontrada.
echo.

rem ============================================================
rem 4. ABRE A CAMERA
rem ============================================================

echo [4/4] Abrindo a camera...
echo.
echo       A primeira imagem pode levar alguns segundos.
echo.
echo       IMPORTANTE:
echo       Para encerrar, feche normalmente a janela da camera
echo       ou pressione Q dentro do FFplay.
echo.
echo       Este arquivo nunca usa TASKKILL no FFplay.
echo       Assim a sessao RTSP pode ser encerrada normalmente.
echo.
echo ------------------------------------------------------------
echo.

rem ============================================================
rem CONEXAO QUE JA FUNCIONOU NESTE COMPUTADOR
rem ============================================================

"%FFPLAY%" -hide_banner -loglevel fatal -rtsp_transport udp "%STREAM%"

set "RESULTADO=%ERRORLEVEL%"

echo.
echo ------------------------------------------------------------
echo.

if "%RESULTADO%"=="0" (
    echo [ OK ] Camera encerrada normalmente.
    echo.
    timeout /t 2 /nobreak >nul
    goto :EOF
)

echo [ERRO] O FFplay encerrou a conexao com codigo %RESULTADO%.
echo.
echo        Nenhum processo sera morto a forca.
echo        Se a impressora estiver acessivel, tente novamente
echo        apenas depois de confirmar que nao existe outra
echo        janela da camera aberta.
echo.
pause

endlocal
