# Terraform - Leveraging Infrastructure as Code Functionality


# Variables

Terraform allows us to declare values as variables, making our applications more dynamic and reusable. We can declare variables with the following notation:

```hcl
variable "availability_zone_names" {
  type    = list(string)
  default = ["us-west-1a"]
}
```


It can be useful to compare Terraform modules to function definitions:
- Input variables are like function arguments.
- Output values are like function return values.
- Local values are like a function's temporary local variables.

As well as declaring variables in a .tf file, we can also declare them in a workspace or use system environment variables.

## Setting and using Environment Variables

We can assign system environment variables as terraform variables. This is ideal when we might want to use sensitive information, such as a GitHub token, or AWS access key, in our Terraform projects without having to hardcode it into our apps. 

In order for Terraform to detect our environment variable we need to prefix it with TF_VAR_ like so:

```hcl
TF_VAR_super_secret_variable
```
Terraform will automatically detect this variable and use it if referenced. We can assign the 

Alternatively, we can pass environment veriable in the CLI like so:
```bash
terraform apply -var super_secret_variable=$super_secret_variable
```
## variables.tf and terraform.tfvars

HCL allows us to separate the **declaration** and **value assignment** of the variables used into a **variable.tf** file and **terraform.tfvars** file. 

We can share the variables.tf file, and outline what inputs the Terraform configuration expects, without having to provide sensitive details about my architecture.

# Dynamic Resource Creation

## The for_each Meta-Argument

Sometimes we may want to manage several similar objects or resourcxes (like a fixed pool of compute instances) without having to write a separate block for each one. We can achieve this with `for_each`.


I couldn't use a for_each loop to create the aws_instances. I needed to pass in the db's private ip address to the app's user_data - setting this in a for_each with the templatefile function would result in a Self-referential block when creating the database, even if there we didn't run user data (variable has to be declared regardless of wether it's used). Terraform doesn't allow this, resulting in an error.   


cat /var/log/cloud-init-output.log
terraform apply -target=github_repository.terraform_IaC_functionality -target=github_repository_file.add_file

# S3 State Storage

"state" refers to the data structure that Terraform uses to keep track of the infrastructure resources it manages. Allows us to track the config and all associated data.

**Using an AWS S3 bucket for state storage means that:**

- Shared state: when working in a team, multiple team members can access and work on the same state file.
- State Locking: We can use DynamoDB in conjunction with S3 to lock the state, preventing concurrent operations that could corrupt the state file.
- Encryption: S3 supports server-side encryption (SSE) to protect your state file at rest. 
- Disaster Recovery: Storing state in a highly durable service like S3 ensures that your state file is available even in the event of hardware failure or other disasters.

