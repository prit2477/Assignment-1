output "s3_bucket_id" {
  value = aws_s3_bucket.bucket.id
}

output "efs_id" {
  value = aws_efs_file_system.efs.id
}

output "ec2_instance_id" {
  value = aws_instance.ec2.id
}

output "security_group_id" {
  value = aws_security_group.sg.id
}

output "subnet_id" {
  value = aws_subnet.subnet.id
}