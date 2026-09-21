# Network Policy
Every application in the cluster is locked down with a Cilium Network Policy (used over plain Kubernetes NetworkPolicies for the extra granularity, DNS-aware rules, FQDN allowlisting, etc). Each namespace has a default deny-all for both ingress and egress.

Apps using OIDC need egress to Authentik and kube-dns, plus ingress from the [`ingress` entity](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) (Cilium's label for traffic arriving via Gateway API). Apps without native OIDC support (Prometheus, Glance, etc.) sit behind Authentik's Outpost instead, so they need ingress allowed from Authentik itself rather than from `ingress` directly.

If Cilium CLI is installed, `cilium hubble ui` is useful for watching live ingress/egress traffic and seeing what's getting dropped.

## Notes

### DNS wildcard matching
```yaml
toPorts:
  - ports:
      - port: "53"
        protocol: ANY
    rules:
      dns:
        - matchPattern: "*"
```

`matchPattern: "*"` here does not mean "allow all traffic." It's scoped to port 53 traffic to kube-dns, so it only means "allow the pod to make any DNS query." A few things worth keeping in mind:
- Cilium's FQDN-based policies (`toFQDNs: matchName` / `matchPattern`) work by snooping DNS responses to learn which IPs map to which allowed domains, that snooping requires the pod to actually be able to resolve DNS in the first place, hence this rule.
- Locking DNS down to only resolve specific domains would mean maintaining that list separately from the `toFQDNs` allowlist.
- The `rules.dns` block also switches on Cilium's DNS-aware L7 proxying, which is what lets Hubble show the actual domain being queried instead of just a bare IP, information it can't get from ordinary L3/L4 flow observation alone.
- See [Cilium's DNS-based policy docs](https://docs.cilium.io/en/stable/security/policy/layer3/#dns-based).

### Glance Cluster-wide Network Policy
Glance needs egress to a bunch of small homelab services scattered across different namespaces (Prometheus, Vaultwarden, etc.). A normal namespaced `CiliumNetworkPolicy` implicitly scopes `toEndpoints` matches to its own namespace, so reaching pods in other namespaces would mean adding `io.kubernetes.pod.namespace` to every single rule. Using a `CiliumClusterwideNetworkPolicy` instead removes that implicit scoping: Glance's egress rule just matches on a shared label (e.g. `homelab.io/glance-visible: "true"`) applied to any service that should be reachable, regardless of which namespace it actually lives in, one rule instead of one per namespace.

### Hairpinning
Some in-cluster traffic doesn't go pod-to-pod directly, it leaves toward an external-facing address and loops back in. An app with OIDC (say Vaultwarden's SSO) flow is an example:

```
          Vaultwarden
              |
              v
authentik.homelab.example.com
              |
              v
          192.168.1.11
              |
              v
            Gateway
              |
              v
          Authentik
```

Vaultwarden resolves `authentik.homelab.example.com`, which points at the Gateway's external-facing IP, and the Gateway routes the request back into the cluster to Authentik. This matters for network policy because the identity Cilium enforces on isn't necessarily what it looks like at the DNS/application layer, the traffic is ultimately destined for the Authentik pod, so the policy can (and should) target Authentik directly rather than treating this as egress to an external address:
```yaml
egress:
  # DNS
  - toEndpoints:
      - matchLabels:
          io.kubernetes.pod.namespace: kube-system
          k8s-app: kube-dns
    toPorts:
      - ports:
          - port: "53"
            protocol: ANY
        rules:
          dns:
            - matchPattern: "authentik.homelab.example.com"
  # SSO, direct to the Authentik pod despite the hairpin
  - toEndpoints:
      - matchLabels:
          io.kubernetes.pod.namespace: authentik
          app.kubernetes.io/instance: authentik
    toPorts:
      - ports:
          - port: "9000"
            protocol: TCP
```