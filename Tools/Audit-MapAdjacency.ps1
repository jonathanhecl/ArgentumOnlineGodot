# Audit-MapAdjacency.ps1 — Verifica Assets/Init/map_neighbors.json contra los .Inf del servidor.
#
# Regla de adyacencia: Y.N=X y X.S=Y (mutuo) => adyacentes. El seed debe registrar
# TODO par mutuo votado, sin saltearse ninguno. Matices reales del formato VB6:
#  - Cruce ONE-WAY (A.D->B votado, B.opuesto(D)->otro votado): teleport dirigido real
#    (dungeons). El seed conserva ambos reclamos dirigidos.
#  - Duplicado mismo-vecino (A.D1->B y A.D2->B, p.ej. 168 E+W -> 37): el Exportador
#    conserva el par con mas votos (_ReconcileCardinalPairs/_RemoveOppositeDoubleLinks).
#  - Reciproca materializada (seed A.D->B sin votos propios, con B.opuesto(D)->A votado):
#    la genera _AddReciprocalCardinalLinks.
#  - Diagonales: derivadas best-effort, no se auditan como cardinales.
#
# Uso: powershell -File Tools/Audit-MapAdjacency.ps1  (desde la raiz del proyecto)
# Exit 1 si hay FAIL.

param([string]$Neighbors = "Assets/Init/map_neighbors.json")

$opp = @{ N = "S"; S = "N"; E = "W"; W = "E" }
$cardinalDirs = @("N", "S", "E", "W")
$BAND = 15
$fail = 0

function Is-Crossing($e, [string]$d) {
  switch ($d) {
    "N" { return ($e.y -le $BAND) -and ($e.dy -ge (101 - $BAND)) }
    "S" { return ($e.y -ge (101 - $BAND)) -and ($e.dy -le $BAND) }
    "E" { return ($e.x -ge (101 - $BAND)) -and ($e.dx -le $BAND) }
    "W" { return ($e.x -le $BAND) -and ($e.dx -ge (101 - $BAND)) }
  }
  return $false
}

function Get-Exits([int]$mid) {
  $p = "Assets/Maps/Mapa${mid}.Inf"
  if (-not (Test-Path -LiteralPath $p)) { return @() }
  $b = [System.IO.File]::ReadAllBytes($p); $off = 10; $ex = @()
  for ($y = 1; $y -le 100; $y++) {
    for ($x = 1; $x -le 100; $x++) {
      if ($off -ge $b.Length) { break }
      $f = $b[$off]; $off++
      if ($f -band 1) {
        $dm = [int][BitConverter]::ToInt16($b, $off)
        $dx = [int][BitConverter]::ToInt16($b, ($off + 2))
        $dy = [int][BitConverter]::ToInt16($b, ($off + 4)); $off += 6
        if ($dm -gt 0 -and $dm -ne $mid) { $ex += [pscustomobject]@{ x = $x; y = $y; dest = $dm; dx = $dx; dy = $dy } }
      }
      if ($f -band 2) { $off += 2 }
      if ($f -band 4) { $off += 4 }
    }
  }
  return $ex
}

# Votos por (mapa, dir): mejor destino con >=1 cruce (igual que MIN_PASSAGE_EXITS=1)
$files = Get-ChildItem "Assets/Maps/Mapa*.Inf" | ForEach-Object { [int]($_.BaseName -replace "Mapa", "") } | Sort-Object
$directed = @{}
foreach ($m in $files) {
  $bydest = @{}
  foreach ($e in (Get-Exits $m)) {
    if (-not $bydest.ContainsKey($e.dest)) { $bydest[$e.dest] = @() }
    $bydest[$e.dest] += $e
  }
  foreach ($dest in $bydest.Keys) {
    $g = $bydest[$dest]
    foreach ($d in $cardinalDirs) {
      $c = @($g | Where-Object { Is-Crossing $_ $d }).Count
      if ($c -ge 1 -and ((-not $directed.ContainsKey($m)) -or (-not $directed[$m].ContainsKey($d)) -or ($c -gt $directed[$m][$d].votes))) {
        if (-not $directed.ContainsKey($m)) { $directed[$m] = @{} }
        $directed[$m][$d] = @{ dest = $dest; votes = $c }
      }
    }
  }
}

function Has-Votes([int]$a, [string]$d, [int]$b) {
  return ($directed.ContainsKey($a) -and $directed[$a].ContainsKey($d) -and $directed[$a][$d].dest -eq $b)
}

$raw = Get-Content $Neighbors -Raw | ConvertFrom-Json
$seed = @{}
foreach ($k in $raw.PSObject.Properties.Name) {
  $mid = [int]$k; $seed[$mid] = @{}
  foreach ($dd in $raw.$k.PSObject.Properties.Name) { $seed[$mid][$dd] = [int]$raw.$k.$dd.id }
}
function Seed-Link([int]$a, [string]$d) {
  if ($seed.ContainsKey($a) -and $seed[$a].ContainsKey($d)) { return $seed[$a][$d] }
  return 0
}
function Seed-Links-To([int]$a, [int]$b) {
  # Direcciones cardinales del seed en A que apuntan a B
  $r = @()
  if ($seed.ContainsKey($a)) { foreach ($d in $seed[$a].Keys) { if (($cardinalDirs -contains $d) -and $seed[$a][$d] -eq $b) { $r += $d } } }
  return $r
}

# 1. Pares mutuos votados: el seed debe registrarlos (en este par de dirs o en el
#    par duplicado que el Exportador conservo por votos).
$mutualTotal = 0; $dedupOk = 0
$seenPair = @{}
foreach ($a in $directed.Keys) {
  foreach ($d in $directed[$a].Keys) {
    $b = $directed[$a][$d].dest; $od = $opp[$d]
    if (-not (Has-Votes $b $od $a)) { continue }
    $pk = if ($a -lt $b) { "$a-$b" } else { "$b-$a" }
    if ($seenPair.ContainsKey($pk)) { continue }
    $seenPair[$pk] = $true
    $mutualTotal++
    if ((Seed-Link $a $d) -eq $b -and (Seed-Link $b $od) -eq $a) { continue }
    # Aceptar si el seed registra el par en otro par de dirs mutuamente consistente
    $altOk = $false
    foreach ($d2 in (Seed-Links-To $a $b)) {
      if ((Seed-Link $b $opp[$d2]) -eq $a) { $altOk = $true; break }
    }
    if ($altOk) { $dedupOk++; continue }
    Write-Host ("FAIL mutuo omitido: {0}.{1}<->{2}.{3}" -f $a, $d, $b, $od)
    $fail++
  }
}
Write-Host ("Mutuos votados: {0} (registrados directos o por duplicado conservado: {1} dedup)" -f $mutualTotal, $dedupOk)

# 2. Cardinales del seed: al menos un lado con votos (propios o reciproca materializada).
foreach ($a in $seed.Keys) {
  foreach ($d in @($seed[$a].Keys)) {
    if (-not ($cardinalDirs -contains $d)) { continue }
    $b = $seed[$a][$d]; $od = $opp[$d]
    if (-not (Has-Votes $a $d $b) -and -not (Has-Votes $b $od $a)) {
      Write-Host ("FAIL seed sin respaldo: {0}.{1}->{2} (sin votos en ningun lado)" -f $a, $d, $b)
      $fail++
    }
  }
}

# 3. Reclamos votados one-way/duplicados: el seed debe conservar la adyacencia con B
#    en alguna direccion (la votada o la reconciliada).
foreach ($a in $directed.Keys) {
  foreach ($d in $directed[$a].Keys) {
    $b = $directed[$a][$d].dest
    if ((Seed-Links-To $a $b).Count -eq 0) {
      Write-Host ("FAIL reclamo perdido: {0}.{1}->{2} ({3} votos) sin enlace en el seed" -f $a, $d, $b, $directed[$a][$d].votes)
      $fail++
    }
  }
}

if ($fail -gt 0) { Write-Host ("RESULTADO: {0} FALLOS" -f $fail); exit 1 }
Write-Host "RESULTADO: OK — todas las adyacencias mutuas registradas, nada omitido ni inventado"
exit 0
