data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../01-networking/terraform.tfstate"
  }
}