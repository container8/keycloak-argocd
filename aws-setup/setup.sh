#!/usr/bin/env bash

export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export REGION=$(aws configure get region)

# Configuration

EKS_ROLE_NAME=EKSClusterRole
NODE_ROLE_NAME=EKSNodeGroupRole
VPC_STACK_NAME=keycloak-eks-vpc-stack
CLUSTER_NAME=keycloak-cluster
NODEGROUP_NAME=keycloak-workers

# Permissions / Role setup

aws iam create-role \
  --role-name ${EKS_ROLE_NAME} \
  --assume-role-policy-document file://"eks-cluster-role-trust-policy.json"

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
  --role-name ${EKS_ROLE_NAME}

aws iam create-role \
  --role-name ${NODE_ROLE_NAME} \
  --assume-role-policy-document file://"eks-nodegroup-role-trust-policy.json"

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --role-name ${NODE_ROLE_NAME}
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --role-name ${NODE_ROLE_NAME}
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --role-name ${NODE_ROLE_NAME}

CLUSTER_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${EKS_ROLE_NAME}"
NODE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${NODE_ROLE_NAME}"

# Network

aws cloudformation create-stack \
  --stack-name ${VPC_STACK_NAME} \
  --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml

aws cloudformation wait stack-create-complete \
  --stack-name ${VPC_STACK_NAME}

VPC_ID=$(aws cloudformation describe-stacks --stack-name ${VPC_STACK_NAME} --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" --output text)
SUBNET_IDS=$(aws cloudformation describe-stacks --stack-name ${VPC_STACK_NAME} --query "Stacks[0].Outputs[?OutputKey=='SubnetIds'].OutputValue" --output text)

# Cluster Setup

aws eks create-cluster \
  --name ${CLUSTER_NAME} \
  --role-arn $CLUSTER_ROLE_ARN \
  --resources-vpc-config subnetIds=${SUBNET_IDS}

aws eks wait cluster-active --name ${CLUSTER_NAME}

FORMATTED_SUBNET_IDS=$(echo "${SUBNET_IDS}" | sed 's/^/"/; s/$/"/; s/,/" "/g')

aws eks create-nodegroup \
  --cluster-name ${CLUSTER_NAME} \
  --nodegroup-name ${NODEGROUP_NAME} \
  --node-role ${NODE_ROLE_ARN} \
  --subnets ${FORMATTED_SUBNET_IDS} \
  --instance-types t3.medium \
  --scaling-config minSize=2,maxSize=4,desiredSize=2

aws eks wait nodegroup-active --cluster-name ${CLUSTER_NAME} --nodegroup-name ${NODEGROUP_NAME}

aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION}
