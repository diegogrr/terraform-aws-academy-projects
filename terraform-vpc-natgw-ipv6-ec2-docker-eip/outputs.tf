output "vpc_id" {
  description = "ID da VPC criada."
  value       = aws_vpc.main.id
}

output "instance_elastic_ip_ipv4" {
  description = "Endereço IPv4 público (fixo) da instância."
  value       = aws_eip.docker_host_ip.public_ip
}

output "instance_ipv6" {
  description = "Endereço(s) IPv6 da instância."
  value       = aws_instance.docker_host.ipv6_addresses
}

output "ssh_command_ipv4" {
  value = "ssh -i labsuser.pem ubuntu@${aws_eip.docker_host_ip.public_ip}"
}

# Bônus: comando SSH via IPv6 (só funcionará se o aluno tiver IPv6 em casa/faculdade)
output "ssh_command_ipv6" {
  value = "ssh -i labsuser.pem ubuntu@[${aws_instance.docker_host.ipv6_addresses[0]}]"
}

output "website_url" {
  value = "http://${aws_eip.docker_host_ip.public_ip}"
}