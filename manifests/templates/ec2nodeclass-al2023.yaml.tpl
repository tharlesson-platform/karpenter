apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default-al2023
  labels:
    environment: ${ENVIRONMENT}
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: ${AMI_ALIAS_AL2023}

  instanceProfile: ${KARPENTER_INSTANCE_PROFILE_NAME}

  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${CLUSTER_NAME}

  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${CLUSTER_NAME}

  metadataOptions:
    httpEndpoint: enabled
    httpTokens: required
    httpPutResponseHopLimit: 2

  detailedMonitoring: true

  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeType: gp3
        volumeSize: ${ROOT_VOLUME_SIZE_GB}Gi
        encrypted: true
        deleteOnTermination: true
        iops: 3000
        throughput: 125

  tags:
    Name: ${CLUSTER_NAME}-karpenter
    environment: ${ENVIRONMENT}
    kubernetes.io/cluster/${CLUSTER_NAME}: owned
    workload-tier: elastic