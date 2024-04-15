terraform {
  required_version = ">=1.6.0" # Versão do Terraform

  # Provedores Utilizados
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0" # Versão do AWS no Terraform
    }
  }
}

provider "aws" {
 region = "us-east-1"
 shared_config_files      = ["C:/Users/CRSCESAR/.aws/config"]
 shared_credentials_files = ["C:/Users/CRSCESAR/.aws/credentials"]
}

# Criar VPC
resource "aws_vpc" "vpc" {
 cidr_block = "193.16.0.0/16"

 tags = {
   name = "VPC_Crirar"
 }
}

# Criar Subrede Pública
resource "aws_subnet" "Subrede_Publica" {
 vpc_id     = aws_vpc.vpc.id
 cidr_block = "193.16.1.0/24"
}

# Criar Subrede Privada
resource "aws_subnet" "Subrede_Privada" {
 vpc_id     = aws_vpc.vpc.id
 cidr_block = "193.16.2.0/24"
}

# Criar Gateway de Internet 
resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.vpc.id
}

# Criar Tabelade Rotas
resource "aws_route_table" "public" {
 vpc_id = aws_vpc.vpc.id

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
 }
}

# Associar  a subrede pública à tabela
resource "aws_route_table_association" "public" {
 subnet_id      = aws_subnet.Subrede_Publica.id
 route_table_id = aws_route_table.public.id
}

# Criar Grupo de Segurança Linux
resource "aws_security_group" "Grupo_de_Seguranca_LInux" {
 name        = "grupolinux"
 description = "Allow SSH inbound traffic"
 vpc_id      = aws_vpc.vpc.id

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }
}

# Criar Grupo de Segurança Windows
resource "aws_security_group" "Grupo_de_Seguranca_Windows" {
 name        = "grupowindows"
 description = "Allow rdp inbound traffic"
 vpc_id      = aws_vpc.vpc.id

 ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }
}

# Criar EC2 Linux
resource "aws_instance" "linux" {
 ami           = "ami-058bd2d568351da34" # Debian 
 instance_type = "t2.micro"
 key_name      = "terraform" # Não esqueca de gerar a chave  pública e privada para este nome!
 vpc_security_group_ids = [aws_security_group.Grupo_de_Seguranca_LInux.id]
 subnet_id     = aws_subnet.Subrede_Publica.id
 associate_public_ip_address = true

 tags = {
    Name = "Linux_Instance"
 }
}

# Criar EC2 Windows
resource "aws_instance" "windows" {
 ami           = "ami-03cd80cfebcbb4481" # Windows Server 2022 Base
 instance_type = "t2.micro"
 key_name      = "terraform" # Não esqueca de gerar a chave  pública e privada para este nome!
 vpc_security_group_ids = [aws_security_group.Grupo_de_Seguranca_Windows.id]
 subnet_id     = aws_subnet.Subrede_Publica.id
 associate_public_ip_address = true

 tags = {
    Name = "Windows_Instance"
 }
}

