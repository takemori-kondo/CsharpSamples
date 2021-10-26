﻿# ローカルクライアント側  :192.168.3.2
# リモートホスト側        :192.168.3.8 PowerShellTestUser/p@55w0rd
#
# 【PowerShell基礎知識】
# WinRM                                              : Windows Remote Management。PSをリモートする場合には有効にすることが必須
# Scope                                              : Process（現在のみ有効）、CurrentUser（ユーザに対して永続）、LocalMachine（マシン全体で永続）
#    各コマンドのデフォルトスコープ
#    Set-ExecutionPolicy  : LocalMachine
#    Set-WSManQuickConfig : LocalMachine
#
# 【各コマンド概要】
# Set-ExecutionPolicy                                : スクリプトの実行やリモート、信頼された/されていないなどをどこまで許可するか
# Set-WSManQuickConfig                               : リモートからの操作を受け付けるようにする
# Enable-PSRemoting                                  : Set-WSManQuickConfigのエイリアス？とは違うけどほぼ同じ
# winrm quickconfig                                  : WinRMを許可したうえで起動するなど
# Set-Item WSMan:\localhost\Client\TrustedHosts <IP> : クライアントから見て信頼するホストを追加する。必須
# New-NetFirewallRule                                : Windows Defenderの設定変更。iptablesやfirewalldの親戚。PrivateモードのInboundのTCPのRPC動的ポート（RPCを指定すればよい）を開ける必要あり。
#
#
#
# 【リモートホスト側の事前設定】
# # 設定 > ネットワークとインターネット > (Wifi > 現在接続中の接続、など) > ネットワークプロファイル：Private（＝信頼済み）にする
# Set-PSSessionConfiguration Microsoft.PowerShell -ShowSecurityDescriptorUI
#
# #  使用したいリモートホスト側のユーザのフルコントロールを許可
# #  ※ 注意1：もしリモートが自分自身（Localhostや自身のIP）の場合、リモートのユーザは管理者ユーザでかつ管理者としてPowerShellが実行されないとうまくいかない。接続しようとする時に、以下のエラーが出る
# #     新しいPSSession： [computerName]リモートサーバーlocalhostへの接続が失敗し、次のエラーメッセージが表示されました。WSManサービスは、指定された要求を処理するためのホストプロセスを起動できませんでした。 WSManプロバイダーのホストサーバーとプロキシが正しく登録されていることを確認してください。詳細については、about_Remote_Troubleshootingヘルプトピックを参照してください。」
# Set-ExecutionPolicy RemoteSigned -Force
# Set-WSManQuickConfig -SkipNetworkProfileCheck -Force
# Enable-PSRemoting -SkipNetworkProfileCheck -Force
#
# # FWの許可（例：Windows Defender）
# New-NetFirewallRule -DisplayName "@RemotePowerShell-enable" -Program "%SystemRoot%\System32\svchost.exe" -Profile Private -Direction Inbound -Protocol TCP -LocalPort RPC -Action Allow
# New-NetFirewallRule -DisplayName "@RemotePowerShell-enable" -Program "%SystemRoot%\System32\svchost.exe" -Profile Public -Direction Inbound -Protocol TCP -LocalPort RPC -Action Allow
#
# # リモート先がさらにネットワークドライブにアクセスしたり、多段ログインしたい場合、2nd hopを許可する（リモートデスクトップでは特に制限されていないが、PowerShellだとなぜかデフォルトで未許可）
# # なお、PSSessionを開始する際には、 -Authentication Credssp引数を明示的に指定する必要もある
# # https://devblogs.microsoft.com/scripting/enable-powershell-second-hop-functionality-with-credssp/
# Enable-WSManCredSSP -Role Server -Force
#
#
#
# 【ローカルクライアント側の事前設定】
# Set-ExecutionPolicy RemoteSigned -Force
# winrm quickconfig -force
# Set-Item WSMan:\localhost\Client\TrustedHosts <リモートのIP> -Force
# #  2nd hop対応する場合
# #  ※ 注意2：もしリモートが自分自身（Localhostや自身のIP）の場合、仮に管理者権限で実行しても2nd hopがうまくいかない
# Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
# 
#
#
# 【リモート先が自分自身の場合の注意点まとめ】
# # 1. Powershellを管理者権限で実行する必要がある
# # 2. 2nd hopが許可できない
# # 3. 2nd hopが許可できないためNew-PSSessionなどする際に、-Authentication Credssp を指定してはいけない
# # 一応、以下のようなエラーが出てくるため、解消はできるはずだが未調査
# # WinRM クライアントは要求を処理できません。このユーザー資格情報をこのターゲット コンピューターに委任することは、ターゲット コンピューターが信頼されていないため、コンピューター ポリシーにより許可されません。 ターゲット コンピューターの ID を検証可能にするには、有効な証明書を使用するよう次のコマンドで WSMAN サービスを構成してください: winrm set winrm/config/service '@{CertificateThumbprint=\"<拇印>\"}'  または、イベント ビューアーを使用し、WSMAN/<コンピューターの FQDN> という SPN を作成できなかったことを示すイベントを確認してください。このイベントが記録されていた場合は、setspn.exe を使用して手動で SPN を作成できます。 該当する SPN が存在するにもかかわらず CredSSP で Kerberos を使用してターゲット コンピューターの ID を検証できない場合、ユーザー資格情報をターゲット コンピューターに委任できるようにするには、gpedit.msc を使用し、[コンピューターの構成] -> [管理用テンプレート] -> [システム] -> [資格情報の委任] -> [NTLM のみのサーバー認証で新しい資格情報を許可する] ポリシーを確認してください。 このポリシーが有効になっており、ターゲット コンピューターの適切な SPN を使用して構成されている必要があります。 たとえば、ターゲット コンピューター名が \"myserver.domain.com\" の場合、SPN は WSMAN/myserver.domain.com または WSMAN/*.domain.com のいずれかです。 これらの変更を行ってから、要求を再試行してください。
#
#
# 【sample.ps1】
# $sum = 0;
# for ($i=0; $i -lt 100000000; $i++) {
#     $sum += $i;
# }
# echo $sum
# Get-ChildItem env:

function MakePSCredential( $ID, $PlainPassword ){
    $SecurePassword = ConvertTo-SecureString -String $PlainPassword -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($ID, $SecurePassword)
    Return $Credential
}
$Credential = MakePSCredential "PowerShellTestUser" "p@55w0rd"
$TargetServer = "192.168.3.2"
# $PSSession = New-PSSession $TargetServer -Credential $Credential -Authentication Credssp
$PSSession = New-PSSession $TargetServer -Credential $Credential
Invoke-Command -Session $PSSession -ScriptBlock { cd $env:userprofile\desktop }
Invoke-Command -Session $PSSession -ScriptBlock { .\sample.ps1 }