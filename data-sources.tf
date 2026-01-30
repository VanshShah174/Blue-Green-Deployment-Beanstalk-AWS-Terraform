# Get the latest Node.js 20 solution stack
data "aws_elastic_beanstalk_solution_stack" "nodejs" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 .* running Node.js 20$"
}