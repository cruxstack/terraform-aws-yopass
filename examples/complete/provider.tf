provider "aws" {
  region = "us-east-1"
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
