# 隐藏启动窗口（可选）
Add-Type -AssemblyName System.Windows.Forms

function Select-FolderDialog {
    param (
        [string]$Description = "请选择一个文件夹"
    )
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.ShowNewFolderButton = $true

    $result = $folderBrowser.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    } else {
        Write-Host "未选择任何文件夹，脚本将退出。"
        exit
    }
}

function Get-RandomString {
    param (
        [int]$Length = 8
    )
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    return -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# 提示用户选择目标文件夹
Write-Host "请选择要随机重命名文件的目标文件夹。"
$targetDirectory = Select-FolderDialog -Description "选择要随机重命名文件的文件夹"

# 提示用户输入随机字符串长度（可选）
[string]$inputLength = Read-Host "请输入随机字符串的长度（按 Enter 使用默认长度 8）"
if ([string]::IsNullOrWhiteSpace($inputLength)) {
    $stringLength = 8
} elseif ($inputLength -match '^\d+$') {
    $stringLength = [int]$inputLength
} else {
    Write-Host "输入无效，使用默认长度 8。"
    $stringLength = 8
}

# 获取所有文件（不包括子目录中的文件）
try {
    $files = Get-ChildItem -Path $targetDirectory -File -Force
    if ($files.Count -eq 0) {
        Write-Host "在目录 '$targetDirectory' 中未找到任何文件。"
        exit
    }
} catch {
    Write-Error "无法访问目录 '$targetDirectory': $_"
    exit 1
}

# 创建一个哈希表来存储已生成的随机名称，避免重复
$generatedNames = @{}

foreach ($file in $files) {
    $extension = $file.Extension
    $newName = ""
    $attempts = 0
    $maxAttempts = 100

    do {
        # 生成随机字符串
        $randomString = Get-RandomString -Length $stringLength
        $newName = "$randomString$extension"

        $attempts++

        if ($attempts -gt $maxAttempts) {
            Write-Error "无法为文件 '$($file.Name)' 生成唯一的随机名称。"
            continue
        }

    } while ($generatedNames.ContainsKey($newName) -or (Test-Path (Join-Path -Path $targetDirectory -ChildPath $newName)))

    # 记录已生成的名称
    $generatedNames[$newName] = $true

    $newPath = Join-Path -Path $targetDirectory -ChildPath $newName

    try {
        Rename-Item -Path $file.FullName -NewName $newName -Force
        Write-Host "已将 '$($file.Name)' 重命名为 '$newName'"
    } catch {
        Write-Error "无法重命名文件 '$($file.Name)'：$_"
    }
}

Write-Host "完成在 '$targetDirectory' 目录下的文件随机重命名。"
