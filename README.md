# Terraform Tech Talk

## Infraestrutura como código
- Segurança
- Consistência
- Repetição
- Versionamento
- Compartilhamento

Terraform nos permite definir recursos e infraestrutura em uma linguagem amigável aos humanos

IMG-TF1.PNG

Podemos utilizar o terraform para gerenciar uma infraestrutura multi cloud
A linguagem amigável à humano nos permite escrever infraestrutura rapidamente
Rastrear as mudanças nos recursos
Colaboração

## Casos de uso
https://www.terraform.io/intro/use-cases.html


## Passos para deploy da sua infraestrutura
1. Scopo: Identifique a infraestrutura do seu projeto
2. Desenvolver: Escreva a configuração que define sua infraestrutura
3. Initialize: Instale os provedores Terraform necessários
4. Plan: Veja as mudanças que serão realizadas
5. Apply: Aplique as mudanças em sua infraestrutura

Todas as alterações serão armazenadas no terraform state file, este atua como uma fonte de verdade para seu ambiente.
Terraform usa os state file para determinar quais mudanças fazer em sua infra.

## Provedores
Aqui é onde falamos ao terraform onde iremos nos conectar para criar os recursos.
Cada provider tem seus parâmetros, ou seja, não são todos iguais, logo verifique a documentação do terraform para configurara seu provedor corretamente.

[Browser providers](https://registry.terraform.io/browse/providers)

- provider.tf
```
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.66.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "joaosobrinho"
  region  = "sa-east-1"
}
```

### Bloco Terraform
Contém configurações do Terraform, incluindo os provedores necessários para provisionar sua infraestrutura. O parâmetro source indica de onde é para baixar esse provider, no caso é do [registry da Hashicorp](https://registry.terraform.io/browse/providers)

### Bloco Provider
O bloco **provider** configura o provedor especificado.


## Provisionar uma instância EC2
[Demo Build Infra](https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started)

### Pré requisitos
- Terraform CLI
- AWS CLI
- Uma conta AWS
- Credencias (CLIENT ID e SECRET ID)

Configure sua credencial
```bash
aws configure --profile ${PROFILE_NAME}
```

### Escreva seu código
main.tf
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.66.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "joaosobrinho"
  region  = "sa-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0e66f5495b4efdd0f"
  instance_type = "t2.micro"

  tags = {
    Name    = "ExampleAppServerInstance"
    Projeto = "XPTO"
  }
}
```

### Bloco Resource
Define os componentes da sua infraestrutura, como EC2, S3, Elastic Cache, Azure AppServices, EKS, AKS, enfim é a definição dos recursos que serão provisionados.

Declaramos duas strings antes do bloco:
1. Tipo do recurso
2. Nome do recurso


### Inicialização do diretório

Quando você cria uma nova configuração ou analisa uma existente a partir do controle de versão, você precisa inicializar o diretório com ```terraform init```.
Esse comando fará o download e a instalação dos provedores definidos na configuração, neste caso o ```aws```.
Tudo que for baixado ficará no diretório .terraform e no arquivo .terraform.lock.hcl terá as especificações das versões utilizadas.

```bash
terraform init
```

### Formatar e validar a configuração
```bash
terraform fmt
terraform validate
```

### Plan
Usamos o ```terraform plan``` para analisarmos as alterações que ocorrerão em nossa infraestrutura.
```bash
terraform plan
```

+ Indica que haverão novas configurações ou recursos completos
- Indica que configurações ou recursos serão deletados
~ Indica uma modificação de um recurso existente sem a destruição do mesmo

### Apply
Agora aplique as configurações com o ```terraform apply```. Terraform irá mostrar novamente as alterações e irá solicitar YES/NO para prosseguir
```bash
terraform apply
```

## Inspecionar o state file
Quando sua configuração é aplicada, o terraform escreve tudo no arquivo ```terraform.tfstate```. Aqui ficam IDs e propriedades dos recursos, inclusive variáveis sensíveis e isso é usado para atualizar ou destruir sua infraestrutura.

Apenas recursos gerenciados pelo Terraform estão presentes no arquivo de estado.

É importante manter esse arquivo seguro e disponível.

```bash
terraform show
```

## Alterando a infraestrutura
1. Realize a mudança da tag Name para mostrar uma mudança sem destruição do recurso.
2. Uma mudança destrututiva pode ser mostrando alterando a AMI usada, aproveitar para explicar o DATA.

## Variáveis
Até agora usamos valores hard-coded mas o Terraform nos permite o uso de variáveis para deixamos tudo mais flexível.

Nossa primeira variável será o Nome da instância
Crie o arquivo **variables.tf**
```hcl
variable "instance_name" {
  descrição = "Nome da instância EC2"
  type      = string
  default   = "appserver01"
}
```

Agora altere o valor no arquivo **main.tf**
```hcl
  tags = {
-   Name    = "ExampleAppServerInstance"
+   Name    = var.instance_name
    Projeto = "XPTO"
  }
```


## Output
São como valores de retorno e há vários casos de uso.


```hcl
output "app_server_public_ip" {
  description = IP Público da instância EC2
  value       = aws_instance.app_server.public_ip
}

output "app_server_public_dns" {
  description = DNS da instância EC2
  value       = aws_instance.app_server.public_dns
}

output "instance_id" {
  description = "ID da Instancia EC2"
  value       = aws_intance.app_server.id
}
```

## Data
```
data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}
```

## Remote State
Até agora deixamos o arquivo de estado no disco local, porém dessa forma não conseguimos compartilhar nosso código para que outras pessoas possam colaborar conosco, uma vez que eles não terão acesso ao Terraform state file onde está descrita toda a infra já implementada, então precisamos utilizar dos **backend** para mantermos o state file remoto.

Há diversas opções de backend, aqui iremos utilizar o Terraform Cloud.

1. Autenticar no terraform cloud

```bash
terraform login
```

2. Adicionar o bloco backend no arquivo de configuração

 provider.tf
```hcl
terraform {
  backend "remote" {
    organization = "orgjoaolms"

    workspaces {
      name = "tech-talk"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.66.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "joaosobrinho"
  region  = "sa-east-1"
}
```

3. Executar o init, este comando já solicitará para fazer a migração do state file local para o remoto
```bash
terraform init
```

4. Exclua o state file local
```bash
rm terraform.tfstate*
```

5. O Terraform Cloud executa os comando remotamente ou local, são workflows que pode ser escolhido na configuração, neste caso altere nas configurações para a execução local.

6. Execute o plan / apply e mostre que não há state file local.

## Destroy
Este comando é destrutivo, ele irá verificar os recursos no State File e irá destruir todos os recursos.

```bash
terraform destroy
```