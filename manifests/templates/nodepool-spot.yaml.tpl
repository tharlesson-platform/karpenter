apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: spot-flexible
  labels:
    environment: ${ENVIRONMENT}
spec:
  template:
    metadata:
      labels:
        workload-tier: flexible
        capacity-tier: spot
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default-al2023

      taints:
        - key: spot-only
          value: "true"
          effect: NoSchedule

      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["6"]
        - key: karpenter.k8s.aws/instance-hypervisor
          operator: In
          values: ["nitro"]
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: ["c7g", "m7g", "r7g", "c8g", "m8g", "r8g"]
        - key: kubernetes.io/arch
          operator: In
          values: ["arm64"]

      expireAfter: ${SPOT_EXPIRE_AFTER}

  disruption:
    consolidateAfter: ${SPOT_CONSOLIDATE_AFTER}
    consolidationPolicy: WhenEmptyOrUnderutilized
    budgets:
      - nodes: "20%"

  limits:
    cpu: ${SPOT_CPU_LIMIT}
    memory: ${SPOT_MEMORY_LIMIT}

  weight: 20