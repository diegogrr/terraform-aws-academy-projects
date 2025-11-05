variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados."
  type        = string
  default     = "us-east-1" # Região padrão utilizada nos laboratórios do Academy
}

variable "project_name" {
  description = "Nome do projeto para ser usado nas tags dos recursos."
  type        = string
  default     = "Lab-Sistemas-Distribuidos"
}

variable "instance_type" {
  description = "Tipo da instância EC2. t2.micro é elegível para o nível gratuito."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nome do par de chaves SSH já existente na AWS Academy."
  type        = string
  default     = "vockey"
}
