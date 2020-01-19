output "instance_ids" {
    value = join(",", aws_instance.web_servers.*.id)
}

output "instance_public_ip" {
    value = join(",", aws_instance.web_servers.*.public_ip)
}

output "ami_id" {
    value = data.aws_ami.recent_amazon_linux_2.id
}

output "key_name" {
    value = aws_key_pair.instance_ssh_key_pairs.id
}