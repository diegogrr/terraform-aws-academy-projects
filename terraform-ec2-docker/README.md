# Provisionamento de EC2 com Docker via Terraform

Este projeto contém os arquivos de configuração do Terraform necessários para provisionar automaticamente uma instância Amazon EC2 rodando Ubuntu Server 24.04 LTS. O script de inicialização (User Data) encarrega-se de instalar o Docker Engine, configurar as permissões de usuário e iniciar um container Nginx de exemplo para validação imediata.

Este material foi desenvolvido originalmente como um exercício prático para a disciplina de Sistemas Distribuídos, focado no ambiente AWS Academy Learner Lab, mas pode ser facilmente adaptado para contas AWS padrão.

## Estrutura do Projeto

O projeto segue uma estrutura modular padrão de mercado para Terraform, facilitando a leitura e manutenção.

* **`main.tf`**: Arquivo principal que define os recursos a serem criados na AWS. Inclui a busca automática pela AMI do Ubuntu mais recente, a definição do Security Group (firewall) e a especificação da instância EC2 com seu script de *User Data*.
* **`variables.tf`**: Define as variáveis de entrada, permitindo a personalização da infraestrutura (como região, tipo de instância e nome da chave SSH) sem necessidade de alterar o código principal.
* **`outputs.tf`**: Especifica quais informações devem ser retornadas ao terminal após a execução bem-sucedida, como o endereço IP público da instância e o comando exato para conexão SSH.
* **`versions.tf`**: Estabelece as versões mínimas requeridas para o Terraform e fixa a versão do provedor AWS, garantindo a reprodutibilidade do ambiente e evitando quebras por atualizações futuras.

## Pré-requisitos

Antes de executar este projeto, certifique-se de possuir:

1.  **Terraform CLI** instalado (versão 1.2 ou superior).
2.  **Credenciais AWS** configuradas em seu ambiente local. Isso pode ser feito via AWS CLI (`aws configure`) ou definindo as variáveis de ambiente `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` (esta última é obrigatória para contas do AWS Academy).

## Execução no AWS Academy Learner Lab

Este projeto foi desenhado para funcionar nativamente no ambiente Learner Lab com as configurações padrão:

* **Região**: `us-east-1` (Norte da Virgínia).
* **Chave SSH**: `vockey`. Esta chave é pré-criada pela AWS Academy. Certifique-se de ter baixado o arquivo privado (`labsuser.pem`) do painel do laboratório para sua máquina local se desejar realizar a conexão SSH.

Para executar:

```bash
terraform init
terraform plan
terraform apply
```

Após a confirmação e finalização do `apply`, aguarde cerca de 3 a 5 minutos para que a instância inicialize completamente e o script de instalação do Docker seja concluído.

## Adaptação para Conta AWS Padrão (Free Tier)
Se você estiver executando este projeto fora do ambiente AWS Academy (por exemplo, em sua conta pessoal), duas alterações principais são necessárias:

1.  **Par de Chaves SSH**: A chave `vockey` não existe em contas padrão. Você deve criar um novo par de chaves na sua console AWS (EC2 > Key Pairs).

2.  **Atualização da Variável**: Após criar sua chave, atualize o arquivo `variables.tf` com o nome correto ou passe o valor durante a execução.

Exemplo de execução com uma chave personalizada chamada minha-chave-pessoal:

```bash
terraform apply -var="key_name=minha-chave-pessoal"
```

O tipo de instância padrão definido é `t2.micro`, que é elegível para o nível gratuito (Free Tier) na maioria das regiões.

## Limpeza de Recursos
Para evitar cobranças indesejadas ou consumo de créditos do laboratório, lembre-se de destruir a infraestrutura quando não estiver mais em uso:

```bash
terraform destroy
```