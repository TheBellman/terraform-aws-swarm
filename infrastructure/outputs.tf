output "vpc_id" {
   value = "${aws_vpc.main.id}"
}

output "public_subnet" {
  value = "${aws_subnet.public.cidr_block}"
}

output "private_subnet" {
  value = "${aws_subnet.private.cidr_block}"
}
