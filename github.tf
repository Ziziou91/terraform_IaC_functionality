terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
    token = var.GITHUB_TERRAFORM_TOKEN
}

resource "github_repository" "terraform_IaC_functionality" {
  name        = "terraform_IaC_functionality"
  description = "Project to demonstrate IaC functionality of Terraform"

  visibility = "public"
  auto_init = true
}

resource "github_repository_file" "add_file" {
  overwrite_on_create = true
  for_each = toset(var.files_to_commit)
  repository          = github_repository.terraform_IaC_functionality.name
  branch              = "main"
  file                = each.key
  content =   file(each.key) 

}