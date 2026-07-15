terraform {
  backend "s3" {
    bucket       = "wl-iac-terraform-state"
    key          = "terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}