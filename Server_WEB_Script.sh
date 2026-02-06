#!/bin/bash

# Variáveis configuráveis

DOMINIO="meusite.local"
USUARIO_FTP="usuarioweb"
SENHA_FTP="SenhaForteAqui123"
PASTA_SITE="/var/www/$DOMINIO"

echo "[1/10] Atualizando pacotes..."
apt update && apt upgrade -y

echo "[2/10] Instalando Apache, PHP, extensões e utilitários..."
apt install -y 
apache2 
php 
libapache2-mod-php 
php-cli 
php-curl 
php-mbstring 
php-xml 
php-zip 
php-intl 
php-bcmath 
php-mysql 
php-pgsql 
php-sqlite3 
vsftpd 
certbot 
python3-certbot-apache

echo "[3/10] Criando diretório do site em $PASTA_SITE"
mkdir -p "$PASTA_SITE"

echo "[4/10] Criando usuário FTP ($USUARIO_FTP) com home em $PASTA_SITE"
useradd -m -d "$PASTA_SITE" -s /bin/bash "$USUARIO_FTP"
echo "$USUARIO_FTP:$SENHA_FTP" | chpasswd

echo "[5/10] Adicionando usuário ao grupo www-data"
usermod -aG www-data "$USUARIO_FTP"

echo "[6/10] Ajustando permissões do site para edição e herança de grupo..."
chown -R "$USUARIO_FTP":www-data "$PASTA_SITE"
chmod 755 "$PASTA_SITE"
find "$PASTA_SITE" -type d -exec chmod 2775 {} ;
find "$PASTA_SITE" -type f -exec chmod 664 {} ;

echo "[7/10] Criando index.php de página em construção..."
cat <<EOF > "$PASTA_SITE/index.php"

<?php
header('Content-Type: text/html; charset=UTF-8');
?>

<!DOCTYPE html>

<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Página em Construção</title>
</head>
<body>
  <h1>Página em Construção</h1>
  <p>Estamos trabalhando para trazer novidades em breve.</p>
</body>
</html>
EOF

echo "[7.1/10] Criando arquivo .htaccess para URLs amigáveis..."
cat <<EOF > "$PASTA_SITE/.htaccess"
RewriteEngine On

RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php?url=$1 [QSA,L]
EOF

echo "[8/10] Criando VirtualHost do Apache..."
VHOST="/etc/apache2/sites-available/$DOMINIO.conf"
cat <<EOF > "$VHOST"
<VirtualHost *:80>
ServerAdmin webmaster@$DOMINIO
ServerName $DOMINIO
DocumentRoot $PASTA_SITE

```
<Directory $PASTA_SITE>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

ErrorLog \${APACHE_LOG_DIR}/$DOMINIO-error.log
CustomLog \${APACHE_LOG_DIR}/$DOMINIO-access.log combined
```

</VirtualHost>
EOF

a2ensite "$DOMINIO.conf"
a2enmod rewrite

echo "[9/10] Reiniciando Apache..."
systemctl restart apache2

echo "[10/10] Ajustando configuração do vsftpd..."
cp /etc/vsftpd.conf /etc/vsftpd.conf.bkp
sed -i 's/^#?write_enable=.*/write_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#?chroot_local_user=.*/chroot_local_user=YES/' /etc/vsftpd.conf
sed -i 's/^#?local_enable=.*/local_enable=YES/' /etc/vsftpd.conf
grep -q "^allow_writeable_chroot=YES" /etc/vsftpd.conf || echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf
systemctl restart vsftpd

echo "Instalação finalizada com sucesso."
echo "Acesse http://$DOMINIO para verificar."
echo "Para SSL após apontar DNS:"
echo "sudo certbot --apache -d $DOMINIO"
echo "Script desenvolvido por Felipe Augusto Weissheimer"
