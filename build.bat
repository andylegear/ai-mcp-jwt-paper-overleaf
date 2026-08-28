@echo off
REM ═══════════════════════════════════════════════════════════════
REM  build.bat — Full LaTeX build for ICSA 2027 paper
REM  Usage: build.bat [clean]
REM  - No args: full 4-pass build (pdflatex → bibtex → pdflatex × 2)
REM  - clean:   remove all generated files
REM ═══════════════════════════════════════════════════════════════

cd /d "%~dp0"

if "%1"=="clean" (
    echo Cleaning generated files...
    del /q *.aux *.bbl *.blg *.log *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz 2>nul
    del /q sections\*.aux 2>nul
    echo Done.
    exit /b 0
)

echo === Pass 1: pdflatex ===
pdflatex -interaction=nonstopmode main.tex > nul 2>&1

echo === Pass 2: bibtex ===
bibtex main > nul 2>&1

echo === Pass 3: pdflatex (resolve refs) ===
pdflatex -interaction=nonstopmode main.tex > nul 2>&1

echo === Pass 4: pdflatex (final) ===
pdflatex -interaction=nonstopmode main.tex

echo.
echo === Build complete ===
findstr /c:"Output written" main.log
findstr /c:"Undefined" main.log
findstr /c:"^!" main.log
