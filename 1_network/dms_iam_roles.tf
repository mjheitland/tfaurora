#----------------
#--- IAM Policies
#----------------

# Database Migration Service requires the below IAM Roles to be created before
# replication instances can be created. See the DMS Documentation for
# additional information: https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.APIRole.html
#  * dms-vpc-role
#  * dms-cloudwatch-logs-role
#  * dms-access-for-endpoint
data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
 
    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}
 
resource "aws_iam_role" "dms-access-for-endpoint" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-access-for-endpoint"
}
 
resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
  policy_arn         = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role               = aws_iam_role.dms-access-for-endpoint.name
}
 
resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role"
}
 
resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn         = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role               = aws_iam_role.dms-cloudwatch-logs-role.name
}
 
resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-vpc-role"
}
 
resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn         = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role               = aws_iam_role.dms-vpc-role.name
}
