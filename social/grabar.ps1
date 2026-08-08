# =====================================================================
#  TRM · graba cada animación a MP4 con su duración real
#
#  El problema del script anterior: esperaba un tiempo fijo (~10 s) para
#  todas las piezas, así que las largas salían cortadas. Aquí cada pieza
#  lleva escrita su duración.
#
#  Uso:
#     .\grabar.ps1                 -> graba todo
#     .\grabar.ps1 -Solo video-trm -> graba solo lo que coincida
#     .\grabar.ps1 -SoloLargos     -> solo las piezas de más de 15 s
# =====================================================================
param(
  [string]$Solo = "",
  [switch]$SoloLargos,
  [string]$Salida = "C:\Users\arnau\OneDrive\Desktop\empresa\TRM\salida"
)

$ErrorActionPreference = "Stop"
$social = "C:\Users\arnau\Claude\Projects\trmweb\social"

# --- ffmpeg (instalado con winget, no siempre está en el PATH de la sesión) ---
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
  $ffmpeg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
}
if (-not $ffmpeg) { throw "No encuentro ffmpeg. Instálalo con: winget install Gyan.FFmpeg" }

# --- catálogo: archivo, carpeta, ancho, alto, segundos ---
# Los segundos salen de la propia animación (última entrada + margen).
$piezas = @(
  # --- carruseles estáticos (4:5) — no llevan animación, con 5 s sobra ---
  @{n="car-01-tres-metodos";        d="";        w=1080; h=1350; s=5 }
  @{n="car-02-no-destructivo";      d="";        w=1080; h=1350; s=5 }
  @{n="car-03-epdm";                d="";        w=1080; h=1350; s=5 }
  @{n="car-04-pvc";                 d="";        w=1080; h=1350; s=5 }
  @{n="car-05-tpo";                 d="";        w=1080; h=1350; s=5 }
  @{n="car-06-bituminosa";          d="";        w=1080; h=1350; s=5 }
  @{n="car-07-liquidas";            d="";        w=1080; h=1350; s=5 }
  @{n="car-08-nueva-vs-existente";  d="";        w=1080; h=1350; s=5 }
  @{n="car-09-mantenimiento";       d="";        w=1080; h=1350; s=5 }
  @{n="car-10-rosi";                d="";        w=1080; h=1350; s=5 }

  # --- serie azul y serie clara (4:5) ---
  @{n="video-1-que-es";             d="";        w=1080; h=1350; s=13 }
  @{n="video-2-causas";             d="";        w=1080; h=1350; s=13 }
  @{n="video-3-consecuencias";      d="";        w=1080; h=1350; s=13 }
  @{n="video-4-sensores";           d="";        w=1080; h=1350; s=13 }
  @{n="video-5-mantenimiento";      d="";        w=1080; h=1350; s=13 }
  @{n="video-6-puntos-riesgo";      d="";        w=1080; h=1350; s=13 }
  @{n="video-7-informe";            d="";        w=1080; h=1350; s=13 }
  @{n="video-8-coste";              d="";        w=1080; h=1350; s=13 }
  @{n="video-9-tecnologia";         d="";        w=1080; h=1350; s=13 }
  @{n="light-1-que-es";             d="";        w=1080; h=1350; s=13 }
  @{n="light-2-causas";             d="";        w=1080; h=1350; s=13 }
  @{n="light-3-consecuencias";      d="";        w=1080; h=1350; s=13 }
  @{n="light-4-sensores";           d="";        w=1080; h=1350; s=13 }
  @{n="light-5-mantenimiento";      d="";        w=1080; h=1350; s=13 }
  @{n="light-6-puntos-riesgo";      d="";        w=1080; h=1350; s=13 }
  @{n="light-7-informe";            d="";        w=1080; h=1350; s=13 }
  @{n="light-8-coste";              d="";        w=1080; h=1350; s=13 }
  @{n="light-9-tecnologia";         d="";        w=1080; h=1350; s=13 }
  @{n="light-10-antes-despues";     d="";        w=1080; h=1350; s=13 }

  # --- reels verticales (9:16) ---
  @{n="reel-1-alta-tension";        d="";        w=1080; h=1920; s=10 }
  @{n="reel-2-baja-tension";        d="";        w=1080; h=1920; s=10 }
  @{n="reel-3-puntos-singulares";   d="";        w=1080; h=1920; s=10 }
  @{n="reel-4-encharcamiento";      d="";        w=1080; h=1920; s=10 }
  @{n="reel-5-membranas";           d="";        w=1080; h=1920; s=10 }
  @{n="reel-6-senales";             d="";        w=1080; h=1920; s=10 }
  @{n="hv-1-equipo";                d="";        w=1080; h=1920; s=10 }
  @{n="hv-2-gatillo";               d="";        w=1080; h=1920; s=10 }
  @{n="hv-3-tension-pulsada";       d="";        w=1080; h=1920; s=10 }
  @{n="hv-4-puesta-a-tierra";       d="";        w=1080; h=1920; s=10 }
  @{n="hv-5-que-detecta";           d="";        w=1080; h=1920; s=10 }
  @{n="hv-6-tension-de-prueba";     d="";        w=1080; h=1920; s=10 }

  # --- 3D cuadrado: una vuelta completa de giro son 26 s ---
  @{n="stack-1-capas";              d="";        w=1080; h=1080; s=28 }
  @{n="stack-2-recorrido-agua";     d="";        w=1080; h=1080; s=28 }
  @{n="stack-3-alta-tension";       d="";        w=1080; h=1080; s=28 }

  # --- historias narrativas (9:16) — estas eran las más cortadas ---
  @{n="proceso-deteccion-fugas";    d="";        w=1080; h=1920; s=31 }
  @{n="historia-1-obra-nueva";      d="";        w=1080; h=1920; s=33 }
  @{n="historia-2-sumidero";        d="";        w=1080; h=1920; s=33 }
  @{n="historia-3-sensores";        d="";        w=1080; h=1920; s=32 }
  @{n="historia-4-placas-solares";  d="";        w=1080; h=1920; s=33 }
  @{n="historia-5-antes-de-firmar"; d="";        w=1080; h=1920; s=33 }
  @{n="historia-6-granizo";         d="";        w=1080; h=1920; s=32 }

  # --- cinemáticas 16:9 (en bucle: capturo un ciclo entero) ---
  @{n="cine-1-la-gota";             d="";        w=1920; h=1080; s=16 }
  @{n="cine-2-el-barrido";          d="";        w=1920; h=1080; s=20 }
  @{n="cine-3-el-agua-que-se-queda";d="";        w=1920; h=1080; s=24 }

  # --- el vídeo largo de YouTube ---
  @{n="video-trm-cubiertas";        d="youtube"; w=1920; h=1080; s=382 }
)

if ($Solo)      { $piezas = $piezas | Where-Object { $_.n -like "*$Solo*" } }
if ($SoloLargos){ $piezas = $piezas | Where-Object { $_.s -gt 15 } }

New-Item -ItemType Directory -Force -Path $Salida | Out-Null
$tmp = Join-Path $env:TEMP "trm-rec"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

# --- el grabador (Playwright); se escribe una vez y se reutiliza ---
$recorder = Join-Path $tmp "rec.js"
@'
const { chromium } = require('playwright');
(async () => {
  const [file, outDir, W, H, secs] = process.argv.slice(2);
  const w = +W, h = +H, s = +secs;
  const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });
  const ctx = await browser.newContext({
    viewport: { width: w, height: h },
    recordVideo: { dir: outDir, size: { width: w, height: h } },
    deviceScaleFactor: 1,
  });
  const page = await ctx.newPage();
  await page.goto('file:///' + file.replace(/\\/g, '/'), { waitUntil: 'load' });
  // las fuentes van incrustadas: espera a que estén listas y reinicia la
  // animación desde cero, para no capturar el primer instante en fallback
  await page.evaluate(() => document.fonts.ready);
  await page.addStyleTag({ content:
    'html,body{margin:0;padding:0;background:#000;overflow:hidden}' +
    '.stage,.fit{max-width:none!important;width:100vw!important;height:100vh!important;' +
    'aspect-ratio:auto!important;border-radius:0!important}' });
  await page.evaluate(() => document.getAnimations().forEach(a => { try { a.cancel(); a.play(); } catch (e) {} }));
  await page.waitForTimeout(s * 1000 + 400);
  await ctx.close();
  await browser.close();
})();
'@ | Set-Content -Path $recorder -Encoding utf8

$ok = 0; $fail = 0
$total = ($piezas | Measure-Object).Count
$i = 0

foreach ($p in $piezas) {
  $i++
  $src = if ($p.d) { Join-Path $social "$($p.d)\$($p.n).html" } else { Join-Path $social "$($p.n).html" }
  if (-not (Test-Path $src)) { Write-Host "[$i/$total] FALTA  $($p.n)" -ForegroundColor DarkYellow; $fail++; continue }

  $mins = [math]::Floor($p.s / 60); $rest = $p.s % 60
  $dur  = if ($mins -gt 0) { "{0}:{1:D2}" -f $mins, $rest } else { "$($p.s)s" }
  Write-Host "[$i/$total] $($p.n)  ($($p.w)x$($p.h), $dur)" -ForegroundColor Cyan

  $work = Join-Path $tmp $p.n
  Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $work | Out-Null

  node $recorder $src $work $p.w $p.h $p.s
  if ($LASTEXITCODE -ne 0) { Write-Host "   error grabando" -ForegroundColor Red; $fail++; continue }

  $webm = Get-ChildItem $work -Filter *.webm | Select-Object -First 1
  if (-not $webm) { Write-Host "   no se generó vídeo" -ForegroundColor Red; $fail++; continue }

  $mp4 = Join-Path $Salida "$($p.n).mp4"
  & $ffmpeg -y -loglevel error -i $webm.FullName `
      -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -r 30 `
      -vf "scale=$($p.w):$($p.h):flags=lanczos" -movflags +faststart $mp4
  if ($LASTEXITCODE -ne 0) { Write-Host "   error convirtiendo" -ForegroundColor Red; $fail++; continue }

  Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
  $mb = [math]::Round((Get-Item $mp4).Length / 1MB, 1)
  Write-Host "   OK  $mb MB" -ForegroundColor Green
  $ok++
}

Write-Host ""
Write-Host "Terminado: $ok correctos, $fail con problemas." -ForegroundColor White
Write-Host "Carpeta: $Salida"
