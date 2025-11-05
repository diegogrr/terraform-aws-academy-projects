output "instance_public_ip" {
  description = "Endereço IP público da instância EC2."
  value       = aws_instance.docker_host.public_ip
}

output "website_url" {
  description = "URL para acessar o servidor web Nginx via navegador."
  value       = "http://${aws_instance.docker_host.public_ip}"
}

output "ssh_command" {
  description = "Comando pronto para acessar a instância via SSH (certifique-se de ter a chave labsuser.pem)."
  value       = "ssh -i labsuser.pem ubuntu@${aws_instance.docker_host.public_ip}"
}

