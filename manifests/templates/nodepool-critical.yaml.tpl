apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: critical-ondemand
  labels:
    environment: ${ENVIRONMENT}
spec:
  template:
    metadata:
      labels:
        workload-tier: critical
        capacity-tier: ondemand
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default-al2023

      taints:
        - key: critical-only
          value: "true"
          effect: NoSchedule

      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: ["c6i", "m6i", "r6i", "c7i", "m7i", "r7i"]
        - key: karpenter.k8s.aws/instance-hypervisor
          operator: In
          values: ["nitro"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]

      expireAfter: ${CRITICAL_EXPIRE_AFTER}

  disruption:
    consolidateAfter: ${CRITICAL_CONSOLIDATE_AFTER}
    consolidationPolicy: WhenEmpty
    budgets:
      - nodes: "1"
      - schedule: "0 9 * * mon-fri"
        duration: 8h
        nodes: "0"

  limits:
    cpu: ${CRITICAL_CPU_LIMIT}
    memory: ${CRITICAL_MEMORY_LIMIT}

  weight: 80
