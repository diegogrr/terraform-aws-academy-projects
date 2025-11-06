output "elastic_ip" {
  description = "Endereço IP elástico (fixo) da instância EC2."
  value       = aws_eip.docker_host_ip.public_ip
}

output "website_url" {
  description = "URL para acessar o servidor web Nginx via navegador."
  value       = "http://${aws_eip.docker_host_ip.public_ip}"
}

output "ssh_command" {
  description = "Comando pronto para acessar a instância via SSH."
  value       = "ssh -i labsuser.pem ubuntu@${aws_eip.docker_host_ip.public_ip}"
}