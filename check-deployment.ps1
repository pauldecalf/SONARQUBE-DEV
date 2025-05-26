# Script PowerShell de vérification du déploiement SonarQube
# Serveur cible: 168.231.87.2

$ServerIP = "168.231.87.2"
$DokployPort = "3000"
$SonarPort = "9000"

Write-Host "🔍 Vérification du déploiement SonarQube sur $ServerIP" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Fonction pour tester la connectivité
function Test-Connectivity {
    param(
        [string]$Url,
        [string]$Service
    )
    
    Write-Host "📡 Test de connectivité $Service ($Url)... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 30 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ OK" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ ÉCHEC" -ForegroundColor Red
        return $false
    }
    
    return $false
}

# Test de l'interface Dokploy
Write-Host ""
Write-Host "🐳 Vérification de Dokploy" -ForegroundColor Yellow
Test-Connectivity "http://$ServerIP`:$DokployPort" "Dokploy"

# Test de SonarQube
Write-Host ""
Write-Host "📊 Vérification de SonarQube" -ForegroundColor Yellow
Test-Connectivity "http://$ServerIP`:$SonarPort" "SonarQube Web"

# Test de l'API SonarQube
Write-Host ""
Write-Host "🔌 Vérification de l'API SonarQube" -ForegroundColor Yellow
$ApiUrl = "http://$ServerIP`:$SonarPort/api/system/status"
Write-Host "📡 Test API SonarQube ($ApiUrl)... " -NoNewline

try {
    $apiResponse = Invoke-RestMethod -Uri $ApiUrl -TimeoutSec 30 -ErrorAction Stop
    if ($apiResponse.status -eq "UP") {
        Write-Host "✅ OK (SonarQube fonctionne)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Réponse reçue mais statut inconnu: $($apiResponse | ConvertTo-Json)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Pas de réponse" -ForegroundColor Red
}

# Test de la page de login SonarQube
Write-Host ""
Write-Host "🔐 Vérification de la page de login" -ForegroundColor Yellow
$LoginUrl = "http://$ServerIP`:$SonarPort/sessions/new"
Write-Host "📡 Test page de login ($LoginUrl)... " -NoNewline

try {
    $loginResponse = Invoke-WebRequest -Uri $LoginUrl -TimeoutSec 30 -UseBasicParsing -ErrorAction Stop
    if ($loginResponse.Content -match "login") {
        Write-Host "✅ OK" -ForegroundColor Green
    } else {
        Write-Host "❌ ÉCHEC" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ ÉCHEC" -ForegroundColor Red
}

Write-Host ""
Write-Host "📈 Tests de performance" -ForegroundColor Yellow
Write-Host "======================"

# Test de latence
Write-Host "⏱️ Latence vers le serveur... " -NoNewline
try {
    $ping = Test-Connection -ComputerName $ServerIP -Count 3 -Quiet
    if ($ping) {
        $pingResult = Test-Connection -ComputerName $ServerIP -Count 3
        $avgTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
        Write-Host "$([math]::Round($avgTime))ms" -ForegroundColor Green
    } else {
        Write-Host "Non disponible" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Non disponible" -ForegroundColor Yellow
}

# Test de débit (basique)
Write-Host "🚀 Test de débit HTTP... " -NoNewline
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Invoke-WebRequest -Uri "http://$ServerIP`:$SonarPort" -TimeoutSec 30 -UseBasicParsing -ErrorAction Stop | Out-Null
    $stopwatch.Stop()
    Write-Host "$([math]::Round($stopwatch.Elapsed.TotalSeconds, 2))s" -ForegroundColor Green
}
catch {
    Write-Host "Non disponible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔗 URLs utiles" -ForegroundColor Yellow
Write-Host "=============="
Write-Host "🐳 Dokploy:        http://$ServerIP`:$DokployPort"
Write-Host "📊 SonarQube:      http://$ServerIP`:$SonarPort"
Write-Host "🔌 API Status:     http://$ServerIP`:$SonarPort/api/system/status"
Write-Host "🔐 Login:          http://$ServerIP`:$SonarPort/sessions/new"
Write-Host "📚 Documentation: http://$ServerIP`:$SonarPort/documentation"

Write-Host ""
Write-Host "💡 Prochaines étapes" -ForegroundColor Yellow
Write-Host "==================="
Write-Host "1. Connectez-vous à Dokploy: http://$ServerIP`:$DokployPort"
Write-Host "2. Créez un nouveau projet 'Compose'"
Write-Host "3. Uploadez le fichier docker-compose.dokploy.yml"
Write-Host "4. Configurez les variables d'environnement"
Write-Host "5. Déployez le projet"
Write-Host "6. Accédez à SonarQube: http://$ServerIP`:$SonarPort"
Write-Host "7. Login: admin / admin (à changer immédiatement)"

Write-Host ""
Write-Host "✅ Vérification terminée !" -ForegroundColor Green 