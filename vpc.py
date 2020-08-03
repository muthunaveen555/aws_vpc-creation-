import boto3

ec2 = boto3.resource('ec2', region_name='us-east-1')

vpc = ec2.create_vpc(
    CidrBlock='10.1.0.0/26',
    InstanceTenancy='default',
    TagSpecifications=[
        {
            'ResourceType': 'vpc',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'naveenkumar-20952'
                }
            ]
        }
    ]
)
print(vpc.id)

subnet_priv_1 = ec2.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'private-subnet-1'
                },
            ]
        },
    ],
    AvailabilityZone='us-east-1a',
    CidrBlock='10.1.0.0/28',
    VpcId=vpc.id,
)

print(subnet_priv_1.id)

subnet_priv_2 = ec2.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'private-subnet-2'
                },
            ]
        },
    ],
    AvailabilityZone='us-east-1b',
    CidrBlock='10.1.0.16/28',
    VpcId=vpc.id,
)
print(subnet_priv_2.id)

subnet_pub_1 = ec2.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'public-subnet-1'
                },
            ]
        },
    ],
    AvailabilityZone='us-east-1c',
    CidrBlock='10.1.0.32/28',
    VpcId=vpc.id,
)
print(subnet_pub_1.id)

subnet_pub_2 = ec2.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'public-subnet-2'
                },
            ]
        },
    ],
    AvailabilityZone='us-east-1d',
    CidrBlock='10.1.0.48/28',
    VpcId=vpc.id,
)
print(subnet_pub_2.id)

internet_gateway = ec2.create_internet_gateway(
    TagSpecifications=[
        {
            'ResourceType': 'internet-gateway',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'internet_gateway_20952'
                },
            ]
        },
    ],
)
print(internet_gateway.id)

response = vpc.attach_internet_gateway(
    InternetGatewayId=internet_gateway.id,
)
print("response\n\n")
print(response)

client = boto3.client('ec2')
addr = client.allocate_address(Domain='vpc')
print(addr)

response = client.create_nat_gateway(
    AllocationId=addr['AllocationId'],
    SubnetId=subnet_pub_1.id,
    TagSpecifications=[
        {
            'ResourceType': 'natgateway',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'natgateway-20952'
                },
            ]
        },
    ]
)
print(response)

route_table_priv = vpc.create_route_table(
    TagSpecifications=[
        {
            'ResourceType': 'route-table',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'route_table_priv-20952'
                },
            ]
        },
    ]
)
route_table_pub = vpc.create_route_table(
    TagSpecifications=[
        {
            'ResourceType': 'route-table',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'route_table_pub-20952'
                },
            ]
        },
    ]
)


route_internet = route_table_pub.create_route(
    DestinationCidrBlock='0.0.0.0/0',
    GatewayId=internet_gateway.id
)
nat_gateway_ids = [response['NatGateway']['NatGatewayId']]
client.get_waiter('nat_gateway_available').wait(NatGatewayIds=nat_gateway_ids)
route_natgateway = route_table_priv.create_route(
    DestinationCidrBlock='0.0.0.0/0',
    GatewayId=response['NatGateway']['NatGatewayId']
)

route_table_priv.associate_with_subnet(SubnetId=subnet_priv_1.id)

route_table_priv.associate_with_subnet(SubnetId=subnet_priv_2.id)

route_table_pub.associate_with_subnet(SubnetId=subnet_pub_1.id)

route_table_pub.associate_with_subnet(SubnetId=subnet_pub_2.id)
