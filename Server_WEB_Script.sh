#!/bin/bash

# Variáveis configuráveis
DOMINIO="meusite.local"
USUARIO_FTP="usuarioweb"
SENHA_FTP="SenhaForteAqui123"
PASTA_SITE="/var/www/$DOMINIO"

echo "[1/9] Atualizando pacotes..."
apt update && apt upgrade -y

echo "[2/9] Instalando Apache, PHP, vsftpd e Certbot..."
apt install apache2 php libapache2-mod-php vsftpd certbot python3-certbot-apache -y

echo "[3/9] Criando diretório do site em $PASTA_SITE"
mkdir -p "$PASTA_SITE"

echo "[4/9] Criando usuário FTP ($USUARIO_FTP) com home em $PASTA_SITE"
useradd -m -d "$PASTA_SITE" -s /bin/bash "$USUARIO_FTP"
echo "$USUARIO_FTP:$SENHA_FTP" | chpasswd

echo "[5/9] Ajustando permissões do site para edição e herança de grupo..."
chown -R "$USUARIO_FTP":www-data "$PASTA_SITE"
# Diretórios com setgid para herdar grupo e permissão rwxrwsr-x
find "$PASTA_SITE" -type d -exec chmod 2775 {} \;
# Arquivos com permissão rw-rw-r--
find "$PASTA_SITE" -type f -exec chmod 664 {} \;

echo "[6/9] Criando index.php de página em construção..."
cat <<EOF > "$PASTA_SITE/index.php"
<?php
header('Content-Type: text/html; charset=UTF-8');
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>P&aacute;gina em Constru&ccedil;&atilde;o</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background: linear-gradient(to bottom, #000000, #FF6900);
      font-family: Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
    }
    .container {
      background-color: rgba(255, 255, 255, 0.95);
      padding: 40px;
      border-radius: 15px;
      box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
      text-align: center;
      max-width: 400px;
    }
    h1 {
      font-size: 2em;
      color: #FF6900;
      margin-bottom: 20px;
    }
    p {
      font-size: 1.2em;
      color: #333;
    }
    .spinner {
      margin: 20px auto;
      width: 40px;
      height: 40px;
      border: 4px solid #FF6900;
      border-top: 4px solid transparent;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    @keyframes spin {
      from { transform: rotate(0deg); }
      to   { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="spinner"></div>
    <h1>P&aacute;gina em Constru&ccedil;&atilde;o</h1>
    <p>Estamos trabalhando para trazer novidades em breve.<br> Obrigado pela compreens&atilde;o!</p>
  </div>
</body>
</html>
EOF

echo "[7/9] Criando VirtualHost do Apache..."
VHOST="/etc/apache2/sites-available/$DOMINIO.conf"
cat <<EOF > "$VHOST"
<VirtualHost *:80>
    ServerAdmin webmaster@$DOMINIO
    ServerName $DOMINIO
    DocumentRoot $PASTA_SITE

    <Directory $PASTA_SITE>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMINIO-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMINIO-access.log combined
</VirtualHost>
EOF

a2ensite "$DOMINIO.conf"
a2enmod rewrite
systemctl reload apache2

echo "[8/9] Ajustando configuração do vsftpd..."

cp /etc/vsftpd.conf /etc/vsftpd.conf.bkp

sed -i 's/^#\?write_enable=.*/write_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#\?chroot_local_user=.*/chroot_local_user=YES/' /etc/vsftpd.conf
sed -i 's/^#\?local_enable=.*/local_enable=YES/' /etc/vsftpd.conf

grep -q "^allow_writeable_chroot=YES" /etc/vsftpd.conf || echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf

systemctl restart vsftpd

echo "[9/9] (Opcional) Gerando certificado SSL com Let's Encrypt (Certbot)..."

echo "Instalação finalizada com sucesso. Acesse http://$DOMINIO para verificar."

echo "Você pode executar manualmente após os apontamentos serem realizados: sudo certbot --apache -d $DOMINIO"
echo "Script desenvolvido por Felipe Augusto Weissheimer"
