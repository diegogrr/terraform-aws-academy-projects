# 1. VPC: A base da nossa rede isolada
resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true # Solicita um bloco IPv6 da Amazon
  enable_dns_hostnames             = true
  enable_dns_support               = true

  tags = {
    Name = "${var.project_name}-VPC"
  }
}

# 2. Internet Gateway: A porta de saída para a internet pública
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# Data source para pegar nomes das zonas dinamicamente (ex: us-east-1a, us-east-1b)
data "aws_availability_zones" "available" {
  state = "available"
}

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

# --- Sub-redes Públicas ---

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  # Configuração IPv6
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 101)
  assign_ipv6_address_on_creation = true

  tags = { Name = "${var.project_name}-Public-Subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 102)
  assign_ipv6_address_on_creation = true

  tags = { Name = "${var.project_name}-Public-Subnet-2" }
}

# --- Sub-redes Privadas ---

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "${var.project_name}-Private-Subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "${var.project_name}-Private-Subnet-2" }
}

# Elastic IP para o NAT Gateway (ele precisa de um IP fixo para sair para a rua)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-NAT-EIP" }
}

# NAT Gateway: permite que as privadas acessem a internet, mas não sejam acessadas
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  # O NAT deve ficar na subnet PÚBLICA para conseguir sair pelo IGW
  subnet_id = aws_subnet.public_1.id

  tags = { Name = "${var.project_name}-NAT-GW" }

  # Garante que o IGW exista antes de tentar criar o NAT
  depends_on = [aws_internet_gateway.igw]
}

# --- Tabela de Roteamento Pública ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # Rota padrão IPv4 para a Internet via IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # Rota padrão IPv6 para a Internet via IGW
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-Public-RT" }
}

# Associa as sub-redes públicas a esta tabela
resource "aws_route_table_association" "pub_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "pub_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# --- Tabela de Roteamento Privada ---
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  # Rota padrão IPv4 para a Internet via NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  # Nota: Não configuramos saída IPv6 para privadas neste exemplo simples 
  # (exigiria um Egress-Only Internet Gateway).

  tags = { Name = "${var.project_name}-Private-RT" }
}

# Associa as sub-redes privadas
resource "aws_route_table_association" "priv_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "priv_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group agora deve ser atrelado à nossa VPC específica
resource "aws_security_group" "web_ssh" {
  name        = "${var.project_name}-sg"
  description = "Permite trafego SSH e HTTP IPv4/IPv6"
  vpc_id      = aws_vpc.main.id # <--- IMPORTANTE: especificar a VPC

  ingress {
    description = "SSH IPv4"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH IPv6"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"] # <--- Regra IPv6
  }

  ingress {
    description = "HTTP IPv4"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP IPv6"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"] # <--- Regra IPv6
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"] # <--- Saída IPv6 permitida
  }

  tags = { Name = "${var.project_name}-sg" }
}

# Instância EC2
resource "aws_instance" "docker_host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Define explicitamente em qual sub-rede a máquina vai nascer
  subnet_id = aws_subnet.public_1.id

  vpc_security_group_ids = [aws_security_group.web_ssh.id]

  # Solicita 1 IP IPv6 do pool da sub-rede
  ipv6_address_count = 1

  # Script de User Data (MANTIDO IGUAL À VERSÃO ANTERIOR)
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

  tags = { Name = "${var.project_name}-DockerHost" }
}

# Elastic IP da Instância (separado do NAT)
resource "aws_eip" "docker_host_ip" {
  domain   = "vpc"
  instance = aws_instance.docker_host.id
  tags     = { Name = "${var.project_name}-Instance-EIP" }
}
