# Terraform Tutorial for DevOps [![GitHub stars](https://img.shields.io/github/stars/badges/shields.svg?style=social&label=Stars)](https://github.com/buraktokman/Terraform/)

[![Travis](https://img.shields.io/travis/rust-lang/rust.svg)](https://github.com/buraktokman/Terraform)
[![Repo](https://img.shields.io/badge/source-GitHub-303030.svg?maxAge=3600&style=flat-square)](https://github.com/buraktokman/Terraform)
[![Requires.io](https://img.shields.io/requires/github/celery/celery.svg)](https://requires.io/github/buraktokman/Terraform/requirements/?branch=master)
[![Scrutinizer](https://img.shields.io/scrutinizer/g/filp/whoops.svg)](https://github.com/buraktokman/Terraform)
[![DUB](https://img.shields.io/dub/l/vibe-d.svg)](https://choosealicense.com/licenses/mit/)
[![Donate with Bitcoin](https://img.shields.io/badge/Donate-BTC-orange.svg)](https://blockchain.info/address/17dXgYr48j31myKiAhnM5cQx78XBNyeBWM)
[![Donate with Ethereum](https://img.shields.io/badge/Donate-ETH-blue.svg)](https://etherscan.io/address/91dd20538de3b48493dfda212217036257ae5150)

Terraform is one of the most popular an open-source DevOps tools for Infrastructure as code. Learn how it can be utilized to manage and automate your AWS cloud infrastructure.

Twitter: [@tokmanburak](https://twitter.com/tokmanburak)

------

### Instructions

0. Fork, clone or download this repository.

1. Navigate to the directory.

2. Set up AWS environment variables.

3. Execute Terraform commands.

	```bash
	# DOWNLOAD
	git clone https://github.com/buraktokman/terraform.git
	cd terraform
	
	# CREATE RESOURCES
	terraform init
	terraform plan -var-file=variables.tfvars -out=infra.out
	terraform apply "infra.out"
	
	# DESTROY RESOURCES
	terraform destroy -var-file=variables.tfvars


------

### Versions

**0.1.1 (done)**

```
- Cloud providers
- AWS resource management
- Change and destroy AWS resources
- Terraform commands
- Terraform state
- Output values
- Input variables (parameterize configuration)
- Environment variables
```

**0.0.6 beta**

```
- Use of default AWS components
- Create security group with firewall configuration
- Fetch Amazon Machine Image (AMI) for EC Instance
- Practice for infrastructure configuration
```

**0.0.5 beta**

```
- Introduction to provisioners
- Remote-exec, local-exec and file provisioners
```

**0.0.4 beta**

```
- TF modules
- Project structure
- Use of local modules and AWS network configuration
- Module outputs
- Encapsulating server configuration
- Modularize TF project
- Use third-party modules from Terraform registry
```

**0.0.3 beta**

```
- Introduction to remote state
- Configure remote storage with AWS S3 bucket
```

**0.0.2 beta**

```
- More resources
```

**0.0.1 init**

```
- Init
- AWS configuration
```

------

### License

MIT License



