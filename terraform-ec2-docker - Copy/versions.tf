terraform {
  # Define a versão mínima do binário do Terraform requerida.
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Fixamos uma versão principal (v5) para evitar que atualizações futuras
      # quebrem nosso código (breaking changes).
      version = "~> 5.0"
    }
  }
}

# Configura o provedor AWS. A região será passada via variável
# para tornar nosso código reutilizável em diferentes locais geográficos.
provider "aws" {
  region = var.aws_region
}
