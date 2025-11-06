# Data Source para buscar a AMI mais recente do Ubuntu 24.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID do proprietário oficial da Canonical (Ubuntu)

  filter {
    name = "name"
    # O * funciona como curinga, pegando a versão mais atualizada dessa data
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "web_ssh" {
  name        = "${var.project_name}-sg"
  description = "Permite trafego SSH e HTTP"

  # Regra de entrada (Ingress) para SSH
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ATENÇÃO: Em produção, restrinja ao seu IP.
  }

  # Regra de entrada (Ingress) para HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra de saída (Egress). Permite que a instância inicie conexões para fora
  # (essencial para baixar atualizações e pacotes).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 significa todos os protocolos
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "docker_host" {
  # Usa o ID da AMI encontrado pelo nosso data source
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Vincula o Security Group que criamos acima à esta instância
  vpc_security_group_ids = [aws_security_group.web_ssh.id]

  # Script de User Data para instalação automática do Docker
  user_data = <<-EOF
              #!/bin/bash
              # Atualiza a lista de pacotes
              apt-get update -y
              
              # Instala dependências necessárias para o Docker
              apt-get install -y ca-certificates curl

              # Cria o diretório para as chaves do repositório Docker
              install -m 0755 -d /etc/apt/keyrings
              
              # Baixa a chave GPG oficial do Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc

              # Adiciona o repositório oficial do Docker às fontes do APT
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              # Atualiza novamente para reconhecer os pacotes do novo repositório
              apt-get update -y
              
              # Instala o Docker Engine e plugins
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Permite que o usuário padrão 'ubuntu' use o Docker sem sudo
              usermod -aG docker ubuntu

              # Inicia um container Nginx na porta 80 para testarmos o acesso web imediatamente
              docker run -d --name servidor-web -p 80:80 nginx:latest
              EOF

  tags = {
    Name = "${var.project_name}-DockerHost"
  }
}

# Cria um Elastic IP e já o associa à instância criada
resource "aws_eip" "docker_host_ip" {
  domain   = "vpc"
  instance = aws_instance.docker_host.id

  tags = {
    Name = "${var.project_name}-EIP"
  }
}