#!/bin/bash

# Defina o diretório do seu site
echo "Digite o domínio ou caminho completo do diretório (exemplo: /var/www/seusite.com.br): "
read dominio

# Verifica se o diretório existe
if [ ! -d "$dominio" ]; then
    echo "O diretório $dominio não existe. Verifique o caminho."
    exit 1
fi

# Adiciona o usuário do FTP ao grupo www-data
# Substitua ftpuser pelo nome do usuário do FTP (por exemplo, 'ftpuser', 'userftp' etc.)
echo "Digite o nome do usuário FTP (exemplo: ftpuser): "
read usuario_ftp

echo "Adicionando $usuario_ftp ao grupo www-data..."
sudo usermod -aG www-data "$usuario_ftp"

# Ajusta a propriedade do diretório e arquivos para o grupo www-data
echo "Alterando dono e grupo para www-data..."
sudo chown -R www-data:www-data "$dominio"

# Ajusta as permissões para diretórios e arquivos
echo "Ajustando permissões para diretórios e arquivos..."

# Definindo 2775 para diretórios e 664 para arquivos
find "$dominio" -type d -exec sudo chmod 2775 {} \;
find "$dominio" -type f -exec sudo chmod 664 {} \;

# Fim
echo "Permissões configuradas com sucesso para o diretório $dominio e o usuário FTP $usuario_ftp!"
