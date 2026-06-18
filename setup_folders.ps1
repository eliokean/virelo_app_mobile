$features = @("auth", "wallet", "transfer", "deposit", "kyc", "card", "billing", "notifications", "conversion", "profile", "history", "onboarding", "share")
$layers = @("data/datasources", "data/models", "data/repositories", "domain/entities", "domain/repositories", "domain/usecases", "presentation/bloc", "presentation/pages", "presentation/widgets")

foreach ($feature in $features) {
    foreach ($layer in $layers) {
        $path = "lib/features/$feature/$layer"
        New-Item -ItemType Directory -Force -Path $path | Out-Null
        New-Item -ItemType File -Force -Path "$path/.gitkeep" | Out-Null
    }
}

$coreDirs = @("network", "theme", "constants", "utils")
foreach ($dir in $coreDirs) {
    New-Item -ItemType Directory -Force -Path "lib/core/$dir" | Out-Null
}

$configDirs = @("di", "env", "routes")
foreach ($dir in $configDirs) {
    New-Item -ItemType Directory -Force -Path "lib/config/$dir" | Out-Null
}

New-Item -ItemType Directory -Force -Path "lib/l10n" | Out-Null

Write-Host "✅ Structure créée avec succès"
