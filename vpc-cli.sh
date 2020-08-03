vpc_name="my-vpc-using-cli"
vpcCidrBlock="10.1.0.0/26"
response=$(aws ec2 create-vpc \
   --cidr-block "$vpcCidrBlock" \
   --output json)
vpc_id=$(echo -e "$response" |  /usr/bin/jq '.Vpc.VpcId' | tr -d '"')

aws ec2 create-tags \
  --resources "$vpc_id" \
  --tags Key=Name,Value="$vpc_name"

subnet_response_1=$(aws ec2 create-subnet \
 --cidr-block "10.1.0.0/28" \
 --availability-zone "us-east-1a" \
 --vpc-id "$vpc_id" \
 --output json)
subnet_id_1=$(echo -e "$subnet_response_1" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')

aws ec2 create-tags \
  --resources "$subnet_id_1" \
  --tags Key=Name,Value="private_sub_1"


subnet_response_2=$(aws ec2 create-subnet \
 --cidr-block "10.1.0.16/28" \
 --availability-zone "us-east-1b" \
 --vpc-id "$vpc_id" \
 --output json)
subnet_id_2=$(echo -e "$subnet_response_2" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')

aws ec2 create-tags \
  --resources "$subnet_id_2" \
  --tags Key=Name,Value="private_sub_2"


subnet_response_3=$(aws ec2 create-subnet \
 --cidr-block "10.1.0.32/28" \
 --availability-zone "us-east-1c" \
 --vpc-id "$vpc_id" \
 --output json)
subnet_id_3=$(echo -e "$subnet_response_3" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
#name the subnet
aws ec2 create-tags \
  --resources "$subnet_id_3" \
  --tags Key=Name,Value="public_sub_1"


subnet_response_4=$(aws ec2 create-subnet \
 --cidr-block "10.1.0.48/28" \
 --availability-zone "us-east-1d" \
 --vpc-id "$vpc_id" \
 --output json)
subnet_id_4=$(echo -e "$subnet_response_4" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
#name the subnet
aws ec2 create-tags \
  --resources "$subnet_id_4" \
  --tags Key=Name,Value="public_sub_2"


gateway_response=$(aws ec2 create-internet-gateway \
 --output json)
gateway_id=$(echo -e "$gateway_response" |  /usr/bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')

aws ec2 create-tags \
  --resources "$gateway_id" \
  --tags Key=Name,Value="my_ig_20952"

ig_attach_response=$(aws ec2 attach-internet-gateway \
 --internet-gateway-id "$gateway_id"  \
 --vpc-id "$vpc_id")

private_route_table_response=$(aws ec2 create-route-table \
--vpc-id "$vpc_id" \
--output json)
private_route_table_id=$(echo -e "$private_route_table_response" |  /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
#name the route table
aws ec2 create-tags \
 --resources "$private_route_table_id" \
 --tags Key=Name,Value="private_route_table"

public_route_table_response=$(aws ec2 create-route-table \
--vpc-id "$vpc_id" \
--output json)
public_route_table_id=$(echo -e "$public_route_table_response" |  /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')

aws ec2 create-tags \
--resources "$public_route_table_id" \
--tags Key=Name,Value="public_route_table"

public_ig_route_response=$(aws ec2 create-route \
--route-table-id "$public_route_table_id" \
--destination-cidr-block "0.0.0.0/0" \
--gateway-id "$gateway_id")

sub1_associate_response=$(aws ec2 associate-route-table \
 --subnet-id "$subnet_id_1" \
 --route-table-id "$private_route_table_id")


sub2_associate_response=$(aws ec2 associate-route-table \
--subnet-id "$subnet_id_2" \
--route-table-id "$private_route_table_id")


sub3_associate_response=$(aws ec2 associate-route-table \
 --subnet-id "$subnet_id_3" \
 --route-table-id "$public_route_table_id")


sub4_associate_response=$(aws ec2 associate-route-table \
--subnet-id "$subnet_id_4" \
--route-table-id "$public_route_table_id")


elastic_ip_response=$(aws ec2 allocate-address --domain vpc)

echo $elastic_ip_response
elastic_ip=$(echo -e "$elastic_ip_response" |  /usr/bin/jq '.AllocationId' | tr -d '"')

nat_response=$(aws ec2 create-nat-gateway --subnet-id "$subnet_id_3" --allocation-id "$elastic_ip")

ng_id=$(echo -e "$nat_response" |  /usr/bin/jq '.NatGateway.NatGatewayId' | tr -d '"')

aws ec2 wait nat-gateway-available \
    --nat-gateway-ids "$ng_id"

private_nat_route_response=$(aws ec2 create-route \
--route-table-id "$private_route_table_id" \
--destination-cidr-block "0.0.0.0/0" \
--gateway-id "$ng_id")
