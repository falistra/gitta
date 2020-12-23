# versione 1.2 del 23/12/2020
Write-Output "========== gitta.ps1 versione 2.0 ===========" 
$superfolder=$args[0]

if(-not($superfolder)) { 
  Write-Output "Parametro (make|cgi|batch) non specificato"
  Write-Output "Uso: \gitta.ps1 <make|cgi|batch> <cartella>" 
  exit
  }

if($superfolder -notin "make", "cgi", "batch") { 
  Write-Output 'Parametro diverso da make o cgi o batch'
  Write-Output "Uso: \gitta.ps1 <make|cgi|batch> <cartella>"
  exit
}

$folder=$args[1]
if(-not($folder)) { 
  Write-Output "Parametro 'cartella' non specificato" 
  Write-Output "Uso: \gitta.ps1 <make|cgi|batch> <cartella>" 
  exit
}

if ($superfolder -eq "make") {
  $path="\discoe Script\shell\batch\make\$($folder)"
}
if ($superfolder -eq "cgi") {
  $path="\discoe Script\cgi\$($folder)"
}
if ($superfolder -eq "batch") {
  $path="\discoe Script\shell\batch\$($folder)"
}


$pathCompleto = "\\mdnsvil.manord.com$($path)"
if (-not(Test-Path $pathCompleto -PathType Container)) {
  Write-Output "La cartella $($pathCompleto) non esiste"
  C:
  exit
}

$env:GIT_SSH="C:\Program Files\PuTTY\plink.exe"

Set-Location "\\mdnsvil.manord.com$($path)"
Write-Output "============ Posizionato su mdnsvil ================="

$stato = $null;
$stato = git status -s
if ($null -ne $stato) {
  Write-Host "C'e' qualcosa di pendente su cui fare Add (in stage) / Commit"
  Write-Host "1: Sceglere i files, fare add/commit e proseguire"
  Write-Host "2: NON fare add/committ e proseguire dall'ultimo commit"
  Write-Host "3: Interrompere lo script senza conseguenze"
  Write-Host "Scrivere 1 o 2 o 3:"
  $risposta = Read-Host 
  if ($risposta -eq "3") {
    Write-Host "Script interrotto"
    c:
    exit
  }

  if ($risposta -eq "1") {
    Write-Host "Lista files da aggiungere in stage:"
    $lista_files = git status -s
    if ($lista_files -is [String]) {
      $lista_files = @($lista_files)
    }
    for($a=0; $a -lt $lista_files.Count; $a++) {
      Write-Output "$a : $($lista_files[$a])"
    }
    $stringa_lista_files_scelti = Read-Host -Prompt "Lista degli indici, separati da virgole, dei files scelti (p.e. 0,1,2)"
    $lista_indici_files_scelti = $stringa_lista_files_scelti.split(",")
    $lista_files_scelti = New-Object System.Collections.Generic.List[string]
    Write-Host "Files scelti:"
    for($i=0; $i -lt $lista_indici_files_scelti.Count; $i++) {
      Write-Output "$($lista_indici_files_scelti[$i]) : $($lista_files[$($lista_indici_files_scelti[$i])])"
      $file_scelto = "$($lista_files[$($lista_indici_files_scelti[$i])])"
      $separa = $file_scelto.trim() -split {$_ -eq " "}
      $lista_files_scelti.add("$($separa[1])")
    }
    $fai_commit = Read-Host -Prompt "Proseguo con add/commit (si/no)?"
    if ($fai_commit -eq "no") {
      Write-Output "Esecuzione interrotta"
      C:
      exit
    }
    for($z=0; $z -lt $lista_files_scelti.Count; $z++) {
      Write-Output "git add $($lista_files_scelti[$z])"
      git add $lista_files_scelti[$z]
    }
    $messaggio_commit = "Non specificato"
    $messaggio_commit_ricevuto = $null
    $messaggio_commit_ricevuto = Read-Host -Prompt "Messaggio di commit (Non specificato)"
    if (-not ($messaggio_commit_ricevuto -eq ""))  {
      $messaggio_commit = $messaggio_commit_ricevuto 
    }
    Write-Output "git commit -m '$($messaggio_commit)'"
    git commit -m $messaggio_commit
  }
}

$inizio=(GET-DATE)
git push origin developer
Write-Output "====== Fatta la push su developer ===================="

Write-Output "============ Posizionato su mdnprod ================="
Set-Location "\\mdnprod.manord.com$($path)"
git pull origin developer
Write-Output "====== Fatta la pull da developer ===================="
git push origin production 
Write-Output "====== Fatta la push su production ==================="

Set-Location "\\mdnsvil.manord.com$($path)"
Write-Output "============ (Ri)Posizionato su mdnsvil =============="
git fetch --all

$tempo_impiegato=[Math]::Abs((New-TimeSpan -End ($inizio)).Seconds)
Write-Output "Tempo impiegato: $tempo_impiegato secondi"
Write-Output "====================== FINE =========================="
Write-Output "====================== FINE =========================="
C:
