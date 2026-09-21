# OpenEBS
OpenEBS is a Kubernetes storage solution that runs anywhere, from bare metal to the cloud. OpenEBS provides both local and replicated storage engines, allowing you to choose the right storage solution for each workload.

Local Storage using Local PV Hostpath provisions Kubernetes PersistentVolumes from a directory on a specific node’s filesystem (e.g., under `/mnt/homelab`) and binds the PV with node affinity so the pod must run on that node. If the node goes down the pod loses access to its storage and cannot be rescheduled elsewhere unless you have back up and manually migrate the data.

Mayastor is OpenEBS’s replicated storage engine where each Kubernetes volume gets its own NVMe-oF controller (nexus) and synchronous replicas carved from DiskPools on different nodes; the control plane places replicas on separate nodes and the nexus exports the volume over NVMe-oF TCP so pods see it as a standard block device, writes are acknowledged only after all replicas commit, and it limits metadata overhead and blast radius on node failure while keeping everything declarative via Kubernetes CRs.

## Notes
- Running Mayastor on Talos requires some adjustments, check the [documentation](https://openebs.io/docs/Solutioning/openebs-on-kubernetes-platforms/talos) for more.
- DiskPools are where Mayastor stores volume replicas. Each node needs at least one DiskPool pointing to a dedicated block device ([reference](https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/configuration/rs-create-diskpool)).
- You'll then need to create a StorageClass that uses Mayastor for replicated volumes. The `repl` paramater defines the amount of replicas across disks ([reference](https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/configuration/rs-create-storageclass)).
- Some applications may require direct access to a block device, OpenEBS allows that using raw block volumes ([reference](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-zfs/advanced-operations/zfs-raw-block-volume)).