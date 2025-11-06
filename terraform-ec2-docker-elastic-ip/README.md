# Provisionamento de EC2 com Docker e IP Fixo (Elastic IP)

Este projeto é uma evolução do laboratório básico de provisionamento `terraform-ec2-docker`. Além de configurar uma instância EC2 com Docker via Terraform, ele adiciona um **Elastic IP (EIP)**. Isso garante que o endereço de acesso à sua instância permaneça o mesmo, mesmo se você desligar a máquina ou reiniciar sua sessão de laboratório.

## Diferenças para a versão básica

* **IP Persistente:** A instância agora recebe um endereço IPv4 público estático da AWS.
* **Facilidade de Acesso:** Você não precisa atualizar seus comandos SSH ou configurações de aplicação toda vez que reiniciar o laboratório.

## Estrutura do Projeto

* **`main.tf`**: Define a EC2, o Security Group e, agora, o recurso `aws_eip` (Elastic IP) e sua associação com a instância.
* **`variables.tf`**: Define as variáveis de entrada para personalização do ambiente.
* **`outputs.tf`**: Exibe o Elastic IP final e as strings de conexão atualizadas.
* **`versions.tf`**: Garante as versões corretas do Terraform e do provedor AWS.

## Pré-requisitos

1.  **Terraform CLI** instalado (versão 1.2+).
2.  **Credenciais AWS** configuradas corretamente no seu terminal.

## Execução no AWS Academy Learner Lab

As configurações padrão (`us-east-1`, chave `vockey`) são compatíveis com o ambiente Learner Lab.

Para executar:

```bash
terraform init
terraform plan
terraform apply
```

Aguarde a finalização do comando e a inicialização da instância (3 a 5 minutos para a instalação completa do Docker).

## Adaptação para Conta AWS Padrão (Free Tier)
Se usar fora do Academy, lembre-se de alterar a chave SSH:

```bash
terraform apply -var="key_name=minha-chave-pessoal"
```

**Nota sobre Custos**: Embora a instância `t3.micro` possa ser gratuita, a AWS cobra uma pequena taxa por Elastic IPs que estão alocados mas **não** associados a uma instância em execução.

## Gerenciamento de Custos e Limpeza

### ⚠️ Atenção Crítica para o Learner Lab:

No Learner Lab, instâncias são paradas automaticamente quando sua sessão termina. Um Elastic IP associado a uma instância parada continua consumindo créditos do seu orçamento.

**Recomendação Forte**: Se você não for utilizar o laboratório por vários dias, destrua a infraestrutura para evitar drenar seu orçamento silenciosamente:

```bash
terraform destroy
```