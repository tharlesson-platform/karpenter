apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ondemand-general
  labels:
    environment: ${ENVIRONMENT}
spec:
  template:
    metadata:
      labels:
        workload-tier: elastic
        capacity-tier: ondemand
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default-al2023

      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]
        - key: karpenter.k8s.aws/instance-hypervisor
          operator: In
          values: ["nitro"]
        - key: karpenter.k8s.aws/instance-family
          operator: NotIn
          values: ["t3", "t4g", "m4", "c4", "r4"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]

      expireAfter: ${ONDEMAND_EXPIRE_AFTER}

  disruption:
    consolidateAfter: ${ONDEMAND_CONSOLIDATE_AFTER}
    consolidationPolicy: WhenEmptyOrUnderutilized
    budgets:
      - nodes: "10%"
      - schedule: "0 8 * * mon-fri"
        duration: 4h
        nodes: "0"

  limits:
    cpu: ${ONDEMAND_CPU_LIMIT}
    memory: ${ONDEMAND_MEMORY_LIMIT}

  weight: 40
