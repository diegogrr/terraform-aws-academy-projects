# Infraestrutura Completa de Rede (VPC) com EC2, Docker e IPv4/IPv6

Este projeto representa uma evolução significativa em relação aos laboratórios anteriores (`terraform-ec2-docker` e `terraform-ec2-docker-elastic-ip`). Aqui, não apenas provisionamos um servidor, mas construímos toda a rede virtual que o hospeda, simulando um ambiente de produção real com segmentação de redes públicas e privadas.

## Arquitetura da Solução

Este código Terraform provisiona a seguinte infraestrutura:

* **VPC (Virtual Private Cloud)**: Uma rede isolada com bloco CIDR `10.0.0.0/16` e suporte nativo a IPv6.
* **Sub-redes**: Distribuição em duas Zonas de Disponibilidade (AZs) para alta disponibilidade:
    * 2 Sub-redes Públicas (`10.0.101.0/24`, `10.0.102.0/24`) com IPv4 e IPv6.
    * 2 Sub-redes Privadas (`10.0.1.0/24`, `10.0.2.0/24`) apenas IPv4 interno.
* **Conectividade Internet**:
    * **Internet Gateway (IGW)** para permitir tráfego de entrada/saída nas sub-redes públicas.
    * **NAT Gateway** para permitir que instâncias nas sub-redes privadas acessem a internet (para atualizações, por exemplo) sem serem acessíveis externamente.
* **Roteamento**: Tabelas de rotas distintas para sub-redes públicas (via IGW) e privadas (via NAT Gateway).
* **Servidor de Aplicação**: Uma instância EC2 Ubuntu com Docker, localizada na Sub-rede Pública 1, com:
    * Elastic IP (IPv4 fixo).
    * Endereço IPv6 público global.
    * Security Group permitindo SSH (porta 22) e HTTP (porta 80) via IPv4 e IPv6.

## Pré-requisitos

1.  **Terraform CLI** instalado (v1.2+).
2.  **Credenciais AWS** configuradas.

## Execução no AWS Academy Learner Lab

Este laboratório é compatível com o Learner Lab, mas requer atenção especial aos custos.

Para executar:

```bash
terraform init
terraform plan
terraform apply
```

Aguarde a criação de todos os recursos de rede (o NAT Gateway pode levar alguns minutos para ficar disponível).

## ⚠️ ALERTA CRÍTICO DE CUSTO (NAT Gateway)

Este laboratório cria um **NAT Gateway**, um recurso que tem um custo fixo por hora elevado para os padrões do orçamento do Learner Lab (aprox. $0.045/hora).

**NÃO DEIXE ESTE LABORATÓRIO RODANDO SEM NECESSIDADE.**

Se você esquecer esta infraestrutura ligada por vários dias, ela drenará rapidamente seus créditos, podendo levar ao bloqueio da sua conta de estudante. Sempre execute o comando de destruição ao finalizar seus estudos do dia.

## Adaptação para Conta AWS Padrão

Se utilizar fora do Academy, altere a chave SSH conforme necessário:

```Bash
terraform apply -var="key_name=sua-chave-pessoal"
```

## Limpeza de Recursos

Para evitar cobranças indesejadas e garantir a preservação do seu orçamento estudantil, destrua a infraestrutura após o uso:

```Bash
terraform destroy
```