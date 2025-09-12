#!/usr/bin/env bash

export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export REGION=$(aws configure get region)

# Configuration

EKS_ROLE_NAME=EKSClusterRole
NODE_ROLE_NAME=EKSNodeGroupRole
VPC_STACK_NAME=keycloak-eks-vpc-stack
CLUSTER_NAME=keycloak-cluster
NODEGROUP_NAME=keycloak-workers

# Delete Node Group
aws eks delete-nodegroup --cluster-name ${CLUSTER_NAME} --nodegroup-name ${NODEGROUP_NAME}

# Delete Cluster
aws eks delete-cluster --name ${CLUSTER_NAME}

# Delete CloudFormation Stack
aws cloudformation delete-stack --stack-name ${VPC_STACK_NAME}

# Detach and delete IAM roles
aws iam detach-role-policy --role-name ${NODE_ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name ${NODE_ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam detach-role-policy --role-name ${NODE_ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam delete-role --role-name ${NODE_ROLE_NAME}

aws iam detach-role-policy --role-name ${EKS_ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam delete-role --role-name ${EKS_ROLE_NAME}
