output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "public_subnet" {
  value = "${aws_subnet.public.cidr_block}"
}

output "private_subnet" {
  value = "${aws_subnet.private.cidr_block}"
}

output "swarm_master" {
  value = "${aws_instance.swarm_master.public_ip}"
}

output "service_url" {
  value = "http://${aws_instance.swarm_master.public_ip}"
}

output "visualizer_url" {
  value = "http://${aws_instance.swarm_master.public_ip}:8080"
}
