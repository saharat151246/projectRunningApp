Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -Path $file -Raw
    $newContent = $content -replace '\.withOpacity\(', '.withValues(alpha: '
    if ($newContent -ne $content) {
        Set-Content -Path $file -Value $newContent -NoNewline
        Write-Host "Fixed: $file"
    }
}
Write-Host "Done!"
